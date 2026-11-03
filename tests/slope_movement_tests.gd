class_name SlopeMovementTests
extends SceneTree

var failures := 0
var world: Node2D
var ramp: StaticBody2D
var player: SquarePlayer

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	print("PASS: " if value else "FAIL: ",message)
	if not value:
		failures += 1

func steps(count: int) -> void:
	for i in count:
		await physics_frame

func place(degrees: float) -> void:
	ramp.rotation = deg_to_rad(degrees)
	var normal := Vector2.UP.rotated(ramp.rotation)
	var extent := 15.0*(absf(normal.x)+absf(normal.y))
	player.reset_to(ramp.position+normal*(20.0+extent+2.0))

func visual_contact_error() -> float:
	var normal := Vector2.UP.rotated(ramp.rotation)
	var plane := ramp.position+normal*20.0
	var distances: Array[float] = []
	for point: Vector2 in [Vector2(-15,-15),Vector2(15,-15),Vector2(15,15),Vector2(-15,15)]:
		var visible := player.position+player.avatar.surface_offset+point.rotated(player.avatar.spin)
		distances.append((visible-plane).dot(normal))
	distances.sort()
	return maxf(absf(distances[0]),absf(distances[1]))

func _run() -> void:
	world = Node2D.new()
	root.add_child(world)
	ramp = StaticBody2D.new()
	ramp.position = Vector2(300,400)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(3000,40)
	collision.shape = shape
	ramp.add_child(collision)
	world.add_child(ramp)
	player = SquarePlayer.new()
	world.add_child(player)
	await process_frame
	place(0.0)
	await steps(15)
	var flat_start := player.position
	await steps(45)
	check(player.is_on_floor() and player.position.distance_to(flat_start)<0.2,"cube rests on a flat surface without drifting")
	place(12.0)
	await steps(15)
	var gentle_start := player.position
	await steps(45)
	check(player.is_on_floor() and player.position.distance_to(gentle_start)<0.5,"static friction holds the cube on a gentle slope")
	print("Gentle normal=",player.get_floor_normal()," angle=",player.avatar.ground_angle," position=",player.position)
	check(absf(angle_difference(player.avatar.ground_angle,deg_to_rad(12.0)))<deg_to_rad(1.5),"cube follows the actual surface angle")
	check(visual_contact_error()<0.6,"both visible bottom corners touch the inclined plane")
	for degrees in [-32.0,32.0]:
		place(degrees)
		await steps(10)
		var start := player.position
		await steps(30)
		var tangent := Vector2.RIGHT.rotated(ramp.rotation)
		var direction := signf(degrees)
		print("Slide ",degrees," grounded=",player.is_on_floor()," sliding=",player.sliding," position=",player.position," start=",start," velocity=",player.velocity," normal=",player.get_floor_normal())
		check(player.is_on_floor() and player.sliding and (player.position-start).dot(tangent)*direction>15.0,"gravity slides the cube downhill on a %.0f degree slope" % degrees)
		check(player.velocity.dot(tangent)*direction>0.0 and player.velocity.length()<=SquarePlayer.SLIDE_MAX_SPEED+1.0,"slide direction and maximum speed remain controlled")
		check(visual_contact_error()<0.6,"sliding cube stays flush with the surface")
		await steps(60)
		check(player.is_on_floor() and absf(player.surface_speed)<=SquarePlayer.SLIDE_MAX_SPEED and absf(player.surface_speed)>400.0,"a long slide reaches its speed limit without accelerating indefinitely")
		place(degrees)
		await steps(10)
		player.input_axis = -direction
		await steps(25)
		check(player.velocity.dot(tangent)*direction< -80.0,"movement input can oppose the downhill slide")
		player.request_jump()
		await steps(2)
		check(not player.is_on_floor() and player.velocity.y< -500.0,"jump leaves an inclined surface cleanly")
		var jump_velocity := player.velocity.y
		player.request_jump()
		await steps(2)
		check(player.velocity.y>jump_velocity,"slope jumping still allows only one jump")
	place(0.0)
	await steps(15)
	var rotation_start := player.position
	var contacts := 0
	for i in 120:
		ramp.rotation = deg_to_rad(30.0)*float(i+1)/120.0
		await physics_frame
		if player.is_on_floor():
			contacts += 1
	print("Turning contacts=",contacts," start=",rotation_start," end=",player.position)
	check(contacts>108 and player.position.x>rotation_start.x+20.0,"a turning surface gradually starts a downhill slide")
	check(player.is_on_floor() and visual_contact_error()<0.8,"cube remains aligned while its support turns")
	world.queue_free()
	await process_frame
	await steps(2)
	var level: ChickenLevel = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	level.field.running = false
	level.field.angle = deg_to_rad(30.0)
	level.field.update_projection(true)
	var polygon := level.field.polygons[3]
	var center := Vector2.ZERO
	for point in polygon:
		center += point
	center /= polygon.size()
	var first := Vector2.ZERO
	var last := Vector2.ZERO
	var longest := 0.0
	var normal := Vector2.UP
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i+1)%polygon.size()]
		var edge := b-a
		var outward := Vector2(edge.y,-edge.x).normalized()
		if outward.dot((a+b)*0.5-center)<0.0:
			outward = -outward
		if outward.y< -0.3 and edge.length()>longest:
			longest = edge.length()
			first = a if a.x<b.x else b
			last = b if a.x<b.x else a
			normal = outward
	var contact := first.lerp(last,0.3)
	var extent := 15.0*(absf(normal.x)+absf(normal.y))
	level.player.reset_to(contact+normal*(extent+2.0))
	await steps(8)
	print("Projected stick: support=",level.field.platform_bodies.find(level.player.support)," angle=",rad_to_deg(level.player.avatar.ground_angle))
	check(level.player.is_on_floor() and level.field.platform_bodies.find(level.player.support)==3 and absf(level.player.avatar.ground_angle)>0.08,"cube tilts on the real projected 3D stick")
	if OS.get_cmdline_user_args().has("capture"):
		for i in 8:
			await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_user_data_dir().path_join("slope-shadow-preview.png"))
	print("RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
