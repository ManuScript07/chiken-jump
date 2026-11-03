class_name MusicTests
extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	if value:
		print("PASS: ",message)
	else:
		failures += 1
		printerr("FAIL: ",message)
func wait_audio(seconds: float) -> void:
	await create_timer(seconds,true).timeout
func _run() -> void:
	var level: ChickenLevel = load("res://scenes/main.tscn").instantiate()
	root.add_child(level)
	await process_frame
	var music := level.feedback.music
	var track := music.stream as AudioStreamMP3
	check(AudioServer.get_driver_name()!="Dummy","music is tested through a real audio output driver")
	check(track!=null and track.loop and track.get_length()>1,"supplied MP3 decodes and has native looping enabled")
	var playback_id := music.get_stream_playback().get_instance_id()
	level.session.pause()
	var before := music.get_playback_position()
	await wait_audio(0.35)
	check(music.playing and not music.stream_paused and music.get_playback_position()>before+0.1,"music advances while gameplay is paused")
	before = music.get_playback_position()
	level.restart()
	await wait_audio(0.2)
	check(music.get_stream_playback().get_instance_id()==playback_id and music.get_playback_position()>before,"restart preserves the same playback and does not restart the song")
	level.session.finish(RunSession.EndReason.FALL)
	before = music.get_playback_position()
	await wait_audio(0.2)
	check(music.playing and music.get_playback_position()>before,"music also continues on game over")
	music.seek(track.get_length()-0.12)
	await wait_audio(0.5)
	check(music.playing and music.get_playback_position()<1.0,"track wraps to the beginning at its actual end")
	music.stop()
	level.queue_free()
	await wait_audio(0.15)
	print("RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
