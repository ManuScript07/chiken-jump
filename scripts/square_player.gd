class_name SquarePlayer
extends CharacterBody2D

const SPEED := 230.0
const ACCELERATION := 1900.0
const GRAVITY := 1900.0
const JUMP_SPEED := 685.0
const BODY_SIZE := Vector2(30.0,30.0)
const STATIC_FRICTION := 0.32492 # tan(18 degrees): rest on a gentle surface.
const KINETIC_FRICTION := 0.21256 # tan(12 degrees): a moving cube keeps sliding.
const SLIDE_MAX_SPEED := 500.0
const STOP_SPEED := 8.0

var avatar: SquareAvatar
var input_axis := 0.0
var facing := 1
var jump_pending := false
var jump_buffer := 0.0
var coyote_time := 0.0
var enabled := true
var support: Object
var shadow_field: ShadowField
var surface_normal := Vector2.UP
var sliding := false
var reset_pending := true
var surface_speed := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 6.0
	floor_max_angle = deg_to_rad(75.0)
	floor_stop_on_slope = false
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
	# Wait for deferred CollisionPolygon2D rebuilds before querying the new course.
	set_physics_process(false)
	set_physics_process.call_deferred(true)
	position = start
	velocity = Vector2.ZERO
	support = null
	surface_normal = Vector2.UP
	sliding = false
	reset_pending = true
	surface_speed = 0.0
	jump_pending = false
	jump_buffer = 0.0
	coyote_time = 0.0
	input_axis = 0.0
	facing = 1
	enabled = true
	if avatar != null:
		avatar.reset_pose()

func bounds() -> Rect2:
	return Rect2(position-BODY_SIZE*0.5,BODY_SIZE)

func _surface_velocity(delta: float, normal: Vector2) -> Vector2:
	var tangent := Vector2(-normal.y,normal.x)
	var speed := surface_speed
	var gravity_along := Vector2.DOWN.dot(tangent)*GRAVITY
	var normal_force := maxf(0.0,normal.dot(Vector2.UP))*GRAVITY
	if absf(input_axis)>0.1:
		sliding = false
		speed = move_toward(speed,input_axis*SPEED,ACCELERATION*delta)
		speed += gravity_along*delta
	else:
		var can_rest := absf(gravity_along)<=STATIC_FRICTION*normal_force
		if can_rest and not sliding:
			speed = move_toward(speed,0.0,ACCELERATION*delta)
		elif can_rest and absf(speed)<STOP_SPEED:
			speed = 0.0
			sliding = false
		else:
			sliding = true
			speed += gravity_along*delta
			speed = move_toward(speed,0.0,KINETIC_FRICTION*normal_force*delta)
	speed = clampf(speed,-SLIDE_MAX_SPEED,SLIDE_MAX_SPEED)
	surface_speed = speed
	if sliding and absf(speed)>STOP_SPEED:
		facing = 1 if speed>0.0 else -1
	# Gravity normal to the surface maintains contact; its tangent was applied above.
	return tangent*speed+normal*Vector2.DOWN.dot(normal)*GRAVITY*delta

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var grounded_before := is_on_floor() and not reset_pending
	if grounded_before and is_instance_valid(support) and shadow_field!=null:
		position += shadow_field.motion_for(support)
	if absf(input_axis)>0.1:
		facing = 1 if input_axis>0 else -1
	if grounded_before:
		velocity = _surface_velocity(delta,get_floor_normal())
	else:
		sliding = false
		velocity.x = move_toward(velocity.x,input_axis*SPEED,ACCELERATION*delta)
		velocity.y += GRAVITY*delta
	jump_buffer = maxf(0.0,jump_buffer-delta)
	coyote_time = 0.08 if grounded_before else maxf(0.0,coyote_time-delta)
	if jump_buffer>0.0 and coyote_time>0.0:
		velocity.y = -JUMP_SPEED
		jump_buffer = 0.0
		coyote_time = 0.0
		sliding = false
	jump_pending = false
	move_and_slide()
	reset_pending = false
	if is_on_floor() and not grounded_before:
		var tangent := Vector2(-get_floor_normal().y,get_floor_normal().x)
		surface_speed = velocity.dot(tangent)
	elif is_on_wall():
		surface_speed = 0.0
	var previous_support := support
	support = null
	surface_normal = get_floor_normal() if is_on_floor() else Vector2.UP
	if is_on_floor():
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			if collision.get_normal().dot(up_direction)>=cos(floor_max_angle)-0.001:
				support = collision.get_collider()
				break
		if support==null and is_instance_valid(previous_support):
			support = previous_support
	avatar.update_pose(delta,is_on_floor(),facing,velocity.length_squared()>100.0,surface_normal)
