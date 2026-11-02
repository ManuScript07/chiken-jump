class_name AutomatedWalkthrough
extends SceneTree

const DESIGN = preload("res://scripts/level_design.gd")
var level: ChickenLevel
var goal := 0
var jumps := 0
var last_support := -2
var jumped_from_top := false

func _initialize() -> void:
	call_deferred("_run")

func move_toward_x(target: float) -> void:
	level.hud.touch_actions.erase(21)
	var dx := target - level.player.position.x
	if dx > 8.0:
		level.hud.touch_actions[21] = "right"
	elif dx < -8.0:
		level.hud.touch_actions[21] = "left"

func _run() -> void:
	level = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	for frame in 2400:
		await physics_frame
		if level.completed:
			print("PASS: full level completed through movement and jumps; frames=", frame, " jumps=", jumps)
			quit(0)
			return
		var player := level.player
		if player.is_on_floor():
			var current := level.field.platform_bodies.find(player.support)
			if current != last_support:
				print("LANDED frame=", frame, " support=", current, " pos=", player.position, " stars=", level.hud.stars)
				last_support = current
			goal = mini(current + 1, 2)
			if current == 2:
				goal = 2
			var destination: Rect2 = level.field.rectangles[goal]
			var x: float = DESIGN.STAR_POSITIONS[goal].x
			if current == -1 and player.position.x < DESIGN.SPIKE_STARTS[0].x:
				x = DESIGN.SPIKE_STARTS[0].x - player.BODY_SIZE.x * 0.5 - 12.0
			if current >= 0:
				var base: Rect2 = level.field.rectangles[current]
				x = clampf(x, base.position.x + 18.0, base.end.x - 18.0)
			var can_jump := true
			if current == 2:
				var top: Rect2 = level.field.rectangles[2]
				can_jump = top.position.x < 220.0
				x = top.position.x + 8.0 if can_jump else top.get_center().x
			move_toward_x(x)
			if can_jump and absf(player.position.x - x) < 14.0 and (current < 2 or level.hud.stars < 3):
				jumped_from_top = current == 2
				player.request_jump()
				jumps += 1
		else:
			last_support = -2
			var target: Rect2 = level.field.rectangles[goal]
			var target_x := target.get_center().x
			if goal < DESIGN.STAR_POSITIONS.size() and not level.collected[goal]:
				if goal == 2 and jumped_from_top:
					target_x = DESIGN.STAR_POSITIONS[goal].x
				else:
					target_x = clampf(DESIGN.STAR_POSITIONS[goal].x, target.position.x + 15.0, target.end.x - 15.0)
			move_toward_x(target_x)
	print("FAIL: level was not completed; stars=", level.hud.stars, " pos=", level.player.position, " jumps=", jumps)
	quit(1)
