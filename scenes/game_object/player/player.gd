class_name Player
extends CharacterBody2D

@export var arena_time_manager: Node

@onready var damage_interval_timer = $DamageIntervalTimer
@onready var health_component = $HealthComponent 
@onready var health_bar = $HealthBar
@onready var abilities = $Abilities
@onready var velocity_component = $VelocityComponent
@onready var player_input_synchronizer_component: PlayerInputSynchronizerComponent = $PlayerInputSynchronizerComponent

var input_multiplayer_authority: int
var number_colliding_bodies = 0
var base_speed = 0

func _ready() -> void:
	player_input_synchronizer_component.set_multiplayer_authority(input_multiplayer_authority)
	
	#commented out because its making multiplayer not work. will fix later
	#arena_time_manager.arena_difficulty_increased.connect(on_arena_difficulty_increased)
	
	$CollisionArea2D.body_entered.connect(on_body_entered)
	$CollisionArea2D.body_exited.connect(on_body_exited)
	damage_interval_timer.timeout.connect(on_damage_interval_timer_timeout)
	health_component.health_decreased.connect(on_health_decreased)
	health_component.health_changed.connect(on_health_changed)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	update_health_display()
	

func _process(delta: float) -> void:
	#CHANGING THIS CODE FOR MULTIPLAYER FUNCTIONALITY. REVIST THIS LATER
	#var direction = player_input_synchronizer_component.movement_vector.normalized()
	#velocity_component.accelerate_in_direction(direction)
	#velocity_component.move(self)
	
	
	if is_multiplayer_authority():
		velocity = player_input_synchronizer_component.movement_vector * 100
		move_and_slide()


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
	elif ability_upgrade.id == "player_speed":
		velocity_component.max_speed = base_speed + (base_speed * current_upgrades["player_speed"]["quantity"] * .1)


func on_arena_difficulty_increased(difficulty: int):
	var health_regen_quantity = MetaProgression.get_upgrade_count("health_regen")
	if health_regen_quantity > 0:
		var is_thirty_second_interval = (difficulty % 6) == 0
		if is_thirty_second_interval:
			health_component.heal(health_regen_quantity)
