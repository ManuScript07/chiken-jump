class_name StarMedallion
extends Node

const CAPTURE_SIZE := Vector2i(96,96)
var viewport: SubViewport
var model: MeshInstance3D
var texture: ViewportTexture

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.size = CAPTURE_SIZE
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.positional_shadow_atlas_size = 0
	# A static badge is rendered once, rather than adding a mobile per-frame pass.
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0,0,0,0)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("e1d4bd")
	settings.ambient_light_energy = 0.45
	environment.environment = settings
	world.add_child(environment)
	model = MeshInstance3D.new()
	model.mesh = _mesh()
	model.rotation_degrees = Vector3(12,-30,0)
	model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("e5ac3b")
	gold.metallic = 0.35
	gold.roughness = 0.32
	model.material_override = gold
	world.add_child(model)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25,-30,0)
	light.light_color = Color("fff2ce")
	light.light_energy = 1.15
	world.add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(20,110,0)
	fill.light_color = Color("b7bbd2")
	fill.light_energy = 0.3
	world.add_child(fill)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.5
	camera.position = Vector3(0,0,4)
	world.add_child(camera)
	camera.current = true
	texture = viewport.get_texture()

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (b-a).cross(c-a).normalized()
	# Godot front faces use clockwise winding; normals point out of the closed mesh.
	for vertex in [a,c,b]:
		surface.set_normal(normal)
		surface.add_vertex(vertex)

func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_triangle(surface,a,b,c)
	_triangle(surface,a,c,d)

func _mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector2] = []
	for i in 10:
		points.append(Vector2.from_angle(PI*0.5+float(i)*TAU/10.0)*(1.0 if i%2==0 else 0.46))
	for i in 10:
		var next := (i+1)%10
		var a := points[i]
		var b := points[next]
		var front_a := Vector3(a.x*0.82,a.y*0.82,0.16)
		var front_b := Vector3(b.x*0.82,b.y*0.82,0.16)
		var rim_a := Vector3(a.x,a.y,0.02)
		var rim_b := Vector3(b.x,b.y,0.02)
		var back_a := Vector3(a.x,a.y,-0.28)
		var back_b := Vector3(b.x,b.y,-0.28)
		_triangle(surface,Vector3(0,0,0.23),front_a,front_b)
		_quad(surface,front_a,rim_a,rim_b,front_b)
		_quad(surface,rim_a,back_a,back_b,rim_b)
		_triangle(surface,Vector3(0,0,-0.28),back_b,back_a)
	surface.index()
	return surface.commit()
