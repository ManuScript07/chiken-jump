class_name RunMenu
extends Control

var selected := 0
var options: Array[String] = []
var heading := ""
var score := 0
var star_texture: Texture2D
var center := Vector2(270,400)
var scale_factor := 1.0
var heading_view: SculptedLabel
var item_views: Array[SculptedLabel] = []
var arrows: Array[SculptedLabel] = []
var score_view: SculptedLabel

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading_view = _label()
	for i in 2:
		item_views.append(_label())
		arrows.append(_label())
	score_view = _label()
	visible = false

func _label() -> SculptedLabel:
	var label := SculptedLabel.new()
	add_child(label)
	return label

func show_state(session: RunSession) -> void:
	selected = 0
	visible = session.state!=RunSession.State.RUNNING
	options.assign(["Продолжить","Заново"] if session.state==RunSession.State.PAUSED else ["Заново"])
	heading = "Пауза"
	if session.state==RunSession.State.FINISHED:
		heading = ["Время вышло","Падение","Зажало","Столкновение"][session.end_reason]
	score = session.total_stars
	refresh_layout()

func navigate(direction: int) -> void:
	if visible and not options.is_empty():
		selected = posmod(selected+direction,options.size())
		refresh_layout()

func selected_action() -> String:
	return "resume" if options[selected]=="Продолжить" else "restart"

func _place(label: SculptedLabel, text_value: String, baseline: Vector2, font_size: float, color: Color) -> void:
	label.configure(text_value,font_size,color)
	label.position = baseline-Vector2(label.size.x*0.5,label.size.y*0.5+font_size*0.32)

func refresh_layout() -> void:
	if heading_view==null or options.is_empty():
		return
	var factor := scale_factor
	_place(heading_view,heading,center-Vector2(0,105)*factor,23*factor,Color("d9ccd4"))
	for i in item_views.size():
		item_views[i].visible = i<options.size()
		if i<options.size():
			_place(item_views[i],options[i],center+Vector2(0,i*62)*factor,31*factor,Color("f1d393") if i==selected else Color("e1d7db"))
	var baseline := center+Vector2(0,selected*62)*factor
	var half_width := item_views[selected].size.x*0.5+18*factor
	for i in 2:
		var side := -1.0 if i==0 else 1.0
		arrows[i].configure("",20*factor,Color("f1d393"),-int(side))
		arrows[i].position = baseline+Vector2(side*half_width,-10*factor)-arrows[i].size*0.5
	score_view.visible = options.size()==1
	if score_view.visible:
		_place(score_view,str(score),center+Vector2(14,81)*factor,24*factor,Color("e9e1d6"))
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.10,0.085,0.14,0.78))
	if options.size()==1 and star_texture!=null:
		draw_texture_rect(star_texture,Rect2(center+Vector2(-36,55)*scale_factor,Vector2(36,36)*scale_factor),false)
