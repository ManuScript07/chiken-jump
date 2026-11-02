class_name SquarePlayer
extends CharacterBody2D

const SPEED := 230.0
const ACCELERATION := 1900.0
const GRAVITY := 1900.0
const JUMP_SPEED := 685.0
const BODY_SIZE := Vector2(30.0, 30.0)

var avatar: SquareAvatar
var input_axis := 0.0
var facing := 1
var jump_pending := false
var jump_buffer := 0.0
var coyote_time := 0.0
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
	avatar = SquareAvatar.new()
	add_child(avatar)

func request_jump() -> void:
	if enabled:
		jump_pending = true
		jump_buffer = 0.12

func reset_to(start: Vector2) -> void:
	# CollisionPolygon2D rebuilds its shapes at the end of the frame.
	# Resume movement after that rebuild, so restart never queries stale geometry.
	set_physics_process(false)
	set_physics_process.call_deferred(true)
	position = start
	velocity = Vector2.ZERO
	support = null
	jump_pending = false
	jump_buffer = 0.0
	coyote_time = 0.0
	input_axis = 0.0
	facing = 1
	enabled = true
	if avatar != null:
		avatar.reset_pose()

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
	jump_buffer = maxf(0.0, jump_buffer - delta)
	coyote_time = 0.08 if is_on_floor() else maxf(0.0, coyote_time - delta)
	if jump_buffer > 0.0 and coyote_time > 0.0:
		velocity.y = -JUMP_SPEED
		jump_buffer = 0.0
		coyote_time = 0.0
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
	avatar.update_pose(delta, is_on_floor(), facing, velocity.length_squared() > 100.0)
