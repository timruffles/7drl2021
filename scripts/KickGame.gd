extends Node2D

const Mushroom = preload("res://scripts/Mushroom.tscn")
#const Pigeon = preload("res://npcs/Pigeon.tscn")

signal state_change

const PLAYER = "player"
const AIMING = "aiming"
const CONFIRMING = "confirming"
const RESOLVING_MOVE = "resolving_move" # resolve deterministic move - attack, walk
const RESOLVING_PHYSICS = "resolving_physics" # running physics
const ENEMIES = "enemies" # enemies' turn
const GAME_OVER = "game_over"

# physics layers
const WALL_LAYER = 0
const PLAYER_LAYER = 1

var state_transitions = {}
var state = PLAYER
var resolutionElapsed = 0
var rules: Rules

var enemy_kinds = {
#	pigeon = Pigeon,
	mushroom = Mushroom,
}

const TILE_DIMENSIONS = 16

func _ready():
	$KickButton.visible = false
	$Aimer.visible = false
	
	# TODO integrate procedural generation of the level
	var entities = [
		Rules.Entity.new("player", Vector2(16,10)),
		Rules.Entity.new("enemy", Vector2(12,6)),
		Rules.Entity.new("enemy", Vector2(10,8)),
	]
	rules = Rules.new(18, 11, entities)
	
	state_transitions = {
		AIMING: {
			"enter": funcref(self, "on_enter_aiming"),
		},
		CONFIRMING: {
			"enter": funcref(self, "on_enter_confirming"),
			"exit": funcref(self, "on_exit_confirming"),
		},
		RESOLVING_PHYSICS: {
			"enter": funcref(self, "on_enter_physics"),
			"exit": funcref(self, "on_exit_physics"),
		},
		RESOLVING_MOVE: {
			# no behaviour required beyond preventing additional moves during animations
		},
		ENEMIES: {
			"enter": funcref(self, "on_enter_enemies"),
		},
	}

	_init_positions()
	
	$Ball.connect("body_entered", self, "_on_ball_hit")
	$Player/Area2D.connect("body_exited", self, "_on_player_exit_ball_check")
	#$Player/Area2D.connect("body_exited", self, "_on_player_exit_ball_check")
	# only collide the ball in phyiscs state
	toggle_collisions(false)
	
func _on_player_exit_ball_check(body):
	# if we started the physics resolution inside the player, we disabled the bit. Now
	# rennable to allow ball to bounce off player again
	if in_state(RESOLVING_PHYSICS) and body == $Ball:
		$Ball.set_collision_mask_bit(PLAYER_LAYER, true)
		
func _on_log(n):
	print(n)

func _init_positions():
	var p = rules.entities_of_type("player")
	assert(len(p) > 0, "no players!")

	# current only handles first player
	$Player.position = level_to_render_vec(p[0].position)

	for e in rules.entities_of_type("enemy"):
		var kind = e.props.get("kind", "mushroom")
		var n = enemy_kinds[kind].instance()
		n.set_entity(e)
		n.position = level_to_render_vec(e.position)
		self.add_child(n)
		
func _on_ball_hit(n: Node):
	if n == $Player:
		return
	if n is Enemy:

		var move = rules.ball_hit(n.entity.id, n.position - $Ball.position)
		if move:
			match move.type:
				Rules.PUSHED_MOVE:
					_apply_push(move)
				_:
					pass
	
