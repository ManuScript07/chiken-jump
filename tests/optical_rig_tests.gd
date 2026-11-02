class_name OpticalRigTests
extends SceneTree

const DESIGN = preload("res://scripts/level_design.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if value:
		print("PASS: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var level: ChickenLevel = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	level.field.running = false
	var camera := level.diorama.camera
	var wall_top := camera.unproject_position(DESIGN.canvas_to_wall(Vector2(0, DESIGN.WALL_CROP_Y)))
	var wall_bottom := camera.unproject_position(DESIGN.canvas_to_wall(Vector2(540, DESIGN.WALL_CROP_Y + DESIGN.WALL_TEXTURE_SIZE.y)))
	var wall_rect := Rect2(wall_top, wall_bottom - wall_top)
	var rotor := level.diorama.rotor
	var disk: MeshInstance3D = rotor.get_child(0)
	var disk_left := camera.unproject_position(disk.to_global(Vector3(-2.9, 0, 0)))
	var disk_right := camera.unproject_position(disk.to_global(Vector3(2.9, 0, 0)))
	var source := DESIGN.LIGHT_POSITION
	var world: Node3D = rotor.get_parent()
	var projector: Node3D = world.get_node("Projector")
	check(absf(source.x) > 2.0 and projector.global_position.distance_to(source) < 0.001, "visible projector is placed at the side light source")
	check(DESIGN.project_world_point(rotor.global_position).distance_to(DESIGN.WALL_ORIGIN) < 0.001, "compact rig remains optically centered on the wall")
	check(disk_left.distance_to(disk_right) < wall_rect.size.x * 0.3, "physical disk occupies less than a third of the wall width")
	check(source.distance_to(rotor.global_position) < source.distance_to(DESIGN.canvas_to_wall(DESIGN.WALL_ORIGIN)) * 0.3, "rig is near the lens with room for a large shadow")
	var aim := (DESIGN.canvas_to_wall(Vector2(270,450)) - source).normalized()
	check((-projector.global_basis.z).dot(aim) > 0.9999, "projector body and lens aim toward the center of the canvas")

	# This elevated wide slab represents a future overhanging construction.
	# It is only a test fixture; the shipped level remains unchanged.
	var overhang := {"center":Vector3(0,4.3,0), "depth":0.7, "profile":PackedVector2Array([Vector2(-2.7,0),Vector2(2.7,0),Vector2(2.7,0.5),Vector2(-2.7,0.5)])}
	var ceiling := MeshInstance3D.new()
	ceiling.mesh = DESIGN.prism_mesh(overhang)
	ceiling.position = overhang.center
	rotor.add_child(ceiling)
	var physical_rays_ok := true
	var silhouettes_ok := true
	var clearance := INF
	for phase in 72:
		var angle := TAU * float(phase) / 72.0
		level.field.angle = angle
		level.field.update_projection(true)
		for i in DESIGN.pieces().size():
			var object: MeshInstance3D = rotor.get_child(i + 1)
			var mesh_points: PackedVector3Array = object.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var projected := PackedVector2Array()
			for point in mesh_points:
				var world_point := object.to_global(point)
				# Intersect rays from the rendered mesh, independently of model_to_world.
				var ray := world_point - source
				var hit := source + ray * ((DESIGN.WALL_Z - source.z) / ray.z)
				var canvas_point := DESIGN.wall_to_canvas(hit)
				projected.append(canvas_point.snapped(Vector2.ONE * DESIGN.PROJECTION_STEP))
				physical_rays_ok = physical_rays_ok and (DESIGN.canvas_to_wall(DESIGN.project_world_point(world_point)) - source).cross(ray.normalized()).length() < 0.001
				clearance = minf(clearance, camera.unproject_position(world_point).y - wall_rect.end.y)
			var hull := Geometry2D.convex_hull(projected)
			if hull.size() > 1 and hull[0] == hull[-1]:
				hull.remove_at(hull.size() - 1)
			var visible: PackedVector2Array = level.field.polygons[i]
			silhouettes_ok = silhouettes_ok and visible.size() == hull.size()
			for point in hull:
				var found := false
				for actual in visible:
					found = found or point.distance_to(actual) < 0.001
				silhouettes_ok = silhouettes_ok and found
		var ceiling_points: PackedVector3Array = ceiling.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for point in ceiling_points:
			clearance = minf(clearance, camera.unproject_position(ceiling.to_global(point)).y - wall_rect.end.y)
	check(physical_rays_ok and silhouettes_ok, "rendered meshes cast exactly the playable silhouettes through a full turn")
	check(clearance > 24.0, "tall overhang and all figures stay below the canvas throughout rotation")
	print("Minimum clearance from canvas: ", snappedf(clearance,0.1), " px")
	ceiling.queue_free()
	print("RESULT: ", failures, " failures")
	quit(0 if failures == 0 else 1)
