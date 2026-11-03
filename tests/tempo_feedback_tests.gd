class_name TempoFeedbackTests
extends SceneTree
var failures := 0
var level: ChickenLevel
var pulses: Array[Vector2] = []
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
func click(action: String) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = level.hud.action_rect(action).get_center()
	event.pressed = true
	root.push_input(event,true)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
func _run() -> void:
	var run := RunSession.new()
	run.start(PackedVector2Array([Vector2.ZERO,Vector2.ONE]))
	run.tick(19)
	check(run.remaining==1,"full bar lasts exactly 20 seconds")
	run.collect(0)
	check(run.remaining==2.5,"a late pickup buys only 1.5 seconds")
	run.tick(2.5)
	check(run.state==RunSession.State.FINISHED,"insufficient collection exhausts the bar")
	level = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	level.feedback.pulse_requested.connect(func(duration: int, strength: float) -> void: pulses.append(Vector2(duration,strength)))
	await steps(3)
	click("pause")
	await process_frame
	await process_frame
	check(paused and level.session.state==RunSession.State.PAUSED,"clicking the visible pause control really pauses the run")
	check(level.hud.keys.pause.pressure>0.1,"pause retains visible key travel after gameplay input is cleared")
	check(pulses.size()==1 and pulses[0].x==22,"pause requests one short tactile click")
	var elapsed := level.session.elapsed
	await steps(15)
	check(level.session.elapsed==elapsed,"paused time does not consume the shorter budget")
	click("pause")
	check(not paused,"the same pause button resumes the run")
	var count := pulses.size()
	level.session.collect(0)
	check(pulses.size()==count+1 and pulses.back().x>pulses[0].x and pulses.back().y>pulses[0].y,"star collection requests a stronger and longer tactile pulse")
	level.restart()
	level.player.enabled = false
	var previous := level.field.angular_velocity
	var max_step := 0.0
	for i in 570:
		await physics_frame
		max_step = maxf(max_step,absf(level.field.angular_velocity-previous))
		previous = level.field.angular_velocity
	check(level.session.waves_completed==0 and level.rotation_phase==2 and level.field.target_angular_velocity<0,"acceleration and reversal occur on the clock without collecting a wave")
	check(max_step<=ShadowField.ANGULAR_ACCELERATION/60.0+0.0001,"faster rotation still changes speed continuously")
	level.session.finish(RunSession.EndReason.TIME)
	check(not level.hud.keys.pause.visible,"game over does not show a pause control that cannot act")
	var preset := ConfigFile.new()
	check(preset.load("res://export_presets.cfg")==OK and preset.get_value("preset.0.options","permissions/vibrate",false),"Android preset enables the required vibration permission")
	print("RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
