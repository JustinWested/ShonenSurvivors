extends Node2D
class_name SpearAbility

@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

const TRAVEL_DISTANCE = 300.0
const SPEED = 500.0

var direction = Vector2.RIGHT
var distance_traveled = 0.0

# --- MODIFIED: Add 'area_multiplier' as the last argument ---
@rpc("any_peer", "call_local")
func initialize(start_position: Vector2, initial_direction: Vector2, damage: int, area_multiplier: float):
	global_position = start_position
	direction = initial_direction.normalized()
	rotation = direction.angle() + PI / 2 # Your custom rotation correction
	hitbox_component.damage = damage
	
	# --- NEW: Apply the scale ---
	scale = Vector2.ONE * area_multiplier
	
	synchronizer.root_path = get_path()

# The _physics_process function remains exactly the same and is correct.
func _physics_process(delta):
	if not is_multiplayer_authority():
		return

	var velocity = direction * SPEED * delta
	global_position += velocity
	distance_traveled += velocity.length()

	if distance_traveled >= TRAVEL_DISTANCE:
		queue_free()
