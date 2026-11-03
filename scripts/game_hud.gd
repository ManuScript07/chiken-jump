class_name GameHud
extends Control

signal jump_pressed
signal pause_pressed
signal resume_pressed
signal restart_pressed

var session: RunSession
var menu: RunMenu
var meter_view: SculptedMeter
var star_medallion: StarMedallion
var keys: Dictionary = {}
var layout: Dictionary = {}
var touch_actions: Dictionary = {}
var shown_ratio := 1.0
var pickup_pulse := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	star_medallion = StarMedallion.new()
	add_child(star_medallion)
	meter_view = SculptedMeter.new()
	add_child(meter_view)
	menu = RunMenu.new()
	menu.star_texture = star_medallion.texture
	add_child(menu)
	for action in ["left","right","jump","pause"]:
		var key := SculptedKey.new()
		key.kind = action
		add_child(key)
		keys[action] = key
	get_viewport().size_changed.connect(_relayout)
	_relayout()

func bind(value: RunSession) -> void:
	session = value
	session.state_changed.connect(_on_state_changed)
	session.star_collected.connect(_on_star)
	_on_state_changed(session.state)

func _relayout() -> void:
	size = get_viewport_rect().size
	layout = MobileLayout.calculate(size,MobileLayout.safe_rect(get_viewport()))
	for action: String in keys:
		var rect: Rect2 = layout[action]
		keys[action].position = rect.position
		keys[action].size = rect.size
		keys[action].queue_redraw()
	var meter: Rect2 = layout.meter
	meter_view.position = meter.position
	meter_view.size = meter.size
	meter_view.factor = layout.factor
	meter_view.queue_redraw()
	menu.size = size
	menu.center = layout.menu_center
	menu.scale_factor = layout.factor
	menu.queue_redraw()
	queue_redraw()

func _on_state_changed(_state: int) -> void:
	clear_input()
	menu.show_state(session)
	if session.state==RunSession.State.RUNNING:
		shown_ratio = session.time_ratio()
	queue_redraw()

func _on_star(_index: int, _point: Vector2) -> void:
	pickup_pulse = 1.0

func clear_input() -> void:
	touch_actions.clear()
	for key: SculptedKey in keys.values():
		key.held = false

func horizontal_input() -> float:
	if session==null or session.state!=RunSession.State.RUNNING:
		return 0.0
	return float(int(touch_actions.values().has("right"))-int(touch_actions.values().has("left")))

func action_rect(action: String) -> Rect2:
	return layout.get(action,Rect2())

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		clear_input()
		if OS.has_feature("mobile") and session!=null:
			pause_pressed.emit()
	elif what==NOTIFICATION_WM_GO_BACK_REQUEST and session!=null:
		_activate("pause")

func _input(event: InputEvent) -> void:
	if session==null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var code: Key = event.physical_keycode if event.physical_keycode!=0 else event.keycode
		if code==KEY_ESCAPE:
			_activate("pause")
		elif menu.visible:
			if code in [KEY_LEFT,KEY_A]:
				_activate("left")
			elif code in [KEY_RIGHT,KEY_D]:
				_activate("right")
			elif code in [KEY_UP,KEY_W,KEY_SPACE,KEY_ENTER]:
				_activate("jump")
		elif code in [KEY_UP,KEY_W,KEY_SPACE]:
			_activate("jump")
		else:
			return
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_press(event.index,event.position)
		else:
			touch_actions.erase(event.index)
	elif event is InputEventScreenDrag:
		_drag(event.index,event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(-1,event.position)
		else:
			touch_actions.erase(-1)
	elif event is InputEventMouseMotion and touch_actions.has(-1):
		_drag(-1,event.position)

func _action_at(point: Vector2) -> String:
	for action: String in keys:
		if action_rect(action).has_point(point):
			return action
	return ""

func _press(index: int, point: Vector2) -> void:
	var action := _action_at(point)
	if action.is_empty():
		return
	touch_actions[index] = action
	_activate(action)

func _drag(index: int, point: Vector2) -> void:
	if not touch_actions.has(index):
		return
	var previous: String = touch_actions[index]
	var next := _action_at(point)
	touch_actions[index] = next
	if next!=previous and not next.is_empty():
		_activate(next)

func _activate(action: String) -> void:
	if action=="pause":
		if session.state==RunSession.State.RUNNING:
			pause_pressed.emit()
		elif session.state==RunSession.State.PAUSED:
			resume_pressed.emit()
	elif menu.visible:
		if action=="left" or action=="right":
			menu.navigate(-1 if action=="left" else 1)
		elif action=="jump":
			if menu.selected_action()=="resume":
				resume_pressed.emit()
			else:
				restart_pressed.emit()
	elif action=="jump":
		jump_pressed.emit()

func _process(delta: float) -> void:
	if session==null:
		return
	var keyboard_left := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
	var keyboard_right := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	var keyboard_jump := Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_UP)
	for action: String in keys:
		keys[action].held = touch_actions.values().has(action) or (action=="left" and keyboard_left) or (action=="right" and keyboard_right) or (action=="jump" and keyboard_jump)
	shown_ratio = move_toward(shown_ratio,session.time_ratio(),delta*0.6)
	pickup_pulse = move_toward(pickup_pulse,0.0,delta*3.0)
	meter_view.ratio = shown_ratio
	var color := Color("d4b675") if shown_ratio>0.25 else Color("c77c71")
	meter_view.fill_color = color.lerp(Color("f2d997"),pickup_pulse*0.6)
	meter_view.queue_redraw()
	queue_redraw()

func _draw() -> void:
	if session==null or layout.is_empty():
		return
	var meter: Rect2 = layout.meter
	var factor: float = layout.factor
	var center := Vector2(meter.position.x+12*factor,meter.end.y+27*factor)
	if star_medallion.texture!=null:
		draw_texture_rect(star_medallion.texture,Rect2(center-Vector2(20,20)*factor,Vector2(40,40)*factor),false)
	GameArt.draw_raised_text(self,str(session.total_stars),center+Vector2(23,7)*factor,roundi(21*factor),Color("e9e4db"),factor)
