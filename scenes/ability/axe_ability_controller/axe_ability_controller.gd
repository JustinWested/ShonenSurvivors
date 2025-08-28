extends Node

@export var axe_ability_resource: Ability
@export var axe_ability_scene: PackedScene
@export var base_damage = 5

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

	
func on_timer_timeout():
	spawn_axe()


func spawn_axe():
	if not is_instance_valid(player):
		return

	# Use the new stat for the number of projectiles.
	var angle_slice = 2 * PI / current_projectile_count

	for i in range(current_projectile_count):
		var axe_instance = axe_ability_scene.instantiate()
		var unique_name = str(multiplayer.get_unique_id()) + "_" + str(Time.get_ticks_msec()) + str(i)
		axe_instance.name = unique_name
		
		axe_instance.set_multiplayer_authority(multiplayer.get_unique_id())
		get_tree().get_first_node_in_group("foreground_layer").add_child(axe_instance, true)
		
		var player_path = player.get_path()
		var symmetrical_direction = Vector2.RIGHT.rotated(i * angle_slice)
		
		# Pass the new calculated stats to the axe's initialize RPC.
		axe_instance.rpc("initialize", player.global_position, symmetrical_direction, current_base_damage, player_path, current_area_multiplier)


func update_stats_for_level(level: int):
	# Reset to base stats before recalculating.
	current_projectile_count = 1
	current_base_damage = 5
	current_area_multiplier = 1.0
	$Timer.wait_time = base_wait_time

	# Loop through the progression array up to the current level.
	for i in range(level):
		var level_stats = axe_ability_resource.level_progression[i] as AbilityLevelStats
		current_base_damage += level_stats.damage_increase
		current_projectile_count += level_stats.projectile_increase
		current_area_multiplier *= level_stats.area_multiplier
		$Timer.wait_time *= (1.0 - level_stats.cooldown_reduction_percent)
	
	print("Axe updated to Level %s: Projectiles=%s, Damage=%s" % [level, current_projectile_count, current_base_damage])


func on_new_upgrade_applied(upgrade: AbilityUpgrade, player_specific_upgrades: Dictionary):
	if axe_ability_resource == null: return
	if upgrade.id != axe_ability_resource.id: return

	current_level = player_specific_upgrades.get(upgrade.id, {}).get("quantity", 1)
	update_stats_for_level(current_level)
