class_name RoomRenderTests
extends SceneTree

const DESIGN = preload("res://scripts/level_design.gd")
var failures := 0

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

func row_max_jump(frame: Image, y: int) -> float:
	var largest := 0.0
	for x in range(31,510):
		largest = maxf(largest,absf(luminance(frame.get_pixel(x,y))-luminance(frame.get_pixel(x-1,y))))
	return largest

func _run() -> void:
	var level: ChickenLevel = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	level.field.running = false
	level.player.enabled = false
	for angle in [0.0,PI/4.0,PI/2.0]:
		level.field.angle = angle
		level.field.update_projection(true)
		for i in 8:
			await RenderingServer.frame_post_draw
		var frame := root.get_texture().get_image()
		check(row_max_jump(frame,250)<0.04,"wall has no shadow-acne stripes at phase %.0f" % rad_to_deg(angle))
		check(row_max_jump(frame,770)<0.04,"floor has no exposed spotlight edge at phase %.0f" % rad_to_deg(angle))
		check(luminance(frame.get_pixel(70,300))-luminance(frame.get_pixel(70,730))>0.15,"floor and wall retain distinct lighting at phase %.0f" % rad_to_deg(angle))
		# A known interior point of the beige cube's real shadow, away from edges.
		var canvas_point := DESIGN.project_point(DESIGN.pieces()[0].center,angle)
		var on_wall := DESIGN.canvas_to_wall(canvas_point)
		var pixel := Vector2i(level.diorama.camera.unproject_position(on_wall))
		check(luminance(frame.get_pixelv(pixel))<0.5,"3D cube casts a visible physical shadow at phase %.0f" % rad_to_deg(angle))
	print("RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
