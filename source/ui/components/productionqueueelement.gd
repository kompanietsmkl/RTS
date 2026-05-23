extends Button

@onready var icon_rect = $ItemIcon
@onready var status_label = $Status

func setup(unit_data: UnitData):
	# Ждем, пока дочерние узлы инициализируются, если вызываем сразу после instantiate
	if not is_node_ready():
		await ready
		
	if unit_data and unit_data.icon:
		icon_rect.texture = unit_data.icon
	else:
		print("ВНИМАНИЕ: Иконка не найдена в ресурсе")
		
	status_label.text = "0%"

func update_progress(percent: int):
	if status_label:
		status_label.text = str(percent) + "%"
