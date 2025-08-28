extends Resource
class_name AbilityLevelStats

# The stats that ONE level-up will provide.
# Set to 0 or 1.0 if a level doesn't grant this bonus.
@export var damage_increase: int = 0
@export var projectile_increase: int = 0
@export var area_multiplier: float = 1.0 # Multiplier, so 1.0 is no change
@export var cooldown_reduction_percent: float = 0.0 # e.g., 0.1 for 10%
