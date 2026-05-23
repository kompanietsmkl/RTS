extends Node

# Сигналы для обновления UI и уведомления дронов
signal credits_changed(new_amount)
signal energy_distribution_changed(gathering, defense, production)
signal base_level_changed(new_level, new_max_energy)
signal toggle_factory_ui()
signal drones_count_changed(gatherers_total, defenders_total)
signal production_added(id: int, unit_data: UnitData)
signal production_progress(id: int, time_left: float, duration: float)
signal production_completed(id: int)


# Экономика
var credits: int = 1000:
	set(value):
		credits = value
		credits_changed.emit(credits)

var total_gatherers: int = 0:
	set(value):
		total_gatherers = value
		drones_count_changed.emit(total_gatherers, total_defenders)

var total_defenders: int = 0:
	set(value):
		total_defenders = value
		drones_count_changed.emit(total_gatherers, total_defenders)

# Статистика базы
var base_level: int = 1:
	set(value):
		base_level = value
		max_energy = 5 + (base_level - 1) * 2
		base_level_changed.emit(base_level, max_energy)

var max_energy: int = 5

# Распределение энергии (приоритеты)
var energy_gathering: int = 0
var energy_defense: int = 0
var energy_production: int = 0

# Текущее количество активных дронов
var active_gatherers: int = 0
var active_defenders: int = 0
var active_production: int = 0

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

# --- ЛОГИКА ЭНЕРГИИ ---

# Возвращает количество нераспределенной энергии
func get_available_energy() -> int:
	return max_energy - (energy_gathering + energy_defense + energy_production)

# Попытка установить новую энергию для добычи
func set_energy_gathering(amount: int) -> bool:
	if amount < 0: return false
	
	var diff = amount - energy_gathering
	if diff > 0 and get_available_energy() < diff:
		return false # Не хватает свободной энергии
	
	energy_gathering = amount
	energy_distribution_changed.emit(energy_gathering, energy_defense, energy_production)
	return true

# Попытка установить новую энергию для защиты
func set_energy_defense(amount: int) -> bool:
	if amount < 0: return false
	
	var diff = amount - energy_defense
	if diff > 0 and get_available_energy() < diff:
		return false # Не хватает свободной энергии
		
	energy_defense = amount
	energy_distribution_changed.emit(energy_gathering, energy_defense, energy_production)
	return true

# Попытка установить новую энергию для производства
func set_energy_production(amount: int) -> bool:
	if amount < 0: return false
	
	var diff = amount - energy_production
	if diff > 0 and get_available_energy() < diff:
		return false # Не хватает свободной энергии
		
	energy_production = amount
	energy_distribution_changed.emit(energy_gathering, energy_defense, energy_production)
	return true

# --- ЛОГИКА ЭКОНОМИКИ ---

# Вызывается, когда дрон приносит кристалл на базу
func add_credits(amount: int):
	credits += amount

# Безопасная трата кредитов
func spend_credits(amount: int) -> bool:
	if credits >= amount:
		credits -= amount
		return true
	return false

# Покупка апгрейда базы
func upgrade_base(cost: int) -> bool:
	if spend_credits(cost):
		base_level += 1
		return true
	return false

func start_production(unit_data: UnitData) -> bool:
	if active_production >= energy_production:
		print("Недостаточно энергии производства!")
		return false
		
	if not spend_credits(unit_data.cost):
		print("Недостаточно кредитов!")
		return false
		
	print("Начинаю производство дрона: ", unit_data.display_name)
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
