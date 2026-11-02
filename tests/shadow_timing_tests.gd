class_name ShadowTimingTests
extends SceneTree

var level: ChickenLevel

func _initialize() -> void:
	call_deferred("_run")

func steps(count: int) -> void:
	for i in count:
		await physics_frame

# Start on the upper shadow and make the same rightward jump at a fixed disk angle.
func attempt(angle: float) -> bool:
	level.restart()
	level.field.running = false
	level.field.angle = angle
	level.field.update_projection(true)
	level.collected[0] = true
	level.collected[1] = true
	level.hud.stars = 2
	var platform: Rect2 = level.field.rectangles[2]
	level.player.position = Vector2(platform.get_center().x, platform.position.y - level.player.BODY_SIZE.y / 2.0 - 0.5)
	level.player.velocity = Vector2.ZERO
	await steps(5)
	level.hud.touch_actions[101] = "right"
	level.player.request_jump()
	for i in 45:
		await physics_frame
		if level.player.position.x > 396.0:
			level.hud.touch_actions.erase(101)
	level.hud.touch_actions.erase(101)
	return level.completed

func _run() -> void:
	level = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	var far_phase := await attempt(PI)
	var near_phase := await attempt(0.0)
	print("Far phase reaches star: ", far_phase)
	print("Near phase reaches star: ", near_phase)
	if not far_phase and near_phase:
		print("PASS: the final jump depends on the disk angle")
		quit(0)
	else:
		printerr("FAIL: final jump is not distinguished by disk phase")
		quit(1)
