extends Area2D

var rng := RandomNumberGenerator.new()

@onready var screensize: Vector2 = get_viewport().get_visible_rect().size
@onready var life_timer: Timer = $Timers/LifeTimer
@onready var move_timer: Timer = $Timers/MoveTimer
@onready var flee_timer: Timer = $Timers/FleeTimer
@onready var idle_target: Node2D = $TargetPos # typed as Node2D to allow swapping for bobber later
@onready var sprite: Sprite2D = $Sprite2D
@onready var current_target: Node2D = idle_target
var target_position:
	get():
		return current_target.position

enum FishStates {ROAM, SEEK, HOOK, FLEE}
var fish_state: FishStates = FishStates.ROAM:
	set(value):
		print("Fsh is: " + FishStates.find_key(value))
		fish_state = value

@export var is_immortal: bool = false
@export var lifespan: float = 60.0
@export var time_until_move: float = 3.0
@export var move_speed: float = 40.0
@export var flee_wait: float = time_until_move

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_target()


func set_target(pos: Vector2) -> void:
	idle_target.position = pos


func new_target() -> void:
	var direction := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1))
	var potential := time_until_move * move_speed
	var magnitude := rng.randf_range(0, potential) # adds variety by not always going max-distance
	var t_pos := direction * magnitude
	# Out-of-bounds Checking/Handling
	#t_pos = t_pos.clamp(Vector2.ZERO, screensize)
	idle_target.position = t_pos + position

func start_timers() -> void:
	move_timer.start(time_until_move)
	life_timer.start(lifespan)

func _physics_process(delta: float) -> void:
	match fish_state:
		FishStates.HOOK: # Presumably do nothing while QTEs go off
			pass
		FishStates.ROAM:
			position = position.move_toward(target_position, move_speed * delta)
		FishStates.SEEK: # Pursuing the bobber actively
			position = position.move_toward(target_position, move_speed * delta)
		FishStates.FLEE: # When startled, possibly tied to a signal from the bobber?
			position = position.move_toward(target_position, -move_speed * delta)


func _on_lifespan_timeout() -> void:
	if is_immortal:
		return
	elif fish_state != FishStates.SEEK && fish_state != FishStates.HOOK:
		queue_free()


func _on_move_timeout() -> void:
	new_target()


func _on_fleeing_timeout() -> void:
	new_target()
	fish_state = FishStates.ROAM
	current_target = idle_target


func _on_bobber_move(bobber: Node2D, isScared: bool) -> void: # Check for Interest or Startle
	current_target = bobber
	if !isScared:
		fish_state = FishStates.SEEK
	elif isScared:
		fish_state = FishStates.FLEE
		flee_timer.start(flee_wait)


func attract(bobber) -> void:
	fish_state = FishStates.SEEK
	current_target = bobber


func _on_area_entered(area: Area2D) -> void: # When entering nearest bobber range and biting
	fish_state = FishStates.HOOK
	life_timer.stop()
	await get_tree().physics_frame
	reparent(area)
