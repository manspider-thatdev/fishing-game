extends Area2D
class_name Fish

enum FishStates {ROAM, SEEK, HOOK, FLEE}
var fish_state: FishStates = FishStates.ROAM
var fish_data: FishData = FishData.new() # see: fish_data.gd, usually should change w/ set_values() below
var rng := RandomNumberGenerator.new()

@onready var screensize: Vector2 = get_viewport().size
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var life_timer: Timer = $Timers/Lifespan
@onready var move_timer: Timer = $Timers/Movement
@onready var flee_timer: Timer = $Timers/Fleeing
@onready var idle_target: Node2D = $TargetPos
@onready var current_target: Node2D = idle_target # typed as Node2D to allow swapping for bobber
var target_position:
	get():
		sprite.flip_h = true if (current_target.position - position).x < 0 else false
		return current_target.position

# Update the FishData class in fish_data.gd to add more parameters
func set_values(start_position: Vector2, data: FishData):
	fish_data = data
	position = start_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(fish_data, "[fish_data] is null.")
	sprite.texture = fish_data.texture2D
	new_idle_target()
	move_timer.start(fish_data.time_until_move)
	if fish_data.is_immortal == false:
		life_timer.start(fish_data.lifespan)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match fish_state:
		FishStates.HOOK:
			anim_player.play("ROAM", -1, 4)
		FishStates.ROAM:
			if life_timer.time_left == 0 and !fish_data.is_immortal:
				queue_free()
			anim_player.play("ROAM")
		FishStates.SEEK:
			anim_player.play("ROAM", -1, 1.25)
		FishStates.FLEE:
			if life_timer.time_left == 0 and !fish_data.is_immortal:
				queue_free()
			anim_player.play("ROAM", -1, 2)

func new_idle_target() -> Node2D:
	var direction := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1))
	var potential := fish_data.time_until_move * fish_data.move_speed
	var magnitude := rng.randf_range(0, potential) # adds variety by not always going max-distance
	var t_pos := direction * magnitude
	# Out-of-bounds Checking/Handling
	t_pos = t_pos.clamp(Vector2.ZERO, screensize)
	idle_target.position = t_pos
	print("Fish wants to move to: %s" % target_position)
	return idle_target

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
	if fish_data.is_immortal:
		life_timer.start(fish_data.lifespan)
	elif fish_state != FishStates.SEEK and fish_state != FishStates.HOOK:
		queue_free()

func _on_move_timeout() -> void:
	new_idle_target()

func _on_fleeing_timeout() -> void:
	current_target = new_idle_target()
	fish_state = FishStates.ROAM
	move_timer.paused = false

# Bobber Interactions
func _on_catch() -> void: # When entering nearest bobber range and biting
	fish_state = FishStates.HOOK

func _on_bobber_move(bobber: Node2D, isScared: bool) -> void: # Called by bobber.gd
	current_target = bobber
	if !isScared:
		fish_state = FishStates.SEEK
	elif isScared:
		fish_state = FishStates.FLEE
		move_timer.paused = true
		flee_timer.start(fish_data.flee_wait)
