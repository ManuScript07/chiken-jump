class_name ShadowAntialiasingTests
extends SceneTree

const DESIGN = preload("res://scripts/level_design.gd")
var level: ChickenLevel
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	print("PASS: " if value else "FAIL: ",message)
	if not value:
		failures += 1

func settle() -> void:
	for i in 8:
		await RenderingServer.frame_post_draw

func luma(color: Color) -> float:
	return color.r*0.2126+color.g*0.7152+color.b*0.0722

func profile(frame: Image, phase: float) -> Dictionary:
	var screen := PackedVector2Array()
	for point in DESIGN.vertices(DESIGN.pieces()[3]):
		var on_wall := DESIGN.canvas_to_wall(DESIGN.project_point(point,phase))
		screen.append(level.diorama.camera.unproject_position(on_wall))
	var hull := Geometry2D.convex_hull(screen)
	var errors: Array[float] = []
	var widths: Array[float] = []
	for x in range(175,245):
		var expected := INF
		for i in range(hull.size()-1):
			var a := hull[i]
			var b := hull[i+1]
			if float(x)+0.5>=minf(a.x,b.x) and float(x)+0.5<=maxf(a.x,b.x) and absf(a.x-b.x)>0.01:
				expected = minf(expected,lerpf(a.y,b.y,(float(x)+0.5-a.x)/(b.x-a.x)))
		if not is_finite(expected):
			continue
		var start := floori(expected)-5
		var bright := luma(frame.get_pixel(x,start))
		var dark := luma(frame.get_pixel(x,ceili(expected)+3))
		if bright-dark<0.25:
			continue
		var crossings := PackedFloat32Array([-1.0,-1.0,-1.0])
		for y in range(start+1,ceili(expected)+4):
			var previous := (bright-luma(frame.get_pixel(x,y-1)))/(bright-dark)
			var current := (bright-luma(frame.get_pixel(x,y)))/(bright-dark)
			for threshold in 3:
				var fraction: float = [0.1,0.5,0.9][threshold]
				if crossings[threshold]<0.0 and previous<=fraction and current>fraction:
					crossings[threshold] = float(y)-0.5+(fraction-previous)/(current-previous)
		if crossings[0]>=0.0 and crossings[2]>=0.0:
			errors.append(crossings[1]-expected)
			widths.append(crossings[2]-crossings[0])
	var mean := 0.0
	for error in errors:
		mean += error
	mean /= maxf(1.0,float(errors.size()))
	var variance := 0.0
	var width := 0.0
	for i in errors.size():
		variance += pow(errors[i]-mean,2.0)
		width += widths[i]
	return {"rms":sqrt(variance/maxf(1.0,float(errors.size()))),"width":width/maxf(1.0,float(widths.size())),"samples":errors.size(),"offset":mean}

func _run() -> void:
	level = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	level.player.enabled = false
	level.field.running = false
	var original_angle := level.diorama.key_light.spot_angle
	var original_attenuation := level.diorama.key_light.spot_attenuation
	for degrees in [35.0,45.0,55.0,65.0]:
		level.field.angle = deg_to_rad(degrees)
		level.field.update_projection(true)
		level.diorama.key_light.spot_angle = 42.0
		level.diorama.key_light.spot_attenuation = 0.12
		await settle()
		var baseline := root.get_texture().get_image()
		var reference := profile(baseline,level.field.angle)
		level.diorama.key_light.spot_angle = original_angle
		level.diorama.key_light.spot_attenuation = original_attenuation
		await settle()
		var frame := root.get_texture().get_image()
		var improved := profile(frame,level.field.angle)
		print("SHADOW AA ",degrees," baseline=",reference," candidate=",improved)
		check(improved.samples>=reference.samples*0.9,"shadow contour remains fully represented")
		check(improved.width<=reference.width*1.02,"antialiasing does not widen or blur the shadow edge")
		check(improved.rms<reference.rms*(0.9 if degrees<=45.0 else 1.02),"shadow contour is smoother without a spatial filter")
		if degrees==45.0:
			var lighting_error := 0.0
			var maximum_error := 0.0
			var count := 0
			for y in range(100,350,10):
				for x in range(20,520,10):
					var difference := absf(luma(frame.get_pixel(x,y))-luma(baseline.get_pixel(x,y)))
					lighting_error += difference
					maximum_error = maxf(maximum_error,difference)
					count += 1
			check(lighting_error/float(count)<0.02 and maximum_error<0.06,"wall lighting stays close to the reference without a visible cone edge")
			baseline.save_png(OS.get_user_data_dir().path_join("shadow-aa-before.png"))
			frame.save_png(OS.get_user_data_dir().path_join("shadow-aa-after.png"))
	if OS.get_cmdline_user_args().has("benchmark"):
		var timings: Array[float] = []
		for baseline_mode in [true,false,false,true]:
			level.diorama.key_light.spot_angle = 42.0 if baseline_mode else original_angle
			level.diorama.key_light.spot_attenuation = 0.12 if baseline_mode else original_attenuation
			for i in 30:
				await RenderingServer.frame_post_draw
			var started := Time.get_ticks_usec()
			for i in 180:
				level.field.angle = TAU*float(i)/180.0
				level.field.update_projection(true)
				await RenderingServer.frame_post_draw
			timings.append(float(Time.get_ticks_usec()-started)/180000.0)
		print("SHADOW AA FRAME TIME baseline=",(timings[0]+timings[3])*0.5," ms focused=",(timings[1]+timings[2])*0.5," ms")
	print("RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
