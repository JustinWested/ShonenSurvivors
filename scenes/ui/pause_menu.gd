class_name PauseMenu
extends CanvasLayer

signal quit_requested

var options_scene = preload("res://scenes/ui/options_menu.tscn")
var is_closing
var current_paused_peer: int = -1

@export var end_screen_scene: PackedScene


func _ready():
	
	$%ResumeButton.pressed.connect(on_resume_pressed)
	$%OptionsButton.pressed.connect(on_options_pressed)
	$%QuitButton.pressed.connect(on_quit_pressed)
	
	if is_multiplayer_authority():
		multiplayer.peer_disconnected.connect(on_peer_disconnected)
	
	
func _unhandled_input(event):
	if event.is_action_pressed("pause"): 
		if get_tree().paused:
			request_unpause.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER)
		else:
			request_pause.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER)
		get_viewport().set_input_as_handled()

@rpc("any_peer", "call_local", "reliable")
func request_pause():
	if current_paused_peer > -1:
		return
	pause.rpc(multiplayer.get_remote_sender_id())
	
	
@rpc("any_peer", "call_local", "reliable")
func request_unpause():
	if current_paused_peer != multiplayer.get_remote_sender_id():
		return
	unpause.rpc()
	
	
@rpc("authority", "call_local", "reliable")
func pause(paused_peer: int):
	get_tree().paused = true
	visible = true
	current_paused_peer = paused_peer
	$%ResumeButton.disabled = current_paused_peer != multiplayer.get_unique_id()
	$AnimationPlayer.play("default")
	
	
@rpc("authority", "call_local", "reliable")
func unpause():
	$AnimationPlayer.play_backwards("default")
	await $AnimationPlayer.animation_finished

	current_paused_peer = -1
	
	visible = false
	get_tree().paused = false
	


func on_resume_pressed():
	request_unpause.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER)


func on_options_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	var options_instance = options_scene.instantiate()
	add_child(options_instance)
	options_instance.back_pressed.connect(on_options_closed.bind(options_instance))
	

func on_options_closed(options_instance: Node):
	options_instance.queue_free()

func on_quit_pressed():
	quit_requested.emit()
	
func on_peer_disconnected(peer_id: int):
	if current_paused_peer == peer_id:
		unpause.rpc()
