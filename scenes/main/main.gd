extends Node

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var entities: Node2D = $Entities
@onready var arena_time_manager: Node = $ArenaTimeManager
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var upgrade_manager: Node = $UpgradeManager

@export var end_screen_scene: PackedScene

const RESPAWN_DURATION_MSEC = 15000
const PLAYER_SPAWN_RADIUS = 75.0

var player_scene: PackedScene = preload("uid://bvjm48jsdwgbq")

var player_dictionary: Dictionary[int, Player] = {}
var dead_peers: Array[int] = []
var dead_peers_respawn_times: Dictionary = {}


func _ready():
	#NETWORK MULTIPLAYER RELATED CODE BEYOND THIS POINT	
	multiplayer_spawner.spawn_function = func(data):
		var player_index = player_dictionary.size()
		var angle = player_index * PI 
		var spawn_position = Vector2.RIGHT.rotated(angle) * PLAYER_SPAWN_RADIUS
		var player = player_scene.instantiate() as Player
		
		player.global_position = spawn_position
		
		player.set_display_name(data.display_name)
		player.name = str(data.peer_id)
		player.input_multiplayer_authority = data.peer_id
		player.set_multiplayer_authority(data.peer_id)
		
		if is_multiplayer_authority():
			player.died.connect(on_player_died.bind(data.peer_id))
			
		upgrade_manager.register_player(data.peer_id)
		player_dictionary[data.peer_id] = player
		return player
			
	peer_ready.rpc_id(1, MultiplayerConfig.display_name)
	
	pause_menu.quit_requested.connect(on_quit_requested)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	if is_multiplayer_authority():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _process(delta: float):
	if not is_multiplayer_authority(): return
	if dead_peers_respawn_times.is_empty(): return

	var current_time = Time.get_ticks_msec()
	var peers_to_respawn: Array[int] = []

	for peer_id in dead_peers_respawn_times:
		if current_time >= dead_peers_respawn_times[peer_id]:
			peers_to_respawn.append(peer_id)
	
	if not peers_to_respawn.is_empty():
		for peer_id in peers_to_respawn:
			dead_peers_respawn_times.erase(peer_id)
			dead_peers.erase(peer_id)
			
			var player_node_to_respawn = entities.get_node_or_null(str(peer_id))
			
			if player_node_to_respawn != null:
				player_node_to_respawn.respawn.rpc()

	
	
func on_player_died(peer_id: int):
	dead_peers.append(peer_id)
		
	dead_peers_respawn_times[peer_id] = Time.get_ticks_msec() + RESPAWN_DURATION_MSEC
	
	var all_players = get_tree().get_nodes_in_group("player")
	
	if dead_peers.size() >= all_players.size():
		trigger_game_over_rpc.rpc()


func on_quit_requested():
	trigger_game_over_rpc()
	


func _on_server_disconnected():
	trigger_game_over_rpc()

func _on_peer_disconnected(peer_id: int):
	if player_dictionary.has(peer_id):
		var player := player_dictionary[peer_id]
		if is_instance_valid(player):
			player_dictionary[peer_id].on_player_died()
		player_dictionary.erase(peer_id)

@rpc("any_peer", "call_local", "reliable")
func trigger_game_over_rpc():
	$%MusicPlayer.stop()
	var end_screen_instance = end_screen_scene.instantiate()
	add_child(end_screen_instance)
	end_screen_instance.set_defeat()
	MetaProgression.save()
	
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	
	
@rpc("any_peer", "call_local", "reliable")
func peer_ready(display_name: String):
	var sender_id = multiplayer.get_remote_sender_id()
	multiplayer_spawner.spawn({ 
		"peer_id": sender_id, 
		"display_name": display_name 
		})
