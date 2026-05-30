extends CharacterBody2D

enum State { STALKING, TELEGRAPHING, DASHING, RECOVERY }
var current_state: State = State.STALKING

@export var walk_speed: float = 120.0
@export var dash_speed: float = 450.0

var player: CharacterBody2D = null
var dash_direction: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# Locate the player node at startup
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	# If the player is dead or missing, stop moving
	if not player: 
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	match current_state:
		State.STALKING:
			# Calculate direction vector pointing from enemy to player
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * walk_speed
			
			# Look towards the player
			if direction.x != 0:
				sprite.flip_h = direction.x < 0
			
			# Move using Godot's physics engine
			move_and_slide()
			
			# Trigger the attack tell if the player gets too close (150 pixels)
			if global_position.distance_to(player.global_position) < 150.0:
				start_telegraph()
				
		State.TELEGRAPHING:
			# Stand perfectly still during warning phase
			velocity = Vector2.ZERO
			move_and_slide()

		State.DASHING:
			# Surge along the pre-calculated, locked dash direction
			velocity = dash_direction * dash_speed
			move_and_slide()

		State.RECOVERY:
			# Stand still after dashing
			velocity = Vector2.ZERO
			move_and_slide()
			
func start_telegraph() -> void:
	current_state = State.TELEGRAPHING
	# Lock in the direction of the player at this EXACT instant
	dash_direction = (player.global_position - global_position).normalized()
	
	# Visual flash to telegraph the strike
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.4) 
	tween.finished.connect(start_dash)

func start_dash() -> void:
	current_state = State.DASHING
	sprite.modulate = Color.WHITE
	
	# Dash duration
	await get_tree().create_timer(0.25).timeout
	
	current_state = State.RECOVERY
	# Stun duration
	await get_tree().create_timer(0.5).timeout
	
	current_state = State.STALKING

func die() -> void:
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		ui.add_score(100)
	
	queue_free()
