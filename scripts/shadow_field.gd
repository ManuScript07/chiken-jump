class_name ShadowField
extends Node2D

const DESIGN = preload("res://scripts/level_design.gd")
const PLATFORM_COLOR := Color(0.19, 0.23, 0.27, 0.9)
const HAZARD_COLOR := Color(0.78, 0.23, 0.21, 0.9)

var angle := 0.0
var pieces: Array[Dictionary] = DESIGN.pieces()
var platform_bodies: Array[StaticBody2D] = []
var platform_shapes: Array[RectangleShape2D] = []
var platform_motion: Dictionary = {}
var rectangles: Array[Rect2] = []
var running := true

func _ready() -> void:
	for piece in pieces:
		if piece.hazard:
			continue
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape_node := CollisionShape2D.new()
		# Platforms are solid from above and traversable from below.
		shape_node.one_way_collision = true
		var shape := RectangleShape2D.new()
		shape_node.shape = shape
		body.add_child(shape_node)
		add_child(body)
		platform_bodies.append(body)
		platform_shapes.append(shape)
	_build_static_boundaries()
	update_projection(true)

func _build_static_boundaries() -> void:
	_add_boundary(Vector2(270, 610), Vector2(500, 20))
	_add_boundary(Vector2(10, 350), Vector2(20, 520))
	_add_boundary(Vector2(530, 350), Vector2(20, 520))

func _add_boundary(center: Vector2, dimensions: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)

func _physics_process(delta: float) -> void:
	if running:
		angle = fposmod(angle + DESIGN.ROTATION_SPEED * delta, TAU)
		update_projection(false)

func reset() -> void:
	angle = 0.0
	running = true
	update_projection(true)

func update_projection(reset_motion: bool) -> void:
	rectangles.clear()
	var platform_index := 0
	for piece in pieces:
		var rect: Rect2 = DESIGN.projected_rect(piece, angle)
		rectangles.append(rect)
		if piece.hazard:
			continue
		var body := platform_bodies[platform_index]
		var target := rect.get_center()
		platform_motion[body.get_instance_id()] = Vector2.ZERO if reset_motion else target - body.position
		body.position = target
		platform_shapes[platform_index].size = rect.size
		platform_index += 1
	queue_redraw()

func motion_for(body: Object) -> Vector2:
	if body == null:
		return Vector2.ZERO
	return platform_motion.get(body.get_instance_id(), Vector2.ZERO)

func touches_hazard(player_rect: Rect2) -> bool:
	for i in pieces.size():
		if pieces[i].hazard and rectangles[i].intersects(player_rect):
			return true
	return false

func _draw() -> void:
	for i in rectangles.size():
		var rect := rectangles[i]
		if pieces[i].hazard:
			draw_rect(rect, HAZARD_COLOR)
			var tooth_width := rect.size.x / 4.0
			for tooth in 4:
				var x := rect.position.x + tooth * tooth_width
				draw_polyline(PackedVector2Array([Vector2(x, rect.position.y + 10.0), Vector2(x + tooth_width * 0.5, rect.position.y + 3.0), Vector2(x + tooth_width, rect.position.y + 10.0)]), Color(1.0, 0.82, 0.72, 0.8), 2.0)
		else:
			draw_rect(rect, PLATFORM_COLOR)
			draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), Color(0.38, 0.43, 0.45), 2.0)
