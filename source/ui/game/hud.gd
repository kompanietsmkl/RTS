extends CanvasLayer


@onready var production_hbox: HBoxContainer = $ProductionQueue
var production_ui_items: Dictionary = {}
const QueueElementScene = preload("res://source/ui/components/productionqueueleement.tscn")

func _ready() -> void:
	GameManager.production_added.connect(_on_production_added)
	GameManager.production_progress.connect(_on_production_progress)
	GameManager.production_completed.connect(_on_production_completed)


func _on_production_added(id: int, unit_data: UnitData):
	var item = QueueElementScene.instantiate()
	production_hbox.add_child(item)
	item.setup(unit_data)
	production_ui_items[id] = item

func _on_production_progress(id: int, time_left: float, duration: float):
	if production_ui_items.has(id):
		var item = production_ui_items[id]
		# Вычисляем процент завершения (от 0 до 100)
		var percent = int(((duration - time_left) / duration) * 100)
		item.update_progress(percent)

func _on_production_completed(id: int):
	if production_ui_items.has(id):
		var item = production_ui_items[id]
		item.queue_free()
		production_ui_items.erase(id)
