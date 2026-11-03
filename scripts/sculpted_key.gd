class_name SculptedKey
extends Control

var kind := "jump"
var pressure := 0.0
var held := false
var feedback_time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func press() -> void:
	# State changes can clear gameplay input immediately; key travel must stay visible.
	feedback_time = 0.12

func _process(delta: float) -> void:
	feedback_time = maxf(0.0,feedback_time-delta)
	var next := move_toward(pressure,1.0 if held or feedback_time>0.0 else 0.0,delta*16.0)
	if not is_equal_approx(next,pressure):
		pressure = next
		queue_redraw()

func _rounded_triangle(vertices: PackedVector2Array, cut: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in vertices.size():
		var corner := vertices[i]
		var start := corner.move_toward(vertices[(i+vertices.size()-1)%vertices.size()],cut)
		var end := corner.move_toward(vertices[(i+1)%vertices.size()],cut)
		for j in 7:
			var t := float(j)/6.0
			result.append(start.lerp(corner,t).lerp(corner.lerp(end,t),t))
	return result

func _outline(points: PackedVector2Array, color: Color, width: float) -> void:
	var closed := points.duplicate()
	closed.append(closed[0])
	draw_polyline(closed,color,width,true)

func _solid(points: PackedVector2Array, scale_factor: float) -> void:
	var travel := Vector2(0,(-5.0+pressure*5.0)*scale_factor)
	var face := PackedVector2Array()
	var base := PackedVector2Array()
	var shadow := PackedVector2Array()
	# Normalize winding so mirrored triangles expose the same lower side.
	var contour := points.duplicate()
	var area := 0.0
	for i in contour.size():
		area += contour[i].cross(contour[(i+1)%contour.size()])
	if area<0.0:
		contour.reverse()
	for point in contour:
		face.append(point+travel)
		base.append(point+Vector2(0,6)*scale_factor)
		shadow.append(point+Vector2(0,9)*scale_factor)
	_outline(shadow,Color(0.12,0.10,0.15,0.06),5*scale_factor)
	_outline(shadow,Color(0.12,0.10,0.15,0.08),2.5*scale_factor)
	draw_colored_polygon(shadow,Color(0.12,0.10,0.15,0.18))
	draw_colored_polygon(base,Color("574c59"))
	_outline(base,Color("3d3542"),1.7*scale_factor)
	for i in contour.size():
		var next := (i+1)%contour.size()
		var edge := contour[next]-contour[i]
		var outward := Vector2(edge.y,-edge.x).normalized()
		if outward.y>0.001:
			var shade := Color("796775").darkened((1.0-outward.y)*0.12)
			draw_colored_polygon(PackedVector2Array([face[i],face[next],base[next],base[i]]),shade)
	draw_colored_polygon(face,Color("e9e4db").darkened(pressure*0.06))
	_outline(face,Color("534956"),1.5*scale_factor)
	var center := Rect2(face[0],Vector2.ZERO)
	for point in face:
		center = center.expand(point)
	var inset := PackedVector2Array()
	for point in face:
		inset.append(point.lerp(center.get_center(),0.045))
	_outline(inset,Color(1,0.98,0.92,0.65),1.2*scale_factor)

func _draw() -> void:
	var unit := minf(size.x/108.0,size.y/118.0)
	var center := size*0.5
	if kind=="pause":
		unit = size.x/64.0
		for offset in [-10.0,10.0]:
			var rect := Rect2(center+Vector2(offset-5.5,-18)*unit,Vector2(11,33)*unit)
			_solid(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]),unit)
	elif kind=="jump":
		var points := PackedVector2Array()
		for i in 80:
			points.append(center+Vector2.from_angle(float(i)*TAU/80.0)*44.0*unit)
		_solid(points,unit)
	else:
		# One equilateral master, mirrored together with its bevel, extrusion and shadow.
		# This prevents separate left/right constructions from acquiring different slopes.
		var direction := -1.0 if kind=="left" else 1.0
		var half_height := 44.0 # Same nominal span as the jump key diameter.
		var half_width := half_height*sqrt(3.0)*0.5
		var vertices := PackedVector2Array([Vector2(half_width,0),Vector2(-half_width,half_height),Vector2(-half_width,-half_height)])
		draw_set_transform(center,0.0,Vector2(direction*unit,unit))
		_solid(_rounded_triangle(vertices,4.0),1.0)
		draw_set_transform(Vector2.ZERO)
