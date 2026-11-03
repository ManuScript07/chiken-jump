class_name SquareAvatar
extends Node2D

const QUARTER_TURN := PI / 2.0
const SPIN_SPEED := 8.0
const TRAIL_INTERVAL := 0.035
const TRAIL_LIFETIME := 0.18
var spin := 0.0
var grounded := true
var landing_pulse := 0.0
var trail_clock := 0.0
var trail: Array[Dictionary] = []
var surface_offset := Vector2.ZERO
var ground_angle := 0.0
var resting_turns := 0

func reset_pose() -> void:
	spin = 0.0
	surface_offset = Vector2.ZERO
	ground_angle = 0.0
	resting_turns = 0
	grounded = true
	landing_pulse = 0.0
	trail_clock = 0.0
	trail.clear()
	queue_redraw()

# A stable box collider avoids corner-catching on rebuilding silhouettes.
# The support-function offset places both visible bottom corners on the actual plane.
func update_pose(delta: float, on_ground: bool, direction: int, moving: bool, normal: Vector2 = Vector2.UP) -> void:
	if on_ground:
		ground_angle = Vector2(-normal.y,normal.x).angle()
		if not grounded:
			resting_turns = roundi((spin-ground_angle)/QUARTER_TURN)
			landing_pulse = 1.0
		spin = ground_angle+float(resting_turns)*QUARTER_TURN
		surface_offset = -normal*15.0*(absf(normal.x)+absf(normal.y)-1.0)
	else:
		spin = wrapf(spin + SPIN_SPEED * direction * delta, -TAU, TAU)
		surface_offset = surface_offset.move_toward(Vector2.ZERO,120.0*delta)
	grounded = on_ground
	landing_pulse = move_toward(landing_pulse, 0.0, delta * 7.0)
	for ghost in trail:
		ghost.life -= delta
	trail = trail.filter(func(ghost: Dictionary) -> bool: return ghost.life > 0.0)
	trail_clock -= delta
	if not on_ground and moving and trail_clock <= 0.0:
		trail_clock = TRAIL_INTERVAL
		trail.append({"point": global_position+surface_offset, "angle": spin, "life": TRAIL_LIFETIME})
	queue_redraw()

func _draw() -> void:
	for ghost in trail:
		draw_set_transform(to_local(ghost.point), ghost.angle)
		draw_rect(Rect2(-12,-12,24,24), Color(0.35,0.85,0.48,0.18 * ghost.life / TRAIL_LIFETIME))
	draw_set_transform(surface_offset, spin)
	draw_rect(Rect2(-15,-15,30,30),Color("395b46"))
	draw_rect(Rect2(-13.5,-13.5,27,27),Color("8ac58c"))
	draw_colored_polygon(PackedVector2Array([Vector2(-13.5,-13.5),Vector2(13.5,-13.5),Vector2(10.5,-10.5),Vector2(-10.5,-10.5)]),Color("d1e5b9"))
	draw_colored_polygon(PackedVector2Array([Vector2(13.5,-13.5),Vector2(13.5,13.5),Vector2(10.5,10.5),Vector2(10.5,-10.5)]),Color("669b72"))
	draw_colored_polygon(PackedVector2Array([Vector2(-13.5,13.5),Vector2(13.5,13.5),Vector2(10.5,10.5),Vector2(-10.5,10.5)]),Color("537f5d"))
	draw_set_transform(Vector2.ZERO)
	if landing_pulse > 0.0:
		draw_set_transform(surface_offset,ground_angle)
		var spread := 18.0 + (1.0 - landing_pulse) * 18.0
		draw_line(Vector2(-spread,15),Vector2(-17,15),Color(0.3,0.7,0.4,landing_pulse),2.0,true)
		draw_line(Vector2(17,15),Vector2(spread,15),Color(0.3,0.7,0.4,landing_pulse),2.0,true)
		draw_set_transform(Vector2.ZERO)
