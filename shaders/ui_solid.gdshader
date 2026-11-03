shader_type spatial;
uniform vec4 face_color : source_color = vec4(1.0);
varying float front_face;
void vertex() {
	front_face = step(0.65, NORMAL.z);
}
void fragment() {
	ALBEDO = mix(face_color.rgb * vec3(0.46,0.42,0.46),face_color.rgb,front_face);
	METALLIC = 0.12;
	ROUGHNESS = 0.42;
}
