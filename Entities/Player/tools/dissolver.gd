extends Node3D

const DissolvableWall = preload("uid://b0hqw1jexyktf")
const Player = preload("uid://c6p3o8fitt0i3")
@onready var player: Player = $"../../.."

var ray_cast_point := Vector3.ZERO

var can_shoot := true

var current_wait_time := 0.0
var delay := 2.5

@onready var ui_indicator: TextureProgressBar = $UiIndicator


func interact_start() -> void:
	if player.ray_cast_3d.is_colliding() and can_shoot:
		var collider := player.ray_cast_3d.get_collider()
		#print(collider.name)
		if not collider is CSGShape3D:
			return
		if collider is DissolvableWall:
			
			ray_cast_point = player.ray_cast_3d.get_collision_point()
			collider.trigger_disolve(ray_cast_point)
			
			
			can_shoot = false
			current_wait_time = 0.0

func interact_stop() -> void:
	pass

func _physics_process(delta: float) -> void:
	if current_wait_time >= delay:
		can_shoot = true
		ui_indicator.value = 1.0
		ui_indicator.modulate = Color.CRIMSON
	else:
		current_wait_time += delta
		ui_indicator.value = current_wait_time / delay
		ui_indicator.modulate = Color.DARK_ORCHID
	
	if player.ray_cast_3d.is_colliding() and can_shoot:
		ui_indicator.modulate.a = 1.0
	elif ui_indicator.value == 1.0:
		ui_indicator.modulate.a = 0.3

func tool_hide():
	self.hide()
	ui_indicator.hide()

func tool_show():
	self.show()
	ui_indicator.show()
