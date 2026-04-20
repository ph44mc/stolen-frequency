extends Node2D

var active_sounds: int = 0
var max_sounds_per_frame: int = 100
var sound_queue: Array = []	

var sound_window_count: int = 0
var sound_window_timer: float = 0.0

func _process(delta):
	sound_window_timer += delta
	
	if sound_window_timer >= 1.0:
		sound_window_timer = 0
		sound_window_count = 0

func _ready() -> void:
	Sounds.next_music()
	
func stop_music():
	$Music.stop()
	
func _on_music_finished() -> void:
	$Music.pitch_scale = randf_range(0.7,1.3)
	next_music()

var curr_mus_id: int = 0
var musics = ["music","music2",]

func next_music():
	set_music(musics[curr_mus_id % musics.size()])
	curr_mus_id+=1

func set_music(sound_name: String):
	$Music.stream = load("res://Assets/SFX/" + sound_name + ".ogg")
	$Music.play()

func can_spawn_sound() -> bool:
	if active_sounds >= max_sounds_per_frame:
		return false
	
	if sound_window_count >= 100:
		return false
	
	sound_window_count += 1
	return true
	
func play_sound(sound_name: String, volume: float = 0.0, bus: String = "Master", pitch_offset: float = 0.0, pitch: float = 1.0):
	if not can_spawn_sound():
		return null
	
	active_sounds += 1
	
	sound_name = "res://Assets/SFX/" + sound_name + ".ogg"
	var new_audio: AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(new_audio)
	
	new_audio.bus = bus
	new_audio.stream = load(sound_name)
	new_audio.volume_db = volume
	
	if pitch_offset != 0.0:
		pitch += randf_range(-pitch_offset, pitch_offset)
	
	new_audio.pitch_scale = abs(pitch)
	new_audio.play()
	
	_cleanup_sound(new_audio)
	return new_audio
	
func play_sound_at(where, sound_name: String, volume: float = 0.0, bus: String = "Master", pitch_offset: float = 0.0, pitch: float = 1.0):
	if not can_spawn_sound():
		return null
	
	active_sounds += 1
	
	sound_name = "res://Assets/SFX/" + sound_name + ".ogg"
	var new_audio: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	
	if where is Vector2:
		G.main.add_child(new_audio)
		new_audio.global_position = where
	else:
		add_child(new_audio)

	new_audio.bus = bus
	new_audio.stream = load(sound_name)
	new_audio.volume_db = volume
	new_audio.max_distance = 100 * (volume + 80) / 10
	new_audio.panning_strength = 0.2

	if pitch_offset != 0.0:
		pitch += randf_range(-pitch_offset, pitch_offset)

	new_audio.pitch_scale = abs(pitch)
	new_audio.play()

	_cleanup_sound(new_audio)
	return new_audio
	
func _cleanup_sound(sound):
	if sound == null:
		return
	
	var sound_len = sound.stream.get_length() + 0.1
	
	await get_tree().create_timer(sound_len).timeout
	
	if is_instance_valid(sound):
		active_sounds -= 1
		sound.queue_free()
	
