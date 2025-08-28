# AbilityDB.gd
# Add this script to your project's Autoload settings (Project -> Project Settings -> Autoload)
extends Node

var upgrades = {}

# Preload all possible upgrades here
var upgrade_axe = preload("res://resources/upgrades/axe.tres")
var upgrade_axe_damage = preload("res://resources/upgrades/axe_damage.tres")
var upgrade_axe_count = preload("res://resources/upgrades/axe_count.tres")
var upgrade_sword_rate = preload("res://resources/upgrades/sword_rate.tres")
var upgrade_sword_damage = preload("res://resources/upgrades/sword_damage.tres")
var upgrade_player_speed = preload("res://resources/upgrades/player_speed.tres")
var upgrade_anvil = preload("res://resources/upgrades/anvil.tres")
var upgrade_anvil_count = preload("res://resources/upgrades/anvil_count.tres")
var upgrade_spear = preload("res://resources/upgrades/spear.tres")

func _ready():
	# Create a dictionary mapping resource IDs to the actual resource
	var all_upgrades = [
		upgrade_axe, upgrade_axe_damage, upgrade_axe_count,
		upgrade_sword_rate, upgrade_sword_damage, upgrade_player_speed,
		upgrade_anvil, upgrade_anvil_count, upgrade_spear
	]
	
	for upgrade in all_upgrades:
		if upgrade != null and upgrade.id != "":
			upgrades[upgrade.id] = upgrade

# A helper function to get a resource from its ID
func get_upgrade_from_id(id: String) -> AbilityUpgrade:
	return upgrades.get(id)

# A helper function to get multiple resources from an array of IDs
func get_upgrades_from_ids(ids: Array[String]) -> Array[AbilityUpgrade]:
	var result: Array[AbilityUpgrade] = []
	for id in ids:
		var upgrade = get_upgrade_from_id(id)
		if upgrade:
			result.append(upgrade)
	return result
