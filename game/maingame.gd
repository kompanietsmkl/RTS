extends Node

const GATHERER_SCENE = preload("res://source/units/drones/drone_gatherer.tscn")
const DEFENDER_SCENE = preload("res://source/units/drones/drone_defender.tscn")
const ALIEN_SCENE = preload("res://source/units/aliens/alien.tscn")
const CATALYST_SCENE = preload("res://source/units/aliens/catalyst.tscn")


@onready var main_menu = $UI/MainMenu
@onready var pause_menu = $UI/PauseMenu
@onready var hud = $UI/HUD
@onready var factory_ui = $UI/FactoryUI
@onready var cc_ui = $UI/CommandCenterUI
@onready var game_over = $UI/GameOver
@onready var factory = $NavigationRegion3D/GAME_ENTITIES/Factory
@onready var command_base = $NavigationRegion3D/GAME_ENTITIES/CommandBase
@onready var wave_manager = $WaveManager
@onready var crystals_container = $NavigationRegion3D/GAME_ENTITIES/CrystalsContainer

func _ready() -> void:
	# Connect menu signals
	main_menu.new_game_pressed.connect(_on_new_game)
	main_menu.load_save_pressed.connect(_on_load_save)
	
	pause_menu.resume_pressed.connect(_on_resume)
	pause_menu.save_pressed.connect(_on_save)
	pause_menu.exit_pressed.connect(_on_exit_to_main_menu)
	
	game_over.screen_clicked.connect(_on_game_over_clicked)
	GameManager.base_destroyed.connect(_on_base_destroyed)
	
	# Connect UI toggle events to play open sound effects
	GameManager.toggle_factory_ui.connect(func(): SoundManager.play_sfx("menu_open"))
	GameManager.toggle_commandcenter_ui.connect(func(): SoundManager.play_sfx("menu_open"))
	
	if GameManager.should_start_directly:
		GameManager.should_start_directly = false
		main_menu.visible = false
		pause_menu.visible = false
		hud.visible = true
		factory_ui.visible = false
		cc_ui.visible = false
		game_over.visible = false
		get_tree().paused = false
		SoundManager.play_game_music()
	elif GameManager.should_load_save:
		GameManager.should_load_save = false
		_load_game_now()
	else:
		# Show Main Menu, hide others at start
		main_menu.visible = true
		pause_menu.visible = false
		hud.visible = false
		factory_ui.visible = false
		cc_ui.visible = false
		game_over.visible = false
		
		# Pause the game at start
		get_tree().paused = true
		SoundManager.play_menu_music()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		# Only open pause menu if we are not in the main menu and not already paused
		if not main_menu.visible and not get_tree().paused:
			_on_pause()


func _on_pause() -> void:
	SoundManager.play_sfx("menu_open")
	pause_menu.visible = true
	get_tree().paused = true

func _on_resume() -> void:
	SoundManager.play_sfx("menu_click")
	pause_menu.visible = false
	get_tree().paused = false

func _on_new_game() -> void:
	GameManager.reset_state()
	GameManager.should_start_directly = true
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_base_destroyed() -> void:
	hud.visible = false
	factory_ui.visible = false
	cc_ui.visible = false
	pause_menu.visible = false
	GameManager.close_all_ui.emit()
	
	get_tree().paused = true
	game_over.visible = true

func _on_game_over_clicked() -> void:
	game_over.visible = false
	_on_exit_to_main_menu()

func _on_exit_to_main_menu() -> void:
	# Hide pause menu and hud
	pause_menu.visible = false
	hud.visible = false
	factory_ui.visible = false
	cc_ui.visible = false
	
	# Close all dialog UIs
	GameManager.close_all_ui.emit()
	
	# Show Main Menu
	main_menu.visible = true
	
	# Keep game paused
	get_tree().paused = true
	SoundManager.play_menu_music()

