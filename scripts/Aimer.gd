extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var vector = Vector2(20,30) setget _set_vector
export var color: Color = Color(0, 255 , 100)
export var width: float = 3.0

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _set_vector(v):
	vector = v
	update()

func _draw():
	draw_line(Vector2(0,0), vector, color, width, true)
