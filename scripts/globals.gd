extends Node
const GUI_SCENE := preload("res://scenes/fishing_gui.tscn")
const COMBO_TIME := 20 # seconds
@onready var root := get_tree().root

# Try not to touch these much outside of this script pls
var score: int = 0:
	set(val):
		score = val
		score_updated.emit(score)
var combo: int = 0:
	set(val):
		combo = val
		combo_updated.emit(combo)
var bobber: Area2D = null
var gui_node: CanvasLayer = null
var combo_timer: Timer = null

signal score_updated(score: int)
signal combo_updated(combo: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func instantiate_combo_timer() -> void:
	if combo_timer:
		combo_timer.queue_free()
	combo_timer = Timer.new()
	combo_timer.wait_time = COMBO_TIME
	combo_timer.timeout.connect(_on_combo_timeout)
	add_child(combo_timer)

func instantiate_gui() -> CanvasLayer:
	instantiate_combo_timer()
	gui_node = GUI_SCENE.instantiate()
	return gui_node

func connect_bobber(bobber_node: Node2D):
	bobber = bobber_node
	bobber.win_fish.connect(_on_bobber_win)
	bobber.lose_fish.connect(_on_bobber_lose)
	score_updated.connect(bobber._on_score_changes)

func score_calc(fish: FishData) -> int:
	var size := fish.qte_size
	var time := fish.qte_time
	var c := combo if combo > 0 else 1
	return floori(size * (size/time) * c)

func _on_bobber_win(fish: FishData):
	score += score_calc(fish)
	combo += 1
	combo_timer.start(COMBO_TIME)

func _on_bobber_lose(fish: FishData):
	score -= fish.qte_size
	combo = 0
	combo_timer.stop()

func _on_combo_timeout():
	combo = 0
