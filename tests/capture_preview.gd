class_name CapturePrototypePreview
extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var level: ChickenLevel = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	var victory := OS.get_cmdline_user_args().has("victory")
	if victory:
		level.hud.stars = 3
		level._finish()
	for i in 10:
		await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var filename := "prototype-victory.png" if victory else "prototype-preview.png"
	var path := OS.get_user_data_dir().path_join(filename)
	var result := image.save_png(path)
	print("PREVIEW: ", path, " result=", result)
	quit(result)
