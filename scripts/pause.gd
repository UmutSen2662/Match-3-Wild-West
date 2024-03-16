extends CanvasLayer

@onready var sound_on = ConfigManager.sound_on
@onready var music_on = ConfigManager.music_on
@onready var sound_button = $MarginContainer/SettingsContainer/AudioContainer/VBoxContainer/sound
@onready var music_button = $MarginContainer/SettingsContainer/AudioContainer/VBoxContainer/music
var on_screen = false

func _ready():
	self.offset.x = 576
	sound_button.button_pressed = !sound_on
	music_button.button_pressed = !music_on

func slide_in():
	$AnimationPlayer.play("slide")
	on_screen = true

func slide_out():
	$AnimationPlayer.play_backwards("slide")
	on_screen = false

func _on_play_pressed():
	AudioManager.button_click()
	get_tree().paused = false
	slide_out()

func _on_back_pressed():
	AudioManager.button_click()
	if get_tree().paused:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
	else:
		get_tree().quit()

func _on_grid_pause_game():
	slide_in()

func _on_invis_back_button_pressed():
	_on_play_pressed()


func _on_sound_pressed():
	sound_on = !sound_on
	sound_button.button_pressed = !sound_on
	ConfigManager.sound_on = !ConfigManager.sound_on
	ConfigManager.save_config()
	AudioManager.button_click()

func _on_music_pressed():
	AudioManager.music_toggle()
	music_on = !music_on
	music_button.button_pressed = !music_on
	ConfigManager.music_on = !ConfigManager.music_on
	ConfigManager.save_config()
	AudioManager.button_click()

func _on_settings_pressed():
	AudioManager.button_click()
	if on_screen:
		slide_out()
	else:
		slide_in()
