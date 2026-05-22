extends CharacterBody3D
class_name DroneBase

# Общие параметры для всех дронов
@export var speed := 5.0
@export var max_health := 100.0
var current_health := max_health

@onready var navigation_agent = $NavigationAgent3D

# Общая логика движения по навигационной сетке
func move_to_target(target_pos: Vector3, delta: float):
	navigation_agent.target_position = target_pos
	if not navigation_agent.is_navigation_finished():
		var next_path_position = navigation_agent.get_next_path_position()
		var new_velocity = global_position.direction_to(next_path_position) * speed
		velocity = new_velocity
		move_and_slide()

# Общая функция получения урона
func take_damage(amount: float):
	current_health -= amount
	if current_health <= 0:
		die()

func die():
	queue_free()

# --- А ТЕПЕРЬ МАГИЯ FSM ---
# Базовая функция работы ИИ, которую мы переопределим у детей
func _process(delta: float) -> void:
	execute_behavior(delta)

func execute_behavior(delta: float):
	# В базовом классе она пустая. Каждый дрон сам решит, что тут делать.
	pass
