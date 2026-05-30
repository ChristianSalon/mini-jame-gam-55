extends Node

const MILK_ENEMY_SCENE = preload("res://scenes/milk_enemy.tscn")
const SPAWN_RADIUS: float = 700.0 

@onready var timer: Timer = $Timer

var player: CharacterBody2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
		
	# Pick a random angle
	var random_angle = randf_range(0, 2 * PI)
	# Calculate directional vector from angle
	var spawn_direction = Vector2(cos(random_angle), sin(random_angle))
	var spawn_position = player.global_position + (spawn_direction * SPAWN_RADIUS)
	
	var enemy = MILK_ENEMY_SCENE.instantiate()
	enemy.global_position = spawn_position
	
	get_parent().add_child(enemy)
