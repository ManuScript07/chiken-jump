class_name ChickenPlayer
extends CharacterBody2D

const SPEED := 190.0
const ACCELERATION := 1500.0
const GRAVITY := 1500.0
const JUMP_SPEED := 610.0
const BODY_SIZE := Vector2(26.0, 34.0)

var input_axis := 0.0
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
	enabled = true

func bounds() -> Rect2:
	return Rect2(position - BODY_SIZE * 0.5, BODY_SIZE)

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	if is_on_floor() and is_instance_valid(support) and shadow_field != null:
		position += shadow_field.motion_for(support)
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
	# Temporary vector character: legible at mobile scale and independent of assets.
	draw_circle(Vector2(0, 1), 15.0, Color(0.98, 0.94, 0.79))
	draw_circle(Vector2(3, -8), 9.0, Color(1.0, 0.97, 0.85))
	draw_circle(Vector2(6, -10), 1.6, Color(0.18, 0.21, 0.22))
	draw_colored_polygon(PackedVector2Array([Vector2(11, -7), Vector2(17, -4), Vector2(11, -2)]), Color(0.94, 0.57, 0.2))
	draw_circle(Vector2(-1, -17), 3.0, Color(0.83, 0.26, 0.25))
	draw_circle(Vector2(4, -18), 3.0, Color(0.83, 0.26, 0.25))
	draw_line(Vector2(-6, 13), Vector2(-6, 17), Color(0.78, 0.45, 0.2), 2.0)
	draw_line(Vector2(5, 13), Vector2(5, 17), Color(0.78, 0.45, 0.2), 2.0)
