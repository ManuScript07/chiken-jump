class_name DiskDiorama
extends Control

const DESIGN = preload("res://scripts/level_design.gd")
var rotor: Node3D

func _ready() -> void:
	position = Vector2(30, 625)
	size = Vector2(480, 170)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var container := SubViewportContainer.new()
	container.size = size
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 340)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.own_world_3d = true
	container.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.87, 0.9, 0.87)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.85, 0.83)
	env.ambient_light_energy = 0.75
	environment.environment = env
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 1.0
	world.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.7
	camera.position = Vector3(7, 5.5, 9)
	world.add_child(camera)
	camera.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	camera.current = true
	rotor = Node3D.new()
	world.add_child(rotor)
	var disk := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 2.9
	mesh.bottom_radius = 2.9
	mesh.height = 0.24
	disk.mesh = mesh
	disk.position.y = -0.12
	disk.material_override = _material(Color(0.65, 0.48, 0.34))
	rotor.add_child(disk)
	for piece in DESIGN.pieces():
		var box := MeshInstance3D.new()
		box.mesh = DESIGN.prism_mesh(piece)
		box.position = piece.center
		box.material_override = _material(piece.color)
		rotor.add_child(box)

func set_angle(value: float) -> void:
	if rotor != null:
		rotor.rotation.y = value

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
