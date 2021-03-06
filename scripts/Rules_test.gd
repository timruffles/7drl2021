extends "res://addons/gut/test.gd"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func test_finds_closest_player():
	
	
	var level = to_level(12, """
	   e    p
	 
	  p
	""", {
		e = {
			type = "enemy"
		},
		p = {
			type = "player"
		}
	})
	
	var rules = Rules.new(level)
	print(rules.plan_enemy_moves())

	var moves = [
		[]
	]

func to_level(width, as_string, entities):
	var lines = remove_text_indent(as_string)
	var output = []
	for y in range(len(lines)):
		var l = lines[y]
		assert_lt(len(l), width + 1, "line too big for level (max width %d): '%s'" % [width, l])
		for x in range(len(l)):
			var c = l[x]
			if c == " ":
				continue
			var e = entities.get(c, false)
			assert_not_typeof(e, TYPE_BOOL, "unknown entity ID %s, available %s" % [c, entities.keys()])
			e = e.duplicate(true)
			e["x"] = x
			e["y"] = y
			output.append(e)
	return output
	
	
# levels should always start with "\n" and end with "\t\n"
func remove_text_indent(s):
	var list = []
	s  = s.lstrip("\n").rstrip("\n\t")
	for	line in s.split("\n"):
		# remove leading tabs
		list.append(line.lstrip("\t"))
	return list

func join(parts, joiner):
	var op = ""
	for i in range(len(parts)):
		var p = parts[i]
		op += p
		if i < len(parts) - 1: 
			op += joiner
	return op
