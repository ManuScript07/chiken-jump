class_name ProjectionCanvas
extends Node2D

const DESIGN = preload("res://scripts/level_design.gd")
var level: ChickenLevel

func _draw() -> void:
	# This image is the playable light projection mounted on the physical wall.
	draw_rect(Rect2(0, 0, 540, 620), Color("e9dfc7"))
	for i in 16:
		var alpha := 0.016
		draw_circle(Vector2(270, 570), 350.0 - i * 16.0, Color(1.0, 0.97, 0.82, alpha))
	draw_rect(Rect2(20, 600, 500, 12), Color("353141"))
	if level == null:
		return
	for i in DESIGN.STAR_POSITIONS.size():
		if not level.collected[i]:
			var p: Vector2 = DESIGN.STAR_POSITIONS[i]
			draw_circle(p, 20, Color(1.0,0.76,0.23,0.08))
			var points := PackedVector2Array()
			for j in 10:
				var radius := 12.0 if j % 2 == 0 else 5.5
				points.append(p + Vector2.from_angle(-PI / 2 + j * PI / 5) * radius)
			draw_colored_polygon(points, Color("f3bc4d"))
			points.append(points[0])
			draw_polyline(points, Color("a66720"), 1.5, true)
