extends PanelContainer

signal selected

@onready var name_label: Label = $%NameLabel
@onready var description_label: Label = $%DescriptionLabel

var disabled = false
var is_interactive = false

func _ready():
	gui_input.connect(on_gui_input)
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)

func play_in(delay: float = 0):
	modulate = Color.TRANSPARENT
	await get_tree().create_timer(delay).timeout
	$AnimationPlayer.play("in")
	

func select_card():
	disabled = true
	$AnimationPlayer.play("selected")
	
	for other_card in get_tree().get_nodes_in_group("upgrade_card"):
		if other_card == self:
			continue
		other_card.play_discard()
	
	
	await $AnimationPlayer.animation_finished
	selected.emit()
	
	
func play_discard():
	$AnimationPlayer.play("discard")

func set_ability_upgrade(upgrade: AbilityUpgrade):
	name_label.text = upgrade.name
	description_label.text = upgrade.description

func on_gui_input(event: InputEvent):
	if not is_interactive or disabled:
		return
		
	if event.is_action_pressed("left_click"):
		select_card()

func on_mouse_entered():
	if not is_interactive or disabled:
		return
	$HoverAnimationPlayer.play("hover")

func on_mouse_exited():
	
	$HoverAnimationPlayer.play("RESET")


func set_interactive(can_interact: bool):
	is_interactive = can_interact
	# For visual feedback, we can make the non-interactive cards slightly faded.
	if not is_interactive:
		modulate = Color(1, 1, 1, 0.6) # 60% transparent white tint
