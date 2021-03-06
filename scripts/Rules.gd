extends Node

class_name Rules

# entity types
const ENEMY = "enemy"
const PLAYER = "player"

var level: Level
var astar: AStar2D
var entities = {}

var _entityIdCounter = 0

var example_level = Level.new(12, 10, [
	{type = ENEMY, x = 2, y = 3 },
	{type = PLAYER, x = 8, y = 9 },
])

func _init(lvl):
	# just give an example
	level = lvl
	if lvl == null:
		level = example_level
		
	# TODO think more about where to init these
	entities = {}
	for i in range(len(level.entities)):
		var e = level.entities[i]
		entities[i] = e
		e.id = i
	
	_generate_astar()
	

func _update_astar():
	# avoid routing through entities
	for id in entities:
		var e = entities[id]
		astar.set_point_weight_scale(to_astar_id(e.position), INF)
	
	
func _generate_astar():
	astar = AStar2D.new()
	astar.reserve_space(level.width * level.height)
	
	# generate all points and connections to neighbours
	for x in range(level.width):
		for y in range(level.height):
			var v = Vector2(x,y)
			astar.add_point(to_astar_id(v), v)
	for x in range(level.width):
		for y in range(level.height):
			var id = xy_to_astar_id(x,y)
			for dx in range(-1, 2):
				if x + dx < 0 or x + dx >= level.width:
					continue
				for dy in range(-1, 2):
					if y + dy < 0 or y + dy >= level.height:
						continue
					if dx == 0 and dy == 0:
						continue
					astar.connect_points(id, xy_to_astar_id(x + dx, y + dy))

func apply_move(eid, delta: Vector2):
	# TODO reset astar weight at position (just regenerate as probably fast enough?)
	var e = entities[eid]
	e.position = e.position + delta
		
func to_astar_id(v: Vector2):
	return xy_to_astar_id(v.x, v.y)

func xy_to_astar_id(x, y):
	return 1 + x + y * level.width
				

# decides what foes will do
func plan_enemy_moves(e):
	var players = entities_of_type(PLAYER)
	if len(players) == 0:
		return []

	var distances = []
	for p in players:
		var pp: Vector2 = p.position
		distances.append([p, pp.distance_squared_to(e.position)])
	distances.sort_custom(self, "sort_by_second_pair_el")
	
	var p: Entity = distances[0][0]
	return astar.get_point_path(to_astar_id(e.position), to_astar_id(p.position))
	

func sort_by_second_pair_el(pair_a, pair_b):
	return pair_a[1] < pair_b[1]
	
func entities_of_type(t):
	var op = []
	for id in entities:
		var e = entities[id]
		if e.type == t:
			op.append(e)
	return op
	
class Entity:
	var position: Vector2
	var type: String
	var id: int
	
	func _init(typ, pos):
		position = pos
		type = typ
		

class Level:
	var width = 0
	var height = 0
	var entities = []
	
	func _init(w,h,e):
		width = w
		height = h
		entities = e

