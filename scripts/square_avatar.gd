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

func reset_pose() -> void:
	spin = 0.0
	grounded = true
	landing_pulse = 0.0
	trail_clock = 0.0
	trail.clear()
	queue_redraw()

# Rotation is visual only: the collision box stays stable on moving silhouettes.
func update_pose(delta: float, on_ground: bool, direction: int, moving: bool) -> void:
	if on_ground:
		if not grounded:
			spin = snappedf(spin, QUARTER_TURN)
			landing_pulse = 1.0
	else:
		spin = wrapf(spin + SPIN_SPEED * direction * delta, -TAU, TAU)
	grounded = on_ground
	landing_pulse = move_toward(landing_pulse, 0.0, delta * 7.0)
	for ghost in trail:
		ghost.life -= delta
	trail = trail.filter(func(ghost: Dictionary) -> bool: return ghost.life > 0.0)
	trail_clock -= delta
	if not on_ground and moving and trail_clock <= 0.0:
		trail_clock = TRAIL_INTERVAL
		trail.append({"point": global_position, "angle": spin, "life": TRAIL_LIFETIME})
	queue_redraw()

func _draw() -> void:
	for ghost in trail:
		draw_set_transform(to_local(ghost.point), ghost.angle)
		draw_rect(Rect2(-12,-12,24,24), Color(0.35,0.85,0.48,0.18 * ghost.life / TRAIL_LIFETIME))
	draw_set_transform(Vector2.ZERO, spin)
	draw_rect(Rect2(-15,-15,30,30), Color("254936"))
	draw_rect(Rect2(-12,-12,24,24), Color("70e68a"))
	draw_rect(Rect2(-10,-10,20,5), Color("b3ffa3"))
	draw_rect(Rect2(-7,-5,14,14), Color("45b96b"))
	draw_rect(Rect2(-4,-2,8,8), Color("8af394"))
	draw_set_transform(Vector2.ZERO)
	if landing_pulse > 0.0:
		var spread := 18.0 + (1.0 - landing_pulse) * 18.0
		draw_line(Vector2(-spread,15),Vector2(-17,15),Color(0.3,0.7,0.4,landing_pulse),2.0,true)
		draw_line(Vector2(17,15),Vector2(spread,15),Color(0.3,0.7,0.4,landing_pulse),2.0,true)
