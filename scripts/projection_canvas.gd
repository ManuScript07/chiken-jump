class_name ProjectionCanvas
extends Node2D

var session: RunSession
var pickups: Array[Dictionary] = []

func add_pickup(_index: int, point: Vector2) -> void:
	pickups.append({"point":point,"life":0.22})
	queue_redraw()

func clear_effects() -> void:
	pickups.clear()
	queue_redraw()

func _process(delta: float) -> void:
	if pickups.is_empty():
		return
	for pickup in pickups:
		pickup.life -= delta
	pickups = pickups.filter(func(pickup: Dictionary) -> bool: return pickup.life>0.0)
	queue_redraw()

func _draw() -> void:
	if session==null:
		return
	for i in session.targets.size():
		if not session.collected[i]:
			GameArt.draw_star(self,session.targets[i],12.0)
	for pickup in pickups:
		var life: float = pickup.life/0.22
		GameArt.draw_star(self,pickup.point+Vector2(0,-14*(1-life)),12*life,life)
