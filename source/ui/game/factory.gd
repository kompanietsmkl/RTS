extends CanvasLayer

func _ready() -> void:
	visible = false
	GameManager.toggle_factory_ui.connect(_on_toggle_factory_ui)
	GameManager.close_all_ui.connect(_on_close_all)

func _on_toggle_factory_ui():
	visible = not visible

func _on_close_all():
	visible = false
