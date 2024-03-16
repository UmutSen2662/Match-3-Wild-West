extends CanvasLayer

@onready var final_score_label = $MarginContainer/score_label
@onready var current_highscore = ConfigManager.highscore

func _ready():
	self.offset.x = 576

func slide_in():
	$AnimationPlayer.play("slide")

func _on_continue_button_pressed():
	AudioManager.button_click()
	get_tree().change_scene_to_file("res://scenes/game_space.tscn")

func _on_grid_end_game(score):
	final_score_label.text = str(score)
	if score > current_highscore:
		ConfigManager.highscore = score
	ConfigManager.save_config()
	slide_in()
