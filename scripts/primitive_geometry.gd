class_name PrimitiveGeometry
extends RefCounted

const ARC_SEGMENTS := 32

static func profile(piece: Dictionary) -> PackedVector2Array:
	var points := PackedVector2Array()
	if piece.primitive == "half_cylinder":
		for i in ARC_SEGMENTS + 1:
			var angle := PI * float(i) / ARC_SEGMENTS
			points.append(Vector2(cos(angle),sin(angle)) * float(piece.radius))
	else:
		var half: Vector2 = Vector2(piece.size.x,piece.size.y) * 0.5
		points = PackedVector2Array([Vector2(-half.x,-half.y),Vector2(half.x,-half.y),half,Vector2(-half.x,half.y)])
	return points

static func vertices(piece: Dictionary) -> PackedVector3Array:
	var points := PackedVector3Array()
	var depth: float = piece.depth if piece.primitive == "half_cylinder" else piece.size.z
	for z in [-0.5,0.5]:
		for point in profile(piece):
			points.append(piece.center + Vector3(point.x,point.y,z * depth))
	return points

static func mesh(piece: Dictionary) -> ArrayMesh:
	var points := vertices(piece)
	var count := profile(piece).size()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1,count-1):
		for index in [0,i+1,i,count,count+i,count+i+1]:
			surface.add_vertex(points[index] - piece.center)
	for i in count:
		var next := (i+1)%count
		for index in [i,next,next+count,i,next+count,i+count]:
			surface.add_vertex(points[index] - piece.center)
	surface.generate_normals()
	return surface.commit()
