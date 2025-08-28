extends Node

@onready var label_3d: Label3D = $Label3D
@onready var player: CharacterBody3D = $".."

@export var health = 3

func _physics_process(delta: float) -> void:
	health += 1
	label_3d.text = str(health)
