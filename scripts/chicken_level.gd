class_name ChickenLevel
extends Node2D

const DESIGN = preload("res://scripts/level_design.gd")
const PIXEL = preload("res://scripts/pixel_art.gd")

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
	# The checkerboard and heavy bezel evoke a handheld console.
	draw_rect(Rect2(0, 0, 540, 960), PIXEL.GREEN)
	for y in range(0, 960, 24):
		for x in range(0, 540, 24):
			if (x / 24 + y / 24) % 2 == 0:
				draw_rect(Rect2(x, y, 24, 24), Color("78b68a"))
	draw_rect(Rect2(17, 102, 514, 518), Color("528a69"))
	PIXEL.border(self, Rect2(12, 96, 516, 516), PIXEL.INK, Color("d9e4d4"), 8.0)
	draw_rect(Rect2(21, 105, 498, 495), Color("ebe9df"))
	PIXEL.text(self, Vector2(36, 123), "ЖДИ ПОВОРОТА", 2, Color("6f8474"))
	# Stepped decorative skyline stays behind all playable silhouettes.
	for x in range(26, 515, 36):
		var h := 12 + int((x / 36) % 3) * 9
		draw_rect(Rect2(x, 600 - h, 12, h), Color("d4ded0"))
	draw_rect(Rect2(20, 600, 500, 12), PIXEL.INK)
	draw_rect(Rect2(20, 600, 500, 3), Color("74977b"))
	# The 3D viewport and its content are deliberately left untouched.
	draw_rect(Rect2(25, 620, 490, 180), PIXEL.INK)
	for i in DESIGN.STAR_POSITIONS.size():
		if not collected[i]:
			_draw_star(DESIGN.STAR_POSITIONS[i])

func _draw_star(center: Vector2) -> void:
	var rows: Array[String] = [
		"...KKK...", "...KGK...", "KKKKGKKKK", "KGGGGGGGK", "KGGGGGGGK",
		".KGGGGGK.", "..KGGGK..", ".KGGKGGK.", "KKK...KKK"
	]
	PIXEL.sprite(self, center - Vector2(13, 13), rows, {"K": PIXEL.INK, "G": PIXEL.GOLD}, 3)
