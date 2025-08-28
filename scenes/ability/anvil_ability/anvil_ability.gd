extends Node2D

@onready var hitbox_component: HitboxComponent = $HitboxComponent

# --- MODIFIED: Add 'area_multiplier' as the last argument ---
@rpc("any_peer", "call_local")
func initialize(spawn_position: Vector2, damage: int, area_multiplier: float):
	global_position = spawn_position
	hitbox_component.damage = damage
	
	# --- NEW: Apply the scale ---
	scale = Vector2.ONE * area_multiplier
