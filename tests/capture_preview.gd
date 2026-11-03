class_name CapturePrototypePreview
extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var level: ChickenLevel = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	var phase := -1.0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("angle="):
			phase = deg_to_rad(float(argument.trim_prefix("angle=")))
	if phase >= 0.0:
		level.field.running = false
		level.field.angle = phase
		level.field.update_projection(true)
	var victory := OS.get_cmdline_user_args().has("gameover")
	if victory:
		level.session.total_stars = 12
		level.session.finish(RunSession.EndReason.TIME)
	elif OS.get_cmdline_user_args().has("pause"):
		level.session.pause()
	if OS.get_cmdline_user_args().has("jump"):
		for i in 5:
			await physics_frame
		level.hud.touch_actions[1] = "right"
		level.player.request_jump()
		for i in 12:
			await physics_frame
	if OS.get_cmdline_user_args().has("pressed"):
		level.hud.touch_actions[1] = "jump"
	for i in 10:
		await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var filename := "prototype-gameover.png" if victory else "prototype-preview.png"
	if OS.get_cmdline_user_args().has("jump"):
		filename = "prototype-jump.png"
	elif OS.get_cmdline_user_args().has("pressed"):
		filename = "prototype-pressed.png"
	if OS.get_cmdline_user_args().has("pause"):
		filename = "prototype-pause.png"
	if phase >= 0.0:
		filename = "prototype-angle-%d.png" % roundi(rad_to_deg(phase))
	var path := OS.get_user_data_dir().path_join(filename)
	var result := image.save_png(path)
	print("PREVIEW: ", path, " result=", result)
	quit(result)
