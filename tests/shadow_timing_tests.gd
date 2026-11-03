class_name ShadowTimingTests
extends SceneTree

var level: ChickenLevel

func _initialize() -> void:
	call_deferred("_run")

func steps(count: int) -> void:
	for i in count:
		await physics_frame

# The same jump is blocked by the broad stick, then opens when it turns edge-on.
func attempt(angle: float) -> float:
	level.restart()
	level.field.running = false
	level.field.angle = angle
	level.field.update_projection(true)
	level.player.position = Vector2(180,585)
	level.player.velocity = Vector2.ZERO
	await steps(5)
	level.player.request_jump()
	var highest := level.player.position.y
	for i in 50:
		await physics_frame
		highest = minf(highest,level.player.position.y)
	return highest

func _run() -> void:
	level = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	var blocked_height := await attempt(PI / 2.0)
	var open_height := await attempt(0.0)
	print("Jump under broad stick: ",blocked_height,"; jump after rotation: ",open_height)
	if open_height + 25.0 < blocked_height:
		print("PASS: rotating the 3D stick opens a real jump window")
		quit(0)
	else:
		printerr("FAIL: rotation did not open the expected passage")
		quit(1)
