class_name GameHud
extends Control

signal jump_pressed
signal restart_pressed


const LEFT := Rect2(30, 828, 112, 100)
const RIGHT := Rect2(155, 828, 112, 100)
const JUMP := Rect2(365, 818, 145, 110)
const RESTART := Rect2(417, 28, 100, 47)

const REPLAY := Rect2(224, 444, 92, 76)
var press_depth := {"left": 0.0, "right": 0.0, "jump": 0.0}
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
	if RESTART.has_point(point) or (completed and REPLAY.has_point(point)):
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

# Bevels, inset glyphs and key travel give the controls a physical console feel.
func _process(delta: float) -> void:
	var changed := false
	for action: String in press_depth:
		var target := 1.0 if touch_actions.values().has(action) else 0.0
		var next := move_toward(float(press_depth[action]), target, delta * 14.0)
		changed = changed or not is_equal_approx(next, press_depth[action])
		press_depth[action] = next
	if changed:
		queue_redraw()

func _draw() -> void:
	# Three unlabelled sockets show the collectible objective without text.
	for i in 3:
		var center := Vector2(42 + i * 38, 48)
		draw_circle(center, 16, Color("101820"))
		draw_arc(center,16,0,TAU,32,Color("3a454e"),1.5,true)
		_star(center, 10.0, Color("f3c66a") if i < stars else Color("4c555b"))
	_small_key(RESTART, false)
	_replay_icon(RESTART.get_center(), 13, Color("b5c4c6"))
	# An inset controller deck with small fasteners, rather than floating cards.
	var deck := _chamfer(Rect2(17,805,506,141),18)
	draw_colored_polygon(deck,Color("111a22"))
	draw_polyline(_closed(deck),Color("35434d"),2,true)
	for point in [Vector2(31,819),Vector2(509,819),Vector2(31,933),Vector2(509,933)]:
		draw_circle(point,2.5,Color("60717b"))
		draw_line(point-Vector2(1.5,0),point+Vector2(1.5,0),Color("14202a"),1.0,true)
	_direction_key(LEFT, "left", -1)
	_direction_key(RIGHT, "right", 1)
	_jump_key()
	for i in 4:
		draw_line(Vector2(294,852+i*12),Vector2(325,852+i*12),Color("25313a"),3.0,true)
	if completed:
		draw_rect(Rect2(0,0,540,960),Color(0.025,0.04,0.06,0.72))
		var panel := _chamfer(Rect2(144,290,252,244),20)
		draw_colored_polygon(panel,Color("202f38"))
		draw_polyline(_closed(panel),Color("657d7c"),2.0,true)
		draw_circle(Vector2(270,351),37,Color("324f43"))
		draw_polyline(PackedVector2Array([Vector2(251,351),Vector2(264,364),Vector2(289,338)]),Color("a0f39c"),6.0,true)
		for i in 3:
			_star(Vector2(226+i*44,411),15,Color("f3c66a"))
		_small_key(REPLAY,true)
		_replay_icon(REPLAY.get_center(),19,Color("c9f8bd"))

func _direction_key(rect: Rect2, action: String, direction: int) -> void:
	var depth: float = press_depth[action]
	var face := _key(rect, depth, Color("637885"), Color("3f5361"))
	var center := face.get_center()
	var points := PackedVector2Array([center+Vector2(-direction*8,-18),center+Vector2(direction*11,0),center+Vector2(-direction*8,18)])
	draw_polyline(points,Color("c9dadb"),5.0,true)

func _jump_key() -> void:
	var depth: float = press_depth.jump
	var center := JUMP.get_center() + Vector2(0,depth*6-3)
	draw_circle(JUMP.get_center()+Vector2(0,5),51,Color("080f15"))
	draw_circle(center,49,Color("2d493b"))
	draw_arc(center,47,0,TAU,64,Color("91bb82"),2.0,true)
	draw_circle(center-Vector2(0,2),42,Color("64835a") if depth < 0.5 else Color("526c4a"))
	draw_arc(center-Vector2(0,2),40,PI,TAU,32,Color("9bb68a"),2.0,true)
	draw_polyline(PackedVector2Array([center+Vector2(-16,2),center+Vector2(0,-14),center+Vector2(16,2)]),Color("e2f6cf"),5.0,true)
	draw_line(center+Vector2(0,-12),center+Vector2(0,15),Color("e2f6cf"),5.0,true)
	draw_line(center+Vector2(-12,22),center+Vector2(12,22),Color("bbd6a8"),3.0,true)

func _key(rect: Rect2, depth: float, light: Color, dark: Color) -> Rect2:
	var base := rect.grow(-7)
	draw_colored_polygon(_chamfer(base,12),Color("070e14"))
	var face := Rect2(base.position+Vector2(3,-5+depth*6),base.size-Vector2(6,7))
	draw_colored_polygon(_chamfer(face,10),dark)
	var inset := face.grow(-4)
	draw_colored_polygon(_chamfer(inset,8),light.darkened(depth*0.18))
	draw_line(inset.position+Vector2(8,1),Vector2(inset.end.x-8,inset.position.y+1),light.lightened(0.3),2.0,true)
	return face

func _small_key(rect: Rect2, accent: bool) -> void:
	draw_colored_polygon(_chamfer(rect,10),Color("17242b"))
	draw_polyline(_closed(_chamfer(rect.grow(-2),8)),Color("65806b") if accent else Color("46545c"),1.5,true)

func _replay_icon(center: Vector2, radius: float, color: Color) -> void:
	draw_arc(center,radius,-PI*0.25,PI*1.4,32,color,2.5,true)
	var end := center + Vector2.from_angle(PI*1.4)*radius
	draw_colored_polygon(PackedVector2Array([end+Vector2(-6,-3),end+Vector2(5,-6),end+Vector2(2,5)]),color)

func _star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		points.append(center+Vector2.from_angle(-PI/2+i*PI/5)*(radius if i%2==0 else radius*0.46))
	draw_colored_polygon(points,color)

func _chamfer(rect: Rect2, cut: float) -> PackedVector2Array:
	var p := rect.position
	var e := rect.end
	return PackedVector2Array([p+Vector2(cut,0),Vector2(e.x-cut,p.y),Vector2(e.x,p.y+cut),e-Vector2(0,cut),e-Vector2(cut,0),Vector2(p.x+cut,e.y),Vector2(p.x,e.y-cut),p+Vector2(0,cut)])

func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	result.append(result[0])
	return result
