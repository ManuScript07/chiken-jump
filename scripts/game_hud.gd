class_name GameHud
extends Control

signal jump_pressed
signal restart_pressed


const LEFT := Rect2(30, 828, 112, 100)
const RIGHT := Rect2(155, 828, 112, 100)
const JUMP := Rect2(365, 818, 145, 110)
const RESTART := Rect2(417, 28, 100, 47)

var touch_actions: Dictionary = {}
var stars := 0
var completed := false

func _ready() -> void:
	size = Vector2(540, 960)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		touch_actions.clear()
		queue_redraw()

func horizontal_input() -> float:
	var left := touch_actions.values().has("left")
	var right := touch_actions.values().has("right")
	return float(int(right) - int(left))

func reset() -> void:
	touch_actions.clear()
	stars = 0
	completed = false
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.index, event.position)
		else:
			touch_actions.erase(event.index)
			queue_redraw()
	elif event is InputEventScreenDrag:
		_drag(event.index, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(-1, event.position)
		else:
			touch_actions.erase(-1)
			queue_redraw()
	elif event is InputEventMouseMotion and touch_actions.has(-1):
		_drag(-1, event.position)

func _press(index: int, point: Vector2) -> void:
	if RESTART.has_point(point):
		restart_pressed.emit()
		return
	var action := _action_at(point)
	if action.is_empty():
		return
	touch_actions[index] = action
	if action == "jump":
		jump_pressed.emit()
	queue_redraw()

func _drag(index: int, point: Vector2) -> void:
	if not touch_actions.has(index):
		return
	var previous: String = touch_actions[index]
	var next := _action_at(point)
	touch_actions[index] = next
	if next == "jump" and previous != "jump":
		jump_pressed.emit()
	queue_redraw()

func _action_at(point: Vector2) -> String:
	if LEFT.has_point(point):
		return "left"
	if RIGHT.has_point(point):
		return "right"
	if JUMP.has_point(point):
		return "jump"
	return ""

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(26,43), "Куратень", HORIZONTAL_ALIGNMENT_LEFT,-1,27,Color("f5ebd7"))
	draw_string(font, Vector2(27,69), "Собери звёзды на стене   %d / 3" % stars, HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("b1b8c8"))
	_panel(RESTART, Color("2d3442"), 10)
	draw_string(font, RESTART.position + Vector2(16,29), "Заново", HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("eee8dc"))
	_panel(Rect2(18,806,504,145),Color(0.075,0.09,0.13,0.94),20)
	_button(LEFT,"left")
	_button(RIGHT,"right")
	_button(JUMP,"jump")
	draw_colored_polygon(PackedVector2Array([Vector2(72,878),Vector2(101,860),Vector2(101,896)]),Color("eee6d5"))
	draw_colored_polygon(PackedVector2Array([Vector2(225,878),Vector2(196,860),Vector2(196,896)]),Color("eee6d5"))
	draw_string(font,Vector2(398,881),"Прыжок",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("fff0cf"))
	if completed:
		_panel(Rect2(64,270,412,150),Color("202838"),18)
		draw_string(font,Vector2(101,325),"Все звёзды собраны",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("ffe2a4"))
		draw_string(font,Vector2(112,367),"Нажми «Заново», чтобы повторить",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("d4dae4"))

func _panel(rect: Rect2, color: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	draw_style_box(style,rect)

func _button(rect: Rect2, action: String) -> void:
	var pressed := touch_actions.values().has(action)
	var color := Color("586773") if pressed else Color("303e4e")
	if action == "jump":
		color = Color("8b734b") if pressed else Color("65563d")
	_panel(rect.grow(-5),color,18)
