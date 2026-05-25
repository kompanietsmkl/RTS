extends CanvasLayer

@onready var production_hbox: HBoxContainer = $ProductionQueue
@onready var alerts_container: VBoxContainer = $AlertsContainer
var production_ui_items: Dictionary = {}
var heal_cost: int = 50
var cheat_buffer: String = ""
const QueueElementScene = preload("res://source/ui/components/productionqueueelement.tscn")
const AlertScene = preload("res://source/ui/components/alert_message.tscn")

func _ready() -> void:
	GameManager.production_added.connect(_on_production_added)
	GameManager.production_progress.connect(_on_production_progress)
	GameManager.production_completed.connect(_on_production_completed)
	GameManager.show_alert.connect(_on_show_alert)
	GameManager.wave_started.connect(_on_wave_started)
	
	if $Heal:
		$Heal.pressed.connect(_on_heal_pressed)
		_update_heal_cost(0)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Convert keycode to string, assuming letters
		var key_str = OS.get_keycode_string(event.physical_keycode).to_upper()
		if key_str.length() == 1:
			cheat_buffer += key_str
			if cheat_buffer.length() > 10:
				cheat_buffer = cheat_buffer.substr(cheat_buffer.length() - 10)
				
			if cheat_buffer.ends_with("NNNHHH"):
				cheat_buffer = "" # clear buffer
				GameManager.add_credits(10000)
				GameManager.show_alert.emit("CHEAT ACTIVATED: +10000 credits", GameManager.AlertType.SUCCESS)
				SoundManager.play_sfx("production") # Optional feedback

func _on_wave_started(wave_number: int):
	_update_heal_cost(wave_number)

func _update_heal_cost(wave_number: int):
	heal_cost = 50 + max(0, wave_number - 1) * 10
	if $Heal and $Heal.has_node("Price"):
		$Heal.get_node("Price").text = str(heal_cost)

func _process(_delta: float) -> void:
	if $Heal:
		var aliens = get_tree().get_nodes_in_group("aliens")
		var wm = get_tree().root.find_child("WaveManager", true, false)
		if wm and wm.wave_number > 0 and aliens.size() == 0:
			$Heal.visible = true
		else:
			$Heal.visible = false

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
		var percent = int(((duration - time_left) / duration) * 100)
		item.update_progress(percent)

func _on_production_completed(id: int):
	if production_ui_items.has(id):
		var item = production_ui_items[id]
		item.queue_free()
		production_ui_items.erase(id)
		
func _on_heal_pressed():
	var all_units = get_tree().get_nodes_in_group("commandcenter") + get_tree().get_nodes_in_group("factory") + get_tree().get_nodes_in_group("drones") + get_tree().get_nodes_in_group("defenders") + get_tree().get_nodes_in_group("gatherers")
	
	var needs_healing = false
	for u in all_units:
		if "current_health" in u and "max_health" in u:
			if u.current_health < u.max_health:
				needs_healing = true
				break
				
	if not needs_healing:
		GameManager.show_alert.emit("All units and buildings are already at full health!", GameManager.AlertType.INFO)
		return

	if GameManager.spend_credits(heal_cost):
		GameManager.show_alert.emit("All units and buildings healed!", GameManager.AlertType.SUCCESS)
		
		for u in all_units:
			if "current_health" in u and "max_health" in u:
				u.current_health = u.max_health
				if u.get("healthbar"): u.healthbar.init_health(u.max_health, u.current_health)
	else:
		GameManager.show_alert.emit("Not enough credits to heal!", GameManager.AlertType.ERROR)
