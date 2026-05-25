extends Node3D

@onready var progress_bar = $SubViewport/TextureProgressBar

func _ready():
	hide()

func init_health(max_hp: float, current_hp: float):
	progress_bar.max_value = max_hp
	progress_bar.value = current_hp
	
	if current_hp < max_hp:
		show()
	else:
		hide()

func update_health(new_hp: float):
	progress_bar.value = new_hp
	
	if new_hp < progress_bar.max_value and new_hp > 0:
		show()
		
	if new_hp <= 0:
		hide()
