extends CharacterBody2D

const MAX_SPEED = 115

@onready var health_component: HealthComponent = $HealthComponent
@onready var velocity_component = $VelocityComponent


func _process(delta: float) -> void:
	velocity_component.accelerate_to_player()
	velocity_component.move(self)
