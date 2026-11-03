class_name RoomSurfaceTests
extends SceneTree

const DESIGN = preload("res://scripts/level_design.gd")
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

func luminance(color: Color) -> float:
	return color.r*0.2126+color.g*0.7152+color.b*0.0722

func settle() -> void:
	for i in 8:
		await RenderingServer.frame_post_draw

func changed_pixels(first: Image, second: Image, area: Rect2i) -> int:
	var changed := 0
	for y in range(area.position.y,area.end.y):
		for x in range(area.position.x,area.end.x):
			if absf(luminance(first.get_pixel(x,y))-luminance(second.get_pixel(x,y)))>0.006:
				changed += 1
	return changed

func _run() -> void:
	level = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	level.field.running = false
	level.player.enabled = false
	var floor_material := level.diorama.room_floor.material_override as ShaderMaterial
	var wall_material := level.diorama.room_wall.material_override as ShaderMaterial
	var disk_material := level.diorama.disk_surface.material_override as ShaderMaterial
	check((level.diorama.key_light.light_cull_mask & level.diorama.room_floor.layers)!=0 and (level.diorama.key_light.light_cull_mask & level.diorama.room_wall.layers)!=0,"one key source illuminates both the floor and wall")
	var previous := PackedByteArray()
	for angle in [0.0,PI/4.0,PI/2.0]:
		level.field.angle = angle
		level.field.update_projection(true)
		await settle()
		for capture: PlanarReflection in [level.diorama.floor_reflection,level.diorama.disk_reflection]:
			check(absf(capture.mirror_camera.global_position.y-(capture.plane_height*2.0-level.diorama.camera.global_position.y))<0.001,"reflection camera mirrors its physical plane")
			var sample_point := Vector3(DESIGN.RIG_CENTER.x,capture.plane_height,DESIGN.RIG_CENTER.z+0.4)
			var main_uv := level.diorama.camera.unproject_position(sample_point)/Vector2(540,960)
			var reflected_uv := capture.mirror_camera.unproject_position(sample_point)/Vector2(PlanarReflection.CAPTURE_SIZE)
			check(main_uv.distance_to(Vector2(reflected_uv.x,1.0-reflected_uv.y))<0.001,"reflection texture registers with the real surface")
			var image := capture.viewport.get_texture().get_image()
			var red := 0
			var blue := 0
			for y in image.get_height():
				for x in image.get_width():
					var color := image.get_pixel(x,y)
					if color.a<0.5:
						continue
					if color.r>0.3 and color.r>color.g*1.5 and color.r>color.b*1.5:
						red += 1
					if color.b>0.3 and color.b>color.r*1.5 and color.b>color.g*1.1:
						blue += 1
			if capture == level.diorama.floor_reflection:
				check(red+blue>5 and capture.sources.has(level.diorama.disk_surface),"floor reflection includes visible figures and disk occlusion")
			else:
				check(red>5 and blue>5,"disk capture contains the real red and blue figures")
		var capture_frame := level.diorama.disk_reflection.viewport.get_texture().get_image().get_data()
		check(previous.is_empty() or previous!=capture_frame,"reflected figures update with disk rotation")
		previous = capture_frame
		var baseline := root.get_texture().get_image()
		floor_material.set_shader_parameter("reflection_strength",0.0)
		await settle()
		check(changed_pixels(baseline,root.get_texture().get_image(),Rect2i(0,535,540,270))>20,"floor reflection contributes to the final image")
		floor_material.set_shader_parameter("reflection_strength",0.26)
		disk_material.set_shader_parameter("reflection_strength",0.0)
		await settle()
		check(changed_pixels(baseline,root.get_texture().get_image(),Rect2i(150,620,330,180))>40,"disk reflection contributes to the final image")
		disk_material.set_shader_parameter("reflection_strength",0.4)
	await settle()
	var corner := Vector3(-3.6,DESIGN.FLOOR_Y,DESIGN.WALL_Z+0.15)
	var pixel := Vector2i(level.diorama.camera.unproject_position(corner))
	var shaded := luminance(root.get_texture().get_image().get_pixelv(pixel))
	floor_material.set_shader_parameter("corner_strength",0.0)
	wall_material.set_shader_parameter("corner_strength",0.0)
	await settle()
	var open_corner := luminance(root.get_texture().get_image().get_pixelv(pixel))
	check(open_corner-shaded>0.005,"wall-floor junction receives a soft local occlusion gradient")
	floor_material.set_shader_parameter("corner_strength",0.65)
	wall_material.set_shader_parameter("corner_strength",0.65)
	level.field.running = true
	await settle()
	var started := Time.get_ticks_usec()
	for i in 120:
		await RenderingServer.frame_post_draw
	var milliseconds := float(Time.get_ticks_usec()-started)/120000.0
	print("Native moving-scene frame time: ",snappedf(milliseconds,0.1)," ms")
	print("RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
