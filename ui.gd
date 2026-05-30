extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var restart_button: Button = $GameOverPanel/CenterContainer/VBoxContainer/RestartButton

var score: int = 0

func _ready() -> void:
	update_score_text()
	game_over_panel.hide()
	restart_button.pressed.connect(_on_restart_button_pressed)
	
func show_game_over() -> void:
	game_over_panel.show()
	# Pause the entire game world logic so enemies stop moving
	get_tree().paused = true 

func _on_restart_button_pressed() -> void:
	# Unpause the game tree before reloading, otherwise the new game stays frozen
	get_tree().paused = false 
	
	# Reload the current active scene from scratch
	get_tree().reload_current_scene()

func add_score(amount: int) -> void:
	score += amount
	update_score_text()

func update_score_text() -> void:
	score_label.text = "Score: " + str(score)
