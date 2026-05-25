extends CharacterBody3D

@export var max_health: float = 30.0
@export var speed: float = 3.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 4.0
@export var attack_cooldown: float = 1.5

var current_health: float
var target: Node3D = null
var is_attacking: bool = false
var time_since_last_attack: float = 0.0

var last_position: Vector3 = Vector3.ZERO
var stuck_timer: float = 0.0
var unstuck_vector: Vector3 = Vector3.ZERO
var unstuck_time_left: float = 0.0

var noise_timer: float = 0.0
var target_noise_angle: float = 0.0
var current_noise_angle: float = 0.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D if has_node("NavigationAgent3D") else null
@onready var healthbar = $Healthbar if has_node("Healthbar") else null

func _ready() -> void:
	add_to_group("aliens")
	current_health = max_health
	if healthbar:
		healthbar.init_health(max_health, current_health)
	
	await get_tree().create_timer(0.5).timeout
	find_target()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		target = null
		find_target()
		if target == null:
			velocity = Vector3.ZERO
			move_and_slide()
			return
			
	var distance_to_target = global_position.distance_to(target.global_position)
	
	noise_timer -= delta
	if noise_timer <= 0:
		noise_timer = randf_range(0.5, 2.0)
		target_noise_angle = randf_range(-0.8, 0.8)
	current_noise_angle = lerp(current_noise_angle, target_noise_angle, delta * 2.0)
	
	if distance_to_target <= attack_range:
		velocity = Vector3.ZERO
		is_attacking = true
		time_since_last_attack += delta
		
		var look_pos = target.global_position
		look_pos.y = global_position.y
		if global_position.distance_to(look_pos) > 0.1:
			look_at(look_pos, Vector3.UP)
			
		if time_since_last_attack >= attack_cooldown:
			attack_target()
			time_since_last_attack = 0.0
	else:
		is_attacking = false
		time_since_last_attack = 0.0
		
		if unstuck_time_left > 0:
			unstuck_time_left -= delta
			velocity = unstuck_vector
			if velocity.length() > 0.1:
				var look_pos = global_position + velocity
				look_pos.y = global_position.y
				look_at(look_pos, Vector3.UP)
			move_and_slide()
		else:
			if nav_agent and not nav_agent.is_navigation_finished():
				var next_pos = nav_agent.get_next_path_position()
				var optimal_dir = global_position.direction_to(next_pos)
				optimal_dir.y = 0
				optimal_dir = optimal_dir.normalized()
				
				var noise_multiplier = clamp((distance_to_target - attack_range) / 15.0, 0.0, 1.0)
				var noisy_dir = optimal_dir.rotated(Vector3.UP, current_noise_angle * noise_multiplier)
				
				velocity = noisy_dir * speed
				
				if velocity.length() > 0.1:
					var look_pos = global_position + velocity
					look_pos.y = global_position.y
					look_at(look_pos, Vector3.UP)
			else:
				var optimal_dir = global_position.direction_to(target.global_position)
				optimal_dir.y = 0
				optimal_dir = optimal_dir.normalized()
				
				var noise_multiplier = clamp((distance_to_target - attack_range) / 15.0, 0.0, 1.0)
				var noisy_dir = optimal_dir.rotated(Vector3.UP, current_noise_angle * noise_multiplier)
				
				velocity = noisy_dir * speed
				
				if velocity.length() > 0.1:
					var look_pos = global_position + velocity
					look_pos.y = global_position.y
					look_at(look_pos, Vector3.UP)
				
			move_and_slide()
			
			if global_position.distance_to(last_position) < speed * delta * 0.3:
				stuck_timer += delta
				if stuck_timer > 0.5:
					unstuck_vector = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * speed * 2.0
					unstuck_time_left = 0.3
					stuck_timer = 0.0
					if target and nav_agent:
						nav_agent.target_position = target.global_position
			else:
				stuck_timer = 0.0
				
			last_position = global_position

func find_target() -> void:
	var buildings = get_tree().get_nodes_in_group("commandcenter") + get_tree().get_nodes_in_group("factory")
	var nearest_dist = INF
	var nearest_building = null
	
	for b in buildings:
		if is_instance_valid(b) and not b.is_queued_for_deletion():
			var d = global_position.distance_to(b.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest_building = b
				
	target = nearest_building
	if target and nav_agent:
		nav_agent.target_position = target.global_position

func attack_target() -> void:
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(attack_damage)

func take_damage(amount: float) -> void:
	current_health -= amount
	if healthbar:
		healthbar.update_health(current_health)
		
	if current_health <= 0:
		queue_free()
