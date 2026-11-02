class_name ChickenPlayer
extends CharacterBody2D

const SPEED := 190.0
const ACCELERATION := 1500.0
const GRAVITY := 1500.0
const JUMP_SPEED := 610.0
const BODY_SIZE := Vector2(27.0, 34.0)

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

func request_jump() -> void:
	if enabled:
		jump_pending = true
		jump_buffer = 0.12

func reset_to(start: Vector2) -> void:
	position = start
	velocity = Vector2.ZERO
	support = null
	jump_pending = false
	jump_buffer = 0.0
	coyote_time = 0.0
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
	queue_redraw()

func _draw() -> void:
	var direction := float(facing)
	draw_circle(Vector2(0,1),12.5,Color("fff2cc"))
	draw_circle(Vector2(direction * 3,-7),8,Color("fff6dd"))
	draw_circle(Vector2(direction * 6,-9),1.7,Color("262b36"))
	draw_colored_polygon(PackedVector2Array([Vector2(direction*9,-5),Vector2(direction*13,-2),Vector2(direction*9,0)]),Color("e7a33f"))
	draw_circle(Vector2(0,-15),2.5,Color("c44f48"))
	draw_circle(Vector2(4*direction,-15),2.5,Color("c44f48"))
	draw_line(Vector2(-4,12),Vector2(-4,17),Color("c38a3e"),2.0,true)
	draw_line(Vector2(4,12),Vector2(4,17),Color("c38a3e"),2.0,true)
