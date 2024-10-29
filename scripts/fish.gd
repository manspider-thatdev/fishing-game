extends Area2D
class_name Fish

enum FishStates {ROAM, SEEK, HOOK, FLEE}
var fish_state: FishStates = FishStates.ROAM

class FishData: # for instantiation
	var is_immortal: bool = false
	var lifespan: float = 60.0
	var time_until_move: float = 3.0
	var move_speed: float = 40.0
	var flee_wait: float = time_until_move
	var texture2D: Texture2D = preload("res://assets/2d/placeholder fish/FishRed.png")

var fish_data: FishData
var rng := RandomNumberGenerator.new()

@onready var screensize: Vector2 = get_viewport().get_visible_rect().size
@onready var life_timer: Timer = $Timers/Lifespan
@onready var move_timer: Timer = $Timers/Movement
@onready var flee_timer: Timer = $Timers/Fleeing
@onready var idle_target: Node2D = $TargetPos # typed as Node2D to allow swapping for bobber later
@onready var sprite: Sprite2D = $Sprite2D
@onready var current_target: Node2D = idle_target
var target_position:
	get():
		return current_target.position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.texture = fish_data.texture2D
	new_target()
	move_timer.start(fish_data.time_until_move)
	if fish_data.is_immortal == false:
		life_timer.start(fish_data.lifespan)

# Sets the values of the fish instance. Update the FishData class above for more needed parameters
func set_values(new_position: Vector2, new_data: FishData = FishData.new()):
	fish_data.is_immortal = new_data.is_immortal
	fish_data.lifespan = new_data.lifespan
	fish_data.time_until_move = new_data.time_until_move
	fish_data.move_speed = new_data.move_speed
	position = new_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if life_timer.time_left == 0 and !is_immortal:
		if fish_state != FishStates.SEEK && fish_state != FishStates.HOOK:
			queue_free()

func set_target(pos: Vector2) -> void:
	idle_target.position = pos

func new_target() -> void:
	var direction := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1))
	var potential := time_until_move * move_speed
	var magnitude := rng.randf_range(0, potential) # adds variety by not always going max-distance
	var t_pos := direction * magnitude
	# Out-of-bounds Checking/Handling
	t_pos = t_pos.clamp(Vector2.ZERO, screensize)
	idle_target.position = t_pos


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
	if fish_data.is_immortal:
		life_timer.start(fish_data.lifespan)
	elif fish_state != FishStates.SEEK && fish_state != FishStates.HOOK:
		queue_free()


func _on_move_timeout() -> void:
	new_target()
	print("Fish wants to move to:")
	print(current_target.position)

func _on_fleeing_timeout() -> void:
	new_target()
	fish_state = FishStates.ROAM
	current_target = idle_target

# Future Signals Probably
func _on_catch() -> void: # When entering nearest bobber range and biting
	fish_state = FishStates.HOOK

func _on_bobber_move(bobber: Node2D, isScared: bool) -> void: # Check for Interest or Startle
	current_target = bobber
	if !isScared:
		fish_state = FishStates.SEEK
	elif isScared:
		fish_state = FishStates.FLEE
		flee_timer.start(fish_data.flee_wait)
