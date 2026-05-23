extends DroneBase # Тоже получает все базовые функции бесплатно

@export var attack_range := 8.0
@export var damage := 15.0

func _enter_tree() -> void:
	GameManager.total_defenders += 1

func _exit_tree() -> void:
	GameManager.total_defenders -= 1

# У защитника поведение совершенно другое
func execute_behavior(delta: float):
	var enemy = find_nearest_enemy()
	if enemy:
		attack_target(enemy, delta)
	else:
		patrol_base(delta)

func find_nearest_enemy() -> Node3D:
	# Логика поиска алиенов (например, через Area3D или группы)
	return null

func attack_target(target: Node3D, delta: float):
	# Летим к врагу и стреляем
	pass

func patrol_base(delta: float):
	# Просто летаем вокруг командного центра, пока врагов нет
	pass
