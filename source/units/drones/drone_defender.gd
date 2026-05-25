extends DroneBase

@export var attack_range := 8.0
@export var damage := 15.0
@export var attack_cooldown := 1.0
@export var detection_range := 10.0

var current_target: Node3D = null
var time_since_last_attack: float = 0.0

# Base patrol and random walk variables
var patrol_angle: float = 0.0
var base_building: Node3D = null
var is_active: bool = false

var patrol_target: Vector3 = Vector3.ZERO
var noise_timer: float = 0.0
var target_noise_angle: float = 0.0
var current_noise_angle: float = 0.0
var target_set_frames: int = 0

func _enter_tree() -> void:
	GameManager.total_defenders += 1

func _exit_tree() -> void:
	GameManager.total_defenders -= 1
	if is_active:
		GameManager.active_defenders -= 1

func _ready() -> void:
	# Add to groups for querying
	add_to_group("drones")
	add_to_group("defenders")
	
	patrol_angle = randf_range(0.0, TAU)
	
	# Find CommandCenter as base
	var bases = get_tree().get_nodes_in_group("commandcenter")
	if bases.size() > 0:
		base_building = bases[0]
		
	GameManager.energy_distribution_changed.connect(_on_energy_changed)
	
	if healthbar:
		healthbar.init_health(max_health, current_health)

func _on_energy_changed(_gathering_energy: int, defense_energy: int, _production_energy: int):
	if is_active and GameManager.active_defenders > defense_energy:
		deactivate()

func activate():
	if not is_active and GameManager.active_defenders < GameManager.energy_defense:
		is_active = true
		GameManager.active_defenders += 1
		print("Defender: Activated!")

func deactivate():
	if is_active:
		is_active = false
		GameManager.active_defenders -= 1
		current_target = null
		print("Defender: Deactivated (no energy).")

func execute_behavior(delta: float):
	# Lazy load CommandCenter if it wasn't ready during _ready()
	if not is_instance_valid(base_building):
		var bases = get_tree().get_nodes_in_group("commandcenter")
		if bases.size() > 0:
			base_building = bases[0]

	if not is_active:
		activate()
		if not is_active:
			# No energy: fly back to base and stand idle
			return_to_base_and_idle(delta)
			return
			
	# Combat target selection heuristic (detection range <= 10.0m)
	current_target = select_target()
	
	if current_target:
		attack_target(current_target, delta)
	else:
		patrol_base(delta)

func select_target() -> Node3D:
	var defenders = get_tree().get_nodes_in_group("defenders")
	var catalysts = get_tree().get_nodes_in_group("catalysts")
	
	# Filter active catalysts within detection range (10.0m)
	var active_catalysts = []
	for c in catalysts:
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			var dist = global_position.distance_to(c.global_position)
			if dist <= detection_range:
				active_catalysts.append(c)
			
	# Find unclaimed catalysts within detection range
	var unclaimed_catalysts = []
	for c in active_catalysts:
		var is_claimed = false
		for d in defenders:
			if d != self and is_instance_valid(d) and d.get("current_target") == c:
				is_claimed = true
				break
		if not is_claimed:
			unclaimed_catalysts.append(c)
			
	# Heuristic 1: Target nearest unclaimed Catalyst within 10m
	if unclaimed_catalysts.size() > 0:
		return get_nearest(unclaimed_catalysts)
		
	# Heuristic 2: Target nearest spider-alien (not catalyst) within 10m
	var aliens = get_tree().get_nodes_in_group("aliens")
	var spiders = []
	for a in aliens:
		if is_instance_valid(a) and not a.is_queued_for_deletion() and not a.is_in_group("catalysts"):
			var dist = global_position.distance_to(a.global_position)
			if dist <= detection_range:
				spiders.append(a)
			
	if spiders.size() > 0:
		return get_nearest(spiders)
		
	# Heuristic 3: Fallback - target any nearest Catalyst within 10m even if claimed
	if active_catalysts.size() > 0:
		return get_nearest(active_catalysts)
		
	return null

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

