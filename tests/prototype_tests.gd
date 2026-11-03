class_name PrototypeTests
extends SceneTree
const DESIGN = preload("res://scripts/level_design.gd")
var failures := 0
var level: ChickenLevel
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", message)
	else:
		print("PASS: ", message)
func steps(count: int) -> void:
	for i in count:
		await physics_frame
func touch(index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	root.push_input(event, true)
func _run() -> void:
	level = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	await steps(5)
	check(level.player.is_on_floor(), "safe grounded start")
	check(level.player.get_world_2d() == level.diorama.wall_viewport.world_2d and level.field.get_world_2d() == level.player.get_world_2d(), "wall character and colliders share the projection viewport")
	var rays_ok := true
	for phase in 24:
		for piece in DESIGN.pieces():
			for vertex in DESIGN.vertices(piece):
				var angle := float(phase) * TAU / 24.0
				var object_point: Vector3 = DESIGN.model_to_world(vertex, angle)
				var wall_point: Vector3 = DESIGN.canvas_to_wall(DESIGN.project_point(vertex, angle))
				var ray: Vector3 = (object_point - DESIGN.LIGHT_POSITION).normalized()
				rays_ok = rays_ok and (wall_point - DESIGN.LIGHT_POSITION).cross(ray).length() < 0.001
	check(rays_ok, "all model vertices project along rays from the visible lens")
	var ray_origin := DESIGN.RIG_CENTER
	var toward_lens := (DESIGN.LIGHT_POSITION - ray_origin).normalized()
	var close_size := DESIGN.project_world_point(ray_origin + toward_lens * 0.3 + Vector3.UP * 0.3).distance_to(DESIGN.WALL_ORIGIN)
	var far_size := DESIGN.project_world_point(ray_origin - toward_lens * 0.3 + Vector3.UP * 0.3).distance_to(DESIGN.WALL_ORIGIN)
	check(close_size > far_size, "moving toward the projector enlarges the shadow")
	var geometry_ok := true
	level.field.running = false
	for frame in 72:
		level.field.angle = TAU * frame / 72.0
		level.field.update_projection(true)
		for i in level.field.platform_shapes.size():
			var shape := level.field.platform_shapes[i]
			var body := level.field.platform_bodies[i]
			for j in shape.polygon.size():
				geometry_ok = geometry_ok and (body.position + shape.polygon[j]).distance_to(level.field.polygons[i][j]) < 0.001
	check(geometry_ok, "collision follows projected model vertices throughout rotation")
	level.restart()
	await steps(5)
	var start_x := level.player.position.x
	touch(4, level.hud.action_rect("right").get_center(), true)
	await steps(10)
	check(level.player.position.x > start_x + 5, "movement responds to touch")
	touch(5, level.hud.action_rect("jump").get_center(), true)
	await steps(3)
	check(level.player.velocity.y < -300, "movement and jump can be held together")
	check(absf(level.player.avatar.spin) > 0.1 and absf(level.player.rotation) < 0.001, "airborne square rotates without rotating its collider")
	check(level.player.avatar.trail.size() > 0, "airborne movement emits a bounded visual trail")
	var speed := level.player.velocity.y
	level.player.request_jump()
	await steps(2)
	check(level.player.velocity.y > speed, "no double jump")
	touch(4, Vector2.ZERO, false)
	touch(5, Vector2.ZERO, false)
	check(level.hud.horizontal_input() == 0, "release clears touch movement")
	await steps(90)
	check(level.player.is_on_floor() and absf(level.player.avatar.spin-level.player.avatar.ground_angle-snappedf(level.player.avatar.spin-level.player.avatar.ground_angle,PI/2.0)) < 0.001, "landing aligns the square to a quarter turn")
	check(level.player.avatar.trail.is_empty(), "old trail fades after landing")
	var cam := level.diorama.camera
	var corners := [DESIGN.canvas_to_wall(Vector2(0,280)), DESIGN.canvas_to_wall(Vector2(540,280)), DESIGN.canvas_to_wall(Vector2(540,620)), DESIGN.canvas_to_wall(Vector2(0,620))]
	var screen: Array[Vector2] = []
	for corner: Vector3 in corners:
		screen.append(cam.unproject_position(corner))
	check(absf(screen[0].y-screen[1].y)<20.0 and absf(screen[2].y-screen[3].y)<20.0 and absf(screen[0].x-screen[3].x)<40.0 and absf(screen[1].x-screen[2].x)<40.0, "wall perspective remains gentle and readable")
	var key_source := FileAccess.get_file_as_string("res://scripts/sculpted_key.gd")
	check(not key_source.contains("draw_string"),"physical controls have no printed text or glyphs")
	level.restart()
	# The reference installation has no dangerous object; inject a physical test fixture.
	var hazard_piece := {"id":"test_hazard", "primitive":"box", "center":Vector3(0,0.35,1.0), "size":Vector3(0.3,0.7,0.3), "color":Color.RED, "hazard":true}
	var hazard_mesh := MeshInstance3D.new()
	hazard_mesh.mesh = DESIGN.primitive_mesh(hazard_piece)
	hazard_mesh.position = hazard_piece.center
	level.diorama.rotor.add_child(hazard_mesh)
	level.field.pieces.append(hazard_piece)
	level.field.update_projection(true)
	var hazard: PackedVector2Array = level.field.polygons.back()
	var center := Vector2.ZERO
	for point in hazard:
		center += point
	center /= hazard.size()
	level.player.position = center
	await steps(3)
	check(level.session.state==RunSession.State.FINISHED and level.session.end_reason==RunSession.EndReason.HAZARD,"projected physical hazard ends attempt")
	level.field.pieces.pop_back()
	level.field.update_projection(true)
	hazard_mesh.queue_free()
	level.restart()
	for star in DESIGN.STAR_POSITIONS:
		level.player.position = star
		level.player.velocity = Vector2.ZERO
		await steps(2)
	check(level.session.waves_completed==1 and level.session.total_stars==3,"all stars complete the first wave")
	level.session.pause()
	touch(8,level.hud.action_rect("right").get_center(),true)
	touch(8,Vector2.ZERO,false)
	touch(9,level.hud.action_rect("jump").get_center(),true)
	touch(9,Vector2.ZERO,false)
	await steps(3)
	check(level.player.avatar.trail.is_empty() and absf(level.player.avatar.spin) < 0.001, "restart clears square animation")
	check(level.session.state==RunSession.State.RUNNING and level.session.total_stars==0, "restart restores playable state")
	print("RESULT: ", failures, " failures")
	quit(0 if failures == 0 else 1)
