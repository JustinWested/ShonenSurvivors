extends Node

@export var spear_ability_scene: PackedScene

var base_damage = 25
const MAX_TARGETING_RANGE = 1000


func _ready():
	$Timer.timeout.connect(on_timer_timeout)

func get_direction_to_nearest_enemy(player: Node2D):
	var enemies = get_tree().get_nodes_in_group("enemy")
	enemies = enemies.filter(func(enemy: Node2D):
		return enemy.global_position.distance_squared_to(player.global_position) < pow(MAX_TARGETING_RANGE, 2)
	)

	if enemies.is_empty():
		return null

	var nearest_enemy = null
	var minimum_distance_sq = INF

	for enemy in enemies:
		var distance_sq = player.global_position.distance_squared_to(enemy.global_position)
		if distance_sq < minimum_distance_sq:
			minimum_distance_sq = distance_sq
			nearest_enemy = enemy
	
	if nearest_enemy != null:
		return (nearest_enemy.global_position - player.global_position).normalized()
	
	return null

func on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var target_direction = get_direction_to_nearest_enemy(player)
	
	if target_direction == null:
		return
	
	spawn_spear(player, target_direction)

# The fix is in this function.
func spawn_spear(player: Node2D, direction: Vector2):
	var foreground_layer = get_tree().get_first_node_in_group("foreground_layer") as Node2D
	if foreground_layer == null:
		return

	var spear_instance = spear_ability_scene.instantiate()
	foreground_layer.add_child(spear_instance, true)
	spear_instance.global_position = player.global_position
	
	# The setup function now passes the corrected direction to the spear.
	# The spear's own script will handle setting the rotation.
	spear_instance.setup(direction)
	
	if spear_instance.has_node("HitboxComponent"):
		spear_instance.get_node("HitboxComponent").damage = base_damage
