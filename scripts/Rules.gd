extends Node

class_name Rules

# entity types
const ENEMY = "enemy"
const PLAYER = "player"



var level: Level
var astar

var example_level = Level.new(12, 10, [
	{type = ENEMY, x = 2, y = 3, hp = 3, damage = 1 },
	{type = PLAYER, x = 8, y = 9, hp = 10 },
])

func _init(lvl):
	# just give an example
	level = lvl
	if lvl == null:
		level = example_level
	_generate_astar()
	
	
func _generate_astar():
	astar = AStar2D.new()
	astar.reserve_space(level.width * level.height)
	for x in range(level.width):
		for y in range(level.height):
			astar.add_point()
		

func enemy_hit(player):
	pass

# decides what foes will do
func plan_enemy_moves():
	return []

	
func find_nearest_node(q):
	pass
		 

class Level:
	var width = 0
	var height = 0
	var entities = []
	
	func _init(w,h,e):
		width = w
		height = h
		entities = e
		
		
