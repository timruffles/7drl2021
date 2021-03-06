extends Node2D

const IDLE = 0
const AIMING = 1
const CONFIRMING = 2
const RESOLVING = 3 # resolve player's moves
const ENEMIES = 4 # enemies' turn

var state_transitions = {}
var state = IDLE


func _ready():
	$KickButton.visible = false
	$Aimer.visible = false
	
	state_transitions = {
		AIMING: {
			"enter": funcref(self, "on_enter_aiming"),
		},
		CONFIRMING: {
			"enter": funcref(self, "on_enter_confirming"),
			"exit": funcref(self, "on_exit_confirming"),
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
	$Aimer.visible = true
	
func on_enter_confirming():
	$KickButton.visible = true
	
func on_exit_confirming():
	$Aimer.visible = false
	$Ball.get_node("RigidBody2D").apply_impulse(Vector2(0,0), $Aimer.vector)
	$KickButton.visible = false

func _on_KickButton_button_up():
	enter_state(IDLE)

func _on_Player_selected():
	if in_state(IDLE):
		enter_state(AIMING)
