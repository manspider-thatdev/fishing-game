extends Area2D
class_name Fish

enum FishStates {ROAM, SEEK, HOOK, FLEE}
var fish_state: FishStates = FishStates.ROAM:
	set(value):
		sprite.texture = fish_data.texture2D
		if fish_state != FishStates.HOOK:
			fish_state = value
		if fish_state == FishStates.FLEE:
			sprite.texture = preload("res://assets/2d/fish/FishShadow.png")
var fish_data: FishData = FishData.new() # see: fish_data.gd, usually should change w/ set_values() below

var rng := RandomNumberGenerator.new()

var swimming_rect: Rect2
@onready var life_timer: Timer = $Timers/LifeTimer
@onready var move_timer: Timer = $Timers/MoveTimer
@onready var flee_timer: Timer = $Timers/FleeTimer
@onready var idle_target: Node2D = $TargetPos # typed as Node2D to allow swapping for bobber later
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var current_target: Node2D = idle_target
var target_position:
	get():
		sprite.flip_h = true if (current_target.position - position).x < 0 else false
		if fish_state == FishStates.FLEE:
			sprite.flip_h = !sprite.flip_h
		return current_target.position
var is_immortal: bool = false


# Update the FishData class in fish_data.gd to add more parameters
func set_values(start_position: Vector2, data: FishData, swimming_area: Rect2):
	fish_data = data
	position = start_position
	swimming_rect = swimming_area


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(fish_data, "[fish_data] is null.")
	sprite.texture = fish_data.texture2D
	new_idle_target()
	move_timer.start(fish_data.time_until_move)
	if is_immortal == false:
		life_timer.start(fish_data.lifespan)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	match fish_state:
		FishStates.HOOK:
			anim_player.play("ROAM", -1, 4)
		FishStates.ROAM:
			if life_timer.time_left == 0 and !is_immortal:
				queue_free()
			anim_player.play("ROAM")
		FishStates.SEEK:
			anim_player.play("ROAM", -1, 1.25)
			if !current_target.monitoring:
				fish_state = FishStates.ROAM
				start_timers()
				current_target = new_idle_target()
		FishStates.FLEE:
			if life_timer.time_left == 0 and !is_immortal:
				queue_free()
			anim_player.play("ROAM", -1, 2)


func set_target(pos: Vector2) -> void:
	idle_target.position = pos


func new_idle_target() -> Node2D:
	var direction := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1))
	var potential := fish_data.time_until_move * fish_data.move_speed
	var magnitude := rng.randf_range(0, potential) # adds variety by not always going max-distance
	var t_pos := direction * magnitude
	# Out-of-bounds Checking/Handling
	t_pos = t_pos.clamp(swimming_rect.position, swimming_rect.end)
	idle_target.position = t_pos + position
	return idle_target


func start_timers() -> void:
	move_timer.start(fish_data.time_until_move)
	life_timer.start(fish_data.lifespan)


func _physics_process(delta: float) -> void:
	match fish_state:
		FishStates.HOOK: # Presumably do nothing while QTEs go off
			pass
		FishStates.ROAM:
			position = position.move_toward(target_position, fish_data.move_speed * delta)
		FishStates.SEEK: # Pursuing the bobber actively, see _on_bobber_move() below
			position = position.move_toward(target_position, fish_data.move_speed * delta)
		FishStates.FLEE: # When startled, see _on_bobber_move() below
			position = position.move_toward(target_position, -fish_data.move_speed * delta)


func _on_lifespan_timeout() -> void:
	if !is_immortal and fish_state != FishStates.SEEK and fish_state != FishStates.HOOK:
		queue_free()


func _on_move_timeout() -> void:
	new_idle_target()


func _on_fleeing_timeout() -> void:
	current_target = new_idle_target()
	fish_state = FishStates.ROAM
	move_timer.paused = false


func _on_bobber_move(bobber: Node2D, isScared: bool) -> void: # Check for Interest or Startle
	if fish_state == FishStates.HOOK:
		return
	current_target = bobber
	if !isScared:
		fish_state = FishStates.SEEK
	elif isScared:
		fish_state = FishStates.FLEE
		move_timer.paused = true
		flee_timer.start(fish_data.flee_wait)


func attract(bobber) -> void:
	fish_state = FishStates.SEEK
	current_target = bobber


func _on_area_entered(area: Area2D) -> void: # When entering nearest bobber range and biting
	fish_state = FishStates.HOOK
	life_timer.stop()
	flee_timer.stop()
	move_timer.stop()
	is_immortal = true
	await get_tree().physics_frame
	reparent(area)
	sprite.flip_h = false
	rotation_degrees = 90
