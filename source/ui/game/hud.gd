extends CanvasLayer

@onready var production_hbox: HBoxContainer = $ProductionQueue
@onready var alerts_container: VBoxContainer = $AlertsContainer
var production_ui_items: Dictionary = {}
const QueueElementScene = preload("res://source/ui/components/productionqueueleement.tscn")
const AlertScene = preload("res://source/ui/components/alert_message.tscn")

func _ready() -> void:
	GameManager.production_added.connect(_on_production_added)
	GameManager.production_progress.connect(_on_production_progress)
	GameManager.production_completed.connect(_on_production_completed)
	GameManager.show_alert.connect(_on_show_alert)

func _on_show_alert(message: String, type: int):
	var alert = AlertScene.instantiate()
	alerts_container.add_child(alert)
	alert.init_alert(message, type)

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
