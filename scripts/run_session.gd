class_name RunSession
extends RefCounted

signal changed
signal state_changed(state: int)
signal star_collected(index: int, point: Vector2)
signal wave_completed(index: int)

enum State { RUNNING, PAUSED, FINISHED }
enum EndReason { TIME, FALL, CRUSH, HAZARD }
const DURATION := 20.0
const STAR_BONUS := 1.5

var state := State.RUNNING
var end_reason := EndReason.TIME
var remaining := DURATION
var elapsed := 0.0
var total_stars := 0
var wave_index := 0
var waves_completed := 0
var targets := PackedVector2Array()
var collected: Array[bool] = []
var awaiting_wave := false

func start(points: PackedVector2Array) -> void:
	remaining = DURATION
	elapsed = 0.0
	total_stars = 0
	wave_index = 0
	waves_completed = 0
	end_reason = EndReason.TIME
	state = State.RUNNING
	_set_targets(points)
	state_changed.emit(state)
	changed.emit()

func _set_targets(points: PackedVector2Array) -> void:
	assert(not points.is_empty(),"A wave must contain at least one target")
	targets = points.duplicate()
	collected.clear()
	collected.resize(targets.size())
	collected.fill(false)
	awaiting_wave = false

func next_wave(points: PackedVector2Array) -> void:
	if state!=State.RUNNING or not awaiting_wave:
		return
	wave_index += 1
	_set_targets(points)
	changed.emit()

func tick(delta: float) -> void:
	if state!=State.RUNNING or delta<=0.0:
		return
	elapsed += delta
	remaining = maxf(0.0,remaining-delta)
	if remaining<=0.0:
		finish(EndReason.TIME)
	else:
		changed.emit()

func collect(index: int) -> bool:
	if state!=State.RUNNING or awaiting_wave or index<0 or index>=targets.size() or collected[index]:
		return false
	collected[index] = true
	total_stars += 1
	remaining = minf(DURATION,remaining+STAR_BONUS)
	star_collected.emit(index,targets[index])
	if not collected.has(false):
		awaiting_wave = true
		waves_completed += 1
		wave_completed.emit(wave_index)
	changed.emit()
	return true

func pause() -> void:
	if state==State.RUNNING:
		state = State.PAUSED
		state_changed.emit(state)
		changed.emit()

func resume() -> void:
	if state==State.PAUSED:
		state = State.RUNNING
		state_changed.emit(state)
		changed.emit()

func finish(reason: EndReason) -> void:
	if state==State.FINISHED:
		return
	end_reason = reason
	state = State.FINISHED
	state_changed.emit(state)
	changed.emit()

func time_ratio() -> float:
	return clampf(remaining/DURATION,0.0,1.0)
