class_name ChickenLevel
extends Node2D

const DESIGN = preload("res://scripts/level_design.gd")
const WAVE_DELAY := 0.6
@onready var field: ShadowField = $ShadowField
@onready var player: SquarePlayer = $Player
@onready var diorama: DiskDiorama = $Diorama
@onready var hud: GameHud = $HUD
var session := RunSession.new()
var director := WaveDirector.new()
var crush := CrushDetector.new()
var wave_delay := 0.0

func _ready() -> void:
	# Observe the result of this tick's movement and collider updates.
	process_physics_priority = 100
	player.shadow_field = field
	diorama.mount_gameplay(field,player,session)
	field.projection_changed.connect(diorama.set_angle)
	hud.bind(session)
	hud.jump_pressed.connect(_jump)
	hud.pause_pressed.connect(session.pause)
	hud.resume_pressed.connect(session.resume)
	hud.restart_pressed.connect(restart)
	session.state_changed.connect(_on_state_changed)
	session.star_collected.connect(diorama.projection_canvas.add_pickup)
	session.wave_completed.connect(_on_wave_completed)
	restart()

func restart() -> void:
	get_tree().paused = false
	wave_delay = 0.0
	crush.reset()
	field.reset()
	player.reset_to(DESIGN.PLAYER_START)
	session.start(director.build_wave(0,field.polygons,player.position,PackedVector2Array()))
	diorama.projection_canvas.clear_effects()
	diorama.set_angle(field.angle)

func _jump() -> void:
	if session.state==RunSession.State.RUNNING:
		player.request_jump()

func _on_state_changed(state: int) -> void:
	player.input_axis = 0.0
	player.jump_buffer = 0.0
	player.jump_pending = false
	var stopped := state!=RunSession.State.RUNNING
	diorama.set_simulation_paused(stopped)
	get_tree().paused = stopped

func _on_wave_completed(_index: int) -> void:
	wave_delay = WAVE_DELAY

func _physics_process(delta: float) -> void:
	if session.state!=RunSession.State.RUNNING:
		return
	session.tick(delta)
	if session.state!=RunSession.State.RUNNING:
		return
	var keyboard_axis := int(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))-int(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	player.input_axis = clampf(keyboard_axis+hud.horizontal_input(),-1.0,1.0)
	if player.position.y>DESIGN.WALL_CROP_Y+DESIGN.WALL_TEXTURE_SIZE.y+60.0:
		session.finish(RunSession.EndReason.FALL)
		return
	if field.touches_hazard(player.bounds()):
		session.finish(RunSession.EndReason.HAZARD)
		return
	if crush.update(player,delta):
		session.finish(RunSession.EndReason.CRUSH)
		return
	if session.awaiting_wave:
		wave_delay -= delta
		if wave_delay<=0.0:
			var points := director.build_wave(session.wave_index+1,field.polygons,player.position,session.targets)
			session.next_wave(points)
			field.set_rotation_target(director.rotation_target(session.wave_index))
			diorama.projection_canvas.queue_redraw()
	else:
		for i in session.targets.size():
			if player.position.distance_to(session.targets[i])<26.0:
				if session.collect(i):
					diorama.projection_canvas.queue_redraw()

func _draw() -> void:
	draw_rect(get_viewport_rect(),Color("141824"))
