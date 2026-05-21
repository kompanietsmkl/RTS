extends Node3D

@export var speed: float = 20.0        # Скорость перемещения камеры
@export var edge_margin: float = 20.0  # Размер зоны у края экрана (в пикселях) для движения мышью
@export var use_edge_scroll: bool = true

@onready var camera: Camera3D = $Camera3D

# Границы карты (чтобы камера не улетала в бесконечность)
var map_limit_min: Vector2 = Vector2(-40, -40)
var map_limit_max: Vector2 = Vector2(40, 40)

func _process(delta: float) -> void:
	var direction := Vector3.ZERO
	
	# 1. Управление через WASD / Стрелочки
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.z += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.z -= 1
		
	# 2. Управление мышкой у краев экрана
	if use_edge_scroll:
		var viewport_size = get_viewport().get_mouse_position()
		var window_size = get_viewport().get_visible_rect().size
		
		if viewport_size.x >= window_size.x - edge_margin:
			direction.x += 1
		elif viewport_size.x <= edge_margin:
			direction.x -= 1
			
		if viewport_size.y >= window_size.y - edge_margin:
			direction.z += 1
		elif viewport_size.y <= edge_margin:
			direction.z -= 1

	# Нормализуем вектор, чтобы по диагонали камера не двигалась быстрее
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		
	# Двигаем наш Pivot (якорь) по земле
	global_translate(direction * speed * delta)
	
	# Ограничиваем перемещение камеры в пределах карты
	global_position.x = clamp(global_position.x, map_limit_min.x, map_limit_max.x)
	global_position.z = clamp(global_position.z, map_limit_min.y, map_limit_max.y)

func _unhandled_input(event: InputEvent) -> void:
	# 3. Приближение и отдаление (Zoom) на колесико мыши
	if event is InputEventMouseButton:
		if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
			# Для ортогональной камеры меняем параметр Size
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera.size = clamp(camera.size - 1, 10, 40)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera.size = clamp(camera.size + 1, 10, 40)
		else:
			# Для перспективной камеры двигаем саму камеру ближе/дальше по ее локальной оси Z
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera.position.y = clamp(camera.position.y - 1, 8, 30)
				camera.position.z = clamp(camera.position.z - 1, 8, 30)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera.position.y = clamp(camera.position.y + 1, 8, 30)
				camera.position.z = clamp(camera.position.z + 1, 8, 30)
