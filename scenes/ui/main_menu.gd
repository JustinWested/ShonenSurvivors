extends CanvasLayer

const PORT: int = 3000

var options_scene = preload("res://scenes/ui/options_menu.tscn")
var main_scene = preload("uid://brav3qrwhhowm")


func _ready():
	$%PlayButton.pressed.connect(on_play_pressed)
	$%OptionsButton.pressed.connect(on_options_pressed)
	$%QuitButton.pressed.connect(on_quit_pressed)
	$%MetaButton.pressed.connect(on_meta_pressed)
	$%HostButton.pressed.connect(on_host_pressed)
	$%JoinButton.pressed.connect(on_join_pressed)
	
	#NETWORK MULTIPLAYER RELATED CODE BEYOND THIS POINT
	
	multiplayer.connected_to_server.connect(on_connected_to_server)

func on_play_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	get_tree().change_scene_to_packed(main_scene)
	
func on_options_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	var options_instance = options_scene.instantiate()
	add_child(options_instance)
	options_instance.back_pressed.connect(on_options_closed.bind(options_instance))


func on_options_closed(options_instance: Node):
	options_instance.queue_free()


func on_quit_pressed():
	get_tree().quit()
	

func on_meta_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	get_tree().change_scene_to_file("res://scenes/ui/meta_menu.tscn")


#NETWORK MULTIPLAYER RELATED CODE BEYOND THIS POINT
#NETWORK MULTIPLAYER RELATED CODE BEYOND THIS POINT

func on_host_pressed():
	var server_peer := ENetMultiplayerPeer.new()
	server_peer.create_server(PORT)
	multiplayer.multiplayer_peer = server_peer
	get_tree().change_scene_to_packed(main_scene)
	
	
func on_join_pressed():
	var client_peer := ENetMultiplayerPeer.new()
	client_peer.create_client("127.0.0.1", PORT)
	multiplayer.multiplayer_peer = client_peer

	
func on_connected_to_server():
	get_tree().change_scene_to_packed(main_scene)
