extends CharacterBody3D

#Types
const LavaCollision = preload("uid://bjvt0an2jxbon")

#Camera
@onready var camera_3d: Camera3D = $Camera3D

#Collisions
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var ray_cast_3d: RayCast3D = $Camera3D/RayCast3D

#Main hand
@onready var animation_player: AnimationPlayer = $Camera3D/AnimationPlayer
@onready var gun_holder: Node3D = $Camera3D/GunHolder
@onready var main_hand: Node3D = $Camera3D/MainHand

@export var current_tool : Node3D
var current_tool_id := 0

#UI
@onready var jump_icons: VBoxContainer = $Control/JumpIcons
@onready var jump_icon: TextureRect = $Control/JumpIcons/JumpIcon
@onready var speed_label: Label = $Control/SpeedLabel
@onready var temp_speed_label: Label = $Control/TempSpeedLabel

#health
@export var health = 3

#Character movement management
@export var base_speed = 1
@export var base_jump_velocity = 10

var extra_temp_velocity := 1.0
var wall_velocity := Vector3.ZERO

#Parameters
@export var floor_damping := 0.9
@export var action_speed_multiplier := 1.0

@export var total_jumps := 3
var jumps_lefts := 3

var is_crouched := false

func _ready() -> void:
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera_3d.current = true
	
	for jump in total_jumps-1:
		var new_jump_icon = jump_icon.duplicate()
		jump_icons.add_child(new_jump_icon)

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.002)
		camera_3d.rotate_x(-event.relative.y * 0.002)
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, -PI/2, PI/2)
		
	if event.is_action_pressed("attack") and current_tool:
		current_tool.interact_start()
	if event.is_action_released("attack") and current_tool:
		current_tool.interact_stop()
		
	if event.is_action_pressed("scrollup"):
		change_tool(-1)
	if event.is_action_pressed("scrolldown"):
		change_tool(1)

func change_tool(direction := 0):
	current_tool.process_mode = Node.PROCESS_MODE_DISABLED
	current_tool.tool_hide()
	
	current_tool_id += direction
	var children = main_hand.get_children()
	if children.size() <= current_tool_id:
		current_tool_id = 0
	elif current_tool_id < 0:
		current_tool_id = children.size() -1
	current_tool = children[current_tool_id]
	current_tool.process_mode = Node.PROCESS_MODE_INHERIT
	current_tool.tool_show()

func _physics_process(delta: float) -> void:
	camera_3d.fov = clamp(75.0 + velocity.length() * 0.3, 75, 100)
		
	if not is_on_floor():
		velocity += Vector3(0, -25.0, 0) * delta
	
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# FLOOR MOVEMENT
	if is_on_floor():
		jumps_lefts = total_jumps
		if extra_temp_velocity > 1.0 and velocity.length() < 40.0:
			extra_temp_velocity *= 0.8
		elif extra_temp_velocity < 1.0:
			extra_temp_velocity = 1.0
		if input_dir:
			velocity.x += direction.x * base_speed * action_speed_multiplier
			velocity.z += direction.z * base_speed * action_speed_multiplier
		velocity.x *= floor_damping
		velocity.z *= floor_damping
		wall_velocity = Vector3.ZERO   # reset when grounded

	# WALL SLIDING
	elif is_on_wall():
		# project velocity along the wall so we "stick" instead of losing it
		var normal = get_wall_normal()
		if abs(normal.dot(Vector3.UP)) < 0.5 or true:
			wall_velocity = velocity.slide(normal)
			velocity = wall_velocity.clamp(Vector3(-100, -100, -100), Vector3(100, 100, 100))
			extra_temp_velocity = wall_velocity.length() * 0.1
			velocity.y -= 9.8 * delta  # gravity down slide
		if input_dir:
			velocity.x = lerp(velocity.x, direction.x * (base_speed * 10 * extra_temp_velocity), 1.8 * delta)
			velocity.z = lerp(velocity.z, direction.z * (base_speed * 10 * extra_temp_velocity), 1.8 * delta)

	# AIR MOVEMENT
	else:
		# If input lerp toward input direction
		if input_dir:
			if extra_temp_velocity < 6.0:
				extra_temp_velocity += 0.8 * delta
			velocity.x = lerp(velocity.x, direction.x * (base_speed * 10 * extra_temp_velocity), 2 * delta)
			velocity.z = lerp(velocity.z, direction.z * (base_speed * 10 * extra_temp_velocity), 2 * delta)
		velocity.x *= 0.99
		velocity.z *= 0.99
	
	#Interface
	var id := 0
	for jump_icon_child in jump_icons.get_children():
		if jumps_lefts > id:
			jump_icon_child.modulate.a = 1.0
		else:
			jump_icon_child.modulate.a = 0.0
		id += 1
	
	temp_speed_label.text = str(round(extra_temp_velocity*10)*0.1)
	speed_label.text = str(round(self.velocity.length()))
	
	
	# Handle jump.
	if Input.is_action_pressed("jump"):
		if jumps_lefts > 0:
			if is_on_floor():
				jumps_lefts -= 1
				velocity += get_floor_normal() * base_jump_velocity
			elif Input.is_action_just_pressed("jump"):
				jumps_lefts -= 1
				if velocity.y > 0:
					velocity.y += base_jump_velocity
				else:
					velocity.y = base_jump_velocity
		elif is_on_wall():
			var normal = get_wall_normal()
			if abs(normal.dot(Vector3.UP)) > 0.5:
				velocity += normal * base_jump_velocity
				velocity.y = -velocity.y
				wall_velocity = Vector3.ZERO
	
	
	if Input.is_action_pressed("crouch"):
		if not is_crouched and velocity.length() < 20:
			velocity += direction*10
		is_crouched = true
		collision_shape_3d.shape.height = 1.3
		floor_damping = 0.99
		action_speed_multiplier = 0.1
		floor_max_angle = 0.05 #0.05*PI
	elif collision_shape_3d.shape.height != 2.0:
		is_crouched = false
		collision_shape_3d.shape.height = 2.0
		floor_damping = 0.9
		action_speed_multiplier = 1.0
		floor_max_angle = 0.4*PI
	
	if animation_player.current_animation == "shoot":
		pass
	elif input_dir != Vector2.ZERO and is_on_floor():
		animation_player.play("move")
	else:
		animation_player.play("idle")

	move_and_slide()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "shoot":
		animation_player.play("idle")


func _on_hitbox_area_entered(area: Area3D) -> void:
	print("collided")
	if area.get_parent().is_in_group("deadly"):
		die()
	
func die():
	self.global_position = Vector3(-1.2, 82, 1)
	print("ded")
	
