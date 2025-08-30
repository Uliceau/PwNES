extends ColorRect

@onready var player: CharacterBody3D = $".."

func _on_timer_timeout() -> void:
	var nearest_info :Array= Global.get_nearest(player.global_position, get_tree().get_nodes_in_group("lava"))
	var closest_lava = nearest_info[0]
	if closest_lava is Node3D:
		
		var distance_y :float= player.global_position.y - closest_lava.global_position.y
		if distance_y < 40:
			var new_value := (remap(distance_y, 0, 40, 0.0, 0.01)*-1) + 0.01
			print(new_value)
			self.material.set("shader_parameter/distortion_strength", new_value)
		else:
			self.material.set("shader_parameter/distortion_strength", 0.0)
