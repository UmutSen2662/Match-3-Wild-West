extends Node2D
var length = 0.7
var size = 1.4

func display_multiplier(pos, multiplier):
	size+=multiplier*0.1
	position = pos
	get_node("HBoxContainer/multiplier").text = str(multiplier)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(size, size), length).from(Vector2(.4, .4)).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	get_node("HBoxContainer/DeathTimer").start(length * 0.8)

func _on_death_timer_timeout():
	queue_free()
