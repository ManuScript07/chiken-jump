class_name RenderQualityTests
extends SceneTree

const DESIGN = preload("res://scripts/level_design.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if value:
		print("PASS: ",message)
	else:
		failures += 1
		printerr("FAIL: ",message)

func _run() -> void:
	var vertices := 0
	var triangles := 0
	var valid_meshes := true
	for piece in DESIGN.pieces():
		var arrays := PrimitiveGeometry.mesh(piece).surface_get_arrays(0)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		vertices += points.size()
		triangles += indices.size()/3
		valid_meshes = valid_meshes and points.size()==normals.size() and not indices.is_empty()
		for normal in normals:
			valid_meshes = valid_meshes and normal.is_finite() and absf(normal.length()-1.0)<0.001
		for index in indices:
			valid_meshes = valid_meshes and index>=0 and index<points.size()
	check(valid_meshes,"indexed meshes retain valid normalized shading data")
	check(vertices<564 and triangles==188,"vertex deduplication adds no triangles")
	print("Reference installation: ",vertices," indexed vertices; ",triangles," triangles")
	var level: ChickenLevel = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	level.field.running = false
	level.player.enabled = false
	level.field.angle = PI/4.0
	level.field.update_projection(true)
	for i in 8:
		await RenderingServer.frame_post_draw
	var view := level.diorama
	var viewport := view.camera.get_viewport()
	check(viewport.msaa_3d==Viewport.MSAA_2X,"native multisampling smooths the thin 3D models")
	check(viewport.positional_shadow_atlas_size==4096 and viewport.positional_shadow_atlas_16_bits,"shadow atlas retains the baseline memory budget")
	check(viewport.size==Vector2i(540,960) and view.floor_reflection.viewport.size==Vector2i(180,320),"render target sizes have not increased")
	check(ProjectSettings.get_setting_with_override("rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality")==2,"shadow filtering matches the desktop reference configuration")
	var frame := root.get_texture().get_image()
	var wall := frame.get_pixel(80,250)
	check(wall.r>wall.b and wall.r-wall.g<0.08 and wall.r-wall.b<0.08,"wall remains off-white with a subtle warm pink tint")
	print("RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
