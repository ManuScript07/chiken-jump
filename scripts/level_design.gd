class_name LevelDesign
extends RefCounted

# World coordinates are in metres; the shadow wall uses an orthographic light.
const WALL_ORIGIN := Vector2(270.0, 600.0)
const SCALE := 78.0
const LIGHT_SHEAR := 0.32
const ROTATION_SPEED := 0.32
const PLAYER_START := Vector2(90.0, 583.0)
const STAR_POSITIONS := [Vector2(150.0, 470.0), Vector2(370.0, 380.0), Vector2(90.0, 230.0)]
# Independent 2D hazards; the rotating projected objects remain unchanged.
const SPIKE_STARTS := [Vector2(144.0, 582.0), Vector2(390.0, 582.0)]
const PIXEL_SIZE := 3.0

# The boxes are the single source for both the 3D diorama and 2D projection.
# Height is measured above the surface of the disk.
static func pieces() -> Array[Dictionary]:
	return [
		{"center": Vector3(-0.65, 0.95, -0.2), "size": Vector3(1.65, 0.30, 0.85), "color": Color(0.31, 0.63, 0.72), "hazard": false},
		{"center": Vector3(0.55, 2.10, 0.15), "size": Vector3(1.55, 0.30, 0.9), "color": Color(0.91, 0.65, 0.34), "hazard": false},
		{"center": Vector3(-0.2, 3.25, 0.5), "size": Vector3(1.5, 0.30, 0.85), "color": Color(0.56, 0.69, 0.46), "hazard": false},
		{"center": Vector3(2.35, 0.23, 0.15), "size": Vector3(0.65, 0.46, 0.65), "color": Color(0.86, 0.29, 0.29), "hazard": true},
	]

static func project_point(point: Vector3, angle: float) -> Vector2:
	var rotated := point.rotated(Vector3.UP, angle)
	return WALL_ORIGIN + Vector2((rotated.x + LIGHT_SHEAR * rotated.z) * SCALE, -rotated.y * SCALE)

static func projected_rect(piece: Dictionary, angle: float) -> Rect2:
	var center: Vector3 = piece.center
	var half: Vector3 = piece.size * 0.5
	var left := INF
	var right := -INF
	for dx in [-1.0, 1.0]:
		for dz in [-1.0, 1.0]:
			var x := project_point(center + Vector3(dx * half.x, 0.0, dz * half.z), angle).x
			left = minf(left, x)
			right = maxf(right, x)
	var top := project_point(center + Vector3(0.0, half.y, 0.0), angle).y
	var bottom: float = top + piece.size.y * SCALE
	left = snappedf(left, PIXEL_SIZE)
	right = snappedf(right, PIXEL_SIZE)
	top = snappedf(top, PIXEL_SIZE)
	bottom = snappedf(bottom, PIXEL_SIZE)
	return Rect2(left, top, right - left, bottom - top)

static func spike_strips() -> Array[Rect2]:
	var strips: Array[Rect2] = []
	for origin in SPIKE_STARTS:
		for tooth in 3:
			for row in 6:
				var width := float(row + 1) * PIXEL_SIZE
				var x: float = origin.x + tooth * 18.0 + floorf((18.0 - width) / 6.0) * PIXEL_SIZE
				strips.append(Rect2(x, origin.y + row * PIXEL_SIZE, width, PIXEL_SIZE))
	return strips
