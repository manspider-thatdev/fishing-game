extends Node2D

@onready var score = 0

signal score_changes

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_bobber_win(reward: int) -> void:
	score += reward
	score_changes.emit()

func _on_bobber_lose(penalty: int) -> void:
	score -= penalty
	score_changes.emit()
