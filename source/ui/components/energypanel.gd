extends Control

@onready var energy_label = $Box/VBoxContainer/Header/EnergyLabel
@onready var slider_gather = $Box/VBoxContainer/GatherRow/GatherSlider
@onready var label_gather = $Box/VBoxContainer/GatherRow/GatherValue
@onready var slider_defend = $Box/VBoxContainer/DefendRow/DefendSlider
@onready var label_defend = $Box/VBoxContainer/DefendRow/DefendValue
@onready var slider_prod = $Box/VBoxContainer/ProductionRow/ProductionSlider
@onready var label_prod = $Box/VBoxContainer/ProductionRow/ProductionValue

func _ready():
	# Подписываемся на сигналы
	GameManager.energy_distribution_changed.connect(_on_energy_distribution_changed)
	GameManager.base_level_changed.connect(_on_base_level_changed)
	
	# Настраиваем лимиты ползунков
	slider_gather.max_value = GameManager.max_energy
	slider_defend.max_value = GameManager.max_energy
	slider_prod.max_value = GameManager.max_energy
	
	# Устанавливаем текущие значения без вызова сигналов ползунка (используем set_value_no_signal если надо, 
	# но тут мы подключим сигналы ПОСЛЕ инициализации)
	slider_gather.value = GameManager.energy_gathering
	slider_defend.value = GameManager.energy_defense
	slider_prod.value = GameManager.energy_production
	
	_update_ui()
	
	# Подключаем UI эвенты
	slider_gather.value_changed.connect(_on_gather_slider_changed)
	slider_defend.value_changed.connect(_on_defend_slider_changed)
	slider_prod.value_changed.connect(_on_prod_slider_changed)

func _update_ui():
	var available = GameManager.get_available_energy()
	var max_e = GameManager.max_energy
	
	energy_label.text = "%d/%d" % [available, max_e]
	label_gather.text = str(GameManager.energy_gathering)
	label_defend.text = str(GameManager.energy_defense)
	label_prod.text = str(GameManager.energy_production)

func _on_gather_slider_changed(new_value: float):
	if not GameManager.set_energy_gathering(int(new_value)):
		# Если энергии не хватает, откатываем ползунок обратно
		slider_gather.set_value_no_signal(GameManager.energy_gathering)
	_update_ui()

func _on_defend_slider_changed(new_value: float):
	if not GameManager.set_energy_defense(int(new_value)):
		slider_defend.set_value_no_signal(GameManager.energy_defense)
	_update_ui()

func _on_prod_slider_changed(new_value: float):
	if not GameManager.set_energy_production(int(new_value)):
		slider_prod.set_value_no_signal(GameManager.energy_production)
	_update_ui()

func _on_energy_distribution_changed(gathering: int, defense: int, production: int):
	# Если энергия изменилась извне (например, другой скрипт обнулил)
	slider_gather.set_value_no_signal(gathering)
	slider_defend.set_value_no_signal(defense)
	slider_prod.set_value_no_signal(production)
	_update_ui()

func _on_base_level_changed(_new_level: int, new_max_energy: int):
	# При прокачке базы лимит ползунков увеличивается
	slider_gather.max_value = new_max_energy
	slider_defend.max_value = new_max_energy
	slider_prod.max_value = new_max_energy
	_update_ui()
