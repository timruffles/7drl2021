extends Control


func set_health(n):
	var nodes = [$one,$two,$three]
	for i in range(len(nodes)):
		var node = nodes[i]
		node.visible = i < n
		
