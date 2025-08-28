extends Node

const MAX_TARGETING_RANGE = 1000


@export var spread_angle_degrees: float = 25.0

@export var spear_ability_resource: Ability
@export var spear_ability_scene: PackedScene

@onready var player: Node2D = get_parent().get_parent()

var current_level = 0
var current_projectile_count = 1
var current_base_damage = 5
var current_area_multiplier = 1.0
var base_wait_time

func _ready():
	base_wait_time = $Timer.wait_time
	$Timer.timeout.connect(on_timer_timeout)
	if player.is_multiplayer_authority():
		$Timer.start()

func on_new_upgrade_applied(upgrade: AbilityUpgrade, player_specific_upgrades: Dictionary):
	if spear_ability_resource == null: return
	if upgrade.id != spear_ability_resource.id: return
	current_level = player_specific_upgrades.get(upgrade.id, {}).get("quantity", 1)
	update_stats_for_level(current_level)

func update_stats_for_level(level: int):
	current_projectile_count = 1
	current_base_damage = 5
	current_area_multiplier = 1.0
	$Timer.wait_time = base_wait_time
	for i in range(level):
		var level_stats = spear_ability_resource.level_progression[i] as AbilityLevelStats
		current_base_damage += level_stats.damage_increase
		current_projectile_count += level_stats.projectile_increase
		current_area_multiplier *= level_stats.area_multiplier
		$Timer.wait_time *= (1.0 - level_stats.cooldown_reduction_percent)
	print("Spear updated to Level %s: Projectiles=%s, Damage=%s" % [level, current_projectile_count, current_base_damage])

func on_timer_timeout():
	spawn_spear()

func spawn_spear():
	if not is_instance_valid(player):
		return

	var target_direction = get_direction_to_nearest_enemy()
	if target_direction == null:
		return

	# Convert our degrees value to radians once, for efficiency.
	var spread_angle_rad = deg_to_rad(spread_angle_degrees)

	for i in range(current_projectile_count):
		# --- THIS IS THE NEW SPREAD LOGIC ---
		var final_direction: Vector2
		if i == 0:
			# The first spear (i=0) is always perfectly accurate.
			final_direction = target_direction
		else:
			# Subsequent spears get a random offset.
			var random_offset = randf_range(-spread_angle_rad, spread_angle_rad)
			final_direction = target_direction.rotated(random_offset)
		
		# The rest of the spawning logic is the same, but uses our new `final_direction`.
		var spear_instance = spear_ability_scene.instantiate()
		
		var unique_name = str(multiplayer.get_unique_id()) + "_" + str(Time.get_ticks_msec()) + str(i)
		spear_instance.name = unique_name
		spear_instance.set_multiplayer_authority(multiplayer.get_unique_id())

		get_tree().get_first_node_in_group("foreground_layer").add_child(spear_instance, true)
		
		spear_instance.rpc("initialize", player.global_position, final_direction, current_base_damage, current_area_multiplier)

func get_direction_to_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemy")
	enemies = enemies.filter(func(enemy: Node2D):
		return enemy.global_position.distance_squared_to(player.global_position) < pow(MAX_TARGETING_RANGE, 2)
	)
	if enemies.is_empty(): return null
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
