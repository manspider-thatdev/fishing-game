extends Node

var SCORE: int = 0
var COMBO: int = 0
@onready var root := get_tree().root

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func connect_bobber(bobber: Node2D):
	pass

func _on_bobber_win(fish: FishData):
	SCORE += fish.qte_size
	return

func _on_bobber_lose(fish: FishData):
	SCORE -= fish.qte_size
	return
