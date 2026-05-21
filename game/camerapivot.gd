extends Node3D

@export var move_speed := 15.0
@export var drag_sensitivity := 0.022
@export var zoom_speed := 1.0

@export var min_zoom := 6.0
@export var max_zoom := 30.0

@onready var camera: Camera3D = $IsometricCam3D

# Границы карты
var map_limit_min := Vector2(-40, -40)
var map_limit_max := Vector2(40, 40)

var dragging := false


func _process(delta: float) -> void:

	# ===== WASD MOVEMENT =====

	var input_dir := Vector2.ZERO

	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1

	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1

	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1

	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1

	if input_dir != Vector2.ZERO:

		input_dir = input_dir.normalized()

		# Направления камеры
		var cam_right = camera.global_basis.x
		var cam_forward = camera.global_basis.z

		# Убираем вертикальную составляющую
		cam_right.y = 0
		cam_forward.y = 0

		cam_right = cam_right.normalized()
		cam_forward = cam_forward.normalized()

		# Движение относительно камеры
		var movement = (cam_right * input_dir.x) + (cam_forward * input_dir.y)

		global_position += movement * move_speed * delta

	# ===== MAP LIMITS =====

	global_position.x = clamp(
		global_position.x,
		map_limit_min.x,
		map_limit_max.x
	)

	global_position.z = clamp(
		global_position.z,
		map_limit_min.y,
		map_limit_max.y
	)


func _unhandled_input(event: InputEvent) -> void:

	# ===== DRAG PAN =====

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed

		# ===== ZOOM =====

		if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:

			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera.size = clamp(
					camera.size - zoom_speed,
					min_zoom,
					max_zoom
				)

			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera.size = clamp(
					camera.size + zoom_speed,
					min_zoom,
					max_zoom
				)

		else:

			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera.position.y = clamp(
					camera.position.y - zoom_speed,
					min_zoom,
					max_zoom
				)

				camera.position.z = clamp(
					camera.position.z - zoom_speed,
					min_zoom,
					max_zoom
				)

			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera.position.y = clamp(
					camera.position.y + zoom_speed,
					min_zoom,
					max_zoom
				)

				camera.position.z = clamp(
					camera.position.z + zoom_speed,
					min_zoom,
					max_zoom
				)

	# ===== CAMERA DRAG =====

	if event is InputEventMouseMotion and dragging:

		var delta = event.relative

		var cam_right = camera.global_basis.x
		var cam_forward = camera.global_basis.z

		cam_right.y = 0
		cam_forward.y = 0

		cam_right = cam_right.normalized()
		cam_forward = cam_forward.normalized()

		var movement = (
			(-cam_right * delta.x) +
			(-cam_forward * delta.y))

		global_position += movement * drag_sensitivity
