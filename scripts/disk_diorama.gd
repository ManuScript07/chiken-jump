class_name DiskDiorama
extends Control

const DESIGN = preload("res://scripts/level_design.gd")
const CANVAS = preload("res://scripts/projection_canvas.gd")
var rotor: Node3D
var wall_viewport: SubViewport
var projection_canvas: ProjectionCanvas
var camera: Camera3D

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(540, 960)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	wall_viewport = SubViewport.new()
	wall_viewport.size = DESIGN.WALL_TEXTURE_SIZE
	wall_viewport.world_2d = World2D.new()
	wall_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(wall_viewport)
	projection_canvas = CANVAS.new()
	projection_canvas.position.y = -DESIGN.WALL_CROP_Y
	wall_viewport.add_child(projection_canvas)
	var container := SubViewportContainer.new()
	container.size = size
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(540, 960)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.own_world_3d = true
	container.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("141824")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a6b4cc")
	env.ambient_light_energy = 0.55
	environment.environment = env
	world.add_child(environment)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-55,-30,0)
	fill.light_color = Color("b4c7e8")
	fill.light_energy = 0.65
	world.add_child(fill)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 15.5
	camera.position = Vector3(3.5,9,18)
	world.add_child(camera)
	camera.look_at(Vector3(0.8,1.2,0.5), Vector3.UP)
	camera.current = true
	_add_box(world, Vector3(0,-0.75,2), Vector3(15,0.4,19), Color("343c48"))
	var center := DESIGN.canvas_to_wall(Vector2(270, DESIGN.WALL_CROP_Y + DESIGN.WALL_TEXTURE_SIZE.y / 2.0))
	var wall := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(DESIGN.WALL_TEXTURE_SIZE) / DESIGN.SCALE
	wall.mesh = quad
	wall.position = center
	var surface := StandardMaterial3D.new()
	surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	surface.albedo_texture = wall_viewport.get_texture()
	surface.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	wall.material_override = surface
	world.add_child(wall)
	_add_box(world, center + Vector3(0,0,-0.08), Vector3(quad.size.x + 0.18,quad.size.y + 0.18,0.12), Color("665c53"))
	rotor = Node3D.new()
	world.add_child(rotor)
	var disk := _add_cylinder(rotor,Vector3(0,-0.12,0),2.9,0.24,Color("a87950"))
	disk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_cylinder(world,Vector3(0,-0.38,0),0.9,0.28,Color("222732"))
	for piece in DESIGN.pieces():
		var object := MeshInstance3D.new()
		object.mesh = DESIGN.prism_mesh(piece)
		object.position = piece.center
		object.material_override = _material(piece.color)
		rotor.add_child(object)
	_build_projector(world)

func mount_gameplay(field: ShadowField, player: ChickenPlayer, level: ChickenLevel) -> void:
	projection_canvas.level = level
	field.reparent(projection_canvas, false)
	player.reparent(projection_canvas, false)
	projection_canvas.queue_redraw()

func set_angle(value: float) -> void:
	if rotor != null:
		rotor.rotation.y = value

func _build_projector(world: Node3D) -> void:
	var source: Vector3 = DESIGN.LIGHT_POSITION
	_add_box(world,source + Vector3(0,-0.12,0.38),Vector3(0.95,0.32,0.8),Color("272c35"))
	_add_box(world,source + Vector3(0,-0.37,0.35),Vector3(0.65,0.24,0.5),Color("181e28"))
	var lens := _add_cylinder(world,source,0.18,0.12,Color("f6df9c"))
	lens.rotation.x = PI / 2
	var glow := _material(Color("ffe7a6"))
	glow.emission_enabled = true
	glow.emission = Color("ffe7a6")
	glow.emission_energy_multiplier = 2.0
	lens.material_override = glow
	var light := SpotLight3D.new()
	light.position = source
	light.light_color = Color("ffe7bd")
	light.light_energy = 3.0
	light.spot_range = 26
	light.spot_angle = 34
	light.shadow_enabled = true
	world.add_child(light)
	light.look_at(DESIGN.canvas_to_wall(Vector2(270,450)),Vector3.UP)
	# A faint light volume connects the lens to the actual wall corners.
	var corners := [DESIGN.canvas_to_wall(Vector2(0,280)),DESIGN.canvas_to_wall(Vector2(540,280)),DESIGN.canvas_to_wall(Vector2(540,612)),DESIGN.canvas_to_wall(Vector2(0,612))]
	var beam := SurfaceTool.new()
	beam.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 4:
		for point in [source,corners[i],corners[(i+1)%4]]:
			beam.add_vertex(point)
	var volume := MeshInstance3D.new()
	volume.mesh = beam.commit()
	var material := _material(Color(1.0,0.88,0.6,0.018))
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	volume.material_override = material
	volume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(volume)

func _add_box(parent: Node3D, location: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var object := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	object.mesh = mesh
	object.position = location
	object.material_override = _material(color)
	parent.add_child(object)
	return object

func _add_cylinder(parent: Node3D, location: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var object := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	object.mesh = mesh
	object.position = location
	object.material_override = _material(color)
	parent.add_child(object)
	return object

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
