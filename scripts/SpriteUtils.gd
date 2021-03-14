extends Node


class_name SpriteUtils

static func set_animation(sprite: AnimatedSprite, name):
	var anims = sprite.frames.get_animation_names()
	for n in anims:
		if name == n:
			sprite.animation = n
			return
	print("ERROR: can't find animation name %s, in %s" % [name,anims])
	sprite.animation = "error"
