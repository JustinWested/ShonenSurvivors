extends Node

const BASE_RANGE = 100

@export var anvil_ability_resource: Ability
@export var anvil_ability_scene: PackedScene

@onready var player: Node2D = get_parent().get_parent()

var current_level = 0
var current_projectile_count = 1
var current_base_damage = 10
var current_area_multiplier = 1.0
var base_wait_time

func _ready():
	base_wait_time = $Timer.wait_time
	$Timer.timeout.connect(on_timer_timeout)
	if player.is_multiplayer_authority():
		$Timer.start()

func on_new_upgrade_applied(upgrade: AbilityUpgrade, player_specific_upgrades: Dictionary):
	if anvil_ability_resource == null: return
	if upgrade.id != anvil_ability_resource.id: return

	current_level = player_specific_upgrades.get(upgrade.id, {}).get("quantity", 1)
	update_stats_for_level(current_level)

func update_stats_for_level(level: int):
	current_projectile_count = 1
	current_base_damage = 10
	current_area_multiplier = 1.0
	$Timer.wait_time = base_wait_time

	for i in range(level):
		var level_stats = anvil_ability_resource.level_progression[i] as AbilityLevelStats
		current_base_damage += level_stats.damage_increase
		current_projectile_count += level_stats.projectile_increase
		current_area_multiplier *= level_stats.area_multiplier
		$Timer.wait_time *= (1.0 - level_stats.cooldown_reduction_percent)
	
	print("Anvil updated to Level %s: Projectiles=%s, Damage=%s" % [level, current_projectile_count, current_base_damage])


func on_timer_timeout():
	spawn_anvil()

func spawn_anvil():
	if not is_instance_valid(player):
		return
		
	var direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
	var additional_rotation_degrees = 360.0 / current_projectile_count
	var anvil_distance = randf_range(0, BASE_RANGE)
	
	for i in range(current_projectile_count):
		var adjusted_direction = direction.rotated(deg_to_rad(i * additional_rotation_degrees))
		var spawn_position = player.global_position + (adjusted_direction * anvil_distance)
		
		var query_parameters = PhysicsRayQueryParameters2D.create(player.global_position, spawn_position, 1)
		var result = get_tree().root.world_2d.direct_space_state.intersect_ray(query_parameters)
		if !result.is_empty():
			spawn_position = result["position"]
			
		var anvil_ability = anvil_ability_scene.instantiate()
		
		var unique_name = str(multiplayer.get_unique_id()) + "_" + str(Time.get_ticks_msec()) + str(i)
		anvil_ability.name = unique_name
		anvil_ability.set_multiplayer_authority(multiplayer.get_unique_id())
		
		get_tree().get_first_node_in_group("foreground_layer").add_child(anvil_ability, true)
		
		anvil_ability.rpc("initialize", spawn_position, current_base_damage, current_area_multiplier)
