extends KinematicBody2D

class_name Enemy

var entity: Rules.Entity

func _ready():
	add_to_group(Rules.ENEMY)
	get_node("/root/KickDungeon").connect(Constants.STATE_CHANGE_SIGNAL, self, "_on_turn")

func set_entity(e: Rules.Entity):
	entity = e
	
	var anim
	var k = e.props.get("kind", null)
	if k:
		anim = "%s_idle" % k
	SpriteUtils.set_animation($AnimatedSprite, anim)

	
# pretty dumb, just check what's happening to this sprite
func _on_turn(ent,ex):
	if entity.hp <= 0:
		if not is_queued_for_deletion():
			get_parent().remove_child(self)
			queue_free()
