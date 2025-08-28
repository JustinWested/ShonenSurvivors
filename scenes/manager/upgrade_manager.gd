extends Node

@export var experience_manager: Node
@export var upgrade_screen_scene: PackedScene
@export var main_scene: Node

var current_turn_index = -1 # Start at -1 so the first turn becomes 0
var active_player_id_for_this_level = 0 # Stores the peer ID of the active player
var current_upgrade_screen = null

var ability_scene_map = {}
var player_upgrades = {}
var upgrade_pool: WeightedTable = WeightedTable.new()

var upgrade_axe = preload("res://resources/upgrades/axe.tres")
var upgrade_player_speed = preload("res://resources/upgrades/player_speed.tres")
var upgrade_anvil = preload("res://resources/upgrades/anvil.tres")
var upgrade_spear = preload("res://resources/upgrades/spear.tres")
var upgrade_sword = preload("res://resources/upgrades/sword.tres")

var sword_controller_scene = preload("res://scenes/ability/sword_ability_controller/sword_ability_controller.tscn")
var axe_controller_scene = preload("res://scenes/ability/axe_ability_controller/axe_ability_controller.tscn")
var anvil_controller_scene = preload("res://scenes/ability/anvil_ability_controller/anvil_ability_controller.tscn")
var spear_controller_scene = preload("res://scenes/ability/spear_ability_controller/spear_ability_controller.tscn")



func _ready():
	upgrade_pool.add_item(upgrade_axe, 10)
	upgrade_pool.add_item(upgrade_player_speed, 5)
	upgrade_pool.add_item(upgrade_anvil, 10)
	upgrade_pool.add_item(upgrade_spear, 10)
	upgrade_pool.add_item(upgrade_sword, 10)
	
	ability_scene_map["sword"] = sword_controller_scene
	ability_scene_map["axe"] = axe_controller_scene
	ability_scene_map["anvil"] = anvil_controller_scene
	ability_scene_map["spear"] = spear_controller_scene
	
	experience_manager.level_up.connect(on_level_up)
	
	
func register_player(peer_id: int):
	if not player_upgrades.has(peer_id):
		player_upgrades[peer_id] = {}
		print("UpgradeManager: Registered player %s" % peer_id)

		player_upgrades[peer_id][upgrade_sword.id] = {
			"resource": upgrade_sword,
			"quantity": 1
		}
		

func apply_upgrade(upgrade: AbilityUpgrade, target_player_id: int):
	# If for some reason the player isn't registered, do nothing.
	if not player_upgrades.has(target_player_id):
		return

	var specific_player_upgrades = player_upgrades[target_player_id]
	var has_upgrade = specific_player_upgrades.has(upgrade.id)
	
	if not has_upgrade:
		specific_player_upgrades[upgrade.id] = {
			"resource": upgrade,
			"quantity": 1
		}
	else:
		specific_player_upgrades[upgrade.id]["quantity"] += 1
	
	
	
func pick_upgrades(active_player_id: int):
	var temporary_pool = WeightedTable.new()
	var specific_player_upgrades = player_upgrades.get(active_player_id, {})
	
	var all_levelable_abilities = [upgrade_sword, upgrade_axe, upgrade_player_speed, upgrade_anvil, upgrade_spear]
	
	for ability in all_levelable_abilities:
		var current_quantity = specific_player_upgrades.get(ability.id, {}).get("quantity", 0)
		if ability.max_quantity == 0 or current_quantity < ability.max_quantity:
			temporary_pool.add_item(ability, 10)

	var chosen_upgrades_array: Array[AbilityUpgrade] = []
	for i in 3:
		if temporary_pool.items.size() == chosen_upgrades_array.size():
			break
		var chosen_upgrade = temporary_pool.pick_items(chosen_upgrades_array)
		if chosen_upgrade: 
			chosen_upgrades_array.append(chosen_upgrade)
	
	return chosen_upgrades_array	
	
	
