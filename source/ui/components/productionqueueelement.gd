extends Button

@onready var icon_rect = $ItemIcon
@onready var status_label = $Status

func setup(unit_data: UnitData):
	if not is_node_ready():
		await ready
		
	if unit_data and unit_data.icon:
		icon_rect.texture = unit_data.icon
	else:
		print("WARNING: Icon not found in resource")
		
	status_label.text = "0%"

func update_progress(percent: int):
	if status_label:
		status_label.text = str(percent) + "%"
