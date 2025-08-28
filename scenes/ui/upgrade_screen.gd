extends CanvasLayer

signal upgrade_selected(upgrade: AbilityUpgrade)

@export var upgrade_card_scene: PackedScene

@onready var card_container: HBoxContainer = %CardContainer
@onready var turn_label: Label = $MarginContainer2/TurnLabel


func set_ability_upgrades(upgrades: Array[AbilityUpgrade], is_my_turn: bool, active_player_id: int):
	turn_label.text = "It is Peer %s's Turn" % active_player_id

	var delay = 0
	if upgrades.size() == 0:
		queue_free()
		return
		
	for upgrade in upgrades:
		var card_instance = upgrade_card_scene.instantiate()
		card_container.add_child(card_instance)
		card_instance.set_ability_upgrade(upgrade)
		
		card_instance.set_interactive(is_my_turn)

		card_instance.play_in(delay)
		card_instance.selected.connect(on_upgrade_selected.bind(upgrade))
		delay += .2
		
		
func on_upgrade_selected(upgrade: AbilityUpgrade):
	upgrade_selected.emit(upgrade)

func play_out_and_free():
	# If the animation is already playing, don't restart it.
	if $AnimationPlayer.is_playing() and $AnimationPlayer.current_animation == "out":
		return
		
	$AnimationPlayer.play("out")
	await $AnimationPlayer.animation_finished
	queue_free()
