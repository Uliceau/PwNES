extends ColorRect

#References
@onready var player: CharacterBody3D = $".."

#Adjust heat distortion based on player's proximity to lava
func _on_timer_timeout() -> void:
	var nearest_info :Array = Global.get_nearest(player.global_position, get_tree().get_nodes_in_group("lava"))
	var closest_lava = nearest_info[0]
	if closest_lava is MeshInstance3D:
		var aabb :AABB = closest_lava.mesh.get_aabb()
		
		var local_player_pos = closest_lava.to_local(player.global_position)
		
		var in_aabb_xz = (
			local_player_pos.x >= aabb.position.x and local_player_pos.x <= aabb.position.x + aabb.size.x and
			local_player_pos.z >= aabb.position.z and local_player_pos.z <= aabb.position.z + aabb.size.z
		)
		
		if in_aabb_xz:
			var distance_y :float= player.global_position.y - closest_lava.global_position.y
			if distance_y < 40:
				var new_value := (remap(distance_y, 0, 40, 0.0, 0.01)*-1) + 0.01
				self.material.set("shader_parameter/distortion_strength", new_value)
			else:
				self.material.set("shader_parameter/distortion_strength", 0.0)
