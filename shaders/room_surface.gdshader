shader_type spatial;
render_mode diffuse_lambert;

uniform vec4 base_color : source_color = vec4(0.5,0.48,0.45,1.0);
uniform float surface_roughness : hint_range(0.0,1.0) = 0.5;
uniform bool floor_surface = true;
uniform float floor_height = -0.096;
uniform float wall_depth = -4.0;
uniform float corner_radius : hint_range(0.01,2.0) = 0.32;
uniform float corner_strength : hint_range(0.0,1.0) = 0.65;
uniform sampler2D reflection_texture : source_color,filter_linear,repeat_disable;
uniform float reflection_strength : hint_range(0.0,1.0) = 0.0;
uniform float reflection_blur : hint_range(0.0,5.0) = 1.0;
uniform float reflection_fade_distance : hint_range(0.0,20.0) = 0.0;
// Diffuse wall bounce is a finite-height strip approximation, in world units.
uniform vec4 wall_bounce_color : source_color = vec4(1.0,0.94,0.86,1.0);
uniform float wall_bounce_strength : hint_range(0.0,2.0) = 0.0;
uniform float wall_bounce_height : hint_range(0.1,10.0) = 3.0;
uniform float wall_bounce_width : hint_range(0.1,20.0) = 7.0;
varying vec3 world_position;
varying vec3 world_normal;

float hash21(vec2 p) {
	return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);
}
float grain(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f*f*(3.0-2.0*f);
	return mix(mix(hash21(cell),hash21(cell+vec2(1.0,0.0)),f.x),mix(hash21(cell+vec2(0.0,1.0)),hash21(cell+vec2(1.0)),f.x),f.y);
}
void vertex() {
	world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	world_normal = MODEL_NORMAL_MATRIX*NORMAL;
}
void fragment() {
	vec2 plane = floor_surface ? world_position.xz : world_position.xy;
	float texture_grain = grain(plane*28.0)-0.5;
	ALBEDO = base_color.rgb*(1.0+texture_grain*0.006);
	ROUGHNESS = clamp(surface_roughness+texture_grain*0.02,0.0,1.0);
	SPECULAR = 0.35;
	float distance_to_corner = floor_surface ? max(world_position.z-wall_depth,0.0) : max(world_position.y-floor_height,0.0);
	AO = 1.0-corner_strength*exp(-distance_to_corner/corner_radius);
	AO_LIGHT_AFFECT = 0.15;
	float top_face = smoothstep(0.8,0.98,normalize(world_normal).y);
	float floor_distance = max(world_position.z-wall_depth,0.0);
	// Integrating a diffuse vertical strip gives 0.5*(1-d/sqrt(d*d+h*h)).
	// It spreads over a physical distance, instead of painting a screen-space seam.
	float strip_irradiance = 0.5*(1.0-floor_distance/sqrt(floor_distance*floor_distance+wall_bounce_height*wall_bounce_height));
	float lateral_falloff = exp(-pow(world_position.x/wall_bounce_width,2.0));
	EMISSION = ALBEDO*wall_bounce_color.rgb*wall_bounce_strength*strip_irradiance*lateral_falloff*top_face;
	if (reflection_strength>0.0) {
		// Mirror the vertical texture axis after reflecting the camera plane.
		vec2 uv = vec2(SCREEN_UV.x,1.0-SCREEN_UV.y);
		vec2 texel = reflection_blur/vec2(textureSize(reflection_texture,0));
		vec4 reflected = vec4(0.0);
		for (int y=-1;y<=1;y++) {
			for (int x=-1;x<=1;x++) {
				float weight = float((x==0 ? 2 : 1)*(y==0 ? 2 : 1))/16.0;
				vec4 sample_color = texture(reflection_texture,uv+vec2(float(x),float(y))*texel);
				reflected += vec4(sample_color.rgb*sample_color.a,sample_color.a)*weight;
			}
		}
		float fresnel = pow(1.0-max(dot(normalize(NORMAL),normalize(VIEW)),0.0),5.0);
		float distance_fade = reflection_fade_distance>0.0 ? exp(-floor_distance/reflection_fade_distance) : 1.0;
		float amount = reflection_strength*mix(0.35,1.0,fresnel)*top_face*distance_fade;
		ALBEDO *= 1.0-amount*reflected.a;
		EMISSION = EMISSION*(1.0-amount*reflected.a)+reflected.rgb*amount;
	}
}

void light() {
	float cosine = max(dot(NORMAL,LIGHT),0.0);
	// Rough surfaces retain a small grazing response, without a discontinuous cutoff.
	// The broad wall bounce supplies most of the indirect floor illumination.
	float rough_grazing = floor_surface ? mix(0.12,1.0,smoothstep(0.0,0.3,cosine)) : 1.0;
	DIFFUSE_LIGHT += ALBEDO*LIGHT_COLOR*ATTENUATION*cosine*rough_grazing;
}

