class_name GameFeedback
extends Node

signal pulse_requested(duration_ms: int, amplitude: float)
const MUSIC_PATH := "res://assets/audio/main_theme.mp3"
var music: AudioStreamPlayer
var last_button_pulse := -1000

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music = AudioStreamPlayer.new()
	music.name = "Music"
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	var track := load(MUSIC_PATH) as AudioStreamMP3
	assert(track!=null,"The supplied music must be imported as an MP3 stream")
	track = track.duplicate() as AudioStreamMP3
	track.loop = true
	music.stream = track
	music.volume_db = -10.0
	add_child(music)
	# A dummy audio driver has no output device; avoid keeping an unused playback.
	if AudioServer.get_driver_name()!="Dummy":
		music.play()

func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null

func button_pressed(_action: String) -> void:
	var now := Time.get_ticks_msec()
	if now-last_button_pulse<30:
		return
	last_button_pulse = now
	_pulse(22,0.35)

func star_collected(_index: int, _point: Vector2) -> void:
	_pulse(45,0.65)

func _pulse(duration: int, amplitude: float) -> void:
	pulse_requested.emit(duration,amplitude)
	if not OS.has_feature("mobile"):
		return
	if OS.has_feature("android") and not OS.get_granted_permissions().has("android.permission.VIBRATE"):
		return
	Input.vibrate_handheld(duration,amplitude)
