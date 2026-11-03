class_name ShadowField
extends Node2D

signal projection_changed(angle: float)

const DESIGN = preload("res://scripts/level_design.gd")
const PLATFORM_COLOR := Color("40364f")
const HAZARD_COLOR := Color("b95650")

var angle := 0.0
var angular_velocity := DESIGN.ROTATION_SPEED
var target_angular_velocity := DESIGN.ROTATION_SPEED
const ANGULAR_ACCELERATION := 0.28
var pieces: Array[Dictionary] = DESIGN.pieces()
var platform_bodies: Array[StaticBody2D] = []
var platform_shapes: Array[CollisionPolygon2D] = []
var platform_motion: Dictionary = {}
var rectangles: Array[Rect2] = []
var polygons: Array[PackedVector2Array] = []
var running := true
var base_body: StaticBody2D
var base_shape: CollisionPolygon2D
var base_polygon := PackedVector2Array()

func _ready() -> void:
	for piece in pieces:
		if piece.hazard:
			continue
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape_node := CollisionPolygon2D.new()
		body.add_child(shape_node)
		add_child(body)
		platform_bodies.append(body)
		platform_shapes.append(shape_node)
	_build_static_boundaries()
	update_projection(true)

func _build_static_boundaries() -> void:
	base_body = StaticBody2D.new()
	base_body.collision_layer = 1
	base_body.collision_mask = 0
	base_shape = CollisionPolygon2D.new()
	base_body.add_child(base_shape)
	add_child(base_body)

func _physics_process(delta: float) -> void:
	if running:
		angular_velocity = move_toward(angular_velocity,target_angular_velocity,ANGULAR_ACCELERATION*delta)
		angle = fposmod(angle + angular_velocity * delta, TAU)
		update_projection(false)

func set_rotation_target(speed: float) -> void:
	target_angular_velocity = clampf(speed,-WaveDirector.MAX_ROTATION_SPEED,WaveDirector.MAX_ROTATION_SPEED)

func reset() -> void:
	angle = 0.0
	angular_velocity = DESIGN.ROTATION_SPEED
	target_angular_velocity = DESIGN.ROTATION_SPEED
	running = true
	update_projection(true)

func update_projection(reset_motion: bool) -> void:
	base_polygon = DESIGN.projected_disk_polygon(angle)
	base_shape.polygon = base_polygon
	rectangles.clear()
	polygons.clear()
	var platform_index := 0
	for piece in pieces:
		var rect: Rect2 = DESIGN.projected_rect(piece, angle)
		rectangles.append(rect)
		var polygon: PackedVector2Array = DESIGN.projected_polygon(piece, angle)
		polygons.append(polygon)
		if piece.hazard:
			continue
		var body := platform_bodies[platform_index]
		var target := rect.get_center()
		platform_motion[body.get_instance_id()] = Vector2.ZERO if reset_motion else target - body.position
		body.position = target
		var local := PackedVector2Array()
		for point in polygon:
			local.append(point - target)
		platform_shapes[platform_index].polygon = local
		platform_index += 1
	queue_redraw()
	projection_changed.emit(angle)

func motion_for(body: Object) -> Vector2:
	if body == null:
		return Vector2.ZERO
	return platform_motion.get(body.get_instance_id(), Vector2.ZERO)

func touches_hazard(player_rect: Rect2) -> bool:
	for i in pieces.size():
		if pieces[i].hazard and rectangles[i].intersects(player_rect):
			var box := PackedVector2Array([player_rect.position, Vector2(player_rect.end.x, player_rect.position.y), player_rect.end, Vector2(player_rect.position.x, player_rect.end.y)])
			if not Geometry2D.intersect_polygons(polygons[i], box).is_empty():
				return true
	return false

func _draw() -> void:
	for i in polygons.size():
		var color := HAZARD_COLOR if pieces[i].hazard else PLATFORM_COLOR
		draw_colored_polygon(polygons[i], color)
		var outline := polygons[i].duplicate()
		outline.append(outline[0])
		draw_polyline(outline, color.lightened(0.22), 2.0, false)
