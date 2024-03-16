extends CanvasLayer

@onready var current_sound = ConfigManager.sound_on

func _ready():
	pass

func _on_start_pressed():
	AudioManager.button_click()
	get_tree().change_scene_to_file("res://scenes/game_space.tscn")

func _on_quit_pressed():
	AudioManager.button_click()
	get_tree().quit()
