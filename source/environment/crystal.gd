extends StaticBody3D

@export var max_resources: int = 1000
var current_resources: int = max_resources

# Ссылка на наш новый кастомный бар
@onready var resource_bar = $Resourcebar

func _ready() -> void:
	# Инициализируем бар стартовыми значениями
	resource_bar.init_resource(max_resources, current_resources)


# Эту функцию будет вызывать дрон-сборщик, когда бурит кристалл
func harvest(amount: int):
	# Защита, чтобы нельзя было уйти в минус, если у кристалла осталось мало ресурсов
	var actual_amount = min(amount, current_resources)
	current_resources -= actual_amount
	
	# Обновляем полоску прогресса и текст
	resource_bar.update_resource(current_resources)
	
	if current_resources <= 0:
		deplete_and_respawn()


func deplete_and_respawn():
	# Принудительно прячем бар, так как ресурс иссяк
	resource_bar.hide()
	
	$MeshInstance3D.visible = false
	$CollisionShape3D.disabled = true # Выключаем хитбокс, чтобы он не мешал!
	
	# Запускаем встроенный таймер респавна (sleep time)
	await get_tree().create_timer(30.0).timeout # Ждем 30 секунд
	
	# Возвращаем кристалл к жизни
	current_resources = max_resources
	
	# Сбрасываем значения внутри бара к 1000/1000. 
	# Функция init_resource сама оставит его невидимым до первого удара дрона.
	resource_bar.init_resource(max_resources, current_resources)
	
	$MeshInstance3D.visible = true
	$CollisionShape3D.disabled = false
