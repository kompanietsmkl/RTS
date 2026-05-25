extends CanvasLayer

signal new_game_pressed
signal load_save_pressed

@onready var new_game_button: Button = $CenterContainer/VBoxContainer/NewGame
@onready var load_save_button: Button = $CenterContainer/VBoxContainer/LoadSave
@onready var exit_button: Button = $CenterContainer/VBoxContainer/Exit

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_save_button.pressed.connect(_on_load_save_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_new_game_pressed() -> void:
	SoundManager.play_sfx("click")
	new_game_pressed.emit()

func _on_load_save_pressed() -> void:
	SoundManager.play_sfx("click")
	load_save_pressed.emit()

func _on_exit_pressed() -> void:
	SoundManager.play_sfx("click")
	get_tree().quit()
