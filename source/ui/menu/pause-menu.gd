extends CanvasLayer

signal resume_pressed
signal save_pressed
signal exit_pressed

@onready var resume_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Resume
@onready var save_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Save
@onready var exit_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Exit

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_resume_pressed() -> void:
	SoundManager.play_sfx("click")
	resume_pressed.emit()

func _on_save_pressed() -> void:
	SoundManager.play_sfx("click")
	save_pressed.emit()

func _on_exit_pressed() -> void:
	SoundManager.play_sfx("click")
	exit_pressed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE)):
		resume_pressed.emit()
		get_viewport().set_input_as_handled()
