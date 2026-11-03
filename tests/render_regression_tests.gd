class_name RenderRegressionTests
extends SceneTree

var label := "current"
var level: ChickenLevel
var failures := 0
var motion_frames := 120

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("label="):
			label = argument.trim_prefix("label=")
		elif argument.begins_with("frames="):
			motion_frames = clampi(int(argument.trim_prefix("frames=")),1,3600)
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if value:
		print("PASS: ",message)
	else:
		failures += 1
		printerr("FAIL: ",message)

func settle(frames: int = 8) -> void:
	for i in frames:
		await RenderingServer.frame_post_draw

func luma(color: Color) -> float:
	return color.r*0.2126+color.g*0.7152+color.b*0.0722

func edge_jump(frame: Image) -> float:
	var result := 0.0
	for x in range(170,250):
		var largest := 0.0
		var low := 1.0
		var high := 0.0
		for y in range(417,460):
			var value := luma(frame.get_pixel(x,y))
			low = minf(low,value)
			high = maxf(high,value)
			largest = maxf(largest,absf(value-luma(frame.get_pixel(x,y+1))))
		result += largest/maxf(high-low,0.001)
	return result/80.0

func _run() -> void:
	level = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	level.field.running = false
	level.player.enabled = false
	for degrees in [0.0,45.0,90.0]:
		level.field.angle = deg_to_rad(degrees)
		level.field.update_projection(true)
		await settle()
		var frame := root.get_texture().get_image()
		var filename := "render-"+label+"-%d.png" % roundi(degrees)
		frame.save_png(OS.get_user_data_dir().path_join(filename))
		if degrees==45.0:
			var jump := edge_jump(frame)
			print("COMPARE ",label," stick edge jump=",jump)
			# Intensity jump also rises when an edge becomes sharper.
			# Geometric contour error and transition width are checked independently by ShadowAntialiasingTests.
		var casters: Array[MeshInstance3D] = level.diorama.piece_nodes.duplicate()
		casters.append(level.diorama.disk_surface)
		for caster in casters:
			caster.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		await settle()
		var clear := root.get_texture().get_image()
		var delta := 0.0
		var pixels := 0
		for y in range(610,800):
			for x in range(180,465):
				var difference := luma(clear.get_pixel(x,y))-luma(frame.get_pixel(x,y))
				delta += maxf(0.0,difference)
				if difference>0.025:
					pixels += 1
		print("COMPARE ",label," angle=",degrees," contact shadow energy=",delta," pixels=",pixels)
		# Measured desktop reference: 2725 / 2792 / 3207 pixels at 0 / 45 / 90 degrees.
		var reference_pixels: float = {0:2725,45:2792,90:3207}[roundi(degrees)]
		check(float(pixels)>reference_pixels*0.9,"contact shadows retain the reference footprint at %.0f degrees" % degrees)
		for caster in casters:
			caster.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	level.field.angle = deg_to_rad(35.0)
	level.field.update_projection(true)
	await settle(30)
	level.field.running = true
	var previous_angle := level.diorama.rotor.rotation.y
	var previous_time := Time.get_ticks_usec()
	var repeated := 0
	var maximum_step := 0.0
	var elapsed := 0.0
	var slow_frames := 0
	for i in motion_frames:
		await RenderingServer.frame_post_draw
		var current_time := Time.get_ticks_usec()
		var milliseconds := float(current_time-previous_time)/1000.0
		elapsed += milliseconds
		if milliseconds>25.0:
			slow_frames += 1
		var angle := level.diorama.rotor.rotation.y
		var step := absf(angle_difference(previous_angle,angle))
		if step<0.000001:
			repeated += 1
		maximum_step = maxf(maximum_step,step)
		previous_angle = angle
		previous_time = current_time
	print("COMPARE ",label," native mean frame ms=",elapsed/float(motion_frames)," repeated rotation poses=",repeated," maximum angle step=",maximum_step," frames>25ms=",slow_frames," samples=",motion_frames)
	print("RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
