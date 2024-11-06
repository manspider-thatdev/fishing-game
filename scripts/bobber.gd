extends Area2D

enum State { 
	WINDING, 
	CASTING, 
	REELING, 
	NUDGING, 
	CATCHING,
}

@onready var timer: Timer = $Timer
@onready var label: Label = $Label
@onready var near_bobber: Area2D = $NearBobber
@onready var far_bobber: Area2D = $FarBobber
@onready var qte_event: Node2D = $QteEvent

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

@export_group("Catching")
@export var catch_speed: float = 50.0
@export var drag_speed: float = 5.0
@export var burst_time: float = 1.5

var velocity := Vector2.ZERO
var state := State.WINDING:
	set(value):
		state = value
		await get_tree().physics_frame
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
var fish: Fish = null


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
		check_fish_nudge()
	
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
	
	label.text = "Current Depth: " + str(position.snapped(Vector2.ONE * 0.01))


func check_fish_nudge() -> void:
	var near_fish: Array[Area2D] = near_bobber.get_overlapping_areas()
	for spotted_fish: Area2D in far_bobber.get_overlapping_areas():
		spotted_fish._on_bobber_move(self, near_fish.has(spotted_fish))


func catch(_delta: float) -> void:
	if position.y >= 0:
		position = Vector2.ZERO
		state = State.WINDING
		print("caught fish")
		fish = null
	elif fish == null or !is_ancestor_of(fish):
		fish = null
		state = State.REELING
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
	elif state == State.CATCHING:
		catch(delta)
	
	if Input.is_physical_key_pressed(KEY_K):
		print(get_overlapping_areas())


func _physics_process(delta: float) -> void:
	position += velocity * delta
	
	position = position.clamp(Vector2(-max_extents, -max_cast_distance), Vector2(max_extents, 0.0))
	
	if velocity != Vector2.ZERO:
		if state == State.REELING and far_bobber.monitoring:
			await get_tree().physics_frame
			for spotted_fish: Area2D in far_bobber.get_overlapping_areas():
				spotted_fish._on_bobber_move(self, true)


func _on_bobber_range_area_entered(area: Area2D) -> void:
	area.attract(self)


func _on_area_entered(reel_fish: Area2D) -> void:
	state = State.CATCHING
	velocity = position.normalized() * drag_speed
	fish = reel_fish
	qte_event.choose_inputs(fish.fish_data.qte_size)


func _on_qte_event_end_qte(is_success: bool) -> void:
	if is_success:
		var tween = get_tree().create_tween().set_trans(Tween.TRANS_EXPO)
		velocity = -position.normalized() * catch_speed
		tween.tween_property(self, "velocity", position.normalized() * drag_speed, burst_time)
		await tween.finished
		if state == State.CATCHING:
			qte_event.choose_inputs(fish.fish_data.qte_size)
