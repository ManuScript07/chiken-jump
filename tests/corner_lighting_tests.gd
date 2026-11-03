class_name CornerLightingTests
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

func settle() -> void:
	for i in 8:
		await RenderingServer.frame_post_draw

func luminance(color: Color) -> float:
	return color.r*0.2126+color.g*0.7152+color.b*0.0722

func sample(frame: Image, point: Vector3) -> float:
	var pixel := Vector2i(level.diorama.camera.unproject_position(point))
	var result := 0.0
	for y in range(-2,3):
		for x in range(-2,3):
			result += luminance(frame.get_pixelv(pixel+Vector2i(x,y)))
	return result/25.0

func _run() -> void:
	level = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	level.field.running = false
	level.player.enabled = false
	var surface := level.diorama.room_floor.material_override as ShaderMaterial
	var reflection_strength: float = surface.get_shader_parameter("reflection_strength")
	var bounce_strength: float = surface.get_shader_parameter("wall_bounce_strength")
	surface.set_shader_parameter("reflection_strength",0.0)
	await settle()
	var lit := root.get_texture().get_image()
	surface.set_shader_parameter("wall_bounce_strength",0.0)
	await settle()
	var no_bounce := root.get_texture().get_image()
	# Compare rendered light contribution, not just material settings or light masks.
	var near_corner := Vector3(-1.8,DESIGN.FLOOR_Y,DESIGN.WALL_Z+0.5)
	var foreground := Vector3(-1.8,DESIGN.FLOOR_Y,DESIGN.WALL_Z+7.0)
	var near_value := sample(lit,near_corner)
	var far_value := sample(lit,foreground)
	var near_bounce := near_value-sample(no_bounce,near_corner)
	var far_bounce := far_value-sample(no_bounce,foreground)
	check(near_value-far_value>0.1,"floor illumination falls broadly from the lit wall toward the viewer")
	check(near_bounce>0.12 and far_bounce<near_bounce*0.25,"wall bounce has a measurable local contribution and decays with distance")
	var wall_value := sample(lit,Vector3(-3.0,1.0,DESIGN.WALL_Z))
	check(wall_value-near_value>0.1,"the two planes remain distinguishable across the corner")
	var largest_step := 0.0
	var previous := near_value
	var reversals := 0
	for i in range(1,45):
		var depth := 0.5+float(i)*0.15
		var value := sample(lit,Vector3(-1.8,DESIGN.FLOOR_Y,DESIGN.WALL_Z+depth))
		largest_step = maxf(largest_step,absf(value-previous))
		if value-previous>0.008:
			reversals += 1
		previous = value
	check(largest_step<0.035 and reversals==0,"the floor gradient has no abrupt bands or isolated glowing strip")
	print("Wall-to-foreground floor luminance: ",near_value," -> ",far_value,"; largest step: ",largest_step)
	surface.set_shader_parameter("wall_bounce_strength",bounce_strength)
	surface.set_shader_parameter("reflection_strength",reflection_strength)
	var capture := level.diorama.floor_reflection
	var reflected_light := capture.viewport.get_child(0).get_node("SideLight") as SpotLight3D
	check(capture.captures_shadows and reflected_light.shadow_enabled,"floor capture includes the physical wall shadow")
	for angle in [0.0,PI/4.0,PI/2.0]:
		level.field.angle = angle
		level.field.update_projection(true)
		await settle()
		var baseline := root.get_texture().get_image()
		reflected_light.shadow_enabled = false
		await settle()
		var clear := root.get_texture().get_image()
		var wall_shadow := DESIGN.canvas_to_wall(DESIGN.project_point(DESIGN.pieces()[0].center,angle))
		var mirrored_eye := capture.mirror_camera.global_position
		var factor := (DESIGN.FLOOR_Y-mirrored_eye.y)/(wall_shadow.y-mirrored_eye.y)
		var on_floor := mirrored_eye.lerp(wall_shadow,factor)
		var difference := sample(clear,on_floor)-sample(baseline,on_floor)
		print("Reflected wall silhouette phase ",rad_to_deg(angle)," contrast=",difference," pixel=",level.diorama.camera.unproject_position(on_floor))
		check(difference>0.004,"the wall silhouette continues onto the floor in perspective")
		check(difference<0.15,"floor silhouette remains weaker than the primary wall shadow")
		reflected_light.shadow_enabled = true
	print("RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
