extends Node3D

@export var move_speed := 15.0
@export var drag_sensitivity := 0.05
@export var zoom_speed := 2.0 # Увеличил для более отзывчивого зума

# Для ортогональной камеры: min_zoom - это максимальное приближение, max_zoom - максимальное отдаление
@export var min_zoom := 8.0   
@export var max_zoom := 16.0

@onready var camera: Camera3D = $IsometricCam3D

# Размеры вашей карты (границы, за которые геометрия мира не выходит)
var map_limit_min := Vector2(-40, -40)
var map_limit_max := Vector2(40, 40)

var dragging := false


func _process(delta: float) -> void:

	# ===== WASD MOVEMENT =====
	var input_dir := Vector2.ZERO

	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S): input_dir.y += 1

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()

		var cam_right = camera.global_basis.x
		var cam_forward = camera.global_basis.z

		cam_right.y = 0
		cam_forward.y = 0

		cam_right = cam_right.normalized()
		cam_forward = cam_forward.normalized()

		var movement = (cam_right * input_dir.x) + (cam_forward * input_dir.y)
		global_position += movement * move_speed * delta

	# ===== ДИНАМИЧЕСКИЕ ГРАНИЦЫ КАРТЫ =====
	# Вычисляем, какую область карты «съедает» зум. 
	# Чем больше camera.size, тем сильнее сужаем доступные границы для Пивота,
	# чтобы края экрана не выходили за пределы карты.
	var zoom_margin_x = camera.size * 1.2  # Коэффициент под изометрию (можно подкрутить)
	var zoom_margin_y = camera.size * 0.8  # По вертикали в изометрии область видимости меньше

	var current_limit_min_x = map_limit_min.x + zoom_margin_x
	var current_limit_max_x = map_limit_max.x - zoom_margin_x
	var current_limit_min_y = map_limit_min.y + zoom_margin_y
	var current_limit_max_y = map_limit_max.y - zoom_margin_y

	# Защита на случай, если max_zoom слишком большой для такой маленькой карты
	if current_limit_min_x > current_limit_max_x:
		current_limit_min_x = (map_limit_min.x + map_limit_max.x) / 2
		current_limit_max_x = current_limit_min_x
	if current_limit_min_y > current_limit_max_y:
		current_limit_min_y = (map_limit_min.y + map_limit_max.y) / 2
		current_limit_max_y = current_limit_min_y

	# Применяем ограниченные координаты
	global_position.x = clamp(global_position.x, current_limit_min_x, current_limit_max_x)
	global_position.z = clamp(global_position.z, current_limit_min_y, current_limit_max_y)


func _unhandled_input(event: InputEvent) -> void:

	# ===== DRAG PAN =====
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed

		# ===== ZOOM (Только для ORTHOGONAL) =====
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

	# ===== CAMERA DRAG =====
	if event is InputEventMouseMotion and dragging:
		var delta = event.relative

		var cam_right = camera.global_basis.x
		var cam_forward = camera.global_basis.z

		cam_right.y = 0
		cam_forward.y = 0

		cam_right = cam_right.normalized()
		cam_forward = cam_forward.normalized()

		# В изометрии движение мыши по Y должно двигать камеру по диагонали (Z и X).
		# Мы берем инвертированный cam_forward, чтобы перетаскивание ощущалось "привязанным" к полу.
		var movement = (-cam_right * delta.x) + (-cam_forward * delta.y)
		
		# Чуть-чуть масштабируем чувствительность драга в зависимости от зума, 
		# чтобы на близком расстоянии камера не летела слишком быстро.
		var current_drag_sensitivity = drag_sensitivity * (camera.size / max_zoom)
		
		global_position += movement * current_drag_sensitivity
