extends KinematicBody2D

signal selected

func _ready():
	$AnimatedSprite.animation = "idle"
	show()

func _on_Player_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton \
	and event.button_index == BUTTON_LEFT \
	and event.is_pressed():
		emit_signal("selected")
