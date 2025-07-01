class_name Trail
extends Line2D

const MAX_POINTS: int = 10

var target_node: Node2D

func _process(delta: float) -> void:
	if not is_instance_valid(target_node):
		stop()
		return
	
	add_point(target_node.global_position)
	
	if get_point_count() > MAX_POINTS:
		remove_point(0)
	
func stop():
	set_process(false)
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	queue_free()
	
static func create(target: Node2D) -> Trail:
	var scene = preload("res://scenes/game_object/experience_vial/exp_trail.tscn")
	var instance = scene.instantiate() as Trail
	
	instance.target_node = target
	instance.position = Vector2.ZERO
	instance.add_point(target.global_position)
	return instance
