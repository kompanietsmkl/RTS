extends Node

@onready var btn_gatherer = $GathererProd
@onready var btn_defender = $DefenderProd
@onready var btn_upgrade = $Upgrade

func _ready() -> void:
	btn_gatherer.pressed.connect(func(): _try_produce_drone("gatherer", btn_gatherer))
	btn_defender.pressed.connect(func(): _try_produce_drone("defender", btn_defender))
	btn_upgrade.pressed.connect(_on_upgrade_pressed)

func _on_upgrade_pressed():
	var factories = get_tree().get_nodes_in_group("factory")
	if factories.size() > 0:
		factories[0].upgrade_factory()
	else:
		var factory = get_tree().root.find_child("Factory", true, false)
		if factory and factory.has_method("upgrade_factory"):
			factory.upgrade_factory()
		else:
			print("ОШИБКА: Фабрика не найдена для апгрейда!")

func _try_produce_drone(type: String, button: Button):
	# Проверка: есть ли место в очереди (свободная энергия Production)
	if GameManager.active_production >= GameManager.energy_production:
		print("Недостаточно энергии производства!")
		return
		
	# Проверка: хватает ли денег (100 кредитов)
	if not GameManager.spend_credits(100):
		print("Недостаточно кредитов!")
		return
		
	print("Начинаю производство дрона: ", type)
	GameManager.active_production += 1
	
	# Визуальная индикация: блокируем кнопку (можно добавить Timer и показывать оставшееся время, но для MVP хватит блокировки)
	button.disabled = true
	var original_text = button.text
	button.text = "Строится..."
	
	await get_tree().create_timer(5.0).timeout
	
	# Спавним дрона через Фабрику
	var factories = get_tree().get_nodes_in_group("factory")
	if factories.size() > 0:
		factories[0].spawn_drone(type)
	else:
		# Если вдруг фабрики нет в группе, пробуем найти через корневой узел
		var factory = get_tree().root.find_child("Factory", true, false)
		if factory and factory.has_method("spawn_drone"):
			factory.spawn_drone(type)
		else:
			print("ОШИБКА: Фабрика не найдена!")
			
	# Освобождаем энергию производства и восстанавливаем кнопку
	GameManager.active_production -= 1
	button.text = original_text
	button.disabled = false
