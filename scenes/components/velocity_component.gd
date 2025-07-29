extends Node

@export var max_speed: int = 80
@export var acceleration: float = 5

var velocity = Vector2.ZERO


func accelerate_in_direction(direction: Vector2, delta: float):
	var desired_velocity = direction * max_speed
	velocity = velocity.lerp(desired_velocity, 1 - exp(-acceleration * delta))


func move(character_body: CharacterBody2D):
	character_body.velocity = velocity
	character_body.move_and_slide()
	velocity = character_body.velocity
