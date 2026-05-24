extends Control

@onready var credits_label = $Box/VBoxContainer/Header/CreditsLabel

func _ready() -> void:
	# Подписываемся на изменение кредитов
	GameManager.credits_changed.connect(_on_credits_changed)
	# Инициализируем стартовым значением
	_on_credits_changed(GameManager.credits)

func _on_credits_changed(new_amount: int) -> void:
	# Конвертируем в формат (x.x)k
	if new_amount < 1000: credits_label.text = "%.1f" % new_amount
	else:
		var k_value =  float(new_amount) / 1000.0
		credits_label.text = "%.1fk" % k_value
