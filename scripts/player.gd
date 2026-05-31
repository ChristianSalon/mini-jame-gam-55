extends CharacterBody2D

const BULLET_SCENE = preload("res://scenes/bullet.tscn")

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var shoot_timer: Timer = $ShootTimer
@onready var cooldown_bar: ProgressBar = $CooldownBar


func _physics_process(delta: float) -> void:
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * SPEED
	move_and_slide()
	
	if not shoot_timer.is_stopped():
		cooldown_bar.show() # Show the bar while cooling down
		cooldown_bar.value = shoot_timer.time_left / shoot_timer.wait_time
	else:
		cooldown_bar.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse_click") and shoot_timer.is_stopped():
		shoot()

func _on_hurtbox_body_entered(body: Node) -> void:
	# Check if the object hitting us is an enemy
	if body.has_method("die"):
		die()

func die() -> void:
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		ui.show_game_over()
	
	queue_free()

func shoot() -> void:
	shoot_timer.start()
	
	var bullet = BULLET_SCENE.instantiate()
	# Current player position
	bullet.global_position = global_position
	
	var target = get_global_mouse_position()
	bullet.direction = (target - global_position).normalized()
	
	get_parent().add_child(bullet)
