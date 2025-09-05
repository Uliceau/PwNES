@tool
extends MeshInstance3D

@onready var collision_shape_3d: CollisionShape3D = $StaticBody3D/CollisionShape3D
@onready var collision_shape_rigid: CollisionShape3D = $StaticBody3D2/CollisionShapeRigid

@export var mesh_simplify := 4.0
@export var collision_radius := 20.0
const Player = preload("uid://c6p3o8fitt0i3")

@export_tool_button("generate") var test := generate_collisions

var noise_texture: NoiseTexture2D
var noise_overlay: NoiseTexture2D
var time: float = 0.0
var player : Node3D
var mat : Material
var wave_amplitude := 4.0
var noise_scale := 0.01

var subdivide_width : float
var subdivide_depth : float
var sides_x : float
var sides_y : float
var last_update_time := 0.0
var center_position := Vector3.ZERO

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	
	mat = material_override
	
	if mat is ShaderMaterial:
		noise_texture = mat.get_shader_parameter("noise_texture")
		noise_overlay = mat.get_shader_parameter("noise_overlay")
		wave_amplitude = mat.get_shader_parameter("wave_amplitude")
		noise_scale = mat.get_shader_parameter("noise_scale")
	
	if mesh:
		subdivide_width = mesh.subdivide_width
		subdivide_depth = mesh.subdivide_depth
		sides_x = mesh.size.x
		sides_y = mesh.size.y

func generate_collisions(around_position: Vector3 = Vector3.ZERO) -> void:
	
	wave_amplitude = mat.get_shader_parameter("wave_amplitude")
	noise_scale = mat.get_shader_parameter("noise_scale")
	mat = material_override
	if not mat or not mat is ShaderMaterial:
		push_error("No ShaderMaterial found")
		return
	
	var aabb = mesh.get_aabb()
	var local_around = to_local(around_position)
	
	var min_x = max(aabb.position.x, local_around.x - collision_radius)
	var max_x = min(aabb.end.x, local_around.x + collision_radius)
	var min_z = max(aabb.position.z, local_around.z - collision_radius)
	var max_z = min(aabb.end.z, local_around.z + collision_radius)
	
	var section_size_x = int((max_x - min_x) / mesh_simplify) + 1
	var section_size_z = int((max_z - min_z) / mesh_simplify) + 1
	
	if section_size_x <= 2 or section_size_z <= 2:
		return
	
	var heightmap_data = PackedFloat32Array()
	heightmap_data.resize(section_size_x * section_size_z)
	
	var noise_img: Image = noise_texture.get_image()
	var overlay_img: Image = noise_overlay.get_image()
	
	if noise_img == null or overlay_img == null:
		push_error("Could not get image data from noise textures!")
		return
	
	for z in range(section_size_z):
		for x in range(section_size_x):
			
			var world_x = min_x + x * mesh_simplify
			var world_z = min_z + z * mesh_simplify
			
			var local_x = world_x
			var local_z = world_z
			
			var noise_uv = Vector2(local_x, local_z) * noise_scale
			
			var noise_uv1 = noise_uv + Vector2(time * 0.1, time * 0.1)
			var noise_uv2 = noise_uv - Vector2(time * 0.02, time * 0.02)
			
			var noise1 = sample_texture(noise_img, noise_uv1)
			var noise2 = sample_texture(overlay_img, noise_uv2)
			
			var combined_noise = noise1 + noise2 - 0.5
			
			var height = combined_noise * wave_amplitude
			
			heightmap_data[z * section_size_x + x] = height
	
	var heightmap_shape = HeightMapShape3D.new()
	heightmap_shape.map_width = section_size_x
	heightmap_shape.map_depth = section_size_z
	heightmap_shape.map_data = heightmap_data
	
	collision_shape_3d.shape = heightmap_shape
	
	collision_shape_3d.global_position = Vector3(
		global_position.x + min_x + (section_size_x * mesh_simplify) / 2.0,
		global_position.y  + 1.2,
		global_position.z + min_z + (section_size_z * mesh_simplify) / 2.0
	)
	
	collision_shape_3d.scale = Vector3(mesh_simplify, 1.0, mesh_simplify)
	
	collision_shape_rigid.shape = heightmap_shape
	collision_shape_rigid.global_position = collision_shape_3d.global_position
	collision_shape_rigid.scale = collision_shape_3d.scale

func sample_texture(image: Image, uv: Vector2) -> float:
	var width = image.get_width()
	var height = image.get_height()
	
	var wrapped_u = wrapf(uv.x, 0.0, 1.0)
	var wrapped_v = wrapf(uv.y, 0.0, 1.0)
	
	var x = int(wrapped_u * width) % width
	var y = int(wrapped_v * height) % height
	
	return image.get_pixel(x, y).r

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	time += delta * 0.1
	material_override.set_shader_parameter("time", time)
	
	# Update collisions periodically around player

func _on_collider_timer_timeout() -> void:
	var player_vertical_vec := player.global_position
	var self_vertical_vec := global_position
	
	if player_vertical_vec.y < self_vertical_vec.y + wave_amplitude:
		player_vertical_vec.y = 0.0
		self_vertical_vec.y = 0.0
		
		if player_vertical_vec.distance_to(self_vertical_vec) < mesh.get_aabb().size.x * 0.75:
			if collision_shape_3d.disabled:
				collision_shape_3d.set_deferred("disabled", false)
			generate_collisions(player.global_position)
	else:
		if not collision_shape_3d.disabled:
			collision_shape_3d.set_deferred("disabled", true)
