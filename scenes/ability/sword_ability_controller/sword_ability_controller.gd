extends Node

const MAX_RANGE = 150

@export var sword_ability: PackedScene

var base_damage = 5
var additional_damage_percent = 1
var base_wait_time
var owner_authority_id: int = 0 # Initialize to 0 (invalid)
var owner_player: Node2D


func set_ability_owner(player_node: Node2D):
	owner_player = player_node
	
	if owner_player.is_multiplayer_authority():
		$Timer.start()
	else:
		$Timer.stop()

func _ready() -> void:
	base_wait_time = $Timer.wait_time
	$Timer.timeout.connect(on_timer_timeout)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	

func on_timer_timeout():
	if not is_instance_valid(owner_player) or not owner_player.is_multiplayer_authority():
		return

	# THIS IS THE FIX: Use our new helper function.
	var player = owner_player
	if player == null:
		# This will now only fail if the player has been destroyed.
		return
		
		
	# The rest of the logic is now guaranteed to work.
	var enemies = get_tree().get_nodes_in_group("enemy")
	enemies = enemies.filter(func(enemy: Node2D): 
		return enemy.global_position.distance_squared_to(player.global_position) < pow(MAX_RANGE, 2)
	)
	
	if enemies.is_empty():
		return
		
	enemies.sort_custom(func(a: Node2D, b: Node2D):
		var a_distance = a.global_position.distance_squared_to(player.global_position)
		var b_distance = b.global_position.distance_squared_to(player.global_position)
		return a_distance < b_distance
	)
		
	var spawn_position = enemies[0].global_position
	spawn_position += Vector2.RIGHT.rotated(randf_range(0, TAU)) * 4
	var enemy_direction = enemies[0].global_position - spawn_position
	var spawn_rotation = enemy_direction.angle()

	spawn_sword_rpc.rpc(spawn_position, spawn_rotation)

@rpc("any_peer", "call_local", "unreliable")
func spawn_sword_rpc(spawn_position: Vector2, spawn_rotation: float):
	var _local_id = multiplayer.get_unique_id()

	var sword_instance = sword_ability.instantiate()
	var foreground_layer = get_tree().get_first_node_in_group("foreground_layer")
	if foreground_layer != null:
		foreground_layer.add_child(sword_instance, true)

	
	var sword_ability_instance = sword_instance as SwordAbility
	if sword_ability_instance != null and sword_ability_instance.has_node("HitboxComponent"):
		sword_ability_instance.get_node("HitboxComponent").damage = ceil(base_damage * additional_damage_percent)


	sword_instance.global_position = spawn_position
	sword_instance.rotation = spawn_rotation
	
	if sword_instance.has_node("AnimationPlayer"):
		sword_instance.get_node("AnimationPlayer").play("swing")



func on_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	if upgrade.id == "sword_rate":
		var percent_reduction = current_upgrades["sword_rate"]["quantity"] * .1
		$Timer.wait_time = base_wait_time * (1 - percent_reduction)
		

	elif upgrade.id == "sword_damage":
		additional_damage_percent = 1.0 + (current_upgrades["sword_damage"]["quantity"] * 0.15)
