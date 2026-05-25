extends Control

@onready var gatherer_count = $DroneSet/Gatherer/Panel/CountLabel
@onready var defender_count = $DroneSet/Defender/Panel/CountLabel

func _ready() -> void:
	GameManager.drones_count_changed.connect(_on_drones_count_changed)
	_on_drones_count_changed(GameManager.total_gatherers, GameManager.total_defenders)

func _on_drones_count_changed(g_count: int, d_count: int):
	if is_instance_valid(gatherer_count):
		gatherer_count.text = str(g_count)
	if is_instance_valid(defender_count):
		defender_count.text = str(d_count)
