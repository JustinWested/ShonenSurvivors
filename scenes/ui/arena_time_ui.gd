extends CanvasLayer

@export var arena_time_manager: Node
@onready var label = $%Label

func _process(delta):
	if arena_time_manager == null:
		return

	label.text = format_seconds_to_string(arena_time_manager.synced_time_elapsed)

func format_seconds_to_string(seconds: float):
	var minutes = int(floor(seconds / 60))
	var remaining_seconds = seconds - (minutes * 60)
	return str("%02d" % minutes) + ":" + ("%02d" % floor(remaining_seconds))
