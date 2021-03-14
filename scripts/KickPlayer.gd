extends KinematicBody2D

signal selected
signal touched_item

var entity: Rules.Entity

func _ready():
	$AnimatedSprite.animation = "idle"
	show()

func _on_Player_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton \
	and event.button_index == BUTTON_LEFT \
	and event.is_pressed():
		emit_signal("selected")

func _on_Area2D_area_entered(body):
	print("is item ", body is Item)
	if body is Item:
		emit_signal("touched_item", body)
	
