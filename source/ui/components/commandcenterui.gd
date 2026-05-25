extends Button

@onready var price_label = $Price

func _ready() -> void:
	pressed.connect(_on_upgrade_pressed)
	GameManager.toggle_commandcenter_ui.connect(update_price)
	update_price()

func update_price() -> void:
	var centers = get_tree().get_nodes_in_group("commandcenter")
	var center = null
	if centers.size() > 0:
		center = centers[0]
	else:
		center = get_tree().root.find_child("CommandCenter", true, false)
		
	if center and center.has_method("get_upgrade_cost"):
		var cost = center.get_upgrade_cost()
		if cost > 0:
			if price_label:
				price_label.text = str(cost)
			disabled = false
		else:
			if price_label:
				price_label.text = "MAX"
			disabled = true

func _on_upgrade_pressed() -> void:
	var centers = get_tree().get_nodes_in_group("commandcenter")
	if centers.size() > 0:
		centers[0].upgrade_base()
	else:
		var center = get_tree().root.find_child("CommandCenter", true, false)
		if center and center.has_method("upgrade_base"):
			center.upgrade_base()
		else:
			print("ERROR: CommandCenter not found for upgrade!")
			
	update_price()
