extends "res://addons/gut/test.gd"


func test_finds_closest_player():
	# second player is way closer (x distances are visually much smaller than y)
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
	
	var e = rules.entities_of_type("enemy")[0]
	assert_eq_deep(rules.plan_enemy_moves(e), PoolVector2Array([Vector2(3,0), Vector2(3,1), Vector2(3,2)]))

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
			output.append(Rules.Entity.new(e["type"], Vector2(x,y)))
	return Rules.Level.new(width, len(lines), output)
	
	
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
