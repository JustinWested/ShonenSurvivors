class_name Player
extends CharacterBody2D

@export var top_ui_margin: float = 15.0

@onready var damage_interval_timer = $DamageIntervalTimer
@onready var health_component = $HealthComponent 
@onready var health_bar = $HealthBar
@onready var abilities = $Abilities
@onready var player_input_synchronizer_component: PlayerInputSynchronizerComponent = $PlayerInputSynchronizerComponent
@onready var health_regen_timer: Timer = $HealthRegenTimer
@onready var collision_area: Area2D = $CollisionArea2D

var input_multiplayer_authority: int
var number_colliding_bodies = 0
var base_speed = 0

func _ready() -> void:
	player_input_synchronizer_component.set_multiplayer_authority(input_multiplayer_authority)
	
	health_regen_timer.timeout.connect(on_health_regen_timer_timeout)
	collision_area.body_entered.connect(on_body_entered)
	collision_area.body_exited.connect(on_body_exited)
	damage_interval_timer.timeout.connect(on_damage_interval_timer_timeout)
	health_component.health_decreased.connect(on_health_decreased)
	health_component.health_changed.connect(on_health_changed)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	update_health_display()
	

func _process(delta: float) -> void:
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

func on_body_entered(other_body: Node2D):
	number_colliding_bodies += 1
	check_deal_damage()
	
func on_body_exited(other_body: Node2D):
	number_colliding_bodies -= 1
	
func on_damage_interval_timer_timeout():
	check_deal_damage()
	
func on_health_decreased():
	GameEvents.emit_player_damaged()
	$AudioStreamPlayer2D.play()
	
	
func on_health_changed():
	update_health_display()


func on_ability_upgrade_added(ability_upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	if ability_upgrade is Ability:
		var ability = ability_upgrade as Ability
		abilities.add_child(ability_upgrade.ability_controller_scene.instantiate())


func on_health_regen_timer_timeout():
	var health_regen_quantity = 1 + MetaProgression.get_upgrade_count("health_regen")
	if health_regen_quantity > 0:
		health_component.heal(health_regen_quantity)
