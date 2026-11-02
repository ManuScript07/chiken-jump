class_name PrototypeTests
extends SceneTree

const DESIGN = preload("res://scripts/level_design.gd")
var failures: Array[String] = []
var level: ChickenLevel

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
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
	check(level.player.is_on_floor(), "player starts grounded on the safe floor")
	check(level.field.platform_bodies.size() == 3, "three projected solid platforms are created")
	check(level.diorama.rotor.get_child_count() == DESIGN.pieces().size() + 1, "the diorama contains the same boxes as the projection")

	# Geometry, collision and visual dimensions agree at every sampled angle.
	level.field.running = false
	var geometry_ok := true
	for step in 72:
		level.field.angle = TAU * float(step) / 72.0
		level.field.update_projection(true)
		for i in 3:
			var rect := level.field.rectangles[i]
			geometry_ok = geometry_ok and rect.size.x > 1.0
			geometry_ok = geometry_ok and level.field.platform_bodies[i].position.distance_to(rect.get_center()) < 0.001
			geometry_ok = geometry_ok and level.field.platform_shapes[i].size.distance_to(rect.size) < 0.001
	check(geometry_ok, "visible projected platforms match collision geometry throughout a full rotation")
	var spike_geometry_ok := true
	for strip in level.field.spike_strips:
		var sample := Rect2(strip.get_center() - Vector2(0.25, 0.25), Vector2(0.5, 0.5))
		spike_geometry_ok = spike_geometry_ok and level.field.touches_hazard(sample)
	check(spike_geometry_ok, "every visible spike strip is hazardous")
	check(not level.field.touches_hazard(Rect2(144, 582, 2, 2)), "empty space beside a spike is safe")

	level.restart()
	await steps(4)
	var start_x := level.player.position.x
	touch(13, level.hud.RIGHT.get_center(), true)
	await steps(12)
	check(level.player.position.x > start_x + 10.0, "touch movement drives the player")
	touch(14, level.hud.JUMP.get_center(), true)
	await steps(3)
	check(level.player.velocity.y < -300.0, "jump works while movement is held")
	var first_velocity := level.player.velocity.y
	level.player.request_jump()
	await steps(2)
	check(level.player.velocity.y > first_velocity, "jump cannot be triggered again in mid-air")
	touch(13, level.hud.RIGHT.get_center(), false)
	touch(14, level.hud.JUMP.get_center(), false)
	check(level.hud.horizontal_input() == 0.0, "releasing touch clears movement")
	touch(13, level.hud.LEFT.get_center(), true)
	level.hud.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(level.hud.horizontal_input() == 0.0, "losing focus releases held touch controls")

	level.restart()
	await steps(4)
	var keyboard_start := level.player.position.x
	var key := InputEventKey.new()
	key.keycode = KEY_D
	key.physical_keycode = KEY_D
	key.pressed = true
	Input.parse_input_event(key)
	await steps(12)
	check(level.player.position.x > keyboard_start + 10.0, "keyboard movement drives the player")
	key.pressed = false
	Input.parse_input_event(key)
	level.restart()
	await steps(4)
	var jump_key := InputEventKey.new()
	jump_key.keycode = KEY_SPACE
	jump_key.pressed = true
	root.push_input(jump_key, true)
	await steps(3)
	check(level.player.velocity.y < -300.0, "keyboard jump works")

	level.restart()
	var first_rect: Rect2 = level.field.rectangles[0]
	level.player.position = Vector2(first_rect.get_center().x, first_rect.position.y - level.player.BODY_SIZE.y * 0.5 - 0.5)
	level.player.velocity = Vector2.ZERO
	await steps(15)
	var grounded := level.player.is_on_floor()
	var initial_relative := level.player.position.x - level.field.platform_bodies[0].position.x
	var initial_platform_x := level.field.platform_bodies[0].position.x
	await steps(60)
	var relative := level.player.position.x - level.field.platform_bodies[0].position.x
	check(grounded and level.player.is_on_floor() and absf(level.field.platform_bodies[0].position.x - initial_platform_x) > 0.5 and absf(relative - initial_relative) < 3.5, "moving platform carries the grounded player")
	var stayed_on := true
	for frame in 1200:
		await physics_frame
		if not level.player.is_on_floor() or level.player.support != level.field.platform_bodies[0]:
			stayed_on = false
			break
	check(stayed_on, "the player stays on a platform through a full rotation")

	level.restart()
	level.player.position = DESIGN.STAR_POSITIONS[0]
	await steps(3)
	check(level.hud.stars == 1 and level.collected[0], "a star is collected once")
	await steps(3)
	check(level.hud.stars == 1, "a collected star is not counted twice")
	var danger: Rect2 = level.field.rectangles[3]
	level.player.position = danger.get_center()
	await steps(3)
	check(level.hud.stars == 0 and not level.collected[0] and level.player.position.distance_to(DESIGN.PLAYER_START) < 4.0 and level.field.angle < 0.1, "shadow hazard restores the initial attempt")
	level.player.position = DESIGN.SPIKE_STARTS[0] + Vector2(9, 3)
	level.player.velocity = Vector2.ZERO
	await steps(3)
	check(level.player.position.distance_to(DESIGN.PLAYER_START) < 4.0 and level.hud.stars == 0, "floor spikes restart the attempt")

	for star in DESIGN.STAR_POSITIONS:
		level.player.position = star
		level.player.velocity = Vector2.ZERO
		await steps(2)
	check(level.completed and level.hud.stars == 3 and not level.field.running, "three stars complete the level and stop the disk")
	level.restart()
	await steps(2)
	check(not level.completed and level.hud.stars == 0 and level.field.running, "restart starts a fresh playable attempt")
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL", " (", failures.size(), " failures)")
	quit(0 if failures.is_empty() else 1)
