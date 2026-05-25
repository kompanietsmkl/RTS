extends Node

# Music streams
var menu_music = preload("res://assets/audio/main_menu_background.mp3")
var game_music = preload("res://assets/audio/game_background.mp3")

# Sound effects
var sfx_click = preload("res://assets/audio/menu_click.wav")
var sfx_open = preload("res://assets/audio/menu_open.wav")
var sfx_alert = preload("res://assets/audio/alert.wav")
var sfx_production = preload("res://assets/audio/drone_in_production.wav")

var player_menu: AudioStreamPlayer
var player_game: AudioStreamPlayer

func _ready() -> void:
	# Make sure SoundManager processes even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Set loop on music streams
	if menu_music is AudioStreamMP3:
		menu_music.loop = true
	if game_music is AudioStreamMP3:
		game_music.loop = true
		
	# Create audio players
	player_menu = AudioStreamPlayer.new()
	player_menu.stream = menu_music
	player_menu.bus = "Music"
	add_child(player_menu)
	
	player_game = AudioStreamPlayer.new()
	player_game.stream = game_music
	player_game.bus = "Music"
	add_child(player_game)
	
	# Connect to GameManager alerts to play sounds automatically
	GameManager.show_alert.connect(_on_show_alert)
	
	# Start playing main menu music on boot
	play_menu_music()

func play_menu_music(fade_duration: float = 1.5) -> void:
	_crossfade(player_game, player_menu, fade_duration)

func play_game_music(fade_duration: float = 1.5) -> void:
	_crossfade(player_menu, player_game, fade_duration)

func stop_all_music(fade_duration: float = 1.0) -> void:
	var tween = create_tween().set_parallel(true)
	if player_menu.playing:
		tween.tween_property(player_menu, "volume_db", -80.0, fade_duration)
	if player_game.playing:
		tween.tween_property(player_game, "volume_db", -80.0, fade_duration)
	await tween.finished
	player_menu.stop()
	player_game.stop()

func _crossfade(from_player: AudioStreamPlayer, to_player: AudioStreamPlayer, duration: float) -> void:
	# If target is already playing and volume is normal, don't restart it
	if to_player.playing:
		# Just make sure it fades in if it was silent
		var tween = create_tween()
		tween.tween_property(to_player, "volume_db", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		to_player.volume_db = -80.0
		to_player.play()
		var tween = create_tween()
		tween.tween_property(to_player, "volume_db", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	# Fade out source
	if from_player.playing:
		var tween = create_tween()
		tween.tween_property(from_player, "volume_db", -80.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_callback(from_player.stop)

# SFX Helper
func play_sfx(sfx_name: String) -> void:
	var stream: AudioStream = null
	match sfx_name.to_lower():
		"click", "menu_click":
			stream = sfx_click
		"open", "menu_open":
			stream = sfx_open
		"alert":
			stream = sfx_alert
		"production", "drone_in_production":
			stream = sfx_production
			
	if stream:
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.stream = stream
		sfx_player.bus = "SFX"
		add_child(sfx_player)
		sfx_player.play()
		sfx_player.finished.connect(sfx_player.queue_free)

func _on_show_alert(_message: String, type: int) -> void:
	# Play alert sound for warnings and errors
	if type == GameManager.AlertType.WARNING or type == GameManager.AlertType.ERROR:
		play_sfx("alert")

# Volume control helpers (value between 0.0 and 1.0)
func set_music_volume(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func set_sfx_volume(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func get_music_volume() -> float:
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	return 1.0

func get_sfx_volume() -> float:
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	return 1.0
