extends CanvasLayer

@onready var score_label: Label = $ScoreLabel

var score: int = 0

func _ready() -> void:
	update_score_text()

func add_score(amount: int) -> void:
	score += amount
	update_score_text()

func update_score_text() -> void:
	score_label.text = "Score: " + str(score)
