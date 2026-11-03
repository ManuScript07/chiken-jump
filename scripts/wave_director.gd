class_name WaveDirector
extends RefCounted

const DESIGN = preload("res://scripts/level_design.gd")
const PATTERNS := [[85.0,430.0],[70.0,210.0,355.0,480.0],[455.0,270.0,110.0],[135.0,405.0],[75.0,215.0,350.0,475.0]]
const ROTATION_INTERVAL := 4.5
const SPEEDS := [0.24,0.36,-0.34,-0.44,0.38,-0.42,0.46,-0.38]
const MAX_ROTATION_SPEED := 0.48

func rotation_target(phase: int) -> float:
	var speed: float = SPEEDS[phase%SPEEDS.size()]
	return signf(speed)*minf(absf(speed)+float(phase/SPEEDS.size())*0.015,MAX_ROTATION_SPEED)

func rotation_phase(elapsed: float) -> int:
	return floori(maxf(0.0,elapsed)/ROTATION_INTERVAL)

func _top_at(x: float, polygons: Array[PackedVector2Array]) -> float:
	var top := 600.0
	for polygon in polygons:
		for i in polygon.size():
			var a := polygon[i]
			var b := polygon[(i+1)%polygon.size()]
			if absf(a.x-b.x)>0.001 and x>=minf(a.x,b.x) and x<=maxf(a.x,b.x):
				top = minf(top,lerpf(a.y,b.y,(x-a.x)/(b.x-a.x)))
	return top

func build_wave(index: int, polygons: Array[PackedVector2Array], player: Vector2, previous: PackedVector2Array) -> PackedVector2Array:
	if index==0:
		return PackedVector2Array(DESIGN.STAR_POSITIONS)
	var pattern: Array = PATTERNS[(index-1)%PATTERNS.size()]
	var candidates: Array[float] = []
	for value: float in pattern:
		candidates.append(value)
	for value in [45.0,125.0,205.0,285.0,365.0,445.0,495.0]:
		candidates.append(value)
	var result := PackedVector2Array()
	for relax_previous in [false,true]:
		for x in candidates:
			var point := Vector2(x,clampf(_top_at(x,polygons)-42.0,330.0,558.0))
			if point.distance_to(player)<45.0:
				continue
			var separated := true
			for placed in result:
				separated = separated and point.distance_to(placed)>64.0
			if not relax_previous:
				for old in previous:
					separated = separated and point.distance_to(old)>34.0
			if separated:
				result.append(point)
			if result.size()==pattern.size():
				return result
	assert(result.size()>=2,"No playable star layout could be constructed")
	return result
