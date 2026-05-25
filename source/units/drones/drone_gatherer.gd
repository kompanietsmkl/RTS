extends DroneBase

enum State {
	IDLE,
	MOVING_TO_CRYSTAL,
	GATHERING,
	RETURNING_TO_BASE,
	WAITING_TO_UNLOAD,
	UNLOADING
}

var current_state: State = State.IDLE
var is_active: bool = false
var target_crystal: Node3D = null
var base_building: Node3D = null

var current_resources: float = 0.0
var max_capacity: float = 50.0
var harvest_rate: float = 12.5
var unload_time: float = 2.0
var unload_timer: float = 0.0

@export var interact_range := 1.0

func _enter_tree() -> void:
	GameManager.total_gatherers += 1

func _exit_tree() -> void:
	GameManager.total_gatherers -= 1
	if is_active:
		GameManager.active_gatherers -= 1

func _ready():
	add_to_group("drones")
	add_to_group("gatherers")
	GameManager.energy_distribution_changed.connect(_on_energy_changed)
	if healthbar:
		healthbar.init_health(max_health, current_health)
	
	var bases = get_tree().get_nodes_in_group("commandcenter")
	if bases.size() > 0:
		base_building = bases[0]
		print("Дрон-сборщик: База найдена!")
	else:
		print("Дрон-сборщик: База не найдена при старте, поиск отложен.")

func _on_energy_changed(gathering_energy: int, _defense_energy: int, _production_energy: int):
	if is_active and GameManager.active_gatherers > gathering_energy:
		print("Дрон: Энергию урезали, отключаюсь.")
		deactivate()

func activate():
	if not is_active and GameManager.active_gatherers < GameManager.energy_gathering:
		print("Дрон: Получил энергию, активируюсь!")
		is_active = true
		GameManager.active_gatherers += 1
		find_new_crystal()

func deactivate():
	if is_active:
		is_active = false
		GameManager.active_gatherers -= 1
		release_crystal()
		current_state = State.RETURNING_TO_BASE

func release_crystal():
	if is_instance_valid(target_crystal) and target_crystal.get("occupied_by_drone") == self:
		target_crystal.occupied_by_drone = null
	target_crystal = null

func get_base_occupant() -> Node:
	if is_instance_valid(base_building) and base_building.has_meta("occupied_by_drone"):
		return base_building.get_meta("occupied_by_drone")
	return null

func execute_behavior(delta: float):
	match current_state:
		State.IDLE:
			velocity = Vector3.ZERO
			if not is_active:
				activate()
			else:
				find_new_crystal()
			
		State.MOVING_TO_CRYSTAL:
			if not is_instance_valid(target_crystal) or target_crystal.get("occupied_by_drone") != self:
				release_crystal()
				find_new_crystal()
				return
			
			var dist = global_position.distance_to(target_crystal.global_position)
			if dist <= interact_range:
				velocity = Vector3.ZERO
				print("Дрон: Доехал до кристалла. Начинаю добычу!")
				current_state = State.GATHERING
			else:
				move_to_target(target_crystal.global_position, delta)
				
		State.GATHERING:
			velocity = Vector3.ZERO
			if not is_instance_valid(target_crystal) or not target_crystal.is_in_group("crystals") or target_crystal.get("occupied_by_drone") != self:
				release_crystal()
				current_state = State.RETURNING_TO_BASE
				return
				
			var amount = harvest_rate * delta
			if current_resources + amount > max_capacity:
				amount = max_capacity - current_resources
				
			var gathered = amount
			if target_crystal.has_method("harvest"):
				gathered = target_crystal.harvest(amount)
				
			current_resources += gathered
			
			# Если заполнили инвентарь или кристалл иссяк (с учетом погрешности float)
			if current_resources >= max_capacity or target_crystal.current_resources <= 0.01:
				print("Дрон: Ресурсы собраны, возвращаюсь!")
				release_crystal()
				current_state = State.RETURNING_TO_BASE
				
		State.RETURNING_TO_BASE:
			return_to_base(delta)
			
		State.WAITING_TO_UNLOAD:
			velocity = Vector3.ZERO
			if is_instance_valid(base_building) and get_base_occupant() == null:
				base_building.set_meta("occupied_by_drone", self)
				print("Дрон: База освободилась, начинаю разгрузку!")
				current_state = State.UNLOADING
				unload_timer = unload_time
			
		State.UNLOADING:
			velocity = Vector3.ZERO
			unload_timer -= delta
			if unload_timer <= 0:
				var credits_earned = GameManager.convert_resources_to_credits(current_resources)
				print("Дрон: Разгрузился на базе! Жду кулдаун. Заработано кредитов: ", credits_earned)
				GameManager.add_credits(credits_earned)
				print("Всего кредитов: ", GameManager.credits)
				current_resources = 0.0
				
				if is_instance_valid(base_building) and get_base_occupant() == self:
					base_building.set_meta("occupied_by_drone", null)
					
				if is_active:
					find_new_crystal()
				else:
					print("Дрон: Засыпаю на базе.")
					current_state = State.IDLE

func find_new_crystal():
	release_crystal()
	
	var crystals = get_tree().get_nodes_in_group("crystals")
	var available_crystals = []
	for c in crystals:
		if c.get("occupied_by_drone") == null and c.current_resources > 0.01:
			available_crystals.append(c)
			
	if available_crystals.size() == 0:
		if Engine.get_process_frames() % 60 == 0:
			print("Дрон: Ищу кристаллы, но свободных нет!")
		current_state = State.IDLE
		return
		
	var nearest = available_crystals[0]
	var min_dist = global_position.distance_to(nearest.global_position)
	
	for i in range(1, available_crystals.size()):
		var dist = global_position.distance_to(available_crystals[i].global_position)
		if dist < min_dist:
			nearest = available_crystals[i]
			min_dist = dist
			
	target_crystal = nearest
	target_crystal.occupied_by_drone = self
	current_state = State.MOVING_TO_CRYSTAL
	print("Дрон: Занял свободный кристалл на дистанции: ", min_dist)

func return_to_base(delta: float):
	if not is_instance_valid(base_building):
		var bases = get_tree().get_nodes_in_group("commandcenter")
		if bases.size() > 0:
			base_building = bases[0]
		else:
			return
		
	var dist = global_position.distance_to(base_building.global_position)
	if dist <= interact_range + 3.0:
		velocity = Vector3.ZERO
		if current_resources > 0:
			var occupant = get_base_occupant()
			if occupant == null or occupant == self:
				base_building.set_meta("occupied_by_drone", self)
				print("Дрон: Приехал на базу, начинаю разгрузку и отдых...")
				current_state = State.UNLOADING
				unload_timer = unload_time
			else:
				if current_state != State.WAITING_TO_UNLOAD:
					print("Дрон: База занята, жду очереди на разгрузку...")
					current_state = State.WAITING_TO_UNLOAD
		else:
			if is_active:
				find_new_crystal()
			else:
				print("Дрон: Засыпаю на базе.")
				current_state = State.IDLE
	else:
		move_to_target(base_building.global_position, delta)
