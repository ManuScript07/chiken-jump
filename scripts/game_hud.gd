class_name GameHud
extends Control

signal jump_pressed
signal restart_pressed

const LEFT := Rect2(30, 828, 112, 100)
const RIGHT := Rect2(155, 828, 112, 100)
const JUMP := Rect2(365, 818, 145, 110)
const RESTART := Rect2(417, 28, 100, 47)
const INK := Color(0.19, 0.26, 0.27)
const BUTTON := Color(0.29, 0.41, 0.40)

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
	draw_string(font, Vector2(29, 50), "КУРАТЕНЬ", HORIZONTAL_ALIGNMENT_LEFT, -1, 29, INK)
	draw_string(font, Vector2(30, 80), "ЗВЁЗДЫ  %d / 3" % stars, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, INK)
	draw_rect(RESTART, Color(0.9, 0.88, 0.81), true)
	draw_string(font, RESTART.position + Vector2(10, 30), "ЗАНОВО", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
	draw_string(font, Vector2(34, 804), "ВРАЩАЮЩИЙСЯ ДИСК", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.37, 0.43, 0.4))
	_draw_button(LEFT, "left")
	_draw_button(RIGHT, "right")
	_draw_button(JUMP, "jump")
	draw_colored_polygon(PackedVector2Array([Vector2(70, 878), Vector2(102, 855), Vector2(102, 901)]), Color.WHITE)
	draw_colored_polygon(PackedVector2Array([Vector2(227, 878), Vector2(195, 855), Vector2(195, 901)]), Color.WHITE)
	draw_string(font, Vector2(391, 883), "ПРЫЖОК", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_string(font, Vector2(31, 950), "A / D или стрелки  •  Пробел — прыжок  •  R — заново", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.4, 0.45, 0.42))
	if completed:
		draw_rect(Rect2(62, 248, 416, 156), Color(0.97, 0.96, 0.9, 0.97))
		draw_string(font, Vector2(100, 306), "ВСЕ ЗВЁЗДЫ СОБРАНЫ!", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, INK)
		draw_string(font, Vector2(107, 348), "Нажми «ЗАНОВО», чтобы повторить", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)

func _draw_button(rect: Rect2, action: String) -> void:
	var color := BUTTON.lightened(0.18) if touch_actions.values().has(action) else BUTTON
	draw_rect(rect, color, true)
