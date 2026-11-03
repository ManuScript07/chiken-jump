class_name SculptedLabel
extends TextureRect

var viewport: SubViewport
var model: MeshInstance3D
var camera: Camera3D
var surface_material: ShaderMaterial
var value := ""
var point_size := 0.0
var tint := Color.TRANSPARENT
var arrow := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.positional_shadow_atlas_size = 0
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0,0,0,0)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("e2d8de")
	settings.ambient_light_energy = 0.5
	environment.environment = settings
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25,-20,0)
	light.light_color = Color("fff5dd")
	light.light_energy = 0.95
	world.add_child(light)
	model = MeshInstance3D.new()
	model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	surface_material = ShaderMaterial.new()
	surface_material.shader = load("res://shaders/ui_solid.gdshader")
	model.material_override = surface_material
	world.add_child(model)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.position = Vector3(0,-4,8)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO,Vector3.UP)
	camera.current = true
	texture = viewport.get_texture()

func configure(text_value: String, font_size: float, color: Color, direction: int = 0) -> void:
	if value==text_value and is_equal_approx(point_size,font_size) and tint==color and arrow==direction:
		return
	var new_mesh := model.mesh==null or value!=text_value or arrow!=direction
	value = text_value
	point_size = font_size
	tint = color
	arrow = direction
	if new_mesh:
		if direction==0:
			var letters := TextMesh.new()
			letters.font = ThemeDB.fallback_font
			letters.font_size = 48
			letters.curve_step = 0.8
			letters.pixel_size = 0.01
			letters.depth = 0.22
			letters.text = text_value
			model.mesh = letters
		else:
			model.mesh = _arrow_mesh(direction)
	var bounds := model.mesh.get_aabb()
	model.position = -bounds.get_center()
	var pixel_scale := font_size/0.48
	size = Vector2(ceilf(bounds.size.x*pixel_scale+10.0),ceilf(font_size*1.6))
	var resolution := minf(2.0,minf(1024.0/size.x,160.0/size.y))
	viewport.size = Vector2i((size*resolution).ceil())
	camera.size = size.y/pixel_scale
	surface_material.set_shader_parameter("face_color",color)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _arrow_mesh(direction: int) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := [Vector2(0.16*direction,0),Vector2(-0.16*direction,0.22),Vector2(-0.16*direction,-0.22)]
	var front: Array[Vector3] = []
	var back: Array[Vector3] = []
	for point: Vector2 in points:
		front.append(Vector3(point.x,point.y,0.11))
		back.append(Vector3(point.x,point.y,-0.11))
	_face(surface,front[0],front[1],front[2],Vector3.FORWARD*-1)
	_face(surface,back[2],back[1],back[0],Vector3.FORWARD)
	for i in 3:
		var next := (i+1)%3
		var middle: Vector2 = (points[i]+points[next])*0.5
		var normal := Vector3(middle.x,middle.y,0).normalized()
		_face(surface,front[i],back[i],back[next],normal)
		_face(surface,front[i],back[next],front[next],normal)
	surface.index()
	return surface.commit()

func _face(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	var vertices := [a,b,c] if (b-a).cross(c-a).dot(normal)<0 else [a,c,b]
	for vertex: Vector3 in vertices:
		surface.set_normal(normal)
		surface.add_vertex(vertex)
