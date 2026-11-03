class_name UiArtTests
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

func surface(dimensions: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.world_2d = World2D.new()
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	return viewport

func settle() -> void:
	for i in 4:
		await RenderingServer.frame_post_draw

func face_top(image: Image) -> int:
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x,y)
			if pixel.a>0.95 and pixel.r>0.75 and pixel.g>0.7:
				return y
	return -1

func _run() -> void:
	var captures: Array[SubViewport] = []
	var keys: Array[SculptedKey] = []
	for kind in ["left","right","jump"]:
		var viewport := surface(Vector2i(128,140))
		var key := SculptedKey.new()
		key.kind = kind
		key.position = Vector2(10,11)
		key.size = Vector2(108,118)
		viewport.add_child(key)
		captures.append(viewport)
		keys.append(key)
	await settle()
	var left := captures[0].get_texture().get_image()
	var right := captures[1].get_texture().get_image()
	var difference := 0.0
	var maximum := 0.0
	for y in left.get_height():
		for x in left.get_width():
			var a := left.get_pixel(x,y)
			var b := right.get_pixel(left.get_width()-1-x,y)
			var error := absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)+absf(a.a-b.a)
			difference += error
			maximum = maxf(maximum,error)
	difference /= float(left.get_width()*left.get_height()*4)
	check(difference<0.002,"left/right keys, bevels and cast shadows are pixel-mirrored; mean error="+str(difference))
	var jump := captures[2].get_texture().get_image()
	var jump_height := jump.get_used_rect().size.y
	check(left.get_used_rect().size.y<=jump_height and right.get_used_rect().size.y<=jump_height,"direction keys including extrusion and shadow are no taller than jump: "+str(left.get_used_rect().size.y)+" / "+str(right.get_used_rect().size.y)+" <= "+str(jump_height))
	var top := face_top(left)
	for key in keys:
		key.held = true
	for i in 10:
		await process_frame
	await settle()
	var pressed := captures[0].get_texture().get_image()
	var pressed_jump_height := captures[2].get_texture().get_image().get_used_rect().size.y
	check(pressed.get_used_rect().size.y<=pressed_jump_height,"pressed direction key also stays within jump key height")
	check(face_top(pressed)>top+3,"pressing translates the face downward without tilting it")
	var viewport := surface(Vector2i(440,80))
	var meter := SculptedMeter.new()
	meter.position = Vector2(20,15)
	meter.size = Vector2(400,24)
	meter.ratio = 0.5
	viewport.add_child(meter)
	await settle()
	var image := viewport.get_texture().get_image()
	var gold := image.get_pixel(100,27)
	var slot := image.get_pixel(300,27)
	var side := image.get_pixel(100,43)
	check(gold.r>slot.r+0.2 and gold.g>slot.g+0.2 and side.a>0.95 and side.r<gold.r-0.2,"meter visibly separates its fill, recessed slot and solid lower wall")
	var medallion := StarMedallion.new()
	root.add_child(medallion)
	await settle()
	var star_image := medallion.texture.get_image()
	var arrays := medallion.model.mesh.surface_get_arrays(0)
	var triangles := (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size()/3
	check(medallion.model.mesh.get_aabb().size.z>0.4 and triangles<=100,"HUD star is a closed bevelled 3D mesh with visible thickness and a small triangle budget")
	check(RenderingServer.viewport_get_update_mode(medallion.viewport.get_viewport_rid())==RenderingServer.VIEWPORT_UPDATE_DISABLED and medallion.viewport.positional_shadow_atlas_size==0,"static star renders once and allocates no shadow map")
	check(star_image.get_pixel(0,0).a==0 and star_image.get_used_rect().has_area(),"star render has a transparent background without a cast shadow")
	medallion.model.rotation_degrees.y += 40
	medallion.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await settle()
	check(star_image.get_data()!=medallion.texture.get_image().get_data(),"rotating the real star changes visible geometry and lighting")
	print("RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
