extends AnimatedSprite

func _on_KickDungeon_state_change(entering, exiting):
	var player = get_node("/root/KickDungeon/Player")
	var ball = get_node("/root/KickDungeon/Ball")
	if !player or !ball:
		return
	if player.position.distance_to(ball.position) < Rules.BALL_DISTANCE:
		self.modulate.a = 1
	else:
		self.modulate.a = 0.5
		
