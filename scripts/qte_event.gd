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
# @export var fail_value: float = 2.0 # TEMP, smth for the struggle-meter?


func choose_inputs(qte_length: int) -> void:
	rng.randomize()
	chosen_dirs.resize(qte_length)
	for n in qte_length:
		chosen_dirs[n] = rng.randi_range(0, 3) # see above enum
	timer.start(time)
	input_label.show()
	time_label.show()


func make_display_text() -> String:
	var retstr: String = ""
	for n in chosen_dirs.size():
		retstr += text_dirs[chosen_dirs[n]]
		retstr += " "
	return retstr


func player_fail() -> void:
	# idk pause the timer, restart the qte, etc.
	# smth with a struggle meter?
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if timer.time_left == 0:
		return
	
	if chosen_dirs.size() == 0:
		timer.stop()
		input_label.hide()
		time_label.hide()
		end_qte.emit(true)
		return
	
	input_label.text = make_display_text()
	time_label.text = str(timer.time_left).pad_decimals(2)
	match chosen_dirs[0]:
		Directions.LEFT:
			if Input.is_action_just_pressed("left"):
				chosen_dirs.pop_front()
		Directions.RIGHT:
			if Input.is_action_just_pressed("right"):
				chosen_dirs.pop_front()
		Directions.UP:
			if Input.is_action_just_pressed("up"):
				chosen_dirs.pop_front()
		Directions.DOWN:
			if Input.is_action_just_pressed("down"):
				chosen_dirs.pop_front()


func _on_timer_timeout() -> void:
	end_qte.emit(false)
	input_label.hide()
	time_label.hide()
