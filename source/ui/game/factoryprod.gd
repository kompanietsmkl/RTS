extends CanvasLayer

func _ready() -> void:
	# Скрываем при старте (если нужно)
	visible = false
	GameManager.toggle_factory_ui.connect(_on_toggle_factory_ui)

func _on_toggle_factory_ui():
	visible = not visible
