extends Control

@onready var credits_label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/CreditsLabel

func _ready() -> void:
	GameManager.credits_changed.connect(_on_credits_changed)
	_on_credits_changed(GameManager.credits)

func _on_credits_changed(new_amount: int) -> void:
	if new_amount < 1000: credits_label.text = "%.1f" % new_amount
	else:
		var k_value =  float(new_amount) / 1000.0
		credits_label.text = "%.1fk" % k_value
