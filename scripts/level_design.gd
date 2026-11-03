class_name LevelDesign
extends RefCounted

const WALL_ORIGIN := Vector2(270, 600)
const SCALE := 64.0
const WALL_Z := -4.0
const LIGHT_POSITION := Vector3(1.0, 0.0, 8.0)
const MODEL_SCALE := 0.46
const SHADOW_MAGNIFICATION := 1.42
const DISK_RADIUS := 2.8
const DISK_HEIGHT := 0.24
const FLOOR_Y := -DISK_HEIGHT * MODEL_SCALE
# Place the compact rig on the ray to the middle of the wall baseline.
# This balances the smaller objects with a larger optical magnification.
const RIG_RAY_FRACTION := MODEL_SCALE / SHADOW_MAGNIFICATION
const RIG_CENTER := LIGHT_POSITION + (Vector3(0.0, 0.0, WALL_Z) - LIGHT_POSITION) * RIG_RAY_FRACTION
const WALL_CROP_Y := 280.0
const WALL_CROP_X := -30.0
const WALL_TEXTURE_SIZE := Vector2i(600, 340)
const ROTATION_SPEED := 0.16
const PLAYER_START := Vector2(44, 585)
const STAR_POSITIONS := [Vector2(150, 500), Vector2(280, 465), Vector2(410, 420)]
const PROJECTION_STEP := 0.25 # Subpixel precision on the projected wall.

const INSTALLATION_SCENE = preload("res://scenes/levels/reference_installation.tscn")
static var _pieces: Array[Dictionary] = []
static var _disk_points := PackedVector3Array()

static func create_installation() -> Node3D:
	return INSTALLATION_SCENE.instantiate()

# The saved scene is the only source of figure placement and dimensions.
static func pieces() -> Array[Dictionary]:
	if _pieces.is_empty():
		var installation := create_installation()
		_pieces = describe_installation(installation)
		installation.free()
	return _pieces.duplicate(true)

static func describe_installation(installation: Node3D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for piece in PrimitivePiece.collect(installation):
		var data := piece.definition(installation)
		data.transform = installation.transform * data.transform
		data.center = data.transform.origin
		result.append(data)
	return result

static func disk_mesh() -> CylinderMesh:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = DISK_RADIUS
	cylinder.bottom_radius = DISK_RADIUS
	cylinder.height = DISK_HEIGHT
	cylinder.radial_segments = 96
	return cylinder

static func disk_vertices() -> PackedVector3Array:
	if _disk_points.is_empty():
		var points: PackedVector3Array = disk_mesh().surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for point in points:
			_disk_points.append(point-Vector3.UP*DISK_HEIGHT/2.0)
	return _disk_points

static func projected_disk_polygon(angle: float) -> PackedVector2Array:
	return _projected_hull(disk_vertices(),angle)

static func vertices(piece: Dictionary) -> PackedVector3Array:
	return PrimitiveGeometry.vertices(piece)

static func model_to_world(point: Vector3, angle: float) -> Vector3:
	return RIG_CENTER + point.rotated(Vector3.UP, angle) * MODEL_SCALE

static func project_world_point(point: Vector3) -> Vector2:
	var distance := (WALL_Z - LIGHT_POSITION.z) / (point.z - LIGHT_POSITION.z)
	return wall_to_canvas(LIGHT_POSITION + (point - LIGHT_POSITION) * distance)

static func project_point(point: Vector3, angle: float) -> Vector2:
	return project_world_point(model_to_world(point, angle))

static func projected_polygon(piece: Dictionary, angle: float) -> PackedVector2Array:
	return _projected_hull(vertices(piece),angle)

static func _projected_hull(vertices: PackedVector3Array, angle: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for vertex in vertices:
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

static func primitive_mesh(piece: Dictionary) -> ArrayMesh:
	return PrimitiveGeometry.mesh(piece)

static func wall_to_canvas(point: Vector3) -> Vector2:
	return WALL_ORIGIN + Vector2(point.x, -point.y) * SCALE

static func canvas_to_wall(point: Vector2) -> Vector3:
	return Vector3((point.x - WALL_ORIGIN.x) / SCALE, (WALL_ORIGIN.y - point.y) / SCALE, WALL_Z)
