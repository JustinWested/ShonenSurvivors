extends CanvasLayer

const PORT: int = 3000

var options_scene = preload("res://scenes/ui/options_menu.tscn")
var main_scene = preload("uid://brav3qrwhhowm")
var multiplayer_menu = preload("uid://dkmx1mtiwidhc")


func _ready():
	$%PlayButton.pressed.connect(on_play_pressed)
	$%OptionsButton.pressed.connect(on_options_pressed)
	$%QuitButton.pressed.connect(on_quit_pressed)
	$%MetaButton.pressed.connect(on_meta_pressed)
	$%MultiplayerButton.pressed.connect(on_multiplayer_pressed)
	


func on_play_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	get_tree().change_scene_to_packed(main_scene)
	
func on_options_pressed():
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

func on_multiplayer_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	get_tree().change_scene_to_packed(multiplayer_menu)