func _on_save() -> void:
	var save_data = {}
	
	# 1. GameManager stats
	save_data["game_manager"] = {
		"credits": GameManager.credits,
		"base_level": GameManager.base_level,
		"energy_gathering": GameManager.energy_gathering,
		"energy_defense": GameManager.energy_defense,
		"energy_production": GameManager.energy_production
	}
	
	# 2. WaveManager state
	if is_instance_valid(wave_manager):
		save_data["wave_manager"] = {
			"wave_number": wave_manager.wave_number,
			"wave_timer": wave_manager.wave_timer,
			"time_to_next_wave": wave_manager.time_to_next_wave,
			"warning_shown": wave_manager.warning_shown,
			"previous_wave_size": wave_manager.previous_wave_size
		}
	
	# 3. Buildings state
	save_data["command_base"] = {
		"health": command_base.current_health if is_instance_valid(command_base) else 0.0
	}
	save_data["factory"] = {
		"is_built": factory.is_built if is_instance_valid(factory) else false,
		"current_level": factory.current_level if is_instance_valid(factory) else 0,
		"health": factory.current_health if is_instance_valid(factory) else 0.0
	}
	
	# 4. Crystals
	var crystals_data = []
	if is_instance_valid(crystals_container):
		for crystal in crystals_container.get_children():
			if is_instance_valid(crystal):
				crystals_data.append({
					"name": crystal.name,
					"resources": crystal.current_resources
				})
	save_data["crystals"] = crystals_data
	
	# 5. Drones
	var drones_data = []
	for child in get_children():
		if is_instance_valid(child) and child is DroneBase:
			var type = ""
			if child.has_method("find_new_crystal"): # drone_gatherer
				type = "gatherer"
			else: # drone_defender
				type = "defender"
			
			drones_data.append({
				"type": type,
				"position": [child.global_position.x, child.global_position.y, child.global_position.z],
				"health": child.current_health
			})
	save_data["drones"] = drones_data
	
	# 6. Aliens
	var aliens_data = []
	var aliens = get_tree().get_nodes_in_group("aliens")
	for alien in aliens:
		if is_instance_valid(alien):
			var type = "spider"
			if alien.is_in_group("catalysts"):
				type = "catalyst"
			aliens_data.append({
				"type": type,
				"position": [alien.global_position.x, alien.global_position.y, alien.global_position.z],
				"health": alien.current_health
			})
	save_data["aliens"] = aliens_data
	
	# Write to file
	var file = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		GameManager.show_alert.emit("Game saved successfully!", GameManager.AlertType.SUCCESS)
	else:
		GameManager.show_alert.emit("Failed to save game!", GameManager.AlertType.ERROR)

func _on_load_save() -> void:
	if not FileAccess.file_exists("user://save_game.json"):
		GameManager.show_alert.emit("No save file found!", GameManager.AlertType.WARNING)
		return
		
	GameManager.should_load_save = true
	get_tree().paused = false
	get_tree().reload_current_scene()

