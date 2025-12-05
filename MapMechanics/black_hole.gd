extends Node3D

#Black Hole Gravity Effect
func _physics_process(delta: float) -> void:
	if Global.player:
		var distance_vector := self.global_position - Global.player.global_position
		var distance = distance_vector.length()
		Global.player.velocity += distance_vector.normalized() * clamp((100 / (distance)) -1.0, 0.0, 100.0)
