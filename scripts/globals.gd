extends Node

var SCORE: int = 0:
	set(val):
		SCORE = val
		score_updated.emit(SCORE)
var COMBO: int = 0:
	set(val):
		COMBO = val
		combo_updated.emit(COMBO)
var BOBBER: Area2D = null
@onready var root := get_tree().root

signal score_updated(score: int)
signal combo_updated(combo: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func connect_bobber(bobber: Node2D):
	BOBBER = bobber
	BOBBER.win_fish.connect(_on_bobber_win)
	BOBBER.lose_fish.connect(_on_bobber_lose)
	score_updated.connect(BOBBER._on_score_changes)
	return

func score_calc(fish: FishData) -> int:
	var size := fish.qte_size
	var time := fish.qte_time
	var c := COMBO if COMBO > 0 else 1
	return floori(size * (size/time) * c)

func _on_bobber_win(fish: FishData):
	SCORE += score_calc(fish)
	COMBO += 1
	return

func _on_bobber_lose(fish: FishData):
	SCORE -= fish.qte_size
	COMBO = 0
	return
