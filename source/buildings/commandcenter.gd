extends Node3D

var occupied_by_drone: Node = null

# Границы клика для каждого уровня (относительно локальных координат базы)
# Ключ: уровень базы, Значение: [min_x, max_x, min_z, max_z]
const CLICK_BOUNDS = {
	1: [-3.0, 3.0, -3.0, 3.0],
	2: [-4.0, 4.0, -4.0, 4.0]
}

@onready var lvl1 = $BaseLVL1 
@onready var lvl2 = $BaseLVL2
@onready var lvl3 = $BaseLVL3 

func _ready() -> void:
	add_to_group("commandcenter")
	
	# Скрываем (удаляем из дерева) уровни, которые еще не достигнуты, чтобы NavMesh их не учитывал
	if lvl2:
		lvl2.get_parent().remove_child(lvl2)
	if lvl3:
		lvl3.get_parent().remove_child(lvl3)
		
	# Ждем кадр физики (на случай если нужна синхронизация физики для других вещей)
	await get_tree().physics_frame

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var camera = get_viewport().get_camera_3d()
		if not camera: return
		
		var ray_origin = camera.project_ray_origin(event.position)
		var ray_normal = camera.project_ray_normal(event.position)
		var ray_target = ray_origin + ray_normal * 1000.0
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
		var result = space_state.intersect_ray(query)
		
		if result:
			var local_pos = global_transform.affine_inverse() * result.position
			var level = GameManager.base_level
			
			if CLICK_BOUNDS.has(level) or CLICK_BOUNDS.has(2): # Fallback на 2 уровень
				var bounds = CLICK_BOUNDS[level] if CLICK_BOUNDS.has(level) else CLICK_BOUNDS[2]
				if local_pos.x >= bounds[0] and local_pos.x <= bounds[1] and local_pos.z >= bounds[2] and local_pos.z <= bounds[3]:
					GameManager.toggle_ui("commandcenter")
					get_viewport().set_input_as_handled()

func get_upgrade_cost() -> int:
	var level = GameManager.base_level
	if level == 1:
		return 150
	elif level == 2:
		return 300
	return -1 # MAX

func upgrade_base() -> void:
	var cost = get_upgrade_cost()
	if cost <= 0:
		print("База максимального уровня!")
		return
		
	if GameManager.spend_credits(cost):
		var old_level = GameManager.base_level
		GameManager.base_level += 1
		print("База улучшена до уровня ", GameManager.base_level)
		
		# Добавляем в дерево модель нового уровня
		if GameManager.base_level == 2 and lvl2 and lvl2.get_parent() == null:
			add_child(lvl2)
		elif GameManager.base_level == 3 and lvl3 and lvl3.get_parent() == null:
			add_child(lvl3)
			
		# Обновляем навигацию после добавления коллизий
		await get_tree().physics_frame
		bake_navmesh()
	else:
		print("Недостаточно кредитов для улучшения базы!")

func bake_navmesh():
	var nav_region = get_tree().root.find_child("NavigationRegion3D", true, false)
	if nav_region and nav_region is NavigationRegion3D:
		nav_region.bake_navigation_mesh()
		print("NavMesh (Base) успешно обновлен!")
	else:
		print("ВНИМАНИЕ: Не удалось найти NavigationRegion3D для запекания от базы!")
