extends Node

signal credits_changed(new_amount)
signal energy_distribution_changed(gathering, defense, production)
signal base_level_changed(new_level, new_max_energy)
signal toggle_factory_ui()
signal toggle_commandcenter_ui()
signal close_all_ui()
signal drones_count_changed(gatherers_total, defenders_total)
signal production_added(id: int, unit_data: UnitData)
signal production_progress(id: int, time_left: float, duration: float)
signal production_completed(id: int)
signal drone_limit_changed(current, max_limit)
signal base_destroyed()
signal wave_started(wave_number: int)

enum AlertType { INFO, SUCCESS, WARNING, ERROR }
signal show_alert(message: String, type: AlertType)

var active_ui: String = ""
var should_start_directly: bool = false
var should_load_save: bool = false

func _ready() -> void:
	await get_tree().physics_frame
	_bake_initial_navmesh()

func _bake_initial_navmesh():
	var nav_region = get_tree().root.find_child("NavigationRegion3D", true, false)
	if nav_region and nav_region is NavigationRegion3D:
		nav_region.bake_navigation_mesh()
		print("Global NavMesh successfully baked!")
	else:
		print("WARNING: Could not find NavigationRegion3D on start!")

func toggle_ui(ui_name: String) -> void:
	if active_ui == ui_name:
		active_ui = ""
		close_all_ui.emit()
	else:
		active_ui = ui_name
		close_all_ui.emit()
		if ui_name == "factory":
			toggle_factory_ui.emit()
		elif ui_name == "commandcenter":
			toggle_commandcenter_ui.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if active_ui != "":
			active_ui = ""
			close_all_ui.emit()

var credits: int = 1000:
	set(value):
		credits = value
		credits_changed.emit(credits)

var total_gatherers: int = 0:
	set(value):
		total_gatherers = value
		drones_count_changed.emit(total_gatherers, total_defenders)
		_emit_drone_limit()

var total_defenders: int = 0:
	set(value):
		total_defenders = value
		drones_count_changed.emit(total_gatherers, total_defenders)
		_emit_drone_limit()

var base_level: int = 1:
	set(value):
		base_level = value
		max_energy = 5 + (base_level - 1) * 2
		max_drones = 4 + (base_level - 1) * 2
		base_level_changed.emit(base_level, max_energy)
		_emit_drone_limit()

var max_energy: int = 5
var max_drones: int = 4

func _emit_drone_limit():
	var current = total_gatherers + total_defenders + active_production
	drone_limit_changed.emit(current, max_drones)

var energy_gathering: int = 0
var energy_defense: int = 0
var energy_production: int = 0

var active_gatherers: int = 0
var active_defenders: int = 0
var active_production: int = 0:
	set(value):
		active_production = value
		_emit_drone_limit()

var active_productions_list: Array[Dictionary] = []
var next_production_id: int = 0

func _process(delta: float) -> void:
	for i in range(active_productions_list.size() - 1, -1, -1):
		var prod = active_productions_list[i]
		prod.time_left -= delta
		production_progress.emit(prod.id, prod.time_left, prod.duration)
		
		if prod.time_left <= 0:
			var unit_data = prod.unit_data
			var prod_id = prod.id
			active_productions_list.remove_at(i)
			active_production -= 1
			production_completed.emit(prod_id)
			
			var factories = get_tree().get_nodes_in_group("factory")
			if factories.size() > 0:
				factories[0].spawn_drone(unit_data)
			else:
				var factory = get_tree().root.find_child("Factory", true, false)
				if factory and factory.has_method("spawn_drone"):
					factory.spawn_drone(unit_data)


func get_available_energy() -> int:
	return max_energy - (energy_gathering + energy_defense + energy_production)

func set_energy_gathering(amount: int) -> bool:
	if amount < 0: return false
	
	var diff = amount - energy_gathering
	if diff > 0 and get_available_energy() < diff:
		return false
	
	energy_gathering = amount
	energy_distribution_changed.emit(energy_gathering, energy_defense, energy_production)
	return true

func set_energy_defense(amount: int) -> bool:
	if amount < 0: return false
	
	var diff = amount - energy_defense
	if diff > 0 and get_available_energy() < diff:
		return false
		
	energy_defense = amount
	energy_distribution_changed.emit(energy_gathering, energy_defense, energy_production)
	return true

func set_energy_production(amount: int) -> bool:
	if amount < 0: return false
	
	var diff = amount - energy_production
	if diff > 0 and get_available_energy() < diff:
		return false
		
	energy_production = amount
	energy_distribution_changed.emit(energy_gathering, energy_defense, energy_production)
	return true


func convert_resources_to_credits(resources: float) -> int:
	var base_credits = resources / 5.0
	var multiplier = pow(1.7, base_level - 1)
	return round(base_credits * multiplier)

func add_credits(amount: int):
	credits += amount

func spend_credits(amount: int) -> bool:
	if credits >= amount:
		credits -= amount
		return true
	return false

func upgrade_base(cost: int) -> bool:
	if spend_credits(cost):
		base_level += 1
		return true
	return false

func start_production(unit_data: UnitData) -> bool:
	if active_production >= energy_production:
		show_alert.emit("Not enough energy for production!", AlertType.WARNING)
		return false
		
	var current_total = total_gatherers + total_defenders + active_production
	if current_total >= max_drones:
		show_alert.emit("Drone limit reached! Current limit: " + str(max_drones), AlertType.WARNING)
		return false
		
	if not spend_credits(unit_data.cost):
		show_alert.emit("Insufficient credits!", AlertType.ERROR)
		return false
		
	show_alert.emit("Production started: " + unit_data.display_name, AlertType.INFO)
	SoundManager.play_sfx("production")
	active_production += 1
	
	var prod_id = next_production_id
	next_production_id += 1
	
	active_productions_list.append({
		"id": prod_id,
		"unit_data": unit_data,
		"time_left": unit_data.build_time,
		"duration": unit_data.build_time
	})
	
	production_added.emit(prod_id, unit_data)
	return true

func reset_state() -> void:
	credits = 1000
	base_level = 1
	active_production = 0
	active_productions_list.clear()
	next_production_id = 0
	energy_gathering = 0
	energy_defense = 0
	energy_production = 0
	energy_distribution_changed.emit(energy_gathering, energy_defense, energy_production)
