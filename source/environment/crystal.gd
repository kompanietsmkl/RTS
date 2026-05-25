extends StaticBody3D
var rng = RandomNumberGenerator.new()

@export var max_resources: float = 100.0
var current_resources: float = max_resources
var occupied_by_drone: Node = null

@onready var resource_bar = $Resourcebar

func _ready() -> void:
	resource_bar.init_resource(max_resources, current_resources)


func harvest(amount: float) -> float:
	var actual_amount = min(amount, current_resources)
	current_resources -= actual_amount
	
	resource_bar.update_resource(current_resources)
	
	if current_resources <= 0.01:
		current_resources = 0
		deplete_and_respawn()
		
	return actual_amount

func deplete_and_respawn():
	resource_bar.hide()
	
	$MeshInstance3D.visible = false
	$CollisionShape3D.set_deferred("disabled", true)
	remove_from_group("crystals")
	
	await get_tree().create_timer(rng.randi_range(20.0, 60.0)).timeout
	
	current_resources = max_resources
	
	resource_bar.init_resource(max_resources, current_resources)
	
	$MeshInstance3D.visible = true
	$CollisionShape3D.set_deferred("disabled", false)
	add_to_group("crystals")
	
func _mouse_enter() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _mouse_exit() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
