extends Node2D

var rng := RandomNumberGenerator.new()

signal end_qte(is_success: bool)

@onready var timer := $Timer
@onready var input_label := $Labels/Inputs
@onready var time_label := $Labels/Time

enum Directions {LEFT, UP, RIGHT, DOWN}
# WARNING: If you change the String char-order pls update above enum
var text_dirs: String = "🡰🡱🡲🡳"
var chosen_dirs: Array[int] = [] # empty array to add RNG inputs

@export var input_num: int = 4 # number of required inputs
@export var time: float = 5.0
# @export var fail_value: float = 2.0 # TEMP, smth for the struggle-meter?

var prior_event: InputEvent = null


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
	chosen_dirs.push_back(rng.randi_range(0, 3))
	input_label.text = make_display_text()


func _input(event: InputEvent) -> void:
	if timer.time_left == 0: return
	var inputs = {
		"LEFT": event.is_action_pressed("left"),
		"RIGHT": event.is_action_pressed("right"),
		"UP": event.is_action_pressed("up"),
		"DOWN": event.is_action_pressed("down"),
	}
	
	if inputs.values().all(func(is_pressed): return !is_pressed):
		prior_event = null
		return
	
	match chosen_dirs[0]:
		Directions.LEFT:
			if inputs["LEFT"]:
				chosen_dirs.pop_front()
				prior_event = event
		Directions.RIGHT:
			if inputs["RIGHT"]:
				chosen_dirs.pop_front()
				prior_event = event
		Directions.UP:
			if inputs["UP"]:
				chosen_dirs.pop_front()
				prior_event = event
		Directions.DOWN:
			if inputs["DOWN"]:
				chosen_dirs.pop_front()
				prior_event = event
	
	if event.is_match(prior_event, true):
		return
	
	prior_event = event
	player_fail() # add more inputs on fail


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
	time_label.value = timer.time_left / time * 100


func _on_timer_timeout() -> void:
	end_qte.emit(false)
	input_label.hide()
	time_label.hide()
	timer.stop()
