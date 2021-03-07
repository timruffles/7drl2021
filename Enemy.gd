extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var entity: Rules.Entity

func set_entity(e):
	entity = e
	
# pretty dumb, just check what's happening to this sprite
func on_move():
	if entity.hp <= 0:
		self.visible = false
