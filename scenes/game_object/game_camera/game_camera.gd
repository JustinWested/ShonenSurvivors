extends Camera2D


@export var follow_speed: float = 20.0  
@export var min_zoom: float = 1       
@export var max_zoom: float = 1.5      
@export var zoom_margin: float = 1.8    


var target_position = Vector2.ZERO


func _ready() -> void:
	make_current()


func _process(delta: float) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return

	acquire_target(players)
	global_position = global_position.lerp(target_position, 1.0 - exp(-delta * follow_speed))
	update_zoom(players, delta)
	
	
func acquire_target(players: Array):
	if players.size() == 1:
		target_position = players[0].global_position
		return

	var bounding_box = Rect2(players[0].global_position, Vector2.ZERO)
	for player in players:
		bounding_box = bounding_box.expand(player.global_position)
	
	target_position = bounding_box.get_center()


func update_zoom(players: Array, delta: float):
	var bounding_box = Rect2(players[0].global_position, Vector2.ZERO)
	for player in players:
		bounding_box = bounding_box.expand(player.global_position)
	
	var max_dimension = max(bounding_box.size.x, bounding_box.size.y)
	var screen_size = get_viewport().get_visible_rect().size
	
	var ideal_zoom_x = max_dimension / screen_size.x
	var ideal_zoom_y = max_dimension / screen_size.y
	var ideal_zoom = max(ideal_zoom_x, ideal_zoom_y)
	
	var calculated_zoom = 1.0 / (ideal_zoom * zoom_margin)
	var target_zoom_value = clamp(calculated_zoom, min_zoom, max_zoom)
	var target_zoom_vector = Vector2(target_zoom_value, target_zoom_value)
	
	zoom = lerp(zoom, target_zoom_vector, 1.0 - exp(-delta * follow_speed))
