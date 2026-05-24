extends PanelContainer

@onready var label = $MarginContainer/Label

func _ready() -> void:
	# На случай если init_alert не был вызван (например, при тестировании сцены)
	if not label:
		label = $MarginContainer/Label

func init_alert(text: String, type: int):
	if not label:
		label = $MarginContainer/Label
		
	label.text = text
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.border_width_left = 1.5
	style.border_width_right = 1.5
	style.border_width_top = 1.5
	style.border_width_bottom = 1.5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_top_left = 5
	style.corner_radius_bottom_left = 5
	
	match type:
		GameManager.AlertType.INFO:
			style.border_color = Color(0.2, 0.6, 1.0, 1.0) # Синий
		GameManager.AlertType.SUCCESS:
			style.border_color = Color(0.2, 0.8, 0.2, 1.0) # Зеленый
		GameManager.AlertType.WARNING:
			style.border_color = Color(1.0, 0.8, 0.0, 1.0) # Желтый
		GameManager.AlertType.ERROR:
			style.border_color = Color(0.9, 0.2, 0.2, 1.0) # Красный
			
	add_theme_stylebox_override("panel", style)
	
	# Анимация
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	# Чем длиннее текст, тем дольше висит
	var wait_time = max(3.0, text.length() * 0.08)
	tween.tween_interval(wait_time) 
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
