extends Node2D

const MAX_RADIUS = 100

@onready var hitbox_component = $HitboxComponent

@rpc("any_peer", "call_local")
func initialize(start_position: Vector2, start_direction: Vector2, damage: int, player_path: NodePath, area_multiplier: float):
	global_position = start_position
	hitbox_component.damage = damage
	scale = Vector2.ONE * area_multiplier

	var target_player = get_node_or_null(player_path)
	if not is_instance_valid(target_player):
		queue_free()
		return

	if multiplayer.get_unique_id() == get_multiplayer_authority():
		var movement_tween = create_tween()
		movement_tween.tween_method(
			Callable(self, "tween_movement").bind(target_player, start_direction),
			0.0, 1.0, 3.0 
		)
		movement_tween.finished.connect(queue_free)
		var rotation_tween = create_tween()
		rotation_tween.tween_property(self, "rotation", TAU, 0.5) 
		rotation_tween.set_loops() 

func tween_movement(percent: float, player: Node2D, direction: Vector2):
	var current_radius = percent * MAX_RADIUS
	var rotations = percent * 2.0 
	var current_direction = direction.rotated(rotations * TAU)
	
	var new_position = player.global_position + (current_direction * current_radius)
	rpc("set_remote_position", new_position)

@rpc("any_peer", "call_local")
func set_remote_position(new_position: Vector2):
	global_position = new_position
