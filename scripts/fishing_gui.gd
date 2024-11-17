extends CanvasLayer

var score_string: String = "Score: %d"
var combo_string: String = "Combo: x%d"
@onready var score_label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var combo_label = $MarginContainer/VBoxContainer/ComboLabel
@onready var combo_bar = $MarginContainer/VBoxContainer/ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.score_updated.connect(_on_score_update)
	Globals.combo_updated.connect(_on_combo_update)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	assert(Globals.combo_timer)
	combo_bar.value = Globals.combo_timer.time_left

func _on_score_update(score: int):
	score_label.text = score_string % score

func _on_combo_update(combo: int):
	combo_label.text = combo_string % combo
