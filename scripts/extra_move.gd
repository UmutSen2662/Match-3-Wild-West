extends Node2D
var length = 0.7
var y_limit_left = 300
var y_limit_right = 800

func _ready():
	extra_move(Vector2(300, 500))

func extra_move(pos):
	pos.y = max(min(pos.y, y_limit_right), y_limit_left)
	pos.x = max(min(pos.x, 326), 266)
	position = pos
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), length).from(Vector2(.2, .2)).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	get_node("DeathTimer").start(length * 0.8)

func _on_death_timer_timeout():
	queue_free()
