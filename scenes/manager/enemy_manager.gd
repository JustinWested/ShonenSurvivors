extends Node

const SPAWN_RADIUS = 370

@export var basic_enemy_scene: PackedScene
@export var crab_enemy_scene: PackedScene
@export var bat_enemy_scene: PackedScene
@export var arena_time_manager: Node

@onready var timer = $Timer

var base_spawn_time = 0
var enemy_table = WeightedTable.new()
var number_to_spawn = 5

func _ready() -> void:
	enemy_table.add_item(basic_enemy_scene, 20)
	enemy_table.add_item(bat_enemy_scene, 2)
	
	base_spawn_time = timer.wait_time
	timer.timeout.connect(on_timer_timeout)
	arena_time_manager.arena_difficulty_increased.connect(on_arena_difficulty_increased)

func on_timer_timeout():
	timer.start()
	
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	for i in number_to_spawn:
		var enemy_scene = enemy_table.pick_items()
		var enemy = enemy_scene.instantiate()
		var random_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
		var spawn_position = player.global_position + (random_direction * SPAWN_RADIUS)
		var entities_layer = get_tree().get_first_node_in_group("entities_layer")
		entities_layer.add_child(enemy)
		enemy.global_position = spawn_position

func on_arena_difficulty_increased(arena_difficulty: int):
	var time_off = (.1/12) * arena_difficulty
	time_off = max(time_off, .2)
	timer.wait_time = base_spawn_time - time_off

	if arena_difficulty == 6:
		enemy_table.add_item(crab_enemy_scene, 15)
	elif arena_difficulty == 10:
		enemy_table.add_item(bat_enemy_scene, 8)
	
	if (arena_difficulty % 6) == 0:
		number_to_spawn += 1
