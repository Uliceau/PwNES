extends Node3D

const CameraPortal = preload("uid://bsv815k5nxrgj")

@onready var portal_mesh: MeshInstance3D = $PortalMesh
@onready var camera_3d: Camera3D = $SubViewport/Camera3D
@onready var collision_inside: Area3D = $CollisionInside
@onready var collision_inside_shape_3d: CollisionShape3D = $CollisionInside/CollisionShape3D
@onready var distort: Sprite3D = $Distort

@onready var collision_outside: Area3D = $CollisionOutside

@export var portal_end: CameraPortal
const Player = preload("uid://c6p3o8fitt0i3")

func _physics_process(delta: float) -> void:
	# Get player position relative to this portal
	var local_pos : Transform3D = global_transform.affine_inverse() * Global.player.camera_3d.global_transform
	# Rotate 180 degrees around Y to "look back through" the portal
	local_pos = local_pos.rotated(Vector3.UP, PI)
	
	#local_pos = local_pos.rotated(Vector3.FORWARD, PI)
	#local_pos.origin.y = -local_pos.origin.y
	
	camera_3d.global_transform = portal_end.global_transform * local_pos
	camera_3d.fov = Global.player.camera_3d.fov + 30
	camera_3d.near = abs(self.global_position - Global.player.global_position).length()
	#if self.global_position.y < portal_end.global_position.y:
		#camera_3d.global_transform.origin.y -= portal_end.global_position.y - self.global_position.y
	#if name == "Portal2":
		#print(camera_3d.global_position.y)
	
	
func _on_collision_inside_body_entered(body: Node3D) -> void:
	if body is Player:
		body.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		#portal_end.collision_inside_shape_3d.disabled = true
		portal_mesh.mesh.flip_faces = true
		distort.hide()
		portal_end.distort.hide()
		
		portal_mesh.mesh.radius = 10
		portal_mesh.mesh.height = 20.0


func _on_collision_outside_body_exited(body: Node3D) -> void:
	if body is Player:
		portal_end.portal_mesh.mesh.flip_faces = false
		distort.show()
		portal_end.distort.show()
		#collision_inside_shape_3d.disabled = false
		print("entered")
		var relative_pos := body.global_position - self.global_position
		var new_pos := relative_pos.rotated(Vector3(0, 1, 0), PI)
		body.global_position = portal_end.global_position + new_pos
		body.rotation.y += PI
		body.velocity.x*=-1
		body.velocity.z*=-1
		portal_mesh.mesh.radius = 5.0
		portal_mesh.mesh.height = 10.0
		#body.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_INHERIT
