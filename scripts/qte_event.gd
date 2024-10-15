extends Node2D

var rng := RandomNumberGenerator.new()

signal end_qte(success: bool)

@onready var timer := $Timer
@onready var input_label := $Labels/Inputs
@onready var time_label := $Labels/Time

var dirs := ["←", "↑", "→", "↓"]
var chosen_dirs := [] # empty array to add RNG inputs

@export var input_num: int = 4 # number of required inputs
@export var time: float = 5.0

func choose_inputs() -> void:
	chosen_dirs.resize(input_num)
	for n in input_num:
		chosen_dirs[n] = dirs[rng.randi_range(0, 3)]
		
func input_text() -> String:
	var retval: String = ""
	for n in input_num:
		retval += chosen_dirs[n]
		retval += " "
	return retval

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	choose_inputs()
	timer.one_shot = true
	timer.start(time)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	input_label.text = input_text()
	var inp := Input.get_vector("left", "right", "up", "down")
	# idk put conditional logic here
	
	time_label.text = str(timer.time_left).pad_decimals(2)
	pass

func _on_timer_timeout() -> void:
	end_qte.emit(false)
	queue_free()
	pass # Replace with function body.
