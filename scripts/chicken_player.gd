class_name ChickenPlayer
extends CharacterBody2D

const PIXEL = preload("res://scripts/pixel_art.gd")
const SPEED := 190.0
const ACCELERATION := 1500.0
const GRAVITY := 1500.0
const JUMP_SPEED := 610.0
const BODY_SIZE := Vector2(27.0, 34.0)

var input_axis := 0.0
var facing := 1
var jump_pending := false
var enabled := true
var support: Object
var shadow_field: ShadowField

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 4.0
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = BODY_SIZE
	shape_node.shape = shape
	add_child(shape_node)

func request_jump() -> void:
	if enabled:
		jump_pending = true

func reset_to(start: Vector2) -> void:
	position = start
	velocity = Vector2.ZERO
	support = null
	jump_pending = false
	input_axis = 0.0
	facing = 1
	enabled = true

func bounds() -> Rect2:
	return Rect2(position - BODY_SIZE * 0.5, BODY_SIZE)

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	if is_on_floor() and is_instance_valid(support) and shadow_field != null:
		position += shadow_field.motion_for(support)
	if absf(input_axis) > 0.1:
		facing = 1 if input_axis > 0 else -1
	velocity.x = move_toward(velocity.x, input_axis * SPEED, ACCELERATION * delta)
	velocity.y += GRAVITY * delta
	if jump_pending and is_on_floor():
		velocity.y = -JUMP_SPEED
	jump_pending = false
	move_and_slide()
	position.x = clampf(position.x, 33.0, 507.0)
	support = null
	if is_on_floor():
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			if collision.get_normal().y < -0.7:
				support = collision.get_collider()
				break
	queue_redraw()

func _draw() -> void:
	# The 9x11 sprite fits the 27x34 collision body, including the beak and feet.
	var rows: Array[String] = [
		"..R.R....", "..RRRR...", "..KKKK...", ".KWWWWK..", "KWWWKWKO.",
		"KWWWWWWOO", "KWWYYWWK.", "KWWYYWWK.", ".KWWWWK..", "..KKKK...", "..O..O..."
	]
	if facing < 0:
		for i in rows.size():
			rows[i] = rows[i].reverse()
	PIXEL.sprite(self, Vector2(-13.5, -16), rows, {
		"K": PIXEL.INK, "W": Color("fff5d9"), "Y": Color("ded2b5"),
		"R": PIXEL.RED, "O": Color("e9a443")
	}, 3)
