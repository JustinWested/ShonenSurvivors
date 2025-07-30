extends Node

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var entities: Node2D = $Entities

@export var end_screen_scene: PackedScene

var player_scene: PackedScene = preload("uid://bvjm48jsdwgbq")
var pause_menu_scene = preload("res://scenes/ui/pause_menu.tscn")

func _ready():
	GameEvents.player_died.connect(on_player_died)


#NETWORK MULTIPLAYER RELATED CODE BEYOND THIS POINT
#NETWORK MULTIPLAYER RELATED CODE BEYOND THIS POINT
	
	multiplayer_spawner.spawn_function = func(data):
		var player = player_scene.instantiate() as Player
		player.name = str(data.peer_id)
		player.input_multiplayer_authority = data.peer_id
		return player
		
	peer_ready.rpc_id(1)

	
func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		add_child(pause_menu_scene.instantiate())
		get_tree().root.set_input_as_handled()
	
	
func on_player_died():
	$%MusicPlayer.stop()
	var end_screen_instance = end_screen_scene.instantiate()
	add_child(end_screen_instance)
	end_screen_instance.set_defeat()
	MetaProgression.save()


#NETWORK MULTIPLAYER RELATED CODE BEYOND THIS POINT
#NETWORK MULTIPLAYER RELATED CODE BEYOND THIS POINT


@rpc("any_peer", "call_local", "reliable")
func peer_ready():
	print("peer %s ready" % multiplayer.get_remote_sender_id())
	var sender_id = multiplayer.get_remote_sender_id()
	multiplayer_spawner.spawn({"peer_id": sender_id})
