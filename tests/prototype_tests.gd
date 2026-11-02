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
	var geometry_ok := true
	level.field.running = false
	for frame in 72:
		level.field.angle = TAU * frame / 72.0
		level.field.update_projection(true)
		for i in 3:
			var shape := level.field.platform_shapes[i]
			var body := level.field.platform_bodies[i]
			for j in shape.polygon.size():
				geometry_ok = geometry_ok and (body.position + shape.polygon[j]).distance_to(level.field.polygons[i][j]) < 0.001
	check(geometry_ok, "collision follows projected model vertices throughout rotation")
	level.restart()
	await steps(5)
	var start_x := level.player.position.x
	touch(4, level.hud.RIGHT.get_center(), true)
	await steps(10)
	check(level.player.position.x > start_x + 5, "movement responds to touch")
	touch(5, level.hud.JUMP.get_center(), true)
	await steps(3)
	check(level.player.velocity.y < -300, "movement and jump can be held together")
	var speed := level.player.velocity.y
	level.player.request_jump()
	await steps(2)
	check(level.player.velocity.y > speed, "no double jump")
	touch(4, Vector2.ZERO, false)
	touch(5, Vector2.ZERO, false)
	check(level.hud.horizontal_input() == 0, "release clears touch movement")
	level.restart()
	var hazard: PackedVector2Array = level.field.polygons[3]
	var center := Vector2.ZERO
	for point in hazard:
		center += point
	center /= hazard.size()
	level.player.position = center
	await steps(3)
	check(level.player.position.distance_to(DESIGN.PLAYER_START) < 4, "projected triangular hazard restarts attempt")
	for star in DESIGN.STAR_POSITIONS:
		level.player.position = star
		level.player.velocity = Vector2.ZERO
		await steps(2)
	check(level.completed and level.hud.stars == 3, "all stars complete the course")
	level.restart()
	await steps(3)
	check(not level.completed and level.hud.stars == 0, "restart restores playable state")
	print("RESULT: ", failures, " failures")
	quit(0 if failures == 0 else 1)
