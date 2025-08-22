extends CharacterBody2D


@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component = $VelocityComponent
@onready var target_acquisition_timer: Timer = $TargetAcquisitionTimer
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent


var impact_particles_scene: PackedScene = preload("uid://dxnf28wo0iewu")
var ground_particles_scene: PackedScene = preload("uid://bk1trdp7h53uh")
var target_player: Node2D = null


func _ready():
	$HurtboxComponent.hit.connect(on_hit)
	target_acquisition_timer.timeout.connect(acquire_nearest_player)
	health_component.died.connect(_on_died)

	
func _physics_process(delta: float) -> void:
	if not is_instance_valid(target_player):
		return
	var direction = (target_player.global_position - global_position).normalized()
	if is_multiplayer_authority():
		velocity_component.accelerate_in_direction(direction, delta)
		velocity_component.move(self)

func acquire_nearest_player():
	if !is_multiplayer_authority():
		return
	var players = get_tree().get_nodes_in_group("player")
	var closest_player: Node2D = null
	var closest_distance_sq = INF 

	if players.is_empty():
		target_player = null 
		return

	for player in players:
		var distance_sq = global_position.distance_squared_to(player.global_position)
		if distance_sq < closest_distance_sq:
			closest_distance_sq = distance_sq
			closest_player = player
	
	target_player = closest_player


@rpc("authority", "call_local")
func spawn_hit_particles():
	var hit_particles: Node2D = impact_particles_scene.instantiate()
	hit_particles.global_position = hurtbox_component.global_position
	get_parent().add_child(hit_particles)


func on_hit():
	spawn_hit_particles.rpc()
	$AudioStreamPlayer2D.play()

@rpc("authority", "call_local")
func spawn_death_particles():
	var ground_particles: Node2D = ground_particles_scene.instantiate()
	var background_layer = get_tree().get_first_node_in_group("background_layer")
	ground_particles.global_position = global_position
	if background_layer != null:
		background_layer.add_child(ground_particles, true)
		

func _on_died():
	spawn_death_particles.rpc()
	queue_free()
