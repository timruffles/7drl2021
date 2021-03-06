extends Node2D

const Mushroom = preload("res://npcs/Mushroom.tscn")

const IDLE = "idle"
const AIMING = "aiming"
const CONFIRMING = "confirming"
const RESOLVING = "resolving" # resolve player's moves
const ENEMIES = "enemies" # enemies' turn

# signals
const ENEMY_MOVE_SIGNAL = "emove"

var state_transitions = {}
var state = IDLE
var resolutionElapsed = 0
var rules: Rules

var enemyTurnState = EnemyTurnState.new()

# the nodes for each enenmy
var enemyNodes = {}

const TILE_DIMENSIONS = 16

func _ready():
	$KickButton.visible = false
	$Aimer.visible = false
	
	var entities = [
		Rules.Entity.new("player", Vector2(16,10)),
		Rules.Entity.new("enemy", Vector2(5,3)),
		Rules.Entity.new("enemy", Vector2(1,2)),
	]
	rules = Rules.new(Rules.Level.new(18, 11, entities))
	
	state_transitions = {
		AIMING: {
			"enter": funcref(self, "on_enter_aiming"),
		},
		CONFIRMING: {
			"enter": funcref(self, "on_enter_confirming"),
			"exit": funcref(self, "on_exit_confirming"),
		},
		RESOLVING: {
			"enter": funcref(self, "on_enter_resolving"),
		},
		ENEMIES: {
			"enter": funcref(self, "on_enter_enemies"),
		},
	}

	_init_positions()
	
	# after positioned, turn off physics
	#Physics2DServer.set_active(false)
	
func _init_positions():
	var p = rules.entities_of_type("player")
	assert(len(p) > 0, "no players!")
	
	# current only handles first player
	$Player.position = level_to_render_vec(p[0].position)
	
	for e in rules.entities_of_type("enemy"):
		var n = Mushroom.instance()
		enemyNodes[e.id] = n
		n.position = level_to_render_vec(e.position)
		self.add_child(n)
	
func level_to_render_vec(lvl: Vector2) -> Vector2:
	# this needs to be updated when we change the rendering style
	# offset by 0.5 to center in tile
	return Vector2((lvl.x + 0.5) * TILE_DIMENSIONS, (lvl.y + 0.5) * TILE_DIMENSIONS)
	
	
	

func _input(event):
	if event is InputEventMouseButton \
	and event.button_index == BUTTON_LEFT \
	and !event.is_pressed() \
	and in_state(AIMING):
		enter_state(CONFIRMING)

func _physics_process(delta):
	if in_state(AIMING):
		var mouse_pos = get_global_mouse_position()
		$Aimer.vector = mouse_pos - $Player.position
	elif in_state(RESOLVING):
		resolutionElapsed += delta
		var ball = $Ball.get_node("RigidBody2D")
		# we're done if we've given the ball enough time and it's stopped moving
		# TODO research linear velocity
		var lv = ball.linear_velocity.length()
		if (resolutionElapsed > 0.5 and lv < 30) and\
		   (resolutionElapsed > 2.5 and lv < 150 ): # taking too long!
			enter_state(ENEMIES)
		
func in_state(s):
	return state == s
	
func enter_state(entering):
	var exiting = state
	state = entering

	run_state_handler(exiting, "exit")
	run_state_handler(entering, "enter")
		
func run_state_handler(state, event):
	var fn = state_transitions.get(state, {}).get(event, null)
	if fn:
		fn.call_func()
	
func on_enter_aiming():
	$Aimer.position = $Player.position
	$Aimer.visible = true
	
func on_enter_confirming():
	$KickButton.visible = true
	
func on_exit_confirming():
	# simulate the result of the player's move
	Physics2DServer.set_active(true)
	$Aimer.visible = false
	$Ball.get_node("RigidBody2D").apply_impulse(Vector2(0,0), $Aimer.vector)
	$KickButton.visible = false
	
func on_enter_resolving():
	resolutionElapsed = 0
	
func on_enter_enemies():
	enemyTurnState = EnemyTurnState.new()
	Physics2DServer.set_active(false)
	
	next_enemy_move()
	
func next_enemy_move():
	
	# TODO this is placeholder to demo movement
	# I think moving over the turn logic to the rules part makes sense to allow for
	# easier unit testing
	
	
	
	#var enemyMovePair = enemyTurnState.next()
	
	var enemyMovePair = [1,Vector2(1,1)]
	# enemy turn done
	if not enemyMovePair:
		enter_state(IDLE)
		return
		
	var enemyId = enemyMovePair[0]
	var move = enemyMovePair[1]
	
	var enemy = rules.entities[enemyId]
	var node = enemyNodes[enemyId]

	rules.apply_move(enemyId, move)
	
	var tween = $EnemyTween
	tween.interpolate_property(node, "position",
		node.position, level_to_render_vec(enemy.position), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func _on_KickButton_button_up():
	enter_state(RESOLVING)

func _on_Player_selected():
	if in_state(IDLE):
		enter_state(AIMING)

# TODO move to Rules
class EnemyTurnState:
	var enemyIndex = 0
	var enemy: Rules.Entity
	# array of game vector pos
	var moves: Array
	
	func _init():
		pass

func _on_EnemyTween_tween_all_completed():
	# TODO continue enemy turns, shouldn't jump straight to another player turn
	$Ball.position = $Player.position + Vector2(-4, 4)
	enter_state(IDLE)
	pass # Replace with function body.
