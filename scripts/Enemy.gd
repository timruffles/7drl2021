extends KinematicBody2D

class_name Enemy

var entity: Rules.Entity

func _ready():
	add_to_group(Rules.ENEMY)

func set_entity(e):
	entity = e
	
# pretty dumb, just check what's happening to this sprite
func on_move():
	if entity.hp <= 0:
		queue_free()
		get_parent().remove_child(self)
