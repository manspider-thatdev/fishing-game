extends Node2D

var rng := RandomNumberGenerator.new()

signal end_qte(is_success: bool)

@onready var timer := $Timer
@onready var input_label := $Labels/Inputs
@onready var time_label := $Labels/Time

enum Directions {LEFT, UP, RIGHT, DOWN}
# WARNING: If you change the String char-order pls update above enum
var text_dirs: String = "←↑→↓"
var chosen_dirs: Array[int] = [] # empty array to add RNG inputs

@export var input_num: int = 4 # number of required inputs
@export var time: float = 5.0

func choose_inputs() -> void:
	chosen_dirs.resize(input_num)
	for n in input_num:
		chosen_dirs[n] = rng.randi_range(0, 3) # see above enum
		
func make_display_text() -> String:
	var retval: String = ""
	for n in chosen_dirs.size():
		retval += text_dirs[chosen_dirs[n]]
		retval += " "
	return retval

func player_fail() -> void:
	# idk pause the timer, restart the qte, etc.
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	choose_inputs()
	timer.one_shot = true
	timer.start(time)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if chosen_dirs.size() == 0:
		end_qte.emit(true)
		queue_free()
		return
		
	input_label.text = make_display_text()
	time_label.text = str(timer.time_left).pad_decimals(2)
	match chosen_dirs[0]:
		Directions.LEFT:
			if Input.is_action_just_pressed("left"):
				chosen_dirs.pop_front()
			else: player_fail()
		Directions.RIGHT:
			if Input.is_action_just_pressed("right"):
				chosen_dirs.pop_front()
			else: player_fail()
		Directions.UP:
			if Input.is_action_just_pressed("up"):
				chosen_dirs.pop_front()
			else: player_fail()
		Directions.DOWN:
			if Input.is_action_just_pressed("down"):
				chosen_dirs.pop_front()
			else: player_fail()

func _on_timer_timeout() -> void:
	end_qte.emit(false)
	queue_free()
