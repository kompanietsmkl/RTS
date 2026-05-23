extends Node3D

@export var factory_cost: int = 100
var is_built: bool = false
var current_level: int = 0

const GathererScene = preload("res://source/units/drones/drone_gatherer.tscn")
const DefenderScene = preload("res://source/units/drones/drone_defender.tscn")

func spawn_drone(type: String):
	var drone_scene: PackedScene = null
	if type == "gatherer":
		drone_scene = GathererScene
	elif type == "defender":
		drone_scene = DefenderScene
		
	if not drone_scene:
		print("Неизвестный тип дрона:", type)
		return
		
	var drone_instance = drone_scene.instantiate()
	
	# Генерируем случайную позицию в радиусе 5-10 метров
	var angle = randf() * TAU
	var dist = randf_range(5.0, 10.0)
	var random_offset = Vector3(cos(angle), 0, sin(angle)) * dist
	var target_pos = global_position + random_offset
	
	# Безопасная точка на NavMesh
	var safe_pos = NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, target_pos)
	
	# Спавним в корне сцены (сначала добавляем в дерево, потом ставим глобальные координаты)
	get_tree().current_scene.add_child(drone_instance)
	drone_instance.global_position = safe_pos
	print("Фабрика: Дрон ", type, " заспавнен!")



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
	bake_navmesh()
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
		else:
			GameManager.toggle_factory_ui.emit()
