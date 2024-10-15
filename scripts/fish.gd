extends Area2D

var rng := RandomNumberGenerator.new()

@onready var screensize: Vector2 = get_viewport().get_visible_rect().size
@onready var life_timer: Timer = $Timers/Lifespan
@onready var move_timer: Timer = $Timers/Movement
@onready var flee_timer: Timer = $Timers/Fleeing
@onready var move_target: Node2D = $TargetPos # typed as Node2D to allow swapping for bobber later
@onready var sprite: Sprite2D = $Sprite2D

enum FishStates {ROAM, SEEK, HOOK, FLEE}
var fish_state: FishStates = FishStates.ROAM

@export var is_immortal: bool = false
@export var lifespan: float = 60.0
@export var time_until_move: float = 3.0
@export var move_speed: float = 40.0
@export var flee_wait: float = time_until_move

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_target()

# Sets the values of the fish instance. Will probably need more parameters when fish gets more complicated.
func set_values(new_immortal: bool, new_lifespan: float, new_time_until_move: float, new_move_speed: float, new_position: Vector2, new_texture: Texture2D):
	is_immortal = new_immortal
	lifespan = new_lifespan
	time_until_move = new_time_until_move
	move_speed = new_move_speed
	position = new_position
	sprite.set_texture(new_texture)

# Sets the values of teh fish instance and starts its timers.
func set_initial_values(new_immortal: bool, new_lifespan: float, new_time_until_move: float, new_move_speed: float, new_position: Vector2, new_texture: Texture2D):
	set_values(new_immortal, new_immortal, new_time_until_move, new_move_speed, new_position, new_texture)
	
	move_timer.start(time_until_move)
	if !is_immortal:
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
	var potential := time_until_move * move_speed
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

func _on_lifespan_timeout() -> void:
	if is_immortal:
		life_timer.start(lifespan)
	elif fish_state != FishStates.SEEK && fish_state != FishStates.HOOK:
		queue_free()

func _on_move_timeout() -> void:
	new_target()
	print("Fish wants to move to:")
	print(move_target.position)
	
func _on_fleeing_timeout() -> void:
	new_target()
	fish_state = FishStates.ROAM

# Future Signals Probably
func _on_catch() -> void: # When entering nearest bobber range and biting
	fish_state = FishStates.HOOK
func _on_bobber_move(isScared: bool) -> void: # Check for Interest or Startle
	if !isScared:
		fish_state = FishStates.SEEK
	elif isScared:
		fish_state = FishStates.FLEE
		flee_timer.start(flee_wait)
