extends Node

@onready var btn_gatherer = $GathererProd
@onready var btn_defender = $DefenderProd
@onready var btn_upgrade = $Upgrade

@onready var label_gatherer = $GathererProd/Price
@onready var label_defender = $DefenderProd/Price
@onready var label_upgrade = $Upgrade/Price

const GathererData = preload("res://source/resources/gatherer_data.tres")
const DefenderData = preload("res://source/resources/defender_data.tres")

func _ready() -> void:
	btn_gatherer.pressed.connect(func(): _try_produce_drone(GathererData, btn_gatherer))
	btn_defender.pressed.connect(func(): _try_produce_drone(DefenderData, btn_defender))
	btn_upgrade.pressed.connect(_on_upgrade_pressed)
	
	if GathererData:
		label_gatherer.text = str(GathererData.cost)
	if DefenderData:
		label_defender.text = str(DefenderData.cost)
	
	GameManager.toggle_factory_ui.connect(update_prices)
	update_prices()

func update_prices():
	var factories = get_tree().get_nodes_in_group("factory")
	var factory = null
	if factories.size() > 0:
		factory = factories[0]
	else:
		factory = get_tree().root.find_child("Factory", true, false)
		
	if factory and factory.has_method("get_upgrade_cost"):
		var cost = factory.get_upgrade_cost()
		if cost > 0:
			label_upgrade.text = str(cost)
			btn_upgrade.disabled = false
		else:
			label_upgrade.text = "MAX"
			btn_upgrade.disabled = true

func _on_upgrade_pressed():
	var factories = get_tree().get_nodes_in_group("factory")
	if factories.size() > 0:
		factories[0].upgrade_factory()
	else:
		var factory = get_tree().root.find_child("Factory", true, false)
		if factory and factory.has_method("upgrade_factory"):
			factory.upgrade_factory()
		else:
			print("ERROR: Factory not found for upgrade!")
			
	update_prices()

func _try_produce_drone(unit_data: UnitData, button: Button):
	if GameManager.start_production(unit_data):
		pass
