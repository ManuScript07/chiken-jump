class_name DiskDiorama
extends Control

const DESIGN = preload("res://scripts/level_design.gd")
var rotor: Node3D
var wall_viewport: SubViewport
var projection_canvas: ProjectionCanvas
var camera: Camera3D
var key_light: SpotLight3D
var room_wall: MeshInstance3D
var room_floor: MeshInstance3D
var piece_nodes: Array[MeshInstance3D] = []

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(540,960)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	wall_viewport = SubViewport.new()
	wall_viewport.size = DESIGN.WALL_TEXTURE_SIZE
	wall_viewport.world_2d = World2D.new()
	wall_viewport.transparent_bg = true
	wall_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(wall_viewport)
	projection_canvas = ProjectionCanvas.new()
	projection_canvas.position = -Vector2(DESIGN.WALL_CROP_X,DESIGN.WALL_CROP_Y)
	wall_viewport.add_child(projection_canvas)
	var container := SubViewportContainer.new()
	container.size = size
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(540,960)
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.positional_shadow_atlas_size = 4096
	viewport.positional_shadow_atlas_quad_0 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_1
	viewport.positional_shadow_atlas_quad_1 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_1
	viewport.positional_shadow_atlas_quad_2 = Viewport.SHADOW_ATLAS_QUADRANT_SUBDIV_1
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	var world := Node3D.new()
	world.name = "Room"
	viewport.add_child(world)
	_build_environment(world)
	_build_room(world)
	_build_installation(world)
	_build_lighting(world)

func _build_environment(world: Node3D) -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("252333")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("455fae")
	env.ambient_light_energy = 0.5
	environment.environment = env
	world.add_child(environment)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-45,-35,0)
	fill.light_color = Color("9aaccf")
	fill.light_cull_mask = 3
	fill.light_energy = 0.12
	world.add_child(fill)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 38.0
	camera.position = Vector3(0.45,4.0,19.0)
	world.add_child(camera)
	camera.look_at(Vector3(0,1.6,-0.5),Vector3.UP)
	camera.current = true

func _build_room(world: Node3D) -> void:
	# The wall and floor share a real junction, rather than a framed screen.
	room_floor = _box(world,Vector3(0,DESIGN.FLOOR_Y-0.08,16),Vector3(80,0.16,40),Color("6b6364"),0.48)
	room_floor.name = "Floor"
	room_floor.layers = 2
	room_floor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	room_wall = _box(world,Vector3(0,DESIGN.FLOOR_Y+12,DESIGN.WALL_Z-0.1),Vector3(80,24,0.2),Color("bfb9bd"),0.95)
	room_wall.name = "Wall"
	room_wall.layers = 4
	room_wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Only the avatar and collectibles are composited on the lit physical wall.
	# All silhouettes are real shadows cast by the meshes in the installation.
	var overlay := MeshInstance3D.new()
	overlay.name = "WallGameplay"
	var quad := QuadMesh.new()
	quad.size = Vector2(DESIGN.WALL_TEXTURE_SIZE) / DESIGN.SCALE
	overlay.mesh = quad
	overlay.position = DESIGN.canvas_to_wall(Vector2(DESIGN.WALL_CROP_X+DESIGN.WALL_TEXTURE_SIZE.x/2.0,DESIGN.WALL_CROP_Y+DESIGN.WALL_TEXTURE_SIZE.y/2.0)) + Vector3(0,0,0.003)
	var surface := StandardMaterial3D.new()
	surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	surface.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	surface.albedo_texture = wall_viewport.get_texture()
	surface.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	overlay.material_override = surface
	overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(overlay)

func _build_installation(world: Node3D) -> void:
	rotor = Node3D.new()
	rotor.name = "Turntable"
	rotor.position = DESIGN.RIG_CENTER
	rotor.scale = Vector3.ONE * DESIGN.MODEL_SCALE
	world.add_child(rotor)
	var disk := MeshInstance3D.new()
	disk.name = "Disk"
	disk.mesh = DESIGN.disk_mesh()
	disk.position.y = -DESIGN.DISK_HEIGHT / 2.0
	disk.material_override = _material(Color("33343f"),0.52)
	rotor.add_child(disk)
	var installation := DESIGN.create_installation()
	rotor.add_child(installation)
	for object in PrimitivePiece.collect(installation):
		piece_nodes.append(object)

func _build_lighting(world: Node3D) -> void:
	key_light = SpotLight3D.new()
	key_light.name = "SideLight"
	key_light.position = DESIGN.LIGHT_POSITION
	key_light.light_color = Color("fff0dc")
	key_light.light_energy = 1.5
	key_light.light_cull_mask = 5
	key_light.spot_range = 35.0
	key_light.spot_attenuation = 0.12
	key_light.spot_angle = 42.0
	key_light.shadow_enabled = true
	key_light.shadow_bias = 0.015
	key_light.shadow_normal_bias = 0.02
	key_light.shadow_blur = 0.5
	world.add_child(key_light)
	key_light.look_at(DESIGN.canvas_to_wall(Vector2(270,450)),Vector3.UP)
	# Broad bounced room light illuminates the floor without exposing a spotlight cone.
	var floor_light := OmniLight3D.new()
	floor_light.name = "FloorBounce"
	floor_light.position = Vector3(0,5,4)
	floor_light.light_color = Color("d3ccda")
	floor_light.light_energy = 0.85
	floor_light.omni_range = 24.0
	floor_light.omni_attenuation = 0.7
	floor_light.light_cull_mask = 3
	floor_light.shadow_caster_mask = 1
	floor_light.shadow_enabled = true
	floor_light.shadow_bias = 0.005
	floor_light.shadow_normal_bias = 0.01
	floor_light.shadow_blur = 0.7
	world.add_child(floor_light)

func mount_gameplay(field: ShadowField, player: SquarePlayer, level: ChickenLevel) -> void:
	projection_canvas.level = level
	field.reparent(projection_canvas,false)
	field.visible = false
	player.reparent(projection_canvas,false)
	projection_canvas.queue_redraw()

func set_angle(value: float) -> void:
	if rotor != null:
		rotor.rotation.y = value

func _box(parent: Node3D, location: Vector3, dimensions: Vector3, color: Color, roughness: float) -> MeshInstance3D:
	var object := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	object.mesh = mesh
	object.position = location
	object.material_override = _material(color,roughness)
	parent.add_child(object)
	return object

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
