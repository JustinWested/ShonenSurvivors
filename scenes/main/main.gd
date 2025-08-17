extends Node

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var entities: Node2D = $Entities
@onready var arena_time_manager: Node = $ArenaTimeManager

@export var end_screen_scene: PackedScene

const RESPAWN_DURATION_MSEC = 5000

var player_scene: PackedScene = preload("uid://bvjm48jsdwgbq")
var pause_menu_scene = preload("res://scenes/ui/pause_menu.tscn")

var dead_peers: Array[int] = []
var dead_peers_respawn_times: Dictionary = {}

func _ready():
	
#NETWORK MULTIPLAYER RELATED CODE BEYOND THIS POINT	
	multiplayer_spawner.spawn_function = func(data):
		var player = player_scene.instantiate() as Player
		player.name = str(data.peer_id)
		player.input_multiplayer_authority = data.peer_id
		
		if is_multiplayer_authority():
			player.died.connect(on_player_died.bind(data.peer_id))
			
		return player
			
	peer_ready.rpc_id(1)

func _process(delta: float):
	# This logic only runs on the host, who is the game master.
	if not is_multiplayer_authority():
		return

	# If no one is dead, there's nothing to check. This is an efficiency improvement.
	if dead_peers_respawn_times.is_empty():
		return

	var current_time = Time.get_ticks_msec()
	# We create a temporary array to avoid modifying the dictionary while iterating over it.
	var peers_to_respawn: Array[int] = []

	# Check each dead player to see if their time is up.
	for peer_id in dead_peers_respawn_times:
		if current_time >= dead_peers_respawn_times[peer_id]:
			peers_to_respawn.append(peer_id)
	
	# Now, process the players who are ready to respawn.
	if not peers_to_respawn.is_empty():
		for peer_id in peers_to_respawn:
			# Remove them from the tracking lists.
			dead_peers_respawn_times.erase(peer_id)
			dead_peers.erase(peer_id)
			
			# Call your existing, working spawn logic for this specific player.
			multiplayer_spawner.spawn({ "peer_id": peer_id })
	
func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		add_child(pause_menu_scene.instantiate())
		get_tree().root.set_input_as_handled()
	
	
func on_player_died(peer_id: int):
	dead_peers.append(peer_id)
		
	dead_peers_respawn_times[peer_id] = Time.get_ticks_msec() + RESPAWN_DURATION_MSEC
	
	var all_players = get_tree().get_nodes_in_group("player")
	
	printerr("GAME OVER CHECK: Dead peers: %d. Total players: %d." % [dead_peers.size(), all_players.size()])

	# The game ends if the number of dead players equals the total number of players currently in the scene.
	if dead_peers.size() >= all_players.size():
		printerr("GAME OVER CONDITION MET! Triggering defeat screen.")
		trigger_game_over_rpc.rpc()


#NETWORK MULTIPLAYER RELATED CODE BEYOND THIS POINT
#NETWORK MULTIPLAYER RELATED CODE BEYOND THIS POINT

@rpc("any_peer", "call_local", "reliable")
func trigger_game_over_rpc():
	$%MusicPlayer.stop()
	var end_screen_instance = end_screen_scene.instantiate()
	add_child(end_screen_instance)
	end_screen_instance.set_defeat()
	MetaProgression.save()

@rpc("any_peer", "call_local", "reliable")
func peer_ready():
	var sender_id = multiplayer.get_remote_sender_id()
	multiplayer_spawner.spawn({ "peer_id": sender_id })
