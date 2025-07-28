extends Node2D

@onready var detection_area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D

var tween: Tween
var is_homing = false
var current_trail: Trail

func _ready():
	detection_area.area_entered.connect(on_player_range_entered)
	detection_area.body_entered.connect(on_player_body_entered)
	

func start_homing_tween():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		collect()
		return

	make_trail()
	is_homing = true

	tween = create_tween().set_parallel()
	tween.tween_method(tween_collect.bind(global_position), 0.0, 1.0, 0.5)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.05).set_delay(0.45)
	tween.chain().tween_callback(collect)
	
	$AudioStreamPlayer2D.play()

func tween_collect(percent: float, start_position: Vector2):
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		if tween: tween.kill()
		queue_free()
		return
	global_position = start_position.lerp(player.global_position, percent)

func collect():
	if tween and tween.is_valid():
		tween.kill()

	if not is_queued_for_deletion():
		GameEvents.emit_experience_vial_collected(1)
		queue_free()

func make_trail():
	if current_trail:
		current_trail.stop()

	current_trail = Trail.create(self)
	
	get_tree().current_scene.add_child(current_trail)
	
func on_player_range_entered(other_area: Area2D):
	if is_homing:
		return
	
	start_homing_tween()

func on_player_body_entered(body):
	if is_homing:
		collect()
