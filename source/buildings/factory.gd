extends Node3D

@export var factory_cost: int = 100
var is_built: bool = false
var current_level: int = 0

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


func get_upgrade_cost() -> int:
	if current_level == 1:
		return 200
	elif current_level == 2:
		return 350
	return -1

func upgrade_factory():
	if current_level == 1:
		var cost = 200
		if GameManager.spend_credits(cost):
			print("Фабрика улучшена до 2 уровня за ", cost, " кредитов!")
			add_child(lvl2)
			current_level = 2
			update_click_zone()
			await get_tree().physics_frame
			bake_navmesh()
		else:
			print("Не хватает кредитов для апгрейда до 2 уровня! Нужно ", cost, ", а есть ", GameManager.credits)
	elif current_level == 2:
		var cost = 350
		if GameManager.spend_credits(cost):
			print("Фабрика улучшена до 3 уровня за ", cost, " кредитов!")
			add_child(lvl3)
			current_level = 3
			update_click_zone()
			await get_tree().physics_frame
			bake_navmesh()
		else:
			print("Не хватает кредитов для апгрейда до 3 уровня! Нужно ", cost, ", а есть ", GameManager.credits)
	else:
		print("Фабрика уже максимального уровня!")

func _on_click_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_built:
			buy_factory()
			get_viewport().set_input_as_handled()
		else:
			# Клик по уже построенной фабрике
			GameManager.toggle_ui("factory")
			get_viewport().set_input_as_handled()
