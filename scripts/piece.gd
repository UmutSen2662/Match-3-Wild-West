extends Node2D

@export var color: String
var matched = false

func dim():
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.4,1.4),.2).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "modulate", Color.TRANSPARENT,.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func move(target):
	var tween = create_tween()
	tween.tween_property(self, "position", target, .3).from_current().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
