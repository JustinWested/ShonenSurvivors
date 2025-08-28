extends Node

var player_order: Array[int] = []
var current_player_index: int = 0

func initialize_players():
	player_order.clear()
	var peers = multiplayer.get_peers()
	for peer_id in peers:
		player_order.append(int(peer_id))
	if multiplayer.is_server():
		player_order.append(1)  # Include server
	player_order.sort()

func get_next_player() -> int:
	if player_order.is_empty():
		return 1  # Default to server
	
	var player_id = player_order[current_player_index]
	current_player_index = (current_player_index + 1) % player_order.size()
	return player_id

func reset():
	current_player_index = 0
