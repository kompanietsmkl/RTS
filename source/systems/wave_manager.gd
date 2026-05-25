extends Node3D

const AlienScene = preload("res://source/units/aliens/alien.tscn")
const CatalystScene = preload("res://source/units/aliens/catalyst.tscn")

var wave_number: int = 0
var wave_timer: float = 0.0
var time_to_next_wave: float = 60.0
var warning_shown: bool = false
var previous_wave_size: int = 0


# Координаты спавнов по диагонали (для карты 60x60)
var spawn_points: Array[Vector3] = [
	Vector3(-25, 0, 25),
	Vector3(25, 0, -25)
]

func _process(delta: float) -> void:
	wave_timer += delta
	
	var time_left = time_to_next_wave - wave_timer
	
	# Предупреждение за 10 секунд
	if time_left <= 10.0 and not warning_shown:
		warning_shown = true
		GameManager.show_alert.emit("Warning! Alien wave approaching in 10 seconds!", GameManager.AlertType.WARNING)
		
	# Спавн волны
	if wave_timer >= time_to_next_wave:
		spawn_wave()
		wave_timer = 0.0
		time_to_next_wave = 45.0 
		warning_shown = false

func spawn_wave() -> void:
	wave_number += 1
	var base_amount = 5
	
	var total_defenders = GameManager.total_defenders
	var base_level = GameManager.base_level
	
	var factories = get_tree().get_nodes_in_group("factory")
	var factory_level = 1
	if factories.size() > 0:
		factory_level = factories[0].current_level
		
	# Эвристическая формула усложнения
	var bonus = int(total_defenders / 3.0) + base_level + factory_level
	var total_mobs = base_amount + bonus
	
	# Гарантируем, что волна всегда больше предыдущей
	if total_mobs <= previous_wave_size:
		total_mobs = previous_wave_size + 1
		
	previous_wave_size = total_mobs
	
	# Вычисляем количество катализаторов (20% волны, начиная со 2-й волны)
	var catalyst_count = 0
	if wave_number >= 2:
		catalyst_count = max(1, int(total_mobs * 0.2))
	
	GameManager.show_alert.emit("Wave " + str(wave_number) + " has arrived! (" + str(total_mobs) + " aliens)", GameManager.AlertType.ERROR)
	GameManager.wave_started.emit(wave_number)
	
	for i in range(total_mobs):
		var alien_instance = null
		if i < catalyst_count:
			alien_instance = CatalystScene.instantiate()
		else:
			alien_instance = AlienScene.instantiate()
			
		get_tree().current_scene.add_child(alien_instance)
		
		# По очереди выбираем один из углов
		var spawn_pos = spawn_points[i % spawn_points.size()]
		
		# Добавляем случайное смещение, чтобы они не спавнились в одной точке
		var offset = Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		alien_instance.global_position = spawn_pos + offset
