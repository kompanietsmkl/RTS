extends Node3D

@export var data: BuildingData = preload("res://source/resources/factory_data.tres")
@export var factory_cost: int = 100
var is_built: bool = false
var current_level: int = 0
var current_health: float = 0.0
var max_health: float = 0.0
@onready var healthbar = $Healthbar if has_node("Healthbar") else null

func spawn_drone(unit_data: UnitData):
	if not unit_data or not unit_data.unit_scene:
		print("Ошибка спавна: не передан UnitData или отсутствует unit_scene")
		return
		
	var drone_instance = unit_data.unit_scene.instantiate()
	
	# Устанавливаем фиксированную точку спавна (условно "перед дверью" фабрики)
	# Учитываем текущий поворот фабрики
	var spawn_offset = Vector3(0, 0.5, 5.0) # 5 метров вперед по локальной оси Z, немного приподнято
	var base_spawn_pos = global_transform * spawn_offset
	
	# Добавляем небольшой случайный разброс, чтобы дроны не появлялись друг в друге
	var random_x = randf_range(-2.0, 2.0)
	var random_z = randf_range(-2.0, 2.0)
	var spawn_pos = base_spawn_pos + Vector3(random_x, 0, random_z)
	
	# Спавним в корне сцены
	get_tree().current_scene.add_child(drone_instance)
	drone_instance.global_position = spawn_pos

	print("Фабрика: Дрон ", unit_data.display_name, " заспавнен!")

@onready var lvl1 = $"FactoryLVL1"
@onready var lvl2 = $"FactoryLVL2"
@onready var lvl3 = $"FactoryLVL3"
@onready var lvl0 = $"FactoryLVL0"
@onready var click_shape = $"Click/CollisionShape3D"

const CLICK_BOUNDS = {
	0: Vector3(2.5, 0.5, 3.5),    # только платформа
	1: Vector3(3.0, 2.0, 3.5),    # + ангар LVL1
	2: Vector3(6.0, 2.0, 7.0),    # + коридор и круглый ангар LVL2
	3: Vector3(8.0, 2.0, 7.0),   # + пристройка LVL3
}

const CLICK_OFFSETS = {
	0: Vector3(0, 0.2, 0),
	1: Vector3(0, 0.5, 0),
	2: Vector3(1.5, 0.5, -1.0),   # смещение центра под расширение
	3: Vector3(2.5, 0.5, -0.5),
}

func update_click_zone():
	if click_shape and click_shape.shape is BoxShape3D:
		# Делаем shape уникальным, чтобы не менять глобальный ресурс (на всякий случай)
		click_shape.shape = click_shape.shape.duplicate()
		click_shape.shape.size = CLICK_BOUNDS[current_level]
		click_shape.position = CLICK_OFFSETS[current_level]

func _ready() -> void:
	add_to_group("factory")
	
	if data and data.level_healths.size() > 0:
		max_health = data.level_healths[0]
		current_health = max_health
	if healthbar:
		healthbar.init_health(max_health, current_health)
		
	# Убираем невидимые уровни из дерева — тогда NavMesh их не увидит
	if lvl1:
		lvl1.get_parent().remove_child(lvl1)
	if lvl2:
		lvl2.get_parent().remove_child(lvl2)
	if lvl3:
		lvl3.get_parent().remove_child(lvl3)

	await get_tree().physics_frame
	update_click_zone()
		
func buy_factory():
	if GameManager.spend_credits(factory_cost):
		print("Фабрика куплена за ", factory_cost, " кредитов!")
		is_built = true
		current_level = 1
		update_click_zone()
		# Показываем фабрику и включаем её физику (коллизии)
		add_child(lvl1)
		await get_tree().physics_frame
		bake_navmesh()
	else:
		print("Не хватает кредитов! Нужно ", factory_cost, ", а есть ", GameManager.credits)

func bake_navmesh():
	# Ищем NavigationRegion3D в сцене (он должен быть одним из родителей или лежать в корне)
	# В твоей структуре он лежит в корне сцены как NavigationRegion3D
	var nav_region = get_tree().root.find_child("NavigationRegion3D", true, false)
	if nav_region and nav_region is NavigationRegion3D:
		nav_region.bake_navigation_mesh()
		print("NavMesh успешно обновлен!")
	else:
		print("ВНИМАНИЕ: Не удалось найти NavigationRegion3D для запекания!")

func take_damage(amount: float) -> void:
	if not is_built: return
	current_health -= amount
	if healthbar:
		healthbar.update_health(current_health)
	if current_health <= 0:
		print("Factory destroyed!")
		queue_free()


func get_upgrade_cost() -> int:
	if data and current_level < data.level_costs.size():
		return data.level_costs[current_level]
	return -1 # MAX

func upgrade_factory():
	var cost = get_upgrade_cost()
	if cost <= 0:
		GameManager.show_alert.emit("Factory is already at maximum level!", GameManager.AlertType.WARNING)
		return
		
	if GameManager.spend_credits(cost):
		GameManager.show_alert.emit("Factory upgraded to level " + str(current_level + 1) + "!", GameManager.AlertType.SUCCESS)
		current_level += 1
		
		# Добавляем нужную модель
		if current_level == 2 and lvl2 and lvl2.get_parent() == null:
			add_child(lvl2)
		elif current_level == 3 and lvl3 and lvl3.get_parent() == null:
			add_child(lvl3)
			
		update_click_zone()
		
		# Полный отхил при апгрейде
		if data and current_level <= data.level_healths.size():
			max_health = data.level_healths[current_level - 1]
			current_health = max_health
			if healthbar:
				healthbar.init_health(max_health, current_health)
				
		await get_tree().physics_frame
		bake_navmesh()
	else:
		GameManager.show_alert.emit("Not enough credits to upgrade factory!", GameManager.AlertType.ERROR)

func _on_click_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_built:
			buy_factory()
			get_viewport().set_input_as_handled()
		else:
			# Click on an already built factory
			GameManager.toggle_ui("factory")
			get_viewport().set_input_as_handled()

func load_state(built: bool, level: int, health: float) -> void:
	is_built = built
	current_level = level
	
	# First hide/remove lvl1, lvl2, lvl3 if they exist in the tree
	if lvl1 and lvl1.get_parent() == self:
		remove_child(lvl1)
	if lvl2 and lvl2.get_parent() == self:
		remove_child(lvl2)
	if lvl3 and lvl3.get_parent() == self:
		remove_child(lvl3)
		
	if is_built:
		if current_level >= 1 and lvl1 and lvl1.get_parent() == null:
			add_child(lvl1)
		if current_level >= 2 and lvl2 and lvl2.get_parent() == null:
			add_child(lvl2)
		if current_level >= 3 and lvl3 and lvl3.get_parent() == null:
			add_child(lvl3)
			
	update_click_zone()
	
	if data and current_level <= data.level_healths.size() and current_level > 0:
		max_health = data.level_healths[current_level - 1]
	else:
		if data and data.level_healths.size() > 0:
			max_health = data.level_healths[0]
			
	current_health = health
	if healthbar:
		healthbar.init_health(max_health, current_health)
