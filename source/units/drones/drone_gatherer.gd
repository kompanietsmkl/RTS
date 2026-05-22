extends DroneBase

enum State {
	IDLE,
	MOVING_TO_CRYSTAL,
	GATHERING,
	RETURNING_TO_BASE,
	UNLOADING
}

var current_state: State = State.IDLE
var is_active: bool = false
var target_crystal: Node3D = null
var base_building: Node3D = null

var current_resources: float = 0.0
var max_capacity: float = 50.0
var harvest_rate: float = 12.5 # 50 за 4 секунды
var unload_time: float = 2.0
var unload_timer: float = 0.0

@export var interact_range := 1.5

func _ready():
	GameManager.energy_distribution_changed.connect(_on_energy_changed)
	
	var bases = get_tree().get_nodes_in_group("base")
	if bases.size() > 0:
		base_building = bases[0]
		print("Дрон: База найдена!")
	else:
		print("ОШИБКА: Дрон не нашел базу в группе 'base'!")

func _on_energy_changed(gathering_energy: int, _defense_energy: int):
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
		current_state = State.RETURNING_TO_BASE
		target_crystal = null

func execute_behavior(delta: float):
	if not is_active:
		if current_state != State.IDLE:
			return_to_base(delta)
		else:
			activate()
		return
		
	match current_state:
		State.IDLE:
			find_new_crystal()
			
		State.MOVING_TO_CRYSTAL:
			if not is_instance_valid(target_crystal):
				find_new_crystal()
				return
			
			var dist = global_position.distance_to(target_crystal.global_position)
			if dist <= interact_range:
				print("Дрон: Доехал до кристалла. Начинаю добычу!")
				current_state = State.GATHERING
			else:
				move_to_target(target_crystal.global_position, delta)
				
		State.GATHERING:
			if not is_instance_valid(target_crystal) or not target_crystal.is_in_group("crystals"):
				current_state = State.RETURNING_TO_BASE
				return
				
			var amount = harvest_rate * delta
			if current_resources + amount > max_capacity:
				amount = max_capacity - current_resources
				
			current_resources += amount
			
			if target_crystal.has_method("harvest"):
				target_crystal.harvest(amount)
				
			# Если заполнили инвентарь или кристалл иссяк
			if current_resources >= max_capacity or target_crystal.current_resources <= 0:
				print("Дрон: Ресурсы собраны, возвращаюсь!")
				current_state = State.RETURNING_TO_BASE
				
		State.RETURNING_TO_BASE:
			return_to_base(delta)
			
		State.UNLOADING:
			unload_timer -= delta
			if unload_timer <= 0:
				print("Дрон: Разгрузился на базе! Жду кулдаун.")
				GameManager.add_credits(int(current_resources) * 5)
				current_resources = 0.0
				
				if is_active:
					find_new_crystal()
				else:
					print("Дрон: Засыпаю на базе.")
					current_state = State.IDLE

func find_new_crystal():
	var crystals = get_tree().get_nodes_in_group("crystals")
	if crystals.size() == 0:
		if Engine.get_process_frames() % 60 == 0:
			print("Дрон: Ищу кристаллы, но в группе 'crystals' пусто!")
		current_state = State.IDLE
		return
		
	var nearest = crystals[0]
	var min_dist = global_position.distance_to(nearest.global_position)
	
	for i in range(1, crystals.size()):
		var dist = global_position.distance_to(crystals[i].global_position)
		if dist < min_dist:
			nearest = crystals[i]
			min_dist = dist
			
	target_crystal = nearest
	current_state = State.MOVING_TO_CRYSTAL
	print("Дрон: Нашел кристалл на дистанции: ", min_dist)

func return_to_base(delta: float):
	if not is_instance_valid(base_building):
		return
		
	var dist = global_position.distance_to(base_building.global_position)
	if dist <= interact_range + 3.0:
		if current_resources > 0:
			print("Дрон: Приехал на базу, начинаю разгрузку и отдых...")
			current_state = State.UNLOADING
			unload_timer = unload_time
		else:
			if is_active:
				find_new_crystal()
			else:
				print("Дрон: Засыпаю на базе.")
				current_state = State.IDLE
	else:
		move_to_target(base_building.global_position, delta)