func on_level_up(current_level: int):
	print("HOST: on_level_up triggered.") 
	
	var player_ids = main_scene.player_dictionary.keys()
	active_player_id_for_this_level = player_ids[current_turn_index]

	player_ids.sort()
	
	if player_ids.is_empty():
		print("HOST: player_dictionary is empty. Exiting.")
		return
		
	current_turn_index = (current_turn_index + 1) % player_ids.size()
	
	active_player_id_for_this_level = player_ids[current_turn_index]
	print("LEVEL UP! It is Player %s's turn to choose." % active_player_id_for_this_level)
	rpc("pause_game_for_all")
	var chosen_upgrades_array = pick_upgrades(active_player_id_for_this_level)
	var upgrade_paths: Array[String] = []
	for upgrade in chosen_upgrades_array:
		upgrade_paths.append(upgrade.resource_path)
	
	rpc("show_upgrade_screen_on_all_peers", upgrade_paths, active_player_id_for_this_level)
	
	
	
func on_upgrade_selected(upgrade: AbilityUpgrade):
	if multiplayer.get_unique_id() != active_player_id_for_this_level:
		print("Player %s clicked, but it's Player %s's turn. Ignoring." % [multiplayer.get_unique_id(), active_player_id_for_this_level])
		return
	rpc("apply_upgrade_on_target", upgrade.resource_path, active_player_id_for_this_level)
	rpc("unpause_game_for_all")
	rpc("dismiss_upgrade_screen_on_all_peers")

@rpc("any_peer", "call_local", "reliable")
func dismiss_upgrade_screen_on_all_peers():
	if is_instance_valid(current_upgrade_screen):
		current_upgrade_screen.play_out_and_free()
		current_upgrade_screen = null

@rpc("any_peer", "call_local", "reliable")
func show_upgrade_screen_on_all_peers(upgrade_paths: Array[String], active_player_id: int):
	print("[%s] PEER: Received RPC show_upgrade_screen_on_all_peers. Active player is %s." % [multiplayer.get_unique_id(), active_player_id])
	self.active_player_id_for_this_level = active_player_id
	
	var upgrade_screen_instance = upgrade_screen_scene.instantiate()
	current_upgrade_screen = upgrade_screen_instance # Store the reference
	add_child(upgrade_screen_instance)

	var upgrades_to_show: Array[AbilityUpgrade] = []
	for path in upgrade_paths:
		var loaded_upgrade = load(path) as AbilityUpgrade
		if loaded_upgrade:
			upgrades_to_show.append(loaded_upgrade)

	var is_my_turn = (multiplayer.get_unique_id() == active_player_id)
	upgrade_screen_instance.set_ability_upgrades(upgrades_to_show, is_my_turn, active_player_id)
	upgrade_screen_instance.upgrade_selected.connect(on_upgrade_selected)
	


@rpc("any_peer", "call_local", "reliable")
func apply_upgrade_on_target(upgrade_path: String, target_player_id: int):
	var upgrade: AbilityUpgrade = load(upgrade_path)
	if not upgrade:
		return

	apply_upgrade(upgrade, target_player_id)

	var specific_player_upgrades = player_upgrades.get(target_player_id, {})
	var target_player = main_scene.player_dictionary.get(target_player_id)

	if is_instance_valid(target_player) and target_player.is_multiplayer_authority():
		var abilities_container = target_player.get_node_or_null("Abilities")
		if not abilities_container:
			return

		# A) Check if this is a NEW ability (quantity is now 1).
		if upgrade is Ability:
			var quantity = specific_player_upgrades.get(upgrade.id, {}).get("quantity", 0)
			
			if quantity == 1:
				# 1. Check if our look-up table has a scene for this upgrade's ID.
				if ability_scene_map.has(upgrade.id):
					# 2. Get the scene from the map.
					var controller_scene_to_spawn = ability_scene_map[upgrade.id]
					# 3. Instantiate it.
					var ability_instance = controller_scene_to_spawn.instantiate()
					abilities_container.add_child(ability_instance)
		# B) ALWAYS inform all existing controllers about the upgrade.
		for controller in abilities_container.get_children():
			if controller.has_method("on_new_upgrade_applied"):
				controller.on_new_upgrade_applied(upgrade, specific_player_upgrades)


@rpc("any_peer", "call_local", "reliable")
func pause_game_for_all():
	get_tree().paused = true

@rpc("any_peer", "call_local", "reliable")
func unpause_game_for_all():
	get_tree().paused = false
