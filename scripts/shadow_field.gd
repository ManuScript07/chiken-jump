class_name ShadowField
extends Node2D

const DESIGN = preload("res://scripts/level_design.gd")
const PIXEL = preload("res://scripts/pixel_art.gd")
const PLATFORM_COLOR := Color("40364f")
const HAZARD_COLOR := Color("b95650")

var angle := 0.0
var pieces: Array[Dictionary] = DESIGN.pieces()
var platform_bodies: Array[StaticBody2D] = []
var platform_shapes: Array[RectangleShape2D] = []
var platform_motion: Dictionary = {}
var rectangles: Array[Rect2] = []
var spike_strips: Array[Rect2] = DESIGN.spike_strips()
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
	for strip in spike_strips:
		if strip.intersects(player_rect):
			return true
	return false

func _draw() -> void:
	for i in rectangles.size():
		var rect := rectangles[i]
		if pieces[i].hazard:
			draw_rect(rect, HAZARD_COLOR)
			# A striped warning remains entirely inside the hazardous projection.
			for x in range(3, int(rect.size.x) - 3, 12):
				draw_rect(Rect2(rect.position + Vector2(x, 3), Vector2(6, 3)), Color("f3d9bb"))
		else:
			draw_rect(rect, PLATFORM_COLOR)
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color("6c6076"))
			# Colour chips identify which 3D object produced this silhouette.
			var chip: Color = pieces[i].color
			draw_rect(Rect2(rect.position + Vector2(6, 6), Vector2(24, 6)), chip)
	for strip in spike_strips:
		draw_rect(strip, PIXEL.INK)
		if strip.size.x >= 9.0:
			draw_rect(Rect2(strip.position + Vector2(3, 0), Vector2(strip.size.x - 6, strip.size.y)), PIXEL.RED)
