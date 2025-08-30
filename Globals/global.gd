extends Node

const Player = preload("res://Entities/Players/player.gd")
var authority_player : Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#Find nearest node to a position
func get_nearest(origin : Vector3, nodes : Array, localpos := false) -> Array:
	var dist := INF
	var temp_dist := 0.0
	var nearest_node : Node = null
	for node in nodes:
		if localpos:
			if node and (node is Node3D) and node.position != origin:
				temp_dist = origin.distance_squared_to(node.position)
				if temp_dist < dist:
					dist = temp_dist
					nearest_node = node
		else:
			if node and (node is Node3D) and node.global_position != origin:
				temp_dist = origin.distance_squared_to(node.global_position)
				if temp_dist < dist:
					dist = temp_dist
					nearest_node = node
	return [nearest_node, dist]

#Find furthest node from a position
func get_furthest(origin : Vector2, nodes : Array, _localpos := false) -> Node2D:
	var dist := 0.0
	var temp_dist := 0.0
	var furthest_node : Node2D =  null
	for node in nodes:
		if node and node is Node2D:
			temp_dist = origin.distance_squared_to(node.global_position)
			if temp_dist > dist:
				dist = temp_dist
				furthest_node = node
	return furthest_node
