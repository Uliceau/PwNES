extends MultiplayerSynchronizer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(replication_config.get_properties())
