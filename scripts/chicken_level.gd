class_name ChickenLevel
extends Node2D

const DESIGN = preload("res://scripts/level_design.gd")

@onready var field: ShadowField = $ShadowField
@onready var player: ChickenPlayer = $Player
@onready var diorama: DiskDiorama = $Diorama
@onready var hud: GameHud = $HUD

var collected: Array[bool] = [false, false, false]
var completed := false

func _ready() -> void:
	player.shadow_field = field
	hud.jump_pressed.connect(player.request_jump)
	hud.restart_pressed.connect(restart)
	restart()

func restart() -> void:
	completed = false
	collected = [false, false, false]
	field.reset()
	player.reset_to(DESIGN.PLAYER_START)
	hud.reset()
	diorama.set_angle(field.angle)
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_SPACE or event.keycode == KEY_UP or event.keycode == KEY_W:
		player.request_jump()
	elif event.keycode == KEY_R:
		restart()

func _physics_process(_delta: float) -> void:
	diorama.set_angle(field.angle)
	if completed:
		return
	var keyboard_axis := int(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	player.input_axis = clampf(keyboard_axis + hud.horizontal_input(), -1.0, 1.0)
	if field.touches_hazard(player.bounds()):
		restart()
		return
	for i in DESIGN.STAR_POSITIONS.size():
		if not collected[i] and player.position.distance_to(DESIGN.STAR_POSITIONS[i]) < 28.0:
			collected[i] = true
			hud.stars += 1
			hud.queue_redraw()
			queue_redraw()
			if hud.stars == DESIGN.STAR_POSITIONS.size():
				_finish()
				return

func _finish() -> void:
	completed = true
	field.running = false
	player.enabled = false
	hud.completed = true
	hud.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 540, 960), Color(0.94, 0.94, 0.89))
	draw_rect(Rect2(20, 104, 500, 496), Color(0.99, 0.98, 0.93))
	draw_rect(Rect2(20, 104, 500, 496), Color(0.83, 0.85, 0.8), false, 2.0)
	draw_rect(Rect2(20, 600, 500, 12), Color(0.31, 0.36, 0.33))
	for i in DESIGN.STAR_POSITIONS.size():
		if not collected[i]:
			_draw_star(DESIGN.STAR_POSITIONS[i])

func _draw_star(center: Vector2) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var radius := 13.0 if i % 2 == 0 else 6.0
		var a := -PI / 2.0 + float(i) * PI / 5.0
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(points, Color(0.96, 0.72, 0.22))
