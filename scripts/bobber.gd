extends Area2D

enum State { 
	WINDING, 
	CASTING, 
	REELING, 
	NUDGING, 
}

@onready var timer: Timer = $Timer
@onready var label: Label = $Label
@onready var near_bobber: Area2D = $NearBobber
@onready var far_bobber: Area2D = $FarBobber

@export_group("Casting")
@export var cast_speed := Vector2(25.0, 50.0)
@export var max_cast_distance: float = 250.0
@export var max_extents: float = 30.0
@export var cast_time: float = 2.0

@export_group("Reeling")
@export var reel_speed: float = 50.0

@export_group("Nudging")
@export var nudge_speed: float = 20.0
@export var nudge_friction: float = 15.0

var velocity := Vector2.ZERO
var state := State.WINDING:
	set(value):
		state = value
		if state == State.REELING || state == State.NUDGING:
			monitoring = true
			monitorable = true
			near_bobber.monitoring = true
			near_bobber.monitorable = true
			far_bobber.monitoring = true
			far_bobber.monitorable = true
		else:
			monitoring = false
			monitorable = false
			near_bobber.monitoring = false
			near_bobber.monitorable = false
			far_bobber.monitoring = false
			far_bobber.monitorable = false
var predicted_cast: float = 0.0: 
	set(value):
		predicted_cast = snappedf(value, 0.01)
		label.text = "Predicted Cast: " + str(predicted_cast)


func windup(_delta: float) -> void:
	if Input.is_action_just_pressed("space"):
		timer.start(cast_time)
		predicted_cast = 0
	
	elif Input.is_action_just_released("space"):
		timer.stop()
		state = State.CASTING
	
	elif Input.is_action_pressed("space"):
		predicted_cast = pingpong(timer.time_left / (cast_time * 0.5), 1.0) * max_cast_distance


func cast(_delta: float) -> void:
	if Input.is_action_just_pressed("space"):
		state = State.REELING
	
	var sway: float = Input.get_axis("left", "right")
	velocity = Vector2(cast_speed.x * sway, -cast_speed.y)
	
	label.text = "Current Depth: " + str(position.snapped(Vector2.ONE * 0.01))
	
	if absf(position.y) >= predicted_cast:
		position.y = -predicted_cast
		state = State.REELING


func reel(_delta: float) -> void:
	velocity = Input.get_vector("left", "right", "up", "down") * nudge_speed
	if velocity != Vector2.ZERO:
		state = State.NUDGING
	
	if Input.is_action_pressed("space"):
		velocity = -position.normalized() * reel_speed
	elif position.y >= 0 and Input.is_action_just_released("space"):
		state = State.WINDING
		predicted_cast = -1
	
	label.text = "Current Depth: " + str(position.snapped(Vector2.ONE * 0.01))


func nudge(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, delta * nudge_friction)
	if velocity == Vector2.ZERO or Input.is_action_pressed("space"):
		state = State.REELING
	else:
		var near_fish: Array[Area2D] = near_bobber.get_overlapping_areas()
		for fish: Area2D in far_bobber.get_overlapping_areas():
			fish._on_bobber_move(near_fish.has(fish))
	
	label.text = "Current Depth: " + str(position.snapped(Vector2.ONE * 0.01))


func _process(delta: float) -> void:
	if state == State.WINDING:
		windup(delta)
	elif state == State.CASTING:
		cast(delta)
	elif state == State.REELING:
		reel(delta)
	elif state == State.NUDGING:
		nudge(delta)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	
	position = position.clamp(Vector2(-max_extents, -max_cast_distance), Vector2(max_extents, 0.0))
	
	if velocity != Vector2.ZERO:
		if state == State.REELING:
			for fish: Area2D in far_bobber.get_overlapping_areas():
				fish._on_bobber_move(true)
