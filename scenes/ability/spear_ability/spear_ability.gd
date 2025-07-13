extends Node2D
class_name SpearAbility

@onready var hitbox_component: HitboxComponent = $HitboxComponent

const TRAVEL_DISTANCE = 800.0
const SPEED = 900.0

var direction = Vector2.RIGHT
var distance_traveled = 0.0

const ENEMY_COLLISION_MASK = 4 

func setup(initial_direction: Vector2):
	direction = initial_direction.normalized()
	rotation = direction.angle() + PI / 2 # The 90-degree correction we found
