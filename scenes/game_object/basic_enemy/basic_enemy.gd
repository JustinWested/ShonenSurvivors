extends CharacterBody2D


@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component = $VelocityComponent
@onready var target_acquisition_timer: Timer = $TargetAcquisitionTimer

var target_player: Node2D = null


func _ready():
	$HurtboxComponent.hit.connect(on_hit)
	target_acquisition_timer.timeout.connect(acquire_nearest_player)
	
	
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


func on_hit():
	$AudioStreamPlayer2D.play()
