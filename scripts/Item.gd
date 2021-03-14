extends KinematicBody2D

class_name Item

var entity: Rules.Entity

func _ready():
	add_to_group(Rules.ITEM)

func set_entity(e: Rules.Entity):
	entity = e
	var k = e.props.get("kind", null)
	SpriteUtils.set_animation($AnimatedSprite, e.props.get("kind", null))
