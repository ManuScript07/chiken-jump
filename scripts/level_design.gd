class_name LevelDesign
extends RefCounted

const WALL_ORIGIN := Vector2(270, 600)
const SCALE := 64.0
const LIGHT_POSITION := Vector3(0, 0, 9)
const WALL_Z := -4.0
const WALL_CROP_Y := 280.0
const WALL_TEXTURE_SIZE := Vector2i(540, 340)
const ROTATION_SPEED := 0.16
const PLAYER_START := Vector2(70, 583)
const STAR_POSITIONS := [Vector2(150, 500), Vector2(280, 465), Vector2(410, 420)]
const PROJECTION_STEP := 0.25 # Subpixel precision on the projected wall.

# Convex vertical profiles are extruded in depth. Both views consume these vertices.
static func pieces() -> Array[Dictionary]:
	return [
		{"center": Vector3(-1.45,0,-0.2), "depth": 0.65, "profile": PackedVector2Array([Vector2(-0.4,0),Vector2(0.4,0),Vector2(0.4,0.55),Vector2(-0.4,0.55)]), "color": Color("73a8b7"), "hazard": false},
		{"center": Vector3(-0.1,0,0.3), "depth": 0.55, "profile": PackedVector2Array([Vector2(-0.65,0),Vector2(0.65,0),Vector2(0.65,0.95)]), "color": Color("e6a04c"), "hazard": false},
		{"center": Vector3(1.45,0,-0.2), "depth": 0.6, "profile": PackedVector2Array([Vector2(-0.45,0),Vector2(0.45,0),Vector2(0.45,1.35),Vector2(-0.45,1.05)]), "color": Color("8caf76"), "hazard": false},
		{"center": Vector3(0.55,0,-1.65), "depth": 0.18, "profile": PackedVector2Array([Vector2(-0.22,0),Vector2(0.22,0),Vector2(0,0.38)]), "color": Color("b95650"), "hazard": true}
	]

static func vertices(piece: Dictionary) -> PackedVector3Array:
	var result := PackedVector3Array()
	for z in [-0.5, 0.5]:
		for point: Vector2 in piece.profile:
			result.append(piece.center + Vector3(point.x, point.y, z * float(piece.depth)))
	return result

static func project_point(point: Vector3, angle: float) -> Vector2:
	var rotated := point.rotated(Vector3.UP, angle)
	var distance := (WALL_Z - LIGHT_POSITION.z) / (rotated.z - LIGHT_POSITION.z)
	var hit := LIGHT_POSITION + (rotated - LIGHT_POSITION) * distance
	return wall_to_canvas(hit)

static func projected_polygon(piece: Dictionary, angle: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for vertex in vertices(piece):
		points.append(project_point(vertex, angle).snapped(Vector2.ONE * PROJECTION_STEP))
	var hull := Geometry2D.convex_hull(points)
	if hull.size() > 1 and hull[0] == hull[-1]:
		hull.remove_at(hull.size() - 1)
	return hull

static func projected_rect(piece: Dictionary, angle: float) -> Rect2:
	var polygon := projected_polygon(piece, angle)
	var rect := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		rect = rect.expand(point)
	return rect

static func prism_mesh(piece: Dictionary) -> ArrayMesh:
	var points := vertices(piece)
	var count: int = piece.profile.size()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Profiles are convex, so fan triangulation is sufficient for both end caps.
	for i in range(1, count - 1):
		for index in [0, i + 1, i, count, count + i, count + i + 1]:
			surface.add_vertex(points[index] - piece.center)
	for i in count:
		var next := (i + 1) % count
		for index in [i, next, next + count, i, next + count, i + count]:
			surface.add_vertex(points[index] - piece.center)
	surface.generate_normals()
	return surface.commit()

static func wall_to_canvas(point: Vector3) -> Vector2:
	return WALL_ORIGIN + Vector2(point.x, -point.y) * SCALE

static func canvas_to_wall(point: Vector2) -> Vector3:
	return Vector3((point.x - WALL_ORIGIN.x) / SCALE, (WALL_ORIGIN.y - point.y) / SCALE, WALL_Z)
