extends Control

@onready var limit_label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/DroneLabel

func _ready() -> void:
	GameManager.drone_limit_changed.connect(_on_drone_limit_changed)
	
	GameManager._emit_drone_limit()

func _on_drone_limit_changed(current: int, max_limit: int) -> void:
	if limit_label:
		limit_label.text = str(current) + "/" + str(max_limit)
