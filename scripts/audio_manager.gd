extends Node

@onready var music_player = $music_player
@onready var sound_on = ConfigManager.sound_on
@onready var music_on = ConfigManager.music_on
@export var musics: Array[AudioStream]
@export var button_sound: AudioStream
var music_idx

func _ready():
	randomize()
	music_idx = randi() % musics.size()
	if !ConfigManager.music_on:
		music_toggle()
	play_music()

func play_music():
	music_player.stream = musics[music_idx]
	music_player.play()

func play_sound(stream : AudioStream):
	if ConfigManager.sound_on:
		var instance = AudioStreamPlayer.new()
		instance.stream = stream
		instance.finished.connect(remove_audio.bind(instance))
		add_child(instance)
		instance.play()

func remove_audio(instance: AudioStreamPlayer):
	instance.queue_free()

func _on_music_player_finished():
	music_idx = (music_idx+1) % musics.size()
	play_music()

func music_toggle():
	if music_player.volume_db > -79:
		music_player.volume_db = -80
	else:
		music_player.volume_db = -16

func button_click():
	play_sound(button_sound)
