extends Area2D

enum State { 
	WINDING, 
	CASTING, 
	REELING, 
	NUDGING, 
	CATCHING,
}

@onready var timer: Timer = $Timer
@onready var cast_bar: ProgressBar = $CastBar
@onready var score_label: Label = $ScoreLabel
@onready var near_bobber: Area2D = $NearBobber
@onready var far_bobber: Area2D = $FarBobber
@onready var qte_event: Node2D = $QteEvent
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var line: Line2D = $Line2D
# SFX
@onready var windup_sfx_player: AudioStreamPlayer = $SFX/WindupPlayer
@onready var landing_sfx_player: AudioStreamPlayer = $SFX/LandingPlayer
@onready var cast_sfx_player: AudioStreamPlayer = $SFX/CastPlayer
@onready var catch_sfx_player: AudioStreamPlayer = $SFX/CatchPlayer
@onready var reel_sfx_player: AudioStreamPlayer = $SFX/ReelPlayer
@onready var struggle_sfx_player: AudioStreamPlayer = $SFX/StrugglePlayer
@onready var qtereel_sfx_player: AudioStreamPlayer = $SFX/StruggleReelPlayer
@onready var winqte_sfx_player: AudioStreamPlayer = $SFX/QTEWinPlayer
@onready var loseqte_sfx_player: AudioStreamPlayer = $SFX/QTELosePlayer

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

@export_group("Animated Variables (Don't Touch)")
@export var fish_position := Vector2.ZERO

signal win_fish(fishdata: FishData)
signal lose_fish(fishdata: FishData)
signal qte_signal_repeater(is_success: bool)

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
var fish: Fish = null
var fish_data: FishData = null
var qte_tween: Tween = null
var temporary_pause := false


func windup(_delta: float) -> void:
	if Input.is_action_just_pressed("space"):
		timer.start(cast_time)
		predicted_cast = 0
		cast_bar.show()
		windup_sfx_player.play()
	elif Input.is_action_just_released("space"):
		timer.stop()
		state = State.CASTING
		anim_player.play("AIR")
		cast_bar.hide()
		windup_sfx_player.stop()
		cast_sfx_player.play()
	elif Input.is_action_pressed("space"):
		predicted_cast = pingpong(timer.time_left / (cast_time * 0.5), 1.0) * max_cast_distance
		cast_bar.value = predicted_cast


func cast(_delta: float) -> void:
	if Input.is_action_just_pressed("space"):
		state = State.REELING
		anim_player.play("IDLE")
		landing_sfx_player.play()
	
	var sway: float = Input.get_axis("left", "right")
	velocity = Vector2(cast_speed.x * sway, -cast_speed.y)
	
	if absf(position.y) >= predicted_cast:
		position.y = -predicted_cast
		state = State.REELING
		anim_player.play("IDLE")
		landing_sfx_player.play()


func reel(_delta: float) -> void:
	reel_sfx_player.stream_paused = true
	velocity = Input.get_vector("left", "right", "up", "down") * nudge_speed
	if velocity != Vector2.ZERO:
		state = State.NUDGING
		check_fish_nudge()
		play_nudge_animation(velocity)
	
	if Input.is_action_pressed("space"):
		velocity = -position.normalized() * reel_speed
		reel_sfx_player.stream_paused = false
		if not reel_sfx_player.playing: reel_sfx_player.play()
	elif Input.is_action_just_released("space"):
		reel_sfx_player.stream_paused = true
		if position.y >= 0:
			state = State.WINDING
			anim_player.play("REST")
			predicted_cast = -1
			reel_sfx_player.stop()


func nudge(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, delta * nudge_friction)
	if velocity == Vector2.ZERO or Input.is_action_pressed("space"):
		state = State.REELING
		anim_player.play("IDLE")


func check_fish_nudge() -> void:
	var near_fish: Array[Area2D] = near_bobber.get_overlapping_areas()
	for spotted_fish: Area2D in far_bobber.get_overlapping_areas():
		spotted_fish._on_bobber_move(self, near_fish.has(spotted_fish))


func play_nudge_animation(direction: Vector2) -> void:
	if direction.x > 0:
		anim_player.play("RIGHT")
	elif direction.x < 0:
		anim_player.play("LEFT")
	elif direction.y > 0:
		anim_player.play("DOWN")
	else:
		anim_player.play("UP")
	await anim_player.animation_finished
	print(anim_player.current_animation)


func catch(_delta: float) -> void:
	reel_sfx_player.stop()
	if position.y >= 0:
		position = Vector2.ZERO
		velocity = Vector2.ZERO
		if qte_tween != null:
			qte_tween.kill()
		state = State.WINDING
		anim_player.play("REST")
		struggle_sfx_player.stop()
		qtereel_sfx_player.stop()
		catch_sfx_player.play()
		win_fish.emit(fish.fish_data)
		fish.queue_free()
		fish = null
	elif (fish == null or !is_ancestor_of(fish)) and temporary_pause:
		fish = null
		velocity = Vector2.ZERO
		if qte_tween != null:
			qte_tween.kill()
		state = State.REELING
		anim_player.play("IDLE")
		struggle_sfx_player.stop()
		qtereel_sfx_player.stop()
	
	if fish != null:
		fish.position = fish_position
		temporary_pause = false
		if not struggle_sfx_player.playing: struggle_sfx_player.play()
		if not qtereel_sfx_player.playing: qtereel_sfx_player.play()


func _ready() -> void:
	Globals.connect_bobber(self)
	cast_bar.max_value = max_cast_distance


func _process(delta: float) -> void:
	line.points[0] = -position
	match state:
		State.WINDING: windup(delta)
		State.CASTING: cast(delta)
		State.REELING: reel(delta)
		State.NUDGING: nudge(delta)
		State.CATCHING: catch(delta)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	
	position = position.clamp(Vector2(-max_extents, -max_cast_distance), Vector2(max_extents, 0.0))
	
	if velocity != Vector2.ZERO:
		if state == State.REELING and far_bobber.monitoring:
			await get_tree().physics_frame
			for spotted_fish: Area2D in far_bobber.get_overlapping_areas():
				if not overlaps_area(spotted_fish):
					spotted_fish._on_bobber_move(self, true)


func _on_bobber_range_area_entered(area: Area2D) -> void:
	area.attract(self)


func _on_area_entered(reel_fish: Area2D) -> void:
	state = State.CATCHING
	velocity = position.normalized() * drag_speed
	fish = reel_fish
	fish_data = fish.fish_data
	qte_event.choose_inputs(fish.fish_data.qte_size, fish.fish_data.qte_time)
	anim_player.play("REEL")
	temporary_pause = true


func _on_qte_event_end_qte(is_success: bool) -> void:
	qte_signal_repeater.emit(is_success)
	if is_success:
		winqte_sfx_player.play()
		qte_tween = get_tree().create_tween().set_trans(Tween.TRANS_EXPO)
		velocity = -position.normalized() * catch_speed
		qte_tween.tween_property(self, "velocity", position.normalized() * drag_speed, burst_time)
		await qte_tween.finished
		if state == State.CATCHING:
			qte_event.choose_inputs(fish.fish_data.qte_size, fish.fish_data.qte_time)
		else:
			velocity = Vector2.ZERO
	else:
		lose_fish.emit(fish_data)
		fish.queue_free()
		fish = null
		state = State.REELING
		anim_player.play("IDLE")
		struggle_sfx_player.stop()
		qtereel_sfx_player.stop()
		loseqte_sfx_player.play()


func _on_score_changes(score: int) -> void:
	score_label.text = "Score: " + str(score)
