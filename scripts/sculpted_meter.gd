class_name SculptedMeter
extends Control

var ratio := 1.0
var fill_color := Color("d4b675")
var factor := 1.0
var styles: Array[StyleBoxFlat] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 7:
		styles.append(StyleBoxFlat.new())

func _capsule(index: int, rect: Rect2, color: Color) -> void:
	if rect.size.x<=0.1 or rect.size.y<=0.1:
		return
	var style := styles[index]
	style.bg_color = color
	var radius := roundi(minf(rect.size.y,rect.size.x)*0.5)
	style.set_corner_radius_all(radius)
	draw_style_box(style,rect)

func _draw() -> void:
	if styles.is_empty():
		return
	var rect := Rect2(Vector2.ZERO,size)
	_capsule(0,Rect2(Vector2(0,12)*factor,size),Color(0.12,0.09,0.15,0.18))
	_capsule(1,Rect2(Vector2(0,8)*factor,size),Color("60505f"))
	_capsule(2,Rect2(Vector2(0,6)*factor,size),Color("8c7784"))
	_capsule(3,rect,Color("e4ddd3"))
	var channel := rect.grow(-3*factor)
	_capsule(4,channel,Color("544653"))
	var inset := rect.grow(-5*factor)
	var fill := Rect2(inset.position,Vector2(inset.size.x*clampf(ratio,0,1),inset.size.y))
	_capsule(5,Rect2(fill.position+Vector2(0,2)*factor,fill.size),fill_color.darkened(0.28))
	_capsule(6,fill,fill_color)
	# A lit upper rim, recessed slot and shaded lower wall distinguish solid depth.
	draw_line(Vector2(12,1.5)*factor,Vector2(size.x-12*factor,1.5*factor),Color("fff6e7"),1.5*factor,true)
	if fill.size.x>8*factor:
		draw_line(fill.position+Vector2(4,1.5)*factor,Vector2(fill.end.x-4*factor,fill.position.y+1.5*factor),fill_color.lightened(0.45),1.5*factor,true)
