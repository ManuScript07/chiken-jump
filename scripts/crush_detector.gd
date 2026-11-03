class_name CrushDetector
extends RefCounted

const CONFIRM_TIME := 0.035
var compressed_time := 0.0
var probe := RectangleShape2D.new()

func reset() -> void:
	compressed_time = 0.0

# Use the minimum separation axis for each convex physics shape. Two overlapping
# supports on the same side are one floor, not a pair of crushing jaws.
func _escape_normal(hit: Dictionary, player: SquarePlayer) -> Vector2:
	var rid: RID = hit.rid
	var shape_rid := PhysicsServer2D.body_get_shape(rid,hit.shape)
	var shape_type := PhysicsServer2D.shape_get_type(shape_rid)
	var data: Variant = PhysicsServer2D.shape_get_data(shape_rid)
	var points := PackedVector2Array()
	if shape_type==PhysicsServer2D.SHAPE_RECTANGLE:
		var extent: Vector2 = data
		points = PackedVector2Array([Vector2(-extent.x,-extent.y),Vector2(extent.x,-extent.y),extent,Vector2(-extent.x,extent.y)])
	elif shape_type==PhysicsServer2D.SHAPE_CONVEX_POLYGON:
		points = data
	else:
		return Vector2.ZERO
	var body_transform: Transform2D = PhysicsServer2D.body_get_state(rid,PhysicsServer2D.BODY_STATE_TRANSFORM)
	var transform := body_transform*PhysicsServer2D.body_get_shape_transform(rid,hit.shape)
	points = transform*points
	var axes: Array[Vector2] = [Vector2.RIGHT,Vector2.DOWN]
	for i in points.size():
		var edge := points[(i+1)%points.size()]-points[i]
		if edge.length_squared()>0.0001:
			axes.append(Vector2(edge.y,-edge.x).normalized())
	var penetration := INF
	var normal := Vector2.ZERO
	for axis in axes:
		var low := INF
		var high := -INF
		for point in points:
			low = minf(low,point.dot(axis))
			high = maxf(high,point.dot(axis))
		var center := player.global_position.dot(axis)
		var radius := (probe.size*0.5).dot(axis.abs())
		var positive := high-(center-radius)
		var negative := center+radius-low
		if positive<=0 or negative<=0:
			return Vector2.ZERO
		if minf(positive,negative)<penetration:
			penetration = minf(positive,negative)
			normal = axis if positive<negative else -axis
	return normal

func update(player: SquarePlayer, delta: float) -> bool:
	if not player.enabled or player.reset_pending:
		reset()
		return false
	var compressed := false
	# Opposing contacts alone are insufficient: an ordinary ceiling jump is safe.
	for i in player.get_slide_collision_count():
		var a := player.get_slide_collision(i)
		for j in range(i+1,player.get_slide_collision_count()):
			var b := player.get_slide_collision(j)
			var normal := a.get_normal()
			if a.get_collider()!=b.get_collider() and normal.dot(b.get_normal())< -0.8:
				var gap := absf((a.get_position()-b.get_position()).dot(normal))
				var span := SquarePlayer.BODY_SIZE.dot(normal.abs())
				compressed = compressed or gap<span-0.5
	# Moving silhouettes can enclose the cube without producing slide contacts.
	probe.size = SquarePlayer.BODY_SIZE-Vector2(3,3)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = probe
	query.transform = player.global_transform
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	var hits := player.get_world_2d().direct_space_state.intersect_shape(query,16)
	if hits.size()>=2:
		var normals: Array[Vector2] = []
		for hit in hits:
			normals.append(_escape_normal(hit,player))
		for i in hits.size():
			for j in range(i+1,hits.size()):
				if hits[i].collider_id!=hits[j].collider_id:
					compressed = compressed or normals[i].dot(normals[j])< -0.6
	compressed_time = compressed_time+delta if compressed else 0.0
	return compressed_time>=CONFIRM_TIME
