extends KinematicBody2D

signal selected

func _ready():
	$AnimatedSprite.animation = "idle"
	show()

func _on_Player_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton \
	and event.button_index == BUTTON_LEFT \
	and event.is_pressed():
		if position.distance_to(get_node("../Ball").position) <  Rules.BALL_DISTANCE:
			emit_signal("selected")

func on_move():
	# nothing required - game over logic handled elsewhere
	pass
