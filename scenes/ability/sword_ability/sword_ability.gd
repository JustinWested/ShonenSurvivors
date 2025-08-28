extends Node2D
class_name SwordAbility

@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer


@rpc("any_peer", "call_local")
func initialize(spawn_position: Vector2, spawn_rotation: float, damage: int, area_multiplier: float):
	global_position = spawn_position
	rotation = spawn_rotation
	hitbox_component.damage = damage
	scale = Vector2.ONE * area_multiplier
	# Start the animation. The animation should have a call to queue_free()
	# on its last frame to clean itself up.
	animation_player.play("swing")
