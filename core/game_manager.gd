extends Node

# Сигналы для обновления UI и уведомления дронов
signal credits_changed(new_amount)
signal energy_distribution_changed(gathering, defense)
signal base_level_changed(new_level, new_max_energy)

# Экономика
var credits: int = 0:
	set(value):
		credits = value
		credits_changed.emit(credits)

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

# Текущее количество активных дронов
var active_gatherers: int = 0
var active_defenders: int = 0

# --- ЛОГИКА ЭНЕРГИИ ---

# Возвращает количество нераспределенной энергии
func get_available_energy() -> int:
	return max_energy - (energy_gathering + energy_defense)

# Попытка установить новую энергию для добычи
func set_energy_gathering(amount: int) -> bool:
	if amount < 0: return false
	
	var diff = amount - energy_gathering
	if diff > 0 and get_available_energy() < diff:
		return false # Не хватает свободной энергии
	
	energy_gathering = amount
	energy_distribution_changed.emit(energy_gathering, energy_defense)
	return true

# Попытка установить новую энергию для защиты
func set_energy_defense(amount: int) -> bool:
	if amount < 0: return false
	
	var diff = amount - energy_defense
	if diff > 0 and get_available_energy() < diff:
		return false # Не хватает свободной энергии
		
	energy_defense = amount
	energy_distribution_changed.emit(energy_gathering, energy_defense)
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
