extends CharacterBody3D

@export var max_health: float = 120.0
@export var speed: float = 4.0
@export var attack_damage: float = 8.0
@export var attack_range: float = 10.0
@export var attack_cooldown: float = 1.2

var current_health: float
var target: Node3D = null
var time_since_last_attack: float = 0.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D if has_node("NavigationAgent3D") else null
@onready var healthbar = $Healthbar if has_node("Healthbar") else null

# For levitation visual effect
var time_passed: float = 0.0
var base_y: float = 0.0

func _ready() -> void:
	add_to_group("aliens")
	add_to_group("catalysts")
	current_health = max_health
	if healthbar:
		healthbar.init_health(max_health, current_health)
	
	base_y = position.y
	
	# Small delay to ensure navmesh is ready
	await get_tree().create_timer(0.5).timeout
	find_target()

func _physics_process(delta: float) -> void:
	# Constant rotation around its own axis (360 degrees in 30 seconds)
	rotate_y((TAU / 30.0) * delta)
	
	# Levitation effect (since it's a hovering/levitating catalyst)
	time_passed += delta
	var levitation = sin(time_passed * 2.0) * 0.15
	position.y = base_y + levitation
	
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		target = null
		find_target()
		if target == null:
			velocity = Vector3.ZERO
			move_and_slide()
			return
			
	var distance_to_target = global_position.distance_to(target.global_position)
			
	# Combat cooldown
	time_since_last_attack += delta
	
	if distance_to_target <= attack_range:
		# Combat & Kiting logic
		if time_since_last_attack >= attack_cooldown:
			attack_target()
			time_since_last_attack = 0.0
			
		# Kiting: if too close, back away. If in sweet spot, stay still.
		if distance_to_target < 6.0:
			# Move away from target
			var direction = target.global_position.direction_to(global_position)
			direction.y = 0
			velocity = direction.normalized() * speed
			move_and_slide()
		else:
			velocity = Vector3.ZERO
	else:
		# Move towards target
		if nav_agent and not nav_agent.is_navigation_finished():
			nav_agent.target_position = target.global_position
			var next_pos = nav_agent.get_next_path_position()
			var direction = global_position.direction_to(next_pos)
			direction.y = 0
			velocity = direction.normalized() * speed
		else:
			# Fallback straight movement
			var direction = global_position.direction_to(target.global_position)
			direction.y = 0
			velocity = direction.normalized() * speed
			
		move_and_slide()

func find_target() -> void:
	# Priority 1: defenders
	var defenders = get_tree().get_nodes_in_group("defenders")
	var nearest_defender = get_nearest(defenders)
	if nearest_defender:
		target = nearest_defender
		return
		
	# Priority 2: gatherers
	var gatherers = get_tree().get_nodes_in_group("gatherers")
	var nearest_gatherer = get_nearest(gatherers)
	if nearest_gatherer:
		target = nearest_gatherer
		return
		
	# Priority 3: fallback to buildings
	var buildings = get_tree().get_nodes_in_group("commandcenter") + get_tree().get_nodes_in_group("factory")
	var nearest_building = get_nearest(buildings)
	if nearest_building:
		target = nearest_building
		return
		
	target = null

func get_nearest(nodes: Array) -> Node3D:
	var nearest_node = null
	var min_dist = INF
	for node in nodes:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			var dist = global_position.distance_to(node.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest_node = node
	return nearest_node

func attack_target() -> void:
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(attack_damage)
		draw_laser_beam(global_position + Vector3(0, 1.0, 0), target.global_position + Vector3(0, 0.5, 0))

func draw_laser_beam(from_pos: Vector3, to_pos: Vector3):
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	var material = StandardMaterial3D.new()
	
	material.albedo_color = Color(1.0, 0.0, 0.5) # Purple/magenta laser
	material.emission_enabled = true
	material.emission = Color(1.0, 0.0, 0.5)
	material.emission_energy_multiplier = 3.0
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.material_override = material
	
	get_tree().current_scene.add_child(mesh_instance)
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(from_pos)
	immediate_mesh.surface_add_vertex(to_pos)
	immediate_mesh.surface_end()
	
	var tween = create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, 0.15)
	tween.tween_callback(mesh_instance.queue_free)

func take_damage(amount: float) -> void:
	current_health -= amount
	if healthbar:
		healthbar.update_health(current_health)
		
	if current_health <= 0:
		queue_free()
