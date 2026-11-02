class_name OpticalRigTests
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
	var level: ChickenLevel = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	level.field.running = false
	var view := level.diorama
	var camera := view.camera
	var rotor := view.rotor
	var world: Node3D = rotor.get_parent()
	check(camera.projection == Camera3D.PROJECTION_PERSPECTIVE,"room uses a perspective camera")
	check(world.get_node_or_null("Projector") == null and world.get_node_or_null("Beam") == null,"no projector body or light-cone mesh appears in the room")
	check(view.key_light.global_position.distance_to(DESIGN.LIGHT_POSITION)<0.001 and view.key_light.shadow_enabled,"the physical light uses the collision projection origin")
	check(view.wall_viewport.transparent_bg and not level.field.visible,"wall markings are transparent and playable polygons are not painted over real shadows")
	var floor_top := view.room_floor.position.y + (view.room_floor.mesh as BoxMesh).size.y / 2.0
	var wall_bottom := view.room_wall.position.y - (view.room_wall.mesh as BoxMesh).size.y / 2.0
	check(absf(floor_top-wall_bottom)<0.001,"wall and floor meet without a gap or frame")
	check(absf(rotor.global_position.y-DESIGN.DISK_HEIGHT*DESIGN.MODEL_SCALE-floor_top)<0.001,"turntable rests directly on the floor")
	var left := camera.unproject_position(DESIGN.RIG_CENTER+Vector3.LEFT*DESIGN.DISK_RADIUS*DESIGN.MODEL_SCALE)
	var right := camera.unproject_position(DESIGN.RIG_CENTER+Vector3.RIGHT*DESIGN.DISK_RADIUS*DESIGN.MODEL_SCALE)
	check(right.distance_to(left)>180 and right.distance_to(left)<260,"turntable has the requested visible scale")
	var geometry_ok := true
	var clearance := INF
	for phase in 72:
		level.field.angle = TAU * float(phase) / 72.0
		level.field.update_projection(true)
		for i in view.piece_nodes.size():
			var object := view.piece_nodes[i]
			var points: PackedVector3Array = object.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var projected := PackedVector2Array()
			for point in points:
				var physical := object.to_global(point)
				var ray := physical - DESIGN.LIGHT_POSITION
				var hit := DESIGN.LIGHT_POSITION + ray * ((DESIGN.WALL_Z - DESIGN.LIGHT_POSITION.z) / ray.z)
				projected.append(DESIGN.wall_to_canvas(hit).snapped(Vector2.ONE*DESIGN.PROJECTION_STEP))
				var seam := camera.unproject_position(Vector3(physical.x,DESIGN.FLOOR_Y,DESIGN.WALL_Z))
				clearance = minf(clearance,camera.unproject_position(physical).y-seam.y)
			var hull := Geometry2D.convex_hull(projected)
			if hull.size()>1 and hull[0]==hull[-1]:
				hull.remove_at(hull.size()-1)
			var collider: PackedVector2Array = level.field.polygons[i]
			geometry_ok = geometry_ok and hull.size()==collider.size()
			for point in hull:
				var found := false
				for actual in collider:
					found = found or point.distance_to(actual)<0.001
				geometry_ok = geometry_ok and found
	check(geometry_ok,"every rendered primitive projects to its collider through a full rotation")
	check(clearance>12.0,"specified objects do not cover the playable wall throughout rotation")
	print("Minimum physical clearance below wall: ",snappedf(clearance,0.1)," px")
	level.field.angle = 0.0
	level.field.update_projection(true)
	var gap_open := true
	for polygon in level.field.polygons:
		gap_open = gap_open and not Geometry2D.is_point_in_polygon(Vector2(180,550),polygon)
	check(gap_open,"gap beneath the wooden overhang remains open")
	print("RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
