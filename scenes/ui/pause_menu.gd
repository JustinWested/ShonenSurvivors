extends CanvasLayer

var options_scene = preload("res://scenes/ui/options_menu.tscn")
var is_closing

@export var end_screen_scene: PackedScene


func _ready():
	get_tree().paused = true
	$%ResumeButton.pressed.connect(on_resume_pressed)
	$%OptionsButton.pressed.connect(on_options_pressed)
	$%QuitButton.pressed.connect(on_quit_pressed)
	
	$AnimationPlayer.play("default")
	
	
func _unhandled_input(event):
	if event.is_action_pressed("pause"): 
		close()
		get_tree().root.set_input_as_handled()
	
func close():
	if is_closing:
		return
		
	is_closing = true
	$AnimationPlayer.play_backwards("default")
		
	get_tree().paused = false
	queue_free()
	
func on_resume_pressed():
	close()
	

func on_options_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	var options_instance = options_scene.instantiate()
	add_child(options_instance)
	options_instance.back_pressed.connect(on_options_closed.bind(options_instance))
	

func on_options_closed(options_instance: Node):
	options_instance.queue_free()

func on_quit_pressed():
	var end_screen_instance = end_screen_scene.instantiate()
	add_child(end_screen_instance)
	end_screen_instance.set_defeat()
	MetaProgression.save()
