extends Node3D

const Player = preload("uid://c6p3o8fitt0i3")
@onready var player: Player = $"../../.."

var ray_cast_point := Vector3.ZERO
var pull_strength := 10.0
var is_grappled := false
var can_grapple := true

var current_wait_time := 0.0
var delay := 2.0

@onready var ui_indicator: TextureProgressBar = $UiIndicator

func interact_start() -> void:
	if player.ray_cast_3d.is_colliding() and not is_grappled and can_grapple:
		ray_cast_point = player.ray_cast_3d.get_collision_point()
		is_grappled = true
		can_grapple = false
		current_wait_time = 0.0
		await get_tree().create_timer(0.1).timeout
		is_grappled = false

func interact_stop() -> void:
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	if current_wait_time >= delay:
		can_grapple = true
		ui_indicator.value = 1.0
		ui_indicator.modulate = Color.GREEN
	else:
		current_wait_time += delta
		ui_indicator.value = current_wait_time / delay
		ui_indicator.modulate = Color.WHITE
	
	if player.ray_cast_3d.is_colliding() and not is_grappled and can_grapple:
		ui_indicator.visible = true
	elif ui_indicator.value == 1.0:
		ui_indicator.visible = false
	if is_grappled:
		player.velocity += (ray_cast_point - player.global_position).normalized() * pull_strength

func tool_hide():
	self.hide()
	ui_indicator.hide()

func tool_show():
	self.show()
	ui_indicator.show()
