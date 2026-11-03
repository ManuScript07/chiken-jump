class_name MobileLayout
extends RefCounted

static func safe_rect(viewport: Viewport) -> Rect2:
	var whole := viewport.get_visible_rect()
	if not OS.has_feature("mobile"):
		return whole
	var physical := Rect2(DisplayServer.get_display_safe_area())
	if not physical.has_area():
		return whole
	var local := viewport.get_screen_transform().affine_inverse()*physical
	var safe := whole.intersection(local)
	return safe if safe.has_area() else whole

static func calculate(view_size: Vector2, usable: Rect2) -> Dictionary:
	var safe := usable.intersection(Rect2(Vector2.ZERO,view_size))
	var factor := clampf(safe.size.x/540.0,0.65,1.35)
	var margin := 26.0*factor
	var width := 108.0*factor
	var height := 118.0*factor
	var bottom := safe.end.y-28.0*factor
	var left := Rect2(Vector2(safe.position.x+margin,bottom-height),Vector2(width,height))
	var right := Rect2(Vector2(left.end.x+16.0*factor,bottom-height),Vector2(width,height))
	var jump := Rect2(Vector2(safe.end.x-margin-width,bottom-height),Vector2(width,height))
	var pause := Rect2(Vector2(safe.end.x-margin-64.0*factor,safe.position.y+36.0*factor),Vector2(64.0,68.0)*factor)
	var meter := Rect2(Vector2(safe.position.x+margin,safe.position.y+55.0*factor),Vector2(maxf(90.0,pause.position.x-safe.position.x-margin-26.0*factor),24.0*factor))
	return {"safe":safe,"factor":factor,"left":left,"right":right,"jump":jump,"pause":pause,"meter":meter,"controls_top":bottom-height,"menu_center":Vector2(safe.get_center().x,minf(safe.position.y+safe.size.y*0.43,bottom-height-160.0*factor))}