func _load_game_now() -> void:
	var file = FileAccess.open("user://save_game.json", FileAccess.READ)
	if not file:
		GameManager.show_alert.emit("Failed to open save file!", GameManager.AlertType.ERROR)
		return
		
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		GameManager.show_alert.emit("Save file is corrupted!", GameManager.AlertType.ERROR)
		return
		
	var save_data = json.data
	
	# 1. Clear existing Drones and Aliens (instantly via free())
	for child in get_children():
		if is_instance_valid(child) and child is DroneBase:
			child.free()
			
	var aliens = get_tree().get_nodes_in_group("aliens")
	for alien in aliens:
		if is_instance_valid(alien):
			alien.free()
			
	# Reset active counters so spawned drones can re-claim them
	GameManager.active_gatherers = 0
	GameManager.active_defenders = 0
	GameManager.active_production = 0
	GameManager.active_productions_list.clear()
	
	# 2. Restore GameManager stats
	var gm_data = save_data.get("game_manager", {})
	GameManager.credits = gm_data.get("credits", 1000)
	GameManager.base_level = gm_data.get("base_level", 1)
	GameManager.energy_gathering = gm_data.get("energy_gathering", 0)
	GameManager.energy_defense = gm_data.get("energy_defense", 0)
	GameManager.energy_production = gm_data.get("energy_production", 0)
	
	# Force UI distribution update
	GameManager.energy_distribution_changed.emit(
		GameManager.energy_gathering,
		GameManager.energy_defense,
		GameManager.energy_production
	)
	
	# 3. Restore WaveManager state
	var wm_data = save_data.get("wave_manager", {})
	if is_instance_valid(wave_manager) and not wm_data.is_empty():
		wave_manager.wave_number = wm_data.get("wave_number", 0)
		wave_manager.wave_timer = wm_data.get("wave_timer", 0.0)
		wave_manager.time_to_next_wave = wm_data.get("time_to_next_wave", 60.0)
		wave_manager.warning_shown = wm_data.get("warning_shown", false)
		wave_manager.previous_wave_size = wm_data.get("previous_wave_size", 0)
		
	# 4. Restore Buildings state
	var cb_data = save_data.get("command_base", {})
	if is_instance_valid(command_base):
		command_base.load_state(GameManager.base_level, cb_data.get("health", command_base.max_health))
		
	var fact_data = save_data.get("factory", {})
	if is_instance_valid(factory):
		factory.load_state(
			fact_data.get("is_built", false),
			fact_data.get("current_level", 0),
			fact_data.get("health", factory.max_health)
		)
		
	# 5. Restore Crystals resources
	var crystals_data = save_data.get("crystals", [])
	if is_instance_valid(crystals_container):
		for crystal in crystals_container.get_children():
			if is_instance_valid(crystal):
				var found = false
				for c_data in crystals_data:
					if c_data.get("name") == crystal.name:
						crystal.current_resources = c_data.get("resources", crystal.max_resources)
						if crystal.has_node("Resourcebar"):
							crystal.get_node("Resourcebar").init_resource(crystal.max_resources, crystal.current_resources)
						
						if crystal.current_resources <= 0.01:
							crystal.get_node("MeshInstance3D").visible = false
							crystal.get_node("CollisionShape3D").set_deferred("disabled", true)
							crystal.remove_from_group("crystals")
						else:
							crystal.get_node("MeshInstance3D").visible = true
							crystal.get_node("CollisionShape3D").set_deferred("disabled", false)
							if not crystal.is_in_group("crystals"):
								crystal.add_to_group("crystals")
						found = true
						break
				if not found:
					crystal.current_resources = crystal.max_resources
					if crystal.has_node("Resourcebar"):
						crystal.get_node("Resourcebar").init_resource(crystal.max_resources, crystal.current_resources)
	
	# 6. Instantiate Drones
	var drones_data = save_data.get("drones", [])
	for d_data in drones_data:
		var type = d_data.get("type", "gatherer")
		var pos_arr = d_data.get("position", [0.0, 0.0, 0.0])
		var pos = Vector3(pos_arr[0], pos_arr[1], pos_arr[2])
		var health = d_data.get("health", 100.0)
		
		var drone_instance = null
		if type == "gatherer":
			drone_instance = GATHERER_SCENE.instantiate()
		elif type == "defender":
			drone_instance = DEFENDER_SCENE.instantiate()
			
		if drone_instance:
			add_child(drone_instance)
			drone_instance.global_position = pos
			drone_instance.current_health = health
			
	# 7. Instantiate Aliens
	var aliens_data = save_data.get("aliens", [])
	for a_data in aliens_data:
		var type = a_data.get("type", "spider")
		var pos_arr = a_data.get("position", [0.0, 0.0, 0.0])
		var pos = Vector3(pos_arr[0], pos_arr[1], pos_arr[2])
		var health = a_data.get("health", 100.0)
		
		var alien_instance = null
		if type == "catalyst":
			alien_instance = CATALYST_SCENE.instantiate()
		else:
			alien_instance = ALIEN_SCENE.instantiate()
			
		if alien_instance:
			get_tree().current_scene.add_child(alien_instance)
			alien_instance.global_position = pos
			alien_instance.current_health = health
			if alien_instance.has_node("Healthbar"):
				alien_instance.get_node("Healthbar").init_health(alien_instance.max_health, health)
				
	# Re-bake navmesh
	await get_tree().physics_frame
	_bake_navmesh()
	
	# Hide Main Menu, show HUD, and unpause
	main_menu.visible = false
	hud.visible = true
	game_over.visible = false
	get_tree().paused = false
	SoundManager.play_game_music()
	GameManager.show_alert.emit("Game loaded successfully!", GameManager.AlertType.SUCCESS)

func _bake_navmesh() -> void:
	var nav_region = get_tree().root.find_child("NavigationRegion3D", true, false)
	if nav_region and nav_region is NavigationRegion3D:
		nav_region.bake_navigation_mesh()