func _apply_push(move):
	var node = _find_enemy_by_eid(move.eid)
	var ent = rules.entities[move.eid]
	
	# quick push move animation
	var tween = $EnemyTween
	tween.interpolate_property(node, "position",
		node.position, level_to_render_vec(ent.position), 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()

func level_to_render_vec(lvl: Vector2) -> Vector2:
	return Vector2(lvl.x * TILE_DIMENSIONS, lvl.y * TILE_DIMENSIONS)

func render_to_level_vec(v: Vector2) -> Vector2:
	return Vector2(v.x / TILE_DIMENSIONS, v.y / TILE_DIMENSIONS)

func _input(event):
	if event is InputEventMouseButton \
	and event.button_index == BUTTON_LEFT \
	and !event.is_pressed() \
	and in_state(AIMING):
		enter_state(CONFIRMING)

	if in_state(PLAYER) and (event is InputEventKey):
		handle_player_keyboard(event)

func handle_player_keyboard(event):
	match event.scancode:
		KEY_UP:
			player_move(Vector2(0, -1))
		KEY_RIGHT:
			player_move(Vector2(1, 0))
		KEY_DOWN:
			player_move(Vector2(0, 1))
		KEY_LEFT:
			player_move(Vector2(-1, 0))

func player_move(vector):
	var move = rules.player_move(vector)
	if not move:
		# illegal move etc
		return

	enter_state(RESOLVING_MOVE)

	match move.type:
		Rules.WALK_MOVE:
			_apply_player_walk(move)
		Rules.ATTACK_MOVE:
			# TODO animate
			next_enemy_move()
		_:
			assert(false, "TODO handle player move type %s" % move.type)
			
	_notify_on_move()
	
func _notify_on_move():
	get_tree().call_group(Rules.ENEMY, "on_move")

func _apply_player_walk(move: Rules.Move):
	var player = rules.get_player()

	var tween = $PlayerMoveTween
	tween.interpolate_property($Player, "position",
		$Player.position, level_to_render_vec(player.position), 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.connect("tween_all_completed", self, "_player_tween_done")
	tween.start()

func _player_tween_done():
	enter_state(ENEMIES)

func _physics_process(delta):
	if in_state(AIMING):
		var mouse_pos = get_global_mouse_position()
		$Aimer.vector = mouse_pos - $Player.position
	elif in_state(RESOLVING_PHYSICS):
		resolutionElapsed += delta
		var ball: RigidBody2D = $Ball
		# we're done if we've given the ball enough time and it's stopped moving
		var lv = ball.linear_velocity.length()
		if resolutionElapsed > 1.5 and lv < 30:
			ball.sleeping = true
			enter_state(ENEMIES)

func in_state(s):
	return state == s

func enter_state(entering):
	var exiting = state
	state = entering

	print("transitioning %s -> %s" % [exiting, state])
	run_state_handler(exiting, "exit")
	run_state_handler(entering, "enter")
	emit_signal("state_change", entering, exiting)

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
	$Aimer.visible = false
	$Ball.apply_impulse(Vector2(0,0), $Aimer.vector)
	# TODO once ball has left player, enable player layer mask
	$KickButton.visible = false
	
func _layer_bits(bit_index):
	return int(pow(2, bit_index))

func on_enter_physics():
	toggle_collisions(true)
	resolutionElapsed = 0

func on_exit_physics():
	toggle_collisions(false)
	
func toggle_collisions(on):
	# disable collision with players outside of resolution
	var mask = 0b1111
	if on:
		# avoid colliding with player until we've been kicked off the square
		if $Player/Area2D.overlaps_body($Ball):
			mask = mask ^ _layer_bits(PLAYER_LAYER)
	else:
		mask = 1
	$Ball.collision_mask = mask

func on_enter_enemies():
	rules.turn()
	next_enemy_move()

func next_enemy_move():
	var move = rules.step()
	# enemy turn done
	if not move:
		print("no move!")
		enter_state(PLAYER)
		return

	match move.type:
		Rules.WALK_MOVE:
			_apply_walk(move)
		Rules.ATTACK_MOVE:
			_apply_attack(move)

func _apply_attack(move):
	var p = rules.get_player()
	$Heart.set_health(max(p.hp, 0))
	if p.hp == 0:
		_player_died()
	else:
		next_enemy_move()
		
func _player_died():
	enter_state(GAME_OVER)
	$PlayerDied.visible = true
	
func _find_enemy_by_eid(eid):
	for n in get_tree().get_nodes_in_group(Rules.ENEMY):
		if n.entity.id == eid:
			return n
	

func _apply_walk(move):
	var enemy = rules.entities[move.eid]
	var node = _find_enemy_by_eid(move.eid)

	var tween = $EnemyTween
	tween.interpolate_property(node, "position",
		node.position, level_to_render_vec(enemy.position), 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.connect("tween_all_completed", self, "next_enemy_move")
	tween.start()


func _on_KickButton_button_up():
	enter_state(RESOLVING_PHYSICS)

func _on_Player_selected():
	if in_state(PLAYER):
		enter_state(AIMING)

# TODO move to Rules
class EnemyTurnState:
	var enemyIndex = 0
	var enemy: Rules.Entity
	# array of game vector pos
	var moves: Array
	
	func _init():
		pass

