extends DroneBase # Наследуем скорость, здоровье, движение и навигацию

var current_resources := 0
var max_capacity := 10

# Переопределяем логику поведения
func execute_behavior(delta: float):
	if current_resources < max_capacity:
		gather_nearest_crystal(delta)
	else:
		return_to_base(delta)

func gather_nearest_crystal(delta):
	# Код поиска кристалла и движения к нему (используя move_to_target())
	pass

func return_to_base(delta):
	# Код полета к главному зданию для разгрузки
	pass
