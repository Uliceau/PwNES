extends CSGCombiner3D

@onready var csg_sphere_3d: CSGSphere3D = $DissolvableWall/CSGSphere3D
@onready var dissolvable_wall: CSGBox3D = $DissolvableWall

var is_dissolving := false
var dissolve_time := 5.0

func trigger_disolve(pos : Vector3 = Vector3.ZERO):
	if is_dissolving:
		return
	is_dissolving = true
	csg_sphere_3d.show()
	dissolvable_wall.material.set("shader_parameter/sphere_position", pos)
	csg_sphere_3d.global_position = pos
	var tween : Tween = create_tween()
	tween.parallel().tween_property(dissolvable_wall.material, "shader_parameter/sphere_radius", dissolvable_wall.size.length(), dissolve_time).from(0.0)
	tween.parallel().tween_property(csg_sphere_3d, "radius", dissolvable_wall.size.length(), dissolve_time).from(0.0)
	await tween.finished
	queue_free()
	pass
