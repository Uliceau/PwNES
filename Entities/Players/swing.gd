extends Node3D

const Player = preload("uid://c6p3o8fitt0i3")
@onready var player: Player = $"../../.."

var ray_cast_point := Vector3.ZERO
var initial_ray_distance := 0.0

var pull_strength := 10.0
var is_grappled := false
var can_grapple := true

var current_wait_time := 0.0
var delay := 0.5

@onready var ui_indicator: TextureProgressBar = $UiIndicator

func interact_start() -> void:
	if player.ray_cast_3d.is_colliding() and not is_grappled and can_grapple:
		ray_cast_point = player.ray_cast_3d.get_collision_point()
		initial_ray_distance = player.global_position.distance_to(ray_cast_point)
		is_grappled = true

func interact_stop() -> void:
	if initial_ray_distance != 0.0:
		initial_ray_distance = 0.0
		is_grappled = false
		can_grapple = false
		current_wait_time = 0.0

func _physics_process(delta: float) -> void:
	if current_wait_time >= delay:
		can_grapple = true
		ui_indicator.value = 1.0
		ui_indicator.modulate = Color.CRIMSON
	else:
		current_wait_time += delta
		ui_indicator.value = current_wait_time / delay
		ui_indicator.modulate = Color.DARK_ORCHID
	
	if player.ray_cast_3d.is_colliding() and not is_grappled and can_grapple:
		ui_indicator.modulate.a = 1.0
	elif ui_indicator.value == 1.0:
		ui_indicator.modulate.a = 0.3
	if is_grappled:
		var distance = player.global_position.distance_to(ray_cast_point)
		if distance < initial_ray_distance * 0.7:
			return 
		player.velocity += (ray_cast_point - player.global_position).normalized() * pull_strength * (distance * 0.02)

func tool_hide():
	self.hide()
	ui_indicator.hide()

func tool_show():
	self.show()
	ui_indicator.show()
