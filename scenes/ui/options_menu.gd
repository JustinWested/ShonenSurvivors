extends CanvasLayer

signal back_pressed

@onready var window_button: CheckButton = $%WindowButton
@onready var master_slider: HSlider = %MasterSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var back_button = $%BackButton

func _ready():
	back_button.pressed.connect(on_back_pressed)
	window_button.pressed.connect(on_window_button_pressed)
	master_slider.value_changed.connect(on_audio_slider_changed.bind("Master"))
	sfx_slider.value_changed.connect(on_audio_slider_changed.bind("sfx"))
	sfx_slider.drag_ended.connect(on_sfx_drag_ended)
	music_slider.value_changed.connect(on_audio_slider_changed.bind("music"))
	update_display()
	
func update_display():
	window_button.text = "Windowed"
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		window_button.text = "Fullscreen"
	master_slider.value = get_bus_volume_percent("Master")
	sfx_slider.value = get_bus_volume_percent("sfx")
	music_slider.value = get_bus_volume_percent("music")

func get_bus_volume_percent(bus_name: String):
	var bus_index = AudioServer.get_bus_index(bus_name)
	var volume_db = AudioServer.get_bus_volume_db(bus_index)
	return db_to_linear(volume_db)
	
	
func set_bus_volume_percent(bus_name: String, percent: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	var volume_db = linear_to_db(percent)
	AudioServer.set_bus_volume_db(bus_index, volume_db)
	

func on_window_button_pressed():
	var mode = DisplayServer.window_get_mode()
	if mode != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	update_display()

func on_audio_slider_changed(value: float, bus_name: String):
	set_bus_volume_percent(bus_name, value)


func on_sfx_drag_ended(value_changed: bool):
	$%AudioStreamPlayer.play()

func on_back_pressed():
	ScreenTransition.transition()
	await ScreenTransition.transitioned_halfway
	back_pressed.emit()
