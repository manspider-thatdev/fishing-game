extends CharacterBody2D

enum State { WINDUP, CAST, REEL }

@onready var timer: Timer = $Timer
@onready var label: Label = $Label

@export var cast_speed: float = 50.0
@export var max_cast_distance: float = 250.0
@export var cast_time: float = 2.0

var state := State.WINDUP
var predicted_cast: float = 0.0: 
	set(value):
		predicted_cast = value
		label.text = "Predicted Cast: " + str(snappedf(value, 0.1))


func windup(event: InputEvent) -> void:
	if event.is_action_pressed("space"):
		timer.start(cast_time)
		predicted_cast = 0
	
	elif event.is_action_released("space"):
		timer.stop()
		print(predicted_cast)
		state = State.CAST
	
	elif event.is_action("space"):
		predicted_cast = pingpong(timer.time_left / (cast_time * 0.5), 1.0) * max_cast_distance


func cast(event: InputEvent) -> void:
	pass


func reel(event: InputEvent) -> void:
	pass


func _physics_process(delta: float) -> void:
	if not state == State.CAST:
		return
	
	position.y = minf(position.y + (cast_speed * delta), predicted_cast)
	label.text = "Current Depth: " + str(snappedf(position.y, 0.1))


func _input(event: InputEvent) -> void:
	if state == State.WINDUP:
		windup(event)
	elif state == State.CAST:
		cast(event)
