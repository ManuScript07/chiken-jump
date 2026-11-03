class_name PlanarReflection
extends Node

const CAPTURE_SIZE := Vector2i(180,320)
var viewport: SubViewport
var mirror_camera: Camera3D
var source_camera: Camera3D
var plane_height := 0.0
var sources: Array[MeshInstance3D] = []
var proxies: Array[MeshInstance3D] = []
var plain_disk: MeshInstance3D

# An isolated capture world prevents reflective surfaces from sampling themselves.
# Meshes and materials are shared; only instance transforms are copied each frame.
func setup(source: Camera3D, height: float, captured: Array[MeshInstance3D], disk: MeshInstance3D = null) -> ViewportTexture:
	source_camera = source
	plane_height = height
	sources = captured
	plain_disk = disk
	process_priority = -100
	viewport = SubViewport.new()
	viewport.name = "Capture"
	viewport.size = CAPTURE_SIZE
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.positional_shadow_atlas_size = 0
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = source.get_world_3d().environment.duplicate()
	environment.environment.ssao_enabled = false
	world.add_child(environment)
	for child in source.get_parent().get_children():
		if child is Light3D:
			var light := child.duplicate() as Light3D
			light.shadow_enabled = false
			world.add_child(light)
	for object in sources:
		var proxy := MeshInstance3D.new()
		proxy.mesh = object.mesh
		proxy.layers = object.layers
		proxy.material_override = object.material_override
		if object == plain_disk:
			var matte := StandardMaterial3D.new()
			var surface := object.material_override as ShaderMaterial
			matte.albedo_color = surface.get_shader_parameter("base_color")
			matte.roughness = surface.get_shader_parameter("surface_roughness")
			proxy.material_override = matte
		world.add_child(proxy)
		proxies.append(proxy)
	mirror_camera = Camera3D.new()
	mirror_camera.name = "MirrorCamera"
	world.add_child(mirror_camera)
	mirror_camera.current = true
	_update_camera()
	return viewport.get_texture()

func _process(_delta: float) -> void:
	if is_instance_valid(source_camera):
		_update_camera()

func _update_camera() -> void:
	for i in sources.size():
		if not is_instance_valid(sources[i]):
			proxies[i].visible = false
			continue
		proxies[i].global_transform = sources[i].global_transform
		proxies[i].visible = sources[i].is_visible_in_tree()
		if proxies[i].mesh != sources[i].mesh:
			proxies[i].mesh = sources[i].mesh
		if sources[i] != plain_disk and proxies[i].material_override != sources[i].material_override:
			proxies[i].material_override = sources[i].material_override
	var eye := source_camera.global_position
	var target := eye-source_camera.global_basis.z*10.0
	eye.y = plane_height*2.0-eye.y
	target.y = plane_height*2.0-target.y
	mirror_camera.global_position = eye
	mirror_camera.look_at(target,Vector3.UP)
	mirror_camera.fov = source_camera.fov
	mirror_camera.keep_aspect = source_camera.keep_aspect
	mirror_camera.near = source_camera.near
	mirror_camera.far = source_camera.far
