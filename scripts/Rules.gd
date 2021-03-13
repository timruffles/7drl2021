extends Node

# assumptions - as all locations are integers, we can use v2s (useful for astar)
# without float issues

class_name Rules

# entity types
const ENEMY = "enemy"
const PLAYER = "player"

# move types
const WALK_MOVE = "walk"
const ATTACK_MOVE = "attack"
const PUSHED_MOVE = "pushed"

var astar: AStar2D
var entities = {}
var width
var height

var _enemy_move_list = []

func _init(w, h, ent):
	width = w
	height = h

	# TODO think more about where to init these
	entities = {}
	var eid = 0
	for e in ent:
		eid += 1
		var id = eid
		# accept preset IDs (currently just for tests)
		if not e.id == null:
			id = e.id
		entities[id] = e
		e.id = id

# turn prepares the rules to step through the enemies moves 
func turn():
	# we prepare the list to give us a way to track our progress through the move
	_enemy_move_list = entities_of_type(ENEMY)
	
# step updates the game state, and returns a move that describes the change
func step():
	if len(_enemy_move_list) == 0:
		return # end of turn
	_generate_astar()
	
	# continue through the enemies in order, skipping dead ones
	for _i in range(len(_enemy_move_list)):
		var e = _enemy_move_list.pop_front()
		# enemy is dead
		if not entities[e.id]:
			continue
		var move = _enemy_move(e)
		if move:
			return move
		# TODO currently no good reason to not have a move

func get_player():
	# single player currently
	return entities_of_type(PLAYER)[0]
	
func player_move(vec):
	var player = get_player()
	var np = player.position + vec
	if not is_in_bounds(np):
		return
	var e = entity_at(np)
	if e && e.type == ENEMY:
		var mv = Move.new(player.id, e.position, ATTACK_MOVE)
		_apply_player_attack(mv)
		return mv

	player.position += vec
	return Move.new(player.id, player.position, WALK_MOVE)
	
func _apply_player_attack(mv):
	var enemy = entity_at(mv.position)
	enemy.hp = 0
	entities.erase(enemy.id)

	
func entity_at(vec):
	for eid in entities:
		var e = entities[eid]
		if e.position == vec:
			return e
	
func is_in_bounds(vec):
	return vec.x >= 0 && vec.y >= 0 && \
 		   vec.x < width && vec.y < height
	
# turns the ball-hit back into a series of quantised events
# vector in is direction ball is travelling through the node, like a ray aimed at it
func ball_hit(eid, ball_through_node_vector):
	var direction = quantize_vector(ball_through_node_vector)
	var ent = entities[eid]
	var resulting_pos = ent.position + direction
	# TODO do a wall bounce damage thing?/
	if ent and is_in_bounds(resulting_pos):
		ent.position = resulting_pos
		return Move.new(eid, resulting_pos, PUSHED_MOVE)
	return

# quantizes a continuous vector into integer vector
static func quantize_vector(vec: Vector2) -> Vector2:
	var r = vec.normalized().rotated(deg2rad(-45))
	var x = r.x
	var y = r.y
	# rotate a quarter, to make checks easy
	if y < 0:
		if x >= 0:
			# right
			return Vector2(1, 0)
		else:
			# up
			return Vector2(0, -1)
	else:
		if x >= 0:
			# down
			return Vector2(0, 1)
		else:
			# left
			return Vector2(-1, 0)
		

# runs an enemy move, and returns a move that describes the change to visualise
# for the player
func _enemy_move(e):
	var players = entities_of_type(PLAYER)
	if len(players) == 0:
		return []

	var distances = []
	for p in players:
		var pp: Vector2 = p.position
		# sort by straight-line distance heuristic
		distances.append([p, pp.distance_squared_to(e.position)])

	distances.sort_custom(self, "_sort_by_second_pair_el")

	var p: Entity = distances[0][0]

	var path = astar.get_point_path(_to_astar_id(e.position), _to_astar_id(p.position))
	
	# first point on path is current location
	if len(path) < 2:
		# TODO shouldn't be possible
		return
		
	# if we're one square away
	if path[1] == p.position:
		var am = Move.new(e.id, p.position, ATTACK_MOVE)
		_apply_attack(am)
		return am
		
	
	var wm =  Move.new(e.id, path[1], WALK_MOVE)
	_apply_walk(wm)
	return wm

func entities_of_type(t):
	var op = []
	for id in entities:
		var e = entities[id]
		if e.type == t:
			op.append(e)
	return op
	
func _is_neighbouring(v1, v2):
	# adjacent square, non-diagonal
	if v1.x - v2.x == 0:
		return abs(v1.y - v2.y) <= 1
	if v1.y - v2.y == 0:
		return abs(v1.x - v2.x) <= 1
	return false

func _apply_walk(w: Move):
	var e = entities[w.eid]
	e.position = w.position

func _apply_attack(m: Move):
	var e = entities[m.eid]
	# currently assumes single player, so always hits player
	var player = get_player()
	player.hp -= 1

		
var squarewise_deltas = [
	[0,-1],
	[1,0],
	[0,1],
	[-1,0]
]

func _generate_astar():
	astar = AStar2D.new()
	astar.reserve_space(width * height)
	
	# generate all points and connections to neighbours
	for x in range(width):
		for y in range(height):
			var v = Vector2(x,y)
			astar.add_point(_to_astar_id(v), v)
	# avoid routing through entities
	for id in entities:
		var e = entities[id]
		astar.set_point_weight_scale(_to_astar_id(e.position), INF)
	for x in range(width):
		for y in range(height):
			var id = _xy_to_astar_id(x,y)
			for d in squarewise_deltas:
				var dx = d[0]
				var dy = d[1]
				if x + dx < 0 or x + dx >= width:
					continue
				if y + dy < 0 or y + dy >= height:
					continue
				astar.connect_points(id, _xy_to_astar_id(x + dx, y + dy))


func _sort_by_second_pair_el(pair_a, pair_b):
	return pair_a[1] < pair_b[1]
	

func _to_astar_id(v: Vector2):
	return _xy_to_astar_id(v.x, v.y)

func _xy_to_astar_id(x, y):
	return 1 + x + y * width

# outputs an ascii art representation of the rule state
func debug_draw():
	var op = ""
	var entities_by_pos = {}
	var warns = []
	for eid in entities:
		var e = entities[eid]
		var xy = "%d,%d" % [e.position.x, e.position.y]
		if xy in entities_by_pos:
			var o = entities_by_pos[e.id].id
			warns.append("two entities at same position! %s:%s, %s:%s" % [o.type, o.id, e.type, e.id])
		entities_by_pos[xy] = e

	for y in range(height):
		for x in range(width):
			var xy = "%d,%d" % [x,y]
			var e = entities_by_pos.get(xy,null)
			if not e:
				op += " "
				continue

			var symbol = "?"
			match e.type:
				PLAYER:
					symbol = "p"
				ENEMY:
					symbol = "e"
			op += symbol
		op += "\n"
	if len(warns) == 0:
		return op

	return "Warnings: %s\n\n%s" % [warns, op]


class Entity:
	var position: Vector2
	var type: String
	var id
	var hp = 3
	var props
	
	func _init(typ, pos, i = null, p = {}):
		position = pos
		type = typ
		id = i
		props = p

class Move:
	# actor eid
	var eid: int
	var position: Vector2
	var type: String

	func _init(attacker_id, pos, typ):
		eid = attacker_id
		position = pos
		type = typ

	func as_dict():
		return {type = type, eid = eid, position = position}
