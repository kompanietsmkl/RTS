extends CanvasLayer

func _ready() -> void:
	visible = false
	GameManager.toggle_commandcenter_ui.connect(_on_toggle)
	GameManager.close_all_ui.connect(_on_close_all)

func _on_toggle() -> void:
	visible = not visible

func _on_close_all() -> void:
	visible = false
