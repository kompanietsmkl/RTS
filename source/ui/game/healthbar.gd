extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_hp(current_hp: int, max_hp: int):
	$SubViewport/TextureProgressBar.max_value = max_hp
	$SubViewport/TextureProgressBar.value = current_hp
