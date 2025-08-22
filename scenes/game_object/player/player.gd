class_name Player
extends CharacterBody2D

signal died

@export var top_ui_margin: float = 15.0

@onready var damage_interval_timer = $DamageIntervalTimer
@onready var health_component = $HealthComponent 
@onready var health_bar = $HealthBar
@onready var abilities = $Abilities
@onready var player_input_synchronizer_component: PlayerInputSynchronizerComponent = $PlayerInputSynchronizerComponent
@onready var health_regen_timer: Timer = $HealthRegenTimer
@onready var collision_area: Area2D = $CollisionArea2D
@onready var sword_ability_controller: Node = $Abilities/SwordAbilityController
@onready var tombstone_sprite: Sprite2D = $DeathSprite
@onready var player_sprite: Sprite2D = $Sprite2D
@onready var abilities_node: Node = $Abilities
@onready var display_name_label: Label = $DisplayNameLabel



var input_multiplayer_authority: int
var number_colliding_bodies = 0
var base_speed = 0
var is_dead: bool = false
var display_name: String

func _ready() -> void:
	player_input_synchronizer_component.set_multiplayer_authority(input_multiplayer_authority)
	
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		display_name_label.visible = false
	else:
		display_name_label.text = display_name
	
	if sword_ability_controller and sword_ability_controller.has_method("set_ability_owner"):
		sword_ability_controller.set_ability_owner(self)
	
	
	health_regen_timer.timeout.connect(on_health_regen_timer_timeout)
	collision_area.body_entered.connect(on_body_entered)
	collision_area.body_exited.connect(on_body_exited)
	damage_interval_timer.timeout.connect(on_damage_interval_timer_timeout)
	health_component.health_decreased.connect(on_health_decreased)
	health_component.health_changed.connect(on_health_changed)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	update_health_display()
	
	if is_multiplayer_authority():
		health_component.died.connect(on_player_died)

func _process(delta: float) -> void:
	if is_dead:
		return
		
	if is_multiplayer_authority():
		velocity = player_input_synchronizer_component.movement_vector * 100
		move_and_slide()
		
	_clamp_to_camera_bounds()


func _clamp_to_camera_bounds():
	if not is_multiplayer_authority():
		return

	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return

	var view_size = get_viewport().get_visible_rect().size / camera.zoom
	var view_top_left = camera.global_position - (view_size / 2.0)
	var view_bottom_right = camera.global_position + (view_size / 2.0)
	view_top_left.y += top_ui_margin / camera.zoom.y
	var player_bounds_rect = Rect2()
	for i in range(collision_area.shape_owner_get_shape_count(0)):
		var shape = collision_area.shape_owner_get_shape(0, i)
		player_bounds_rect = player_bounds_rect.merge(shape.get_rect())

	var player_half_size = (player_bounds_rect.size / 2.0) * scale
	var min_clamp_bounds = view_top_left + player_half_size
	var max_clamp_bounds = view_bottom_right - player_half_size
	global_position.x = clamp(global_position.x, min_clamp_bounds.x, max_clamp_bounds.x)
	global_position.y = clamp(global_position.y, min_clamp_bounds.y, max_clamp_bounds.y)


func check_deal_damage():
	if number_colliding_bodies == 0 || !damage_interval_timer.is_stopped():
		return
	health_component.damage(1)
	damage_interval_timer.start()
	
func update_health_display():
	health_bar.value = health_component.get_health_percent()


func set_display_name(incoming_name: String):
	display_name = incoming_name


func on_body_entered(other_body: Node2D):
	number_colliding_bodies += 1
	if !is_dead:
		check_deal_damage()
	
func on_body_exited(other_body: Node2D):
	number_colliding_bodies -= 1
	
func on_damage_interval_timer_timeout():
	if !is_dead:
		check_deal_damage()
	
func on_health_decreased():
	GameEvents.emit_player_damaged()
	$AudioStreamPlayer2D.play()
	
	
func on_player_died():
	if not is_multiplayer_authority() or is_dead:
		return
		
	is_dead = true
	# --- Transform into a Tombstone ---
	become_tombstone.rpc()
	
	died.emit()
	GameEvents.emit_player_died(get_multiplayer_authority())

	
func on_health_changed():
	update_health_display()


func on_ability_upgrade_added(ability_upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	if ability_upgrade is Ability:
		var _ability = ability_upgrade as Ability
		abilities.add_child(ability_upgrade.ability_controller_scene.instantiate())


func on_health_regen_timer_timeout():
	if is_dead:
		return
	
	var health_regen_quantity = 1 + MetaProgression.get_upgrade_count("health_regen")
	if health_regen_quantity > 0:
		health_component.heal(health_regen_quantity)
	print("regen health")
	health_regen_timer.start()
	
	
func _set_abilities_active(is_active: bool):
	if is_active:
		abilities_node.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		abilities_node.process_mode = Node.PROCESS_MODE_DISABLED


	for ability_controller in abilities_node.get_children():
		if ability_controller.has_node("Timer"):
			var timer = ability_controller.get_node("Timer")
			if is_active:
				timer.start()
			else:
				timer.stop()

@rpc("any_peer", "call_local", "reliable")
func become_tombstone():
	is_dead = true # Set state on remote clients too
	

	player_sprite.hide()
	health_bar.hide()
	tombstone_sprite.show()
	collision_area.monitoring = false
	collision_area.monitorable = false

	_set_abilities_active(false)

@rpc("authority", "call_local", "reliable")
func respawn():
	if not is_multiplayer_authority():
		return

	is_dead = false
	

	player_sprite.show()
	health_bar.show()
	tombstone_sprite.hide()
	collision_area.monitoring = true
	collision_area.monitorable = true
	health_component.reset_health()
	
	_set_abilities_active(true)
