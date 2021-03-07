extends "res://addons/gut/test.gd"


func test_enemies_seek_closest_player():
	# second player is way closer (x distances are visually much smaller than y)
	var rules = to_rules(12, """
	   e    p
	   
	
	   p
	""", {
		e = {
			id = 1,
			type = "enemy"
		},
		p = {
			type = "player"
		}
	})
	

	rules.turn()
	var moves =  moves_for_entity_for_n_turns(rules, 2, 1)
	assert_eq_deep(to_move_data(moves), [walk([3,1], 1), walk([3,2], 1)])
	
func test_enemies_attack_when_close():
	# second player is way closer (x distances are visually much smaller than y)
	var rules = to_rules(12, """
	e p
	""", {
		e = {
			id = 1,
			type = "enemy"
		},
		p = {
			type = "player"
		}
	})
	

	rules.turn()
	var moves = moves_for_entity_for_n_turns(rules, 3, 1)
		
	assert_eq_deep(to_move_data(moves), [walk([1,0], 1), attack([1,0], 1), attack([1,0], 1)])
	
func walk(position, eid):
	return Rules.Move.new(eid, Vector2(position[0], position[1]), Rules.WALK_MOVE).as_dict()

func attack(position, eid):
	return Rules.Move.new(eid, Vector2(position[0], position[1]), Rules.ATTACK_MOVE).as_dict()
	
func to_move_data(moves):
	var mvs = []
	for m in moves:
		mvs.append(m.as_dict())
	return mvs

func moves_for_n_turns(rules, n):
	var moves_by_turns = []
	for i in range(n):
		var moves = []
		rules.turn()
		while true:
			var move = rules.step()
			if not move:
				break
			moves.append(move)
		moves_by_turns.append(moves)
	return moves_by_turns

func moves_for_entity_for_n_turns(rules, n, eid):
	var by_ent = []
	for moves in moves_for_n_turns(rules, n):
		for m in moves:
			if m.eid == eid:
				by_ent.append(m)
	return by_ent
		

func test_attacks_when_close_enough():
	# second player is way closer (x distances are visually much smaller than y)
	var level = to_rules(12, """
	   ep
	""", {
		e = {
			type = "enemy"
		},
		p = {
			type = "player"
		}
	})

	#var rules = Rules.new(level)


	#var e = rules.entities_of_type("enemy")[0]
	#assert_eq_deep(rules.plan_enemy_moves(e), PoolVector2Array([Vector2(3,0), Vector2(3,1), Vector2(3,2)]))

func to_rules(width, as_string, entities):
	var lines = remove_text_indent(as_string)
	var convertedEntities = []
	for y in range(len(lines)):
		var l = lines[y]
		assert_lt(len(l), width + 1, "line too big for level (max width %d): '%s'" % [width, l])
		for x in range(len(l)):
			var c = l[x]
			if c == " ":
				continue
			var e = entities.get(c, false)
			assert_not_typeof(e, TYPE_BOOL, "unknown entity ID %s, available %s" % [c, entities.keys()])
			convertedEntities.append(Rules.Entity.new(e["type"], Vector2(x,y), e.get("id", null)))
	return Rules.new(width, len(lines), convertedEntities)
	
	
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
