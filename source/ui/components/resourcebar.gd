extends Node3D

@onready var progress_bar = $SubViewport/Control/TextureProgressBar
@onready var label = $SubViewport/Control/Label

func _ready():
	# По дефолту скрываем, как и хелсбар
	hide()

# Инициализация (вызывается при старте карты для каждого кристалла)
func init_resource(max_res: float, current_res: float):
	progress_bar.max_value = max_res
	progress_bar.value = current_res
	
	# Обновляем текст
	_update_text(current_res, max_res)

# Обновление при добыче ресурса
func update_resource(new_res: float):
	progress_bar.value = new_res
	_update_text(new_res, progress_bar.max_value)
	
	# Показываем полоску, если ресурс начали копать
	if new_res < progress_bar.max_value and new_res > 0:
		show()
		
	# Если кристалл иссяк — скрываем бар
	if new_res <= 0:
		hide()

# Внутренняя функция для сборки красивой строки текста
func _update_text(current: float, max_val: float):
	# Вариант 1: Просто "45 / 50" (форматирование через %d, чтобы убрать знаки после запятой)
	label.text = "%d/%d" % [current, max_val]
