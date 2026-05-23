extends CharacterBody3D
class_name DroneBase

# Общие параметры для всех дронов
@export var speed := 5.0
@export var max_health := 100.0
var current_health := max_health

@onready var navigation_agent = $NavigationAgent3D

var stuck_timer: float = 0.0
var previous_pos: Vector3 = Vector3.ZERO
var nudge_dir: Vector3 = Vector3.ZERO

# Общая логика движения по навигационной сетке
func move_to_target(target_pos: Vector3, delta: float):
	navigation_agent.target_position = target_pos
	if not navigation_agent.is_navigation_finished():
		var next_path_position = navigation_agent.get_next_path_position()
		var new_velocity = global_position.direction_to(next_path_position) * speed
		
		# Анти-застревание: если мы почти не сдвинулись за кадр
		if previous_pos.distance_to(global_position) < speed * delta * 0.2:
			stuck_timer += delta
			if stuck_timer > 0.5:
				if nudge_dir == Vector3.ZERO:
					nudge_dir = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized()
				# Добавляем хаотичный толчок в сторону
				new_velocity += nudge_dir * speed * 1.5
		else:
			stuck_timer = 0.0
			nudge_dir = Vector3.ZERO
			
		previous_pos = global_position
		velocity = new_velocity
		
		# Плавный поворот в сторону движения (игнорируем высоту Y, чтобы дрон не кивал носом)
		var flat_target = Vector3(next_path_position.x, global_position.y, next_path_position.z)
		if global_position.distance_to(flat_target) > 0.1:
			var target_transform = transform.looking_at(flat_target, Vector3.UP)
			# interpolate_with делает поворот плавным (10.0 - скорость поворота)
			transform = transform.interpolate_with(target_transform, 10.0 * delta)
			
		move_and_slide()

# Общая функция получения урона
func take_damage(amount: float):
	current_health -= amount
	if current_health <= 0:
		die()

func die():
	queue_free()

var time_passed: float = 0.0
var base_y: float = 0.0
var is_idle: bool = false

# --- А ТЕПЕРЬ МАГИЯ FSM ---
# Базовая функция работы ИИ, которую мы переопределим у детей
func _process(delta: float) -> void:
	# Если мы хотим, чтобы дрон плавно останавливался при отсутствии команд
	if velocity.length() > 0:
		velocity = velocity.move_toward(Vector3.ZERO, speed * delta * 2.0)
		move_and_slide()
		
	execute_behavior(delta)
	
	# Левитация при простое
	if velocity.length() < 0.1:
		if not is_idle:
			is_idle = true
			base_y = position.y
			time_passed = 0.0
			
		time_passed += delta
		if time_passed > 0.2:
			var levitation = sin((time_passed - 0.2) * 1.5) * 0.1
			position.y = base_y + levitation
	else:
		if is_idle:
			is_idle = false
			position.y = base_y

func execute_behavior(delta: float):
	# В базовом классе она пустая. Каждый дрон сам решит, что тут делать.
	pass
	
