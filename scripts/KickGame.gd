extends Node2D

const IDLE = "idle"
const AIMING = "aiming"
const CONFIRMING = "confirming"
const RESOLVING = "resolving" # resolve player's moves
const ENEMIES = "enemies" # enemies' turn

var state_transitions = {}
var state = IDLE
var resolutionElapsed = 0

func _ready():
	$KickButton.visible = false
	$Aimer.visible = false
	
	Physics2DServer.set_active(false)
	
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
		if resolutionElapsed > 0.5 and ball.linear_velocity.length() < 10:
			enter_state(ENEMIES)
		
func in_state(s):
	return state == s
	
func enter_state(entering):
	var exiting = state
	state = entering
	print("transitioning: ", exiting, " -> ", entering)
	run_state_handler(exiting, "exit")
	run_state_handler(entering, "enter")
		
func run_state_handler(state, event):
	var fn = state_transitions.get(state, {}).get(event, null)
	if fn:
		fn.call_func()
	
func on_enter_aiming():
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
	Physics2DServer.set_active(false)
	pass

func _on_KickButton_button_up():
	enter_state(RESOLVING)

func _on_Player_selected():
	if in_state(IDLE):
		enter_state(AIMING)
