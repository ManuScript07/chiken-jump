class_name CrushPhysicsTests
extends SceneTree

var failures := 0
var world: Node2D
var player: SquarePlayer
var detector := CrushDetector.new()
var ever_crushed := false

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if value:
		print("PASS: ",message)
	else:
		failures += 1
		printerr("FAIL: ",message)

func box(at: Vector2, dimensions: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = at
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	world.add_child(body)
	return body

func step(count: int) -> void:
	for i in count:
		await physics_frame
		ever_crushed = detector.update(player,1.0/60.0) or ever_crushed

func _run() -> void:
	world = Node2D.new()
	root.add_child(world)
	box(Vector2(300,610),Vector2(500,20))
	var ceiling := box(Vector2(300,530),Vector2(500,20))
	player = SquarePlayer.new()
	world.add_child(player)
	player.reset_to(Vector2(300,585))
	await step(8)
	player.request_jump()
	var touched_ceiling := false
	for i in 70:
		await step(1)
		touched_ceiling = touched_ceiling or player.is_on_ceiling()
	check(touched_ceiling and not ever_crushed and player.is_on_floor(),"jumping against an overhead platform safely returns to the floor")
	# A descending shadow closes a 60px gap around a live, moving player.
	ever_crushed = false
	detector.reset()
	for i in 75:
		ceiling.position.y += 0.5
		await step(1)
		if ever_crushed:
			break
	check(ever_crushed,"a moving ceiling crushing the live cube against the floor is detected")
	world.queue_free()
	await process_frame
	world = Node2D.new()
	root.add_child(world)
	box(Vector2(300,610),Vector2(500,20))
	var left := box(Vector2(260,560),Vector2(20,100))
	var right := box(Vector2(340,560),Vector2(20,100))
	player = SquarePlayer.new()
	world.add_child(player)
	player.reset_to(Vector2(300,585))
	ever_crushed = false
	detector.reset()
	await step(8)
	for i in 75:
		left.position.x += 0.3
		right.position.x -= 0.3
		await step(1)
		if ever_crushed:
			break
	check(ever_crushed,"opposing moving side walls crush a live cube horizontally")
	print("RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
