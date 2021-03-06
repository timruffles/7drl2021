extends KinematicBody2D

const IDLE = 0
const AIMING = 1
const CONFIRMING = 2

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
	
	$AnimatedSprite.animation = "idle"
	
	show()

func _on_Player_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton \
	and event.button_index == BUTTON_LEFT \
	and event.is_pressed():
		self.on_mousedown()

func _input(event):
	if event is InputEventMouseButton \
	and event.button_index == BUTTON_LEFT \
	and !event.is_pressed() \
	and in_state(AIMING):
			self.on_mouseup()
		
func on_mousedown():
	enter_state(AIMING)
		
func on_mouseup():
	# $Aimer.visible = false
	enter_state(CONFIRMING)


func _physics_process(delta):
	if in_state(AIMING):
		var mouse_pos = get_global_mouse_position()
		$Aimer.vector = mouse_pos - self.position

func in_state(s):
	return state == s
	
func enter_state(entering):
	var exiting = state
	state = entering
	run_state_hanlder(exiting, "exit")
	run_state_hanlder(entering, "enter")
		
	
func run_state_hanlder(state, event):
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
