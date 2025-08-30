@tool
extends MeshInstance3D

@onready var collision_shape_3d: CollisionShape3D = $StaticBody3D/CollisionShape3D # collision shape that only has 1/4 of the vertex of the mesh
@onready var collision_shape_rigid: CollisionShape3D = $StaticBody3D2/CollisionShapeRigid

@export var mesh_simplify := 4.0
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

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	# Get the noise textures from the shader material
	mat = material_override
	if mat is ShaderMaterial:
		noise_texture = mat.get_shader_parameter("noise_texture")
		noise_overlay = mat.get_shader_parameter("noise_overlay")
		wave_amplitude = mat.get_shader_parameter("wave_amplitude")
		noise_scale = mat.get_shader_parameter("noise_scale")
	subdivide_width = mesh.subdivide_width
	subdivide_depth = mesh.subdivide_depth
	sides_x = mesh.size.x
	sides_y = mesh.size.y
	
func generate_collisions() -> void:
	#if not Engine.is_editor_hint():
		#return
	
	#print("Generating heightmap collisions...")
	
	# Get the shader material and noise textures
	wave_amplitude = mat.get_shader_parameter("wave_amplitude")
	noise_scale = mat.get_shader_parameter("noise_scale")
	mat = material_override
	if not mat or not mat is ShaderMaterial:
		push_error("No ShaderMaterial found!")
		return
	
	if not noise_texture or not noise_overlay:
		push_error("Noise textures not found in shader!")
		return
	
	# Get the mesh AABB to determine the size
	var aabb = mesh.get_aabb()
	var size_x = int(subdivide_width*(1.0/mesh_simplify)) +1
	var size_z = int(subdivide_depth*(1.0/mesh_simplify)) +1
	
	# Create heightmap data
	var heightmap_data = PackedFloat32Array()
	heightmap_data.resize(size_x * size_z)
	
	# Get the noise images
	var noise_img: Image = noise_texture.get_image()
	var overlay_img: Image = noise_overlay.get_image()
	
	# Make sure images are readable
	if noise_img == null or overlay_img == null:
		push_error("Could not get image data from noise textures!")
		return
	
	# Fill heightmap data by sampling noise textures
	for z in range(size_z):
		for x in range(size_x):
			# Use LOCAL coordinates like the shader does (VERTEX.xz)
			# The shader uses VERTEX.xz which are local mesh coordinates
			var local_x = aabb.position.x + x * mesh_simplify * (sides_x / subdivide_width)
			var local_z = aabb.position.z + z * mesh_simplify * (sides_y / subdivide_depth)
			
			# Use local coordinates for noise sampling (like VERTEX.xz in shader)
			var noise_uv = Vector2(local_x, local_z) * noise_scale
			
			# Calculate texture coordinates with time offset (same as shader)
			var noise_uv1 = noise_uv + Vector2(time * 0.1, time * 0.1)
			var noise_uv2 = noise_uv - Vector2(time * 0.02, time * 0.02)
			
			# Sample noise textures using get_pixel()
			var noise1 = sample_texture(noise_img, noise_uv1)
			var noise2 = sample_texture(overlay_img, noise_uv2)
			
			# Combine noise (same calculation as shader)
			var combined_noise = noise1 + noise2 - 0.5
			
			# Apply displacement (same as shader)
			var height = combined_noise * wave_amplitude
			
			# Store height in the heightmap
			heightmap_data[z * size_x + x] = height
	
	
	# Create HeightMapShape3D
	var heightmap_shape = HeightMapShape3D.new()
	heightmap_shape.map_width = size_x
	heightmap_shape.map_depth = size_z
	heightmap_shape.map_data = heightmap_data
	
	# Set the collision shape
	collision_shape_3d.shape = heightmap_shape
	collision_shape_rigid.shape = heightmap_shape
	collision_shape_3d.scale = Vector3(mesh_simplify*(sides_x/subdivide_width), 1.0, mesh_simplify*(sides_y/subdivide_depth))
	collision_shape_rigid.scale = collision_shape_3d.scale
	collision_shape_rigid.position.y = -1
	print("Heightmap collisions generated with resolution ", size_x, "x", size_z)

func sample_texture(image: Image, uv: Vector2) -> float:
	# Convert UV coordinates to pixel coordinates with wrapping
	var width = image.get_width()
	var height = image.get_height()
	
	# Handle UV wrapping (same as texture() in shader)
	var wrapped_u = wrapf(uv.x, 0.0, 1.0)
	var wrapped_v = wrapf(uv.y, 0.0, 1.0)
	
	var x = int(wrapped_u * width) % width
	var y = int(wrapped_v * height) % height
	
	# Sample the red channel (assuming grayscale noise)
	return image.get_pixel(x, y).r
# Optional: Update collisions in real-time if needed
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	time += delta*0.5
	material_override.set_shader_parameter("time", time)
		# Uncomment the line below if you want real-time collision updates
		# generate_collisions()


func _on_collider_timer_timeout() -> void:
	var player_vertical_vec := player.global_position
	var self_vectical_vec := self.global_position
	
	if player_vertical_vec.y < self_vectical_vec.y + 20:
		player_vertical_vec.y = 0.0
		self_vectical_vec.y = 0.0
		
		if player_vertical_vec.distance_to(self_vectical_vec) < mesh.get_aabb().size.x*0.75:
			if collision_shape_3d.disabled:
				collision_shape_3d.set("disabled", false)
			generate_collisions()
	else:
		if not collision_shape_3d.disabled:
			collision_shape_3d.set("disabled", true)
