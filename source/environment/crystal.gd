extends StaticBody3D
var rng = RandomNumberGenerator.new()

@export var max_resources: float = 100.0
var current_resources: float = max_resources
var occupied_by_drone: Node = null

# Ссылка на наш новый кастомный бар
@onready var resource_bar = $Resourcebar

func _ready() -> void:
	# Инициализируем бар стартовыми значениями
	resource_bar.init_resource(max_resources, current_resources)


# Эту функцию будет вызывать дрон-сборщик, когда бурит кристалл
func harvest(amount: float) -> float:
	# Защита, чтобы нельзя было уйти в минус, если у кристалла осталось мало ресурсов
	var actual_amount = min(amount, current_resources)
	current_resources -= actual_amount
	
	# Обновляем полоску прогресса и текст
	resource_bar.update_resource(current_resources)
	
	# Используем небольшой эпсилон для защиты от погрешностей float
	if current_resources <= 0.01:
		current_resources = 0
		deplete_and_respawn()
		
	return actual_amount

func deplete_and_respawn():
	# Принудительно прячем бар, так как ресурс иссяк
	resource_bar.hide()
	
	$MeshInstance3D.visible = false
	$CollisionShape3D.set_deferred("disabled", true) # Безопасное отключение физики
	remove_from_group("crystals") # Прячем кристалл от радаров дронов!
	
	# Запускаем встроенный таймер респавна (sleep time)
	await get_tree().create_timer(rng.randi_range(20.0, 60.0)).timeout # Ждем 20-60 секунд
	
	# Возвращаем кристалл к жизни
	current_resources = max_resources
	
	# Сбрасываем значения внутри бара к 1000/1000. 
	# Функция init_resource сама оставит его невидимым до первого удара дрона.
	resource_bar.init_resource(max_resources, current_resources)
	
	$MeshInstance3D.visible = true
	$CollisionShape3D.set_deferred("disabled", false)
	add_to_group("crystals") # Дроны снова могут его найти
	
func _mouse_enter() -> void:
	# Меняем форму курсора на встроенную "руку" или "указатель"
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _mouse_exit() -> void:
	# Возвращаем обычный курсор, когда мышь ушла с объекта
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
