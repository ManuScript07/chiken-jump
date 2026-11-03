class_name PlatformEdgeTests
extends SceneTree

const DESIGN = preload("res://scripts/level_design.gd")
var level: ChickenLevel
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if value:
		print("PASS: ",message)
	else:
		failures += 1
		printerr("FAIL: ",message)

func steps(count: int) -> void:
	for i in count:
		await physics_frame

func edge_positions() -> Vector2:
	var edges := Vector2(INF,-INF)
	for point in level.field.base_polygon:
		if absf(point.y-DESIGN.WALL_ORIGIN.y)<0.1:
			edges.x = minf(edges.x,point.x)
			edges.y = maxf(edges.y,point.x)
	return edges

func walk_to_edge(direction: int) -> bool:
	level.restart()
	level.field.running = false
	var edges := edge_positions()
	var target := edges.x if direction<0 else edges.y
	level.player.reset_to(Vector2(target-direction*45.0,585))
	await steps(5)
	level.hud.touch_actions[900] = "left" if direction<0 else "right"
	var reached := false
	for i in 90:
		await physics_frame
		if direction*(level.player.position.x-target)>-1.0:
			reached = level.player.bounds().position.x >= DESIGN.WALL_CROP_X and level.player.bounds().end.x <= DESIGN.WALL_CROP_X + DESIGN.WALL_TEXTURE_SIZE.x
			break
	level.hud.touch_actions.erase(900)
	return reached

func _run() -> void:
	level = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	check(await walk_to_edge(-1),"player reaches the real left edge without an invisible wall")
	check(await walk_to_edge(1),"player reaches the real right edge without an invisible wall")
	level.restart()
	level.field.running = false
	var edges := edge_positions()
	level.player.reset_to(Vector2(edges.x+30,585))
	await steps(5)
	level.hud.touch_actions[900] = "left"
	var left_surface := false
	var ended := false
	for i in 180:
		await physics_frame
		left_surface = left_surface or level.player.position.x<edges.x-16.0
		if level.session.state==RunSession.State.FINISHED:
			ended = level.session.end_reason==RunSession.EndReason.FALL
			break
	check(left_surface and ended,"walking off the projected disk ends the attempt")
	print("Projected top edges: ",edges)
	print("RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
