class_name MobileUiTests
extends SceneTree

var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if value:
		print("PASS: ",message)
	else:
		failures += 1
		printerr("FAIL: ",message)

func _run() -> void:
	var layouts_ok := true
	for dimensions in [Vector2(540,960),Vector2(540,1200),Vector2(540,1260),Vector2(720,960),Vector2(320,568)]:
		for insets in [Vector2.ZERO,Vector2(12,38)]:
			var usable := Rect2(insets,dimensions-insets-Vector2(12,30))
			var layout := MobileLayout.calculate(dimensions,usable)
			for action in ["left","right","jump","pause","meter"]:
				var rect: Rect2 = layout[action]
				layouts_ok = layouts_ok and usable.encloses(rect)
			layouts_ok = layouts_ok and not layout.left.intersects(layout.right) and not layout.right.intersects(layout.jump)
			layouts_ok = layouts_ok and layout.left.size.x>=48 and layout.pause.size.x>=40
	check(layouts_ok,"controls fit phone/tablet layouts and simulated cutout/gesture insets without overlap")
	var level: ChickenLevel = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	level.field.running = false
	level.player.enabled = false
	for dimensions in [Vector2i(540,960),Vector2i(540,1200),Vector2i(540,1260),Vector2i(720,960),Vector2i(320,568)]:
		root.size = dimensions
		for i in 6:
			await process_frame
		var view_size := root.get_visible_rect().size
		var view := level.diorama
		var render_size := Vector2(view.scene_viewport.size)
		var reflection_size := Vector2(view.floor_reflection.viewport.size)
		var ratios_ok := absf(render_size.aspect()-view_size.aspect())<0.002 and absf(reflection_size.aspect()-view_size.aspect())<0.004
		var fits := true
		var gameplay_bottom := 0.0
		for point in [Vector2(0,280),Vector2(540,280),Vector2(540,620),Vector2(0,620)]:
			var screen: Vector2 = view.camera.unproject_position(LevelDesign.canvas_to_wall(point))/render_size*view_size
			fits = fits and Rect2(Vector2.ZERO,view_size).grow(1.0).has_point(screen)
			gameplay_bottom = maxf(gameplay_bottom,screen.y)
		var disk_screen := view.camera.unproject_position(LevelDesign.RIG_CENTER)/render_size*view_size
		fits = fits and disk_screen.y<level.hud.layout.controls_top-20
		fits = fits and gameplay_bottom<level.hud.layout.controls_top
		check(ratios_ok and fits and view_size.is_equal_approx(level.hud.size),"scene, reflections and controls preserve composition at "+str(dimensions))
		check(render_size.x*render_size.y<=802000 and reflection_size.x*reflection_size.y<=90500,"offscreen rendering stays bounded at "+str(dimensions))
		if DisplayServer.get_name()!="headless":
			for i in 4:
				await RenderingServer.frame_post_draw
			var path := OS.get_user_data_dir().path_join("ui-%dx%d.png"%[dimensions.x,dimensions.y])
			root.get_texture().get_image().save_png(path)
	print("RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
