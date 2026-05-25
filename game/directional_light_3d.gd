extends DirectionalLight3D

@export var day_length_minutes: float = 5.0

@export_range(0.0, 1.0) var time_of_day: float = 0.5 

var rotation_speed: float = 0.0


func _ready() -> void:
	rotation_speed = (2.0 * PI) / (day_length_minutes * 60.0)


func _process(delta: float) -> void:
	time_of_day += (rotation_speed / (2.0 * PI)) * delta
	
	if time_of_day >= 1.0:
		time_of_day = 0.0
	
	var target_angle = time_of_day * 2.0 * PI
	
	rotation.x = target_angle
	rotation.y = deg_to_rad(-45.0)
