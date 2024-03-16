extends TextureRect

@onready var move_label = $Numbers/moves
@onready var score_label = $Numbers/score
@onready var highscore_label = $Numbers/highscore
@onready var current_highscore = ConfigManager.highscore

# Called when the node enters the scene tree for the first time.
func _ready():
	highscore_label.text = str(current_highscore)
	_on_grid_update_score(0)

func _on_grid_update_score(score):
	score_label.text = str(score)
	if score > current_highscore:
		highscore_label.text = str(score)

func _on_grid_update_moves(moves):
	move_label.text = str(moves)
