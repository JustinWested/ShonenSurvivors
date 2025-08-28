extends Node

const MAX_RANGE = 150


@export var sword_ability_resource: Ability 
@export var sword_ability_scene: PackedScene 

@onready var player: Node2D = get_parent().get_parent()

var current_level = 0
var current_projectile_count = 1
var current_base_damage = 5
var current_area_multiplier = 1.0
var base_wait_time

func _ready() -> void:
	base_wait_time = $Timer.wait_time
	$Timer.timeout.connect(on_timer_timeout)
	if player.is_multiplayer_authority():
		$Timer.start()


func on_new_upgrade_applied(upgrade: AbilityUpgrade, player_specific_upgrades: Dictionary):
	if sword_ability_resource == null:
		return
	if upgrade.id != sword_ability_resource.id:
		return
	current_level = player_specific_upgrades.get(upgrade.id, {}).get("quantity", 1)
	update_stats_for_level(current_level)


func update_stats_for_level(level: int):
	# Reset to base stats before recalculating.
	current_projectile_count = 1
	current_base_damage = 5
	current_area_multiplier = 1.0
	$Timer.wait_time = base_wait_time

	# The progression array is 0-indexed, so Level 1 is index 0. We loop up to level - 1.
	for i in range(level):
		var level_stats = sword_ability_resource.level_progression[i] as AbilityLevelStats
		current_base_damage += level_stats.damage_increase
		current_projectile_count += level_stats.projectile_increase
		current_area_multiplier *= level_stats.area_multiplier
		$Timer.wait_time *= (1.0 - level_stats.cooldown_reduction_percent)
	
	print("Sword updated to Level %s: Projectiles=%s, Damage=%s" % [level, current_projectile_count, current_base_damage])

func on_timer_timeout():
	if not is_instance_valid(player):
		return
		
	var enemies = get_tree().get_nodes_in_group("enemy")
	enemies = enemies.filter(func(enemy: Node2D): 
		return enemy.global_position.distance_squared_to(player.global_position) < pow(MAX_RANGE, 2)
	)
	if enemies.is_empty(): return
	enemies.sort_custom(func(a: Node2D, b: Node2D):
		return a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position)
	)
	
	for i in range(min(enemies.size(), current_projectile_count)):
		var target_enemy = enemies[i]
		var spawn_position = target_enemy.global_position + (Vector2.RIGHT.rotated(randf_range(0, TAU)) * 4)
		var spawn_rotation = (target_enemy.global_position - spawn_position).angle()


		var sword_instance = sword_ability_scene.instantiate()
		
		var unique_name = str(multiplayer.get_unique_id()) + "_" + str(Time.get_ticks_msec()) + str(i)
		sword_instance.name = unique_name
		sword_instance.set_multiplayer_authority(multiplayer.get_unique_id())
		get_tree().get_first_node_in_group("foreground_layer").add_child(sword_instance, true)
		sword_instance.rpc("initialize", spawn_position, spawn_rotation, current_base_damage, current_area_multiplier)
