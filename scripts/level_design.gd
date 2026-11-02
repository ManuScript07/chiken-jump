class_name LevelDesign
extends RefCounted

const WALL_ORIGIN := Vector2(270, 600)
const SCALE := 64.0
const WALL_Z := -4.0
const LIGHT_POSITION := Vector3(1.4, 0.0, 7.0)
const MODEL_SCALE := 0.46
const SHADOW_MAGNIFICATION := 1.5
const DISK_RADIUS := 2.65
const DISK_HEIGHT := 0.24
const FLOOR_Y := -DISK_HEIGHT * MODEL_SCALE
# Place the compact rig on the ray to the middle of the wall baseline.
# This balances the smaller objects with a larger optical magnification.
const RIG_RAY_FRACTION := MODEL_SCALE / SHADOW_MAGNIFICATION
const RIG_CENTER := LIGHT_POSITION + (Vector3(0.0, 0.0, WALL_Z) - LIGHT_POSITION) * RIG_RAY_FRACTION
const WALL_CROP_Y := 280.0
const WALL_TEXTURE_SIZE := Vector2i(540, 340)
const ROTATION_SPEED := 0.16
const PLAYER_START := Vector2(44, 585)
const STAR_POSITIONS := [Vector2(150, 500), Vector2(280, 465), Vector2(410, 420)]
const PROJECTION_STEP := 0.25 # Subpixel precision on the projected wall.

# Each convex primitive keeps its own shadow, preserving gaps under overhangs.
static func pieces() -> Array[Dictionary]:
	return [
		{"id":"beige_cube", "primitive":"box", "center":Vector3(-1.55,0.32,0.25), "size":Vector3(0.64,0.64,0.64), "color":Color("e6d1a3"), "hazard":false},
		{"id":"red_support", "primitive":"box", "center":Vector3(0,0.4,0), "size":Vector3(0.72,0.8,0.72), "color":Color("d82936"), "hazard":false},
		{"id":"red_crossbar", "primitive":"box", "center":Vector3(0,0.94,0), "size":Vector3(1.38,0.28,0.64), "color":Color("e63340"), "hazard":false},
		{"id":"wooden_stick", "primitive":"box", "center":Vector3(0,1.125,0), "size":Vector3(4.55,0.09,0.12), "color":Color("e6cc87"), "hazard":false},
		{"id":"blue_tower", "primitive":"box", "center":Vector3(1.45,0.8,-0.1), "size":Vector3(0.66,1.6,0.66), "color":Color("147bc4"), "hazard":false},
		{"id":"rounded_roof", "primitive":"half_cylinder", "center":Vector3(1.45,1.6,-0.1), "radius":0.33, "depth":0.66, "color":Color("dfb778"), "hazard":false}
	]

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

static func primitive_mesh(piece: Dictionary) -> ArrayMesh:
	return PrimitiveGeometry.mesh(piece)

static func wall_to_canvas(point: Vector3) -> Vector2:
	return WALL_ORIGIN + Vector2(point.x, -point.y) * SCALE

static func canvas_to_wall(point: Vector2) -> Vector3:
	return Vector3((point.x - WALL_ORIGIN.x) / SCALE, (WALL_ORIGIN.y - point.y) / SCALE, WALL_Z)
