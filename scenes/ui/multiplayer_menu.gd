extends CanvasLayer


@onready var host_button: Button = %HostButton
@onready var join_button: Button = %JoinButton
@onready var back_button: Button = %BackButton
@onready var display_name_text_edit: TextEdit = %DisplayNameTextEdit
@onready var port_text_edit: TextEdit = %PortTextEdit
@onready var ip_address_text_edit: TextEdit = %IPAddressTextEdit
@onready var error_container: MarginContainer = $ErrorContainer
@onready var client_error_label: Label = %ClientErrorLabel
@onready var server_error_label: Label = %ServerErrorLabel
@onready var error_button: Button = %ErrorButton



var main_scene = preload("uid://brav3qrwhhowm")
var main_menu = preload("uid://u5o0yji32q3c")

var is_connecting: bool

func _ready():
	error_container.visible = false
	error_button.pressed.connect(on_error_confirmed)
	
	back_button.pressed.connect(on_back_pressed)
	host_button.pressed.connect(on_host_pressed)
	join_button.pressed.connect(on_join_pressed)
	
	display_name_text_edit.text_changed.connect(on_text_changed)
	ip_address_text_edit.text_changed.connect(on_text_changed)
	port_text_edit.text_changed.connect(on_text_changed)
	
	display_name_text_edit.text = MultiplayerConfig.display_name
	ip_address_text_edit.text = MultiplayerConfig.ip_address
	port_text_edit.text = str(MultiplayerConfig.port)
	
	multiplayer.connected_to_server.connect(on_connected_to_server)
	multiplayer.connection_failed.connect(on_connection_failed)
	
	validate()
	
func validate():
	var port := port_text_edit.text
	if port.is_valid_int():
		MultiplayerConfig.port = int(port)
		if MultiplayerConfig.port <= 0:
			MultiplayerConfig.port = -1
	else:
		MultiplayerConfig.port = -1
	
	var ip := ip_address_text_edit.text
	if ip.is_valid_ip_address():
		MultiplayerConfig.ip_address = ip
	else:
		MultiplayerConfig.ip_address = ""
	
	MultiplayerConfig.display_name = display_name_text_edit.text
	
	var is_valid_port := MultiplayerConfig.port > 0
	var is_valid_name := !MultiplayerConfig.display_name.is_empty()
	var is_valid_ip := !MultiplayerConfig.ip_address.is_empty()
		
	host_button.disabled = is_connecting || !is_valid_port || !is_valid_name
	join_button.disabled = is_connecting || !is_valid_port || !is_valid_name || !is_valid_ip

func show_error(is_client: bool):
	client_error_label.visible = is_client
	server_error_label.visible = !is_client
	error_container.visible = true
	


func on_back_pressed():
	ScreenTransition.transition_to_scene("res://scenes/ui/main_menu.tscn")
	

func on_text_changed():
	validate()

#NETWORK MULTIPLAYER RELATED CODE BEYOND THIS POINT
#NETWORK MULTIPLAYER RELATED CODE BEYOND THIS POINT

func on_host_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	
	var server_peer := ENetMultiplayerPeer.new()
	var error := server_peer.create_server(MultiplayerConfig.port)
	
	if error != Error.OK:
		show_error(false)
		return
	
	multiplayer.multiplayer_peer = server_peer
	get_tree().change_scene_to_packed(main_scene)
	
	
func on_join_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	var client_peer := ENetMultiplayerPeer.new()
	var error := client_peer.create_client(MultiplayerConfig.ip_address, MultiplayerConfig.port)
	
	if error != Error.OK:
		show_error(true)
		return
		
	is_connecting = true
	multiplayer.multiplayer_peer = client_peer
	validate()

	
func on_connected_to_server():
	get_tree().change_scene_to_packed(main_scene)
	

func on_error_confirmed():
	error_container.visible = false
	
	
func on_connection_failed():
	is_connecting = false
	validate()
	show_error(true)
