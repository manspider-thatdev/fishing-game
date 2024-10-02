extends Area2D

var rng := RandomNumberGenerator.new()

@onready var screensize: Vector2 = get_viewport().get_visible_rect().size
@onready var life_timer: Timer = $Timers/Lifespan
@onready var move_timer: Timer = $Timers/Movement
@onready var flee_timer: Timer = $Timers/Fleeing
@onready var move_target: Node2D = $TargetPos # typed as Node2D to allow swapping for bobber later

enum FishStates {ROAM, SEEK, HOOK, FLEE}
var fish_state: FishStates = FishStates.ROAM

@export var immortal: bool = false
@export var lifespan: float = 60.0
@export var move_wait: float = 3.0
@export var move_speed: float = 40.0
@export var flee_wait: float = move_wait

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_target()
	move_timer.start(move_wait)
	if !immortal:
		life_timer.start(lifespan)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if life_timer.time_left == 0:
		if fish_state != FishStates.SEEK && fish_state != FishStates.HOOK:
			queue_free()

func set_target(pos: Vector2) -> void:
	move_target.position = pos
	
func new_target() -> void:
	var direction := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1))
	var potential := move_wait * move_speed
	var magnitude := rng.randf_range(0, potential) # adds variety by not always going max-distance
	var tPos := direction * magnitude
	# Out-of-bounds Checking/Handling
	tPos.x *= -1 if (tPos.x < 0) else 1
	tPos.y *= -1 if (tPos.y < 0) else 1
	tPos.x = clampf(tPos.x, 0, screensize.x)
	tPos.y = clampf(tPos.y, 0, screensize.y)
	set_target(tPos)

func _physics_process(delta: float) -> void:
	match fish_state:
		FishStates.HOOK: # Presumably do nothing while QTEs go off
			pass
		FishStates.ROAM:
			var speed := delta * move_speed
			position.x = move_toward(position.x, move_target.position.x, speed)
			position.y = move_toward(position.y, move_target.position.y, speed)
		FishStates.SEEK: # Pursuing the bobber actively
			pass
		FishStates.FLEE: # When startled, possibly tied to a signal from the bobber?
			pass

func _on_lifespan_t_timeout() -> void:
	if immortal:
		life_timer.start(lifespan)
	elif fish_state != FishStates.SEEK && fish_state != FishStates.HOOK:
		queue_free()

func _on_move_t_timeout() -> void:
	new_target()
	print("Fish wants to move to:")
	print(move_target.position)
	
func _on_fleeing_timeout() -> void:
	new_target()
	fish_state = FishStates.ROAM

# Future Signals Probably
func _on_catch() -> void: # When entering nearest bobber range and biting
	fish_state = FishStates.HOOK
func _on_bobber_move() -> void: # Check for Interest or Startle
	if false:
		fish_state = FishStates.SEEK
	elif true:
		fish_state = FishStates.FLEE
		flee_timer.start(flee_wait)
