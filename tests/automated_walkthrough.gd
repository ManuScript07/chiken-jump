class_name AutomatedWalkthrough
extends SceneTree
const DESIGN = preload("res://scripts/level_design.gd")
var level: ChickenLevel
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	level = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	var args := OS.get_cmdline_user_args()
	var delay := int(args[0]) if not args.is_empty() else 0
	for i in delay:
		await physics_frame
	var jumps := 0
	for frame in 3600:
		await physics_frame
		if level.completed:
			print("PASS: normal movement and jumps complete the course; ticks=", frame, " jumps=", jumps)
			quit(0)
			return
		var goal := 0
		while goal < 3 and level.collected[goal]:
			goal += 1
		if goal == 3:
			continue
		var target: Vector2 = DESIGN.STAR_POSITIONS[goal]
		var dx := target.x - level.player.position.x
		level.hud.touch_actions.erase(21)
		if absf(dx) > 8.0:
			level.hud.touch_actions[21] = "right" if dx > 0 else "left"
		if level.player.is_on_floor() and (absf(dx) < 115.0 or level.player.is_on_wall()):
			level.player.request_jump()
			jumps += 1
	printerr("FAIL: course incomplete; stars=",level.hud.stars," pos=",level.player.position)
	quit(1)
