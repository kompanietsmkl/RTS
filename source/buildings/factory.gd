extends Node3D

@export var factory_cost: int = 100
var is_built: bool = false

@onready var lvl1 = $"FactoryLVL1"
@onready var lvl2 = $"FactoryLVL2"
@onready var lvl3 = $"FactoryLVL3"
@onready var lvl0 = $"FactoryLVL0"

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
		
func buy_factory():
	if GameManager.spend_credits(factory_cost):
		print("Фабрика куплена за ", factory_cost, " кредитов!")
		is_built = true
		
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


func _on_click_zone_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if is_built:
		return # Уже построено, клики игнорируются (позже тут будет UI апгрейда)
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		buy_factory()
