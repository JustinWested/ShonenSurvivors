extends Node

@export var axe_ability_scene: PackedScene
@export var base_damage = 5

var additional_damage_percent = 1
var axe_count = 0

func _ready():
	$Timer.timeout.connect(on_timer_timeout)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	
func on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var angle_slice = 2 * PI / (axe_count + 1)

	for i in axe_count + 1:
		var axe_instance = axe_ability_scene.instantiate()
		get_tree().root.add_child(axe_instance, true)
		axe_instance.global_position = player.global_position
		var symmetrical_direction = Vector2.RIGHT.rotated(i * angle_slice)
		axe_instance.setup_direction(symmetrical_direction)
		axe_instance.get_node("HitboxComponent").damage = ceil(base_damage * additional_damage_percent)


func on_ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	if upgrade.id == "axe_damage":
		additional_damage_percent = 1 + (current_upgrades["axe_damage"]["quantity"] * .1)
	if upgrade.id == "axe_count":
		axe_count = current_upgrades["axe_count"]["quantity"]
