class_name GameHud
extends Control

signal jump_pressed
signal restart_pressed

const PIXEL = preload("res://scripts/pixel_art.gd")

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
	PIXEL.text(self, Vector2(27, 24), "КУРАТЕНЬ", 3, PIXEL.INK)
	PIXEL.text(self, Vector2(30, 64), "ЗВЕЗДЫ %d/3" % stars, 2, PIXEL.INK)
	PIXEL.border(self, RESTART, PIXEL.INK, PIXEL.CREAM, 4.0)
	PIXEL.text(self, RESTART.position + Vector2(14, 16), "ЗАНОВО", 2, PIXEL.INK)
	PIXEL.text(self, Vector2(30, 801), "ДИСК СОЗДАЕТ ТЕНИ", 2, PIXEL.INK)
	_draw_arrow(LEFT, false, "left")
	_draw_arrow(RIGHT, true, "right")
	_draw_jump()
	PIXEL.text(self, Vector2(394, 938), "ПРЫЖОК", 2, PIXEL.INK)
	if completed:
		draw_rect(Rect2(70, 261, 406, 152), Color("5c7866"))
		PIXEL.border(self, Rect2(64, 255, 406, 152), PIXEL.INK, PIXEL.CREAM, 6.0)
		PIXEL.text(self, Vector2(105, 289), "УРОВЕНЬ", 3, PIXEL.INK)
		PIXEL.text(self, Vector2(105, 320), "ПРОЙДЕН!", 3, PIXEL.INK)
		PIXEL.text(self, Vector2(105, 367), "ЗАНОВО - ЕЩЕ РАЗ", 2, PIXEL.RED)

func _draw_arrow(rect: Rect2, flip: bool, action: String) -> void:
	var rows: Array[String] = [
		"......KKK", ".....KWWK", "....KWWWK", "...KWWWWK", "..KWWWWWK", ".KWWWWWWK", "KWWWWWWWK",
		".KWWWWWWK", "..KWWWWWK", "...KWWWWK", "....KWWWK", ".....KWWK", "......KKK"
	]
	if flip:
		for i in rows.size():
			rows[i] = rows[i].reverse()
	var offset := Vector2(0, 3) if touch_actions.values().has(action) else Vector2.ZERO
	var origin := rect.get_center() - Vector2(27, 39) + offset
	PIXEL.sprite(self, origin + Vector2(0, 6), rows, {"K": PIXEL.INK, "W": Color("856a7e")}, 6)
	PIXEL.sprite(self, origin, rows, {"K": PIXEL.INK, "W": PIXEL.CREAM}, 6)

func _draw_jump() -> void:
	var rows: Array[String] = [
		".....KKKKK.....", "...KKWWWWWKK...", "..KWWWWWWWWWK..", ".KWWWWWWWWWWWK.",
		".KWWWWWWWWWWWK.", "KWWWWWWWWWWWWWK", "KWWWWWWWWWWWWWK", "KWWWWWWWWWWWWWK",
		"KWWWWWWWWWWWWWK", "KWWWWWWWWWWWWWK", ".KWWWWWWWWWWWK.", ".KWWWWWWWWWWWK.",
		"..KWWWWWWWWWK..", "...KKWWWWWKK...", ".....KKKKK....."
	]
	var offset := Vector2(0, 3) if touch_actions.values().has("jump") else Vector2.ZERO
	var origin := JUMP.get_center() - Vector2(45, 45) + offset
	PIXEL.sprite(self, origin + Vector2(0, 6), rows, {"K": PIXEL.INK, "W": Color("856a7e")}, 6)
	PIXEL.sprite(self, origin, rows, {"K": PIXEL.INK, "W": PIXEL.CREAM}, 6)
