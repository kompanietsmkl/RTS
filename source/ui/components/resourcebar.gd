extends Node3D

@onready var progress_bar = $SubViewport/Control/TextureProgressBar
@onready var label = $SubViewport/Control/Label

func _ready():
	hide()

func init_resource(max_res: float, current_res: float):
	progress_bar.max_value = max_res
	progress_bar.value = current_res
	
	_update_text(current_res, max_res)

func update_resource(new_res: float):
	progress_bar.value = new_res
	_update_text(new_res, progress_bar.max_value)
	
	if new_res < progress_bar.max_value and new_res > 0:
		show()
		
	if new_res <= 0:
		hide()

func _update_text(current: float, max_val: float):
	label.text = "%d/%d" % [current, max_val]
