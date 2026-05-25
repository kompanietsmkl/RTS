extends Node3D

@export var data: BuildingData = preload("res://source/resources/commandcenter_data.tres")

var current_health: float = 0.0
var max_health: float = 0.0
@onready var healthbar = $Healthbar if has_node("Healthbar") else null

var occupied_by_drone: Node = null

const CLICK_BOUNDS = {
	1: [-3.0, 3.0, -3.0, 3.0],
	2: [-4.0, 4.0, -4.0, 4.0]
}

@onready var lvl1 = $BaseLVL1 
@onready var lvl2 = $BaseLVL2
@onready var lvl3 = $BaseLVL3 

func _ready() -> void:
	add_to_group("commandcenter")
	
	if data and data.level_healths.size() > 0:
		max_health = data.level_healths[0]
		current_health = max_health
	if healthbar:
		healthbar.init_health(max_health, current_health)
	
	if lvl2:
		lvl2.get_parent().remove_child(lvl2)
	if lvl3:
		lvl3.get_parent().remove_child(lvl3)
		
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
			
			if CLICK_BOUNDS.has(level) or CLICK_BOUNDS.has(2):
				var bounds = CLICK_BOUNDS[level] if CLICK_BOUNDS.has(level) else CLICK_BOUNDS[2]
				if local_pos.x >= bounds[0] and local_pos.x <= bounds[1] and local_pos.z >= bounds[2] and local_pos.z <= bounds[3]:
					GameManager.toggle_ui("commandcenter")
					get_viewport().set_input_as_handled()

func get_upgrade_cost() -> int:
	var level = GameManager.base_level
	if data and level < data.level_costs.size():
		return data.level_costs[level]
	return -1 # MAX

func upgrade_base() -> void:
	var cost = get_upgrade_cost()
	if cost <= 0:
		GameManager.show_alert.emit("Base is already at maximum level!", GameManager.AlertType.WARNING)
		return
		
	if GameManager.spend_credits(cost):
		var old_level = GameManager.base_level
		GameManager.base_level += 1
		GameManager.show_alert.emit("Base upgraded to level " + str(GameManager.base_level), GameManager.AlertType.SUCCESS)
		
		if data and GameManager.base_level <= data.level_healths.size():
			max_health = data.level_healths[GameManager.base_level - 1]
			current_health = max_health
			if healthbar:
				healthbar.init_health(max_health, current_health)
		
		if GameManager.base_level == 2 and lvl2 and lvl2.get_parent() == null:
			add_child(lvl2)
		elif GameManager.base_level == 3 and lvl3 and lvl3.get_parent() == null:
			add_child(lvl3)
			
		await get_tree().physics_frame
		bake_navmesh()
	else:
		GameManager.show_alert.emit("Not enough credits to upgrade base!", GameManager.AlertType.ERROR)

func bake_navmesh():
	var nav_region = get_tree().root.find_child("NavigationRegion3D", true, false)
	if nav_region and nav_region is NavigationRegion3D:
		nav_region.bake_navigation_mesh()
		print("NavMesh (Base) successfully updated!")
	else:
		print("WARNING: Could not find NavigationRegion3D to bake from base!")

func take_damage(amount: float) -> void:
	current_health -= amount
	if healthbar:
		healthbar.update_health(current_health)
	if current_health <= 0:
		print("Base destroyed! GAME OVER.")
		GameManager.base_destroyed.emit()
		queue_free()

func load_state(level: int, health: float) -> void:
	# First hide/remove lvl2 and lvl3 if they exist, then re-add based on loaded level
	if lvl2 and lvl2.get_parent() == self:
		remove_child(lvl2)
	if lvl3 and lvl3.get_parent() == self:
		remove_child(lvl3)
		
	if level >= 2 and lvl2 and lvl2.get_parent() == null:
		add_child(lvl2)
	if level >= 3 and lvl3 and lvl3.get_parent() == null:
		add_child(lvl3)
		
	if data and level <= data.level_healths.size() and level > 0:
		max_health = data.level_healths[level - 1]
	else:
		if data and data.level_healths.size() > 0:
			max_health = data.level_healths[0]
			
	current_health = health
	if healthbar:
		healthbar.init_health(max_health, current_health)
