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
	var target_waves := 1
	for argument in args:
		if argument.begins_with("waves="):
			target_waves = int(argument.trim_prefix("waves="))
	var jumps := 0
	for frame in 3600:
		await physics_frame
		if level.session.waves_completed>=target_waves:
			print("PASS: normal movement and jumps complete "+str(target_waves)+" waves; ticks=", frame, " jumps=", jumps)
			quit(0)
			return
		if level.session.state==RunSession.State.FINISHED:
			printerr("FAIL: run ended; reason=",level.session.end_reason," pos=",level.player.position," angle=",rad_to_deg(level.field.angle)," waves=",level.session.waves_completed," elapsed=",level.session.elapsed)
			quit(1)
			return
		var goal := 0
		while goal<level.session.targets.size() and level.session.collected[goal]:
			goal += 1
		if goal==level.session.targets.size():
			continue
		var target: Vector2 = level.session.targets[goal]
		var dx := target.x - level.player.position.x
		level.hud.touch_actions.erase(21)
		if absf(dx) > 8.0:
			level.hud.touch_actions[21] = "right" if dx > 0 else "left"
		if level.player.is_on_floor() and (absf(dx) < 115.0 or level.player.is_on_wall()):
			level.player.request_jump()
			jumps += 1
	printerr("FAIL: course incomplete; stars=",level.session.total_stars," pos=",level.player.position)
	quit(1)
