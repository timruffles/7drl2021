extends AnimatedSprite





func _on_KickDungeon_state_change(entering, exiting):
	var player = get_node("/root").get_node("Player")
	var ball = get_node("/root").get_node("Ball")
	if !player or !ball:
		return
	var on = player.position.distance_to(ball.position) < 15
	if on:
		self.modulate.a = 1
	else:
		self.modulate.a = 0.5
		
