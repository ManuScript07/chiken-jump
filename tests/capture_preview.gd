class_name CapturePrototypePreview
extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var level: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	for i in 10:
		await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := OS.get_user_data_dir().path_join("prototype-preview.png")
	var result := image.save_png(path)
	print("PREVIEW: ", path, " result=", result)
	quit(result)
