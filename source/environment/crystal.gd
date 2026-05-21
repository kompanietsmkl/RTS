extends StaticBody3D

@export var max_resources: int = 1000
var current_resources: int = max_resources

# Эту функцию будет вызывать дрон-сборщик, когда бурит кристалл
func harvest(amount: int):
	current_resources -= amount
	if current_resources <= 0:
		deplete_and_respawn()

func deplete_and_respawn():
	# 1. Говорим менеджеру спавна (или глобальному триггеру), 
	# что через N секунд в этих координатах нужно создать новый кристалл.
	# (Для MVP можно просто скрыть меш и ОТКЛЮЧИТЬ коллизию)
	$MeshInstance3D.visible = false
	$CollisionShape3D.disabled = true # Выключаем хитбокс, чтобы он не мешал!
	
	# 2. Запускаем встроенный таймер респавна (sleep time)
	await get_tree().create_timer(30.0).timeout # Ждем 30 секунд
	
	# 3. Возвращаем кристалл к жизни
	current_resources = max_resources
	$MeshInstance3D.visible = true
	$CollisionShape3D.disabled = false
