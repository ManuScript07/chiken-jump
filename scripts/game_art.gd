class_name GameArt
extends RefCounted

static func star_points(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		points.append(center+Vector2.from_angle(-PI/2.0+float(i)*PI/5.0)*(radius if i%2==0 else radius*0.46))
	return points

# Shallow lettering extrusion shares the controls’ upper lighting direction.
static func draw_raised_text(canvas: CanvasItem, value: String, baseline: Vector2, font_size: int, color: Color, factor: float = 1.0) -> void:
	var font := ThemeDB.fallback_font
	canvas.draw_string(font,baseline+Vector2(1,4)*factor,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(0.10,0.08,0.13,0.24))
	for depth in [2.5,1.25]:
		canvas.draw_string_outline(font,baseline+Vector2(0,depth)*factor,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,1,Color("554451"))
		canvas.draw_string(font,baseline+Vector2(0,depth)*factor,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("75616a"))
	canvas.draw_string_outline(font,baseline,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,1,Color("574752"))
	canvas.draw_string(font,baseline,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

static func draw_star(canvas: CanvasItem, center: Vector2, radius: float, alpha: float = 1.0) -> void:
	# Tiny pickup remnants can collapse into degenerate polygons at wall coordinates.
	if radius<1.0 or alpha<=0.02:
		return
	var points := star_points(center,radius)
	canvas.draw_colored_polygon(star_points(center+Vector2(0,1.7),radius),Color(0.28,0.21,0.12,alpha*0.6))
	canvas.draw_colored_polygon(points,Color(0.91,0.69,0.29,alpha))
	for i in range(0,10,2):
		canvas.draw_colored_polygon(PackedVector2Array([center,points[i],points[(i+1)%10]]),Color(1.0,0.86,0.50,alpha*0.8))
	var outline := points.duplicate()
	outline.append(points[0])
	canvas.draw_polyline(outline,Color(0.47,0.34,0.16,alpha),0.8,true)
