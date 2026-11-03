class_name RunMenu
extends Control

var selected := 0
var options: Array[String] = []
var heading := ""
var score := 0
var star_texture: Texture2D
var center := Vector2(270,400)
var scale_factor := 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func show_state(session: RunSession) -> void:
	selected = 0
	visible = session.state!=RunSession.State.RUNNING
	options.assign(["Продолжить","Заново"] if session.state==RunSession.State.PAUSED else ["Заново"])
	heading = "Пауза"
	if session.state==RunSession.State.FINISHED:
		heading = ["Время вышло","Падение","Зажало","Столкновение"][session.end_reason]
	score = session.total_stars
	queue_redraw()

func navigate(direction: int) -> void:
	if visible and not options.is_empty():
		selected = posmod(selected+direction,options.size())
		queue_redraw()

func selected_action() -> String:
	return "resume" if options[selected]=="Продолжить" else "restart"

func _text(value: String, at: Vector2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	GameArt.draw_raised_text(self,value,at-Vector2(width*0.5,0),font_size,color,scale_factor)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.10,0.085,0.14,0.78))
	var factor := scale_factor
	_text(heading,center-Vector2(0,105)*factor,roundi(23*factor),Color("c9bec4"))
	for i in options.size():
		var baseline := center+Vector2(0,float(i)*62.0)*factor
		var chosen := i==selected
		_text(options[i],baseline,roundi(31*factor),Color("f1d393") if chosen else Color("d4cbd0"))
		if chosen:
			var half_width := ThemeDB.fallback_font.get_string_size(options[i],HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(31*factor)).x*0.5+22*factor
			for side in [-1.0,1.0]:
				var tip := baseline+Vector2(side*half_width,-10*factor)
				draw_colored_polygon(PackedVector2Array([tip,tip+Vector2(side*8,-6)*factor,tip+Vector2(side*8,6)*factor]),Color("f1d393"))
	if options.size()==1:
		if star_texture!=null:
			draw_texture_rect(star_texture,Rect2(center+Vector2(-36,55)*factor,Vector2(36,36)*factor),false)
		_text(str(score),center+Vector2(14,81)*factor,roundi(24*factor),Color("e9e1d6"))
