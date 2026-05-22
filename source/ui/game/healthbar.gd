extends Node3D

@onready var progress_bar = $SubViewport/TextureProgressBar

func _ready():
	# Скрываем хелсбар при создании объекта
	hide() # или self.visible = false

# Функция для инициализации (вызывается при спавне объекта)
func init_health(max_hp: float, current_hp: float):
	progress_bar.max_value = max_hp
	progress_bar.value = current_hp
	
	# Если при создании у объекта здоровье МЕНЬШЕ максимального
	# (например, спавнится уже раненый юнит), то показываем полоску
	if current_hp < max_hp:
		show()
	else:
		hide()

# Функция для обновления здоровья при получении урона
func update_health(new_hp: float):
	progress_bar.value = new_hp
	
	# Как только получен первый урон (здоровье стало меньше максимума) — показываем
	if new_hp < progress_bar.max_value and new_hp > 0:
		show()
		
	# Если здоровье опустилось до 0, скрываем (юнит умирает)
	if new_hp <= 0:
		hide()