func attack_target(enemy: Node3D, delta: float):
	var dist = global_position.distance_to(enemy.global_position)
	
	# Face the enemy
	var look_pos = enemy.global_position
	look_pos.y = global_position.y
	if global_position.distance_to(look_pos) > 0.1:
		var target_transform = transform.looking_at(look_pos, Vector3.UP)
		transform = transform.interpolate_with(target_transform, 10.0 * delta)
		
	time_since_last_attack += delta
	
	if dist <= attack_range:
		# In range, stop and attack
		velocity = Vector3.ZERO
		
		if time_since_last_attack >= attack_cooldown:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
				draw_laser_beam(global_position + Vector3(0, 0.5, 0), enemy.global_position + Vector3(0, 0.5, 0))
			time_since_last_attack = 0.0
	else:
		# Move towards enemy
		move_to_target(enemy.global_position, delta)

func draw_laser_beam(from_pos: Vector3, to_pos: Vector3):
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	var material = StandardMaterial3D.new()
	
	material.albedo_color = Color(0.0, 1.0, 1.0) # Cyan laser beam
	material.emission_enabled = true
	material.emission = Color(0.0, 1.0, 1.0)
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

func patrol_base(delta: float):
	if not is_instance_valid(base_building):
		var bases = get_tree().get_nodes_in_group("commandcenter")
		if bases.size() > 0:
			base_building = bases[0]
			print("Defender: Base found during patrol!")
		else:
			velocity = Vector3.ZERO
			return
		
	# Choose new random patrol target if we don't have one, reached it, or got stuck/unreachable path
	var needs_new_target = false
	if patrol_target == Vector3.ZERO:
		needs_new_target = true
	else:
		var dist_to_patrol = global_position.distance_to(patrol_target)
		if dist_to_patrol < 1.5:
			needs_new_target = true
		elif target_set_frames > 5 and navigation_agent.is_navigation_finished():
			# If navigation is finished but we are still far away, the target was likely unreachable or map wasn't ready
			needs_new_target = true
			
	if needs_new_target:
		var offset = Vector3(randf_range(-10.0, 10.0), 0.0, randf_range(-10.0, 10.0))
		patrol_target = base_building.global_position + offset
		navigation_agent.target_position = patrol_target
		target_set_frames = 0
	else:
		target_set_frames += 1
		
	# Update noise angle (smooth random path deviation)
	noise_timer -= delta
	if noise_timer <= 0:
		noise_timer = randf_range(0.5, 2.0)
		target_noise_angle = randf_range(-0.6, 0.6)
	current_noise_angle = lerp(current_noise_angle, target_noise_angle, delta * 2.0)
	
	# Move using navigation path + noise
	if not navigation_agent.is_navigation_finished():
		var next_pos = navigation_agent.get_next_path_position()
		var optimal_dir = global_position.direction_to(next_pos)
		optimal_dir.y = 0
		optimal_dir = optimal_dir.normalized()
		
		var noisy_dir = optimal_dir.rotated(Vector3.UP, current_noise_angle)
		velocity = noisy_dir * speed
		
		# Smooth looking at movement direction
		if velocity.length() > 0.1:
			var look_pos = global_position + velocity
			look_pos.y = global_position.y
			var target_transform = transform.looking_at(look_pos, Vector3.UP)
			transform = transform.interpolate_with(target_transform, 5.0 * delta)
	else:
		velocity = Vector3.ZERO

func return_to_base_and_idle(delta: float):
	if not is_instance_valid(base_building):
		var bases = get_tree().get_nodes_in_group("commandcenter")
		if bases.size() > 0:
			base_building = bases[0]
		else:
			velocity = Vector3.ZERO
			return
		
	# Reset patrol target when returning to base
	patrol_target = Vector3.ZERO
	
	var dist = global_position.distance_to(base_building.global_position)
	if dist <= 3.0:
		# Stay still at base
		velocity = Vector3.ZERO
	else:
		# Move back to base
		move_to_target(base_building.global_position, delta)
