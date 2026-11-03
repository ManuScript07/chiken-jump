class_name RunLoopTests
extends SceneTree

var failures := 0
var level: ChickenLevel

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

func tap(action: String, index: int = 1) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = level.hud.action_rect(action).get_center()
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)

func box(at: Vector2, dimensions: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = at
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = dimensions
	shape.shape = rectangle
	body.add_child(shape)
	level.diorama.projection_canvas.add_child(body)
	return body

func _domain() -> void:
	var run := RunSession.new()
	var points := PackedVector2Array([Vector2(10,20),Vector2(30,40)])
	run.start(points)
	points[0] = Vector2.ZERO
	check(run.remaining==60 and run.targets[0]==Vector2(10,20),"60-second start owns an independent target snapshot")
	run.tick(8)
	check(run.collect(0) and run.remaining==55 and run.total_stars==1,"a star adds exactly three seconds")
	check(not run.collect(0) and not run.collect(-1) and not run.collect(2) and run.total_stars==1,"duplicate and invalid pickups cannot award time")
	run.pause()
	run.tick(20)
	check(run.remaining==55 and not run.collect(1),"pause freezes time and pickups")
	run.resume()
	run.collect(1)
	check(run.awaiting_wave and run.waves_completed==1,"last pickup completes a wave")
	run.next_wave(PackedVector2Array([Vector2(1,2),Vector2(3,4),Vector2(5,6)]))
	check(run.wave_index==1 and run.collected.size()==3 and not run.awaiting_wave,"next wave replaces the objective without resetting time or score")
	run.collect(0)
	run.collect(1)
	check(run.remaining==60,"time bonus is capped at one minute")
	run.tick(61)
	check(run.state==RunSession.State.FINISHED and run.end_reason==RunSession.EndReason.TIME and run.remaining==0,"empty timer ends the run")
	run.resume()
	run.tick(5)
	check(run.state==RunSession.State.FINISHED and not run.collect(2),"finished run cannot resume or collect")
	run.start(PackedVector2Array([Vector2.ZERO]))
	check(run.remaining==60 and run.total_stars==0 and run.wave_index==0,"restart clears the whole attempt")
	var director := WaveDirector.new()
	var layouts_ok := true
	var counts: Dictionary = {}
	for phase in 72:
		var polygons: Array[PackedVector2Array] = []
		for piece in LevelDesign.pieces():
			polygons.append(LevelDesign.projected_polygon(piece,float(phase)*TAU/72.0))
		var previous := PackedVector2Array(LevelDesign.STAR_POSITIONS)
		for wave in range(1,13):
			var positions := director.build_wave(wave,polygons,Vector2(270,500),previous)
			counts[positions.size()] = true
			for i in positions.size():
				layouts_ok = layouts_ok and Rect2(30,300,480,300).has_point(positions[i]) and positions[i].distance_to(Vector2(270,500))>=45
				for polygon in polygons:
					layouts_ok = layouts_ok and not Geometry2D.is_point_in_polygon(positions[i],polygon)
				for j in range(i+1,positions.size()):
					layouts_ok = layouts_ok and positions[i].distance_to(positions[j])>64
			previous = positions
	check(layouts_ok and counts.size()==3,"864 generated waves stay separated, outside solids and away from the player; counts vary 2–4")
	check(director.rotation_target(0)>0 and director.rotation_target(3)<0 and absf(director.rotation_target(50))<=0.28,"rotation schedule reverses direction and has a speed limit")

func _run() -> void:
	_domain()
	level = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	await steps(5)
	tap("pause")
	var remaining := level.session.remaining
	var angle := level.field.angle
	var position := level.player.position
	await steps(15)
	check(paused and level.session.remaining==remaining and level.field.angle==angle and level.player.position==position,"pause freezes physics, rotation and time")
	check(level.hud.menu.visible and level.hud.menu.selected==0,"pause opens on Continue")
	tap("left")
	check(level.hud.menu.selected==1,"previous wraps from first menu item to last")
	tap("right")
	check(level.hud.menu.selected==0,"next wraps from last menu item to first")
	tap("jump")
	await steps(2)
	check(not paused and level.session.state==RunSession.State.RUNNING and level.player.jump_buffer==0 and level.hud.horizontal_input()==0,"confirm resumes without leaking a jump or movement")
	level.session.remaining = 10
	tap("pause")
	tap("right")
	tap("jump")
	await steps(3)
	check(level.session.remaining>59 and level.session.total_stars==0 and not paused,"menu restart starts a fresh minute")
	# Collect through the actual controller and wait for replacement targets.
	level.player.set_physics_process(false)
	level.player.reset_pending = false
	for point in level.session.targets.duplicate():
		level.player.position = point
		await steps(1)
	check(level.session.waves_completed==1 and level.session.awaiting_wave,"controller collects the complete first wave")
	await steps(40)
	check(level.session.wave_index==1 and level.session.targets.size()==2 and not level.session.awaiting_wave,"new targets appear after a short wave transition")
	level.field.set_rotation_target(-0.22)
	var previous := level.field.angular_velocity
	var max_step := 0.0
	for i in 360:
		await physics_frame
		max_step = maxf(max_step,absf(level.field.angular_velocity-previous))
		previous = level.field.angular_velocity
	check(level.field.angular_velocity<0 and max_step<=ShadowField.ANGULAR_ACCELERATION/60.0+0.0001,"direction reversal decelerates through zero without a speed jump")
	level.player.position = Vector2(-50,700)
	await steps(2)
	check(paused and level.session.end_reason==RunSession.EndReason.FALL,"falling beyond the platform ends the attempt")
	tap("jump")
	await steps(3)
	check(not paused and level.session.remaining>59,"game-over confirm restarts")
	# A thin inset must overlap two solids for multiple ticks before declaring a crush.
	level.field.running = false
	level.player.set_physics_process(false)
	level.player.position = Vector2(800,500)
	level.player.reset_pending = false
	var first := box(Vector2(800,524),Vector2(120,20))
	await steps(5)
	check(level.session.state==RunSession.State.RUNNING,"contact with one solid is not a crush")
	var second := box(Vector2(800,476),Vector2(120,20))
	await steps(2)
	check(level.session.state==RunSession.State.RUNNING,"an adequately wide corridor is safe")
	first.position.y = 522
	second.position = Vector2(804,522)
	await steps(5)
	check(level.session.state==RunSession.State.RUNNING,"two overlapping supports on the same side do not cause a false crush")
	second.position = Vector2(800,478)
	await steps(5)
	check(paused and level.session.end_reason==RunSession.EndReason.CRUSH,"sustained compression between two shadows ends the run")
	first.queue_free()
	second.queue_free()
	tap("jump")
	await steps(3)
	level.session.remaining = 0.025
	await steps(4)
	check(paused and level.session.end_reason==RunSession.EndReason.TIME,"controller ends the run when time expires")
	print("RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
