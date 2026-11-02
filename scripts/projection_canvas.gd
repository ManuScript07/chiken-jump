class_name ProjectionCanvas
extends Node2D

const DESIGN = preload("res://scripts/level_design.gd")
var level: ChickenLevel

func _draw() -> void:
	# Transparent gameplay markings on the physical wall.
	if level == null:
		return
	for i in DESIGN.STAR_POSITIONS.size():
		if not level.collected[i]:
			var p: Vector2 = DESIGN.STAR_POSITIONS[i]
			var points := PackedVector2Array()
			for j in 10:
				var radius := 12.0 if j % 2 == 0 else 5.5
				points.append(p + Vector2.from_angle(-PI / 2 + j * PI / 5) * radius)
			draw_colored_polygon(points, Color("f3bc4d"))
			points.append(points[0])
			draw_polyline(points, Color("a66720"), 1.5, true)
