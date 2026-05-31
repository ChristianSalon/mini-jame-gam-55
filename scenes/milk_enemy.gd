extends CharacterBody2D

enum State { STALKING, TELEGRAPHING, DASHING, RECOVERY, CORPSE, EXPLODING }

@export var walk_speed: float = 120.0
@export var dash_speed: float = 450.0

var player: CharacterBody2D = null
var dash_direction: Vector2 = Vector2.ZERO
var current_state: State = State.STALKING
var telegraph_tween: Tween = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var corpse_area_shape: CollisionShape2D = $CorpseArea/CollisionShape2D
@onready var explosion_area: Area2D = $ExplosionArea
@onready var corpse_timer: Timer = $CorpseTimer


func _ready() -> void:
	# Locate the player node at startup
	player = get_tree().get_first_node_in_group("player")
	corpse_area_shape.disabled = true

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

func _on_corpse_timer_timeout() -> void:
	# Remove enemy if dead for 1 second
	if current_state == State.CORPSE:
		queue_free()

func _on_corpse_area_body_entered(body: Node2D) -> void:
	if current_state == State.CORPSE and body.is_in_group("player"):
		current_state = State.EXPLODING 
		
		corpse_area_shape.set_deferred("disabled", true)
		corpse_timer.stop()
		
		sprite.modulate = Color.WEB_GREEN
		await get_tree().create_timer(1.0).timeout
		
		start_explosion()

func start_telegraph() -> void:
	current_state = State.TELEGRAPHING
	# Lock in the direction of the player at this EXACT instant
	dash_direction = (player.global_position - global_position).normalized()
	
	# Visual flash to telegraph the strike
	telegraph_tween = create_tween()
	telegraph_tween.tween_property(sprite, "modulate", Color.ORANGE_RED, 0.4) 
	telegraph_tween.finished.connect(start_dash)

func start_dash() -> void:
	# Check if enemy did not die while telegraphing
	if current_state != State.TELEGRAPHING:
		return
	
	current_state = State.DASHING
	sprite.modulate = Color.WHITE
	
	# Dash duration
	await get_tree().create_timer(0.25).timeout
	if current_state != State.DASHING:
		return
	
	current_state = State.RECOVERY
	# Stun duration
	await get_tree().create_timer(0.5).timeout
	if current_state != State.RECOVERY:
		return
	
	current_state = State.STALKING

func start_explosion() -> void:
	# Flash right before exploding
	var scale_tween = create_tween()
	scale_tween.tween_property(sprite, "scale", Vector2(1.4, 1.4), 0.1)
	await scale_tween.finished
	
	# Find all enemies in the explosion radius
	var overlapping_bodies = explosion_area.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body != self and body.has_method("die"):
			body.die()
	
	queue_free()

func die() -> void:
	# Return if already dead
	if current_state == State.CORPSE or current_state == State.EXPLODING:
		return
	
	if telegraph_tween and telegraph_tween.is_valid():
		telegraph_tween.kill()
	
	current_state = State.CORPSE
	velocity = Vector2.ZERO
	
	var main_shape = $CollisionShape2D
	if main_shape:
		main_shape.set_deferred("disabled", true)
	
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)
	
	corpse_area_shape.set_deferred("disabled", false)
	corpse_timer.start()
	
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		ui.add_score(100)
