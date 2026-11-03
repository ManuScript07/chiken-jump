class_name GameArt
extends RefCounted

static func star_points(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		points.append(center+Vector2.from_angle(-PI/2.0+float(i)*PI/5.0)*(radius if i%2==0 else radius*0.46))
	return points

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
