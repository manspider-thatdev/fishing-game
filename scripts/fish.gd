extends Area2D

var rng := RandomNumberGenerator.new()

@onready var screensize: Vector2 = get_viewport().get_visible_rect().size
@onready var life_timer: Timer = $Timers/Lifespan
@onready var move_timer: Timer = $Timers/Movement
@onready var move_target: Marker2D = $TargetPos

@export var lifespan: float = 30.0
@export var move_wait: float = 4.0
@export var move_speed: float = 40.0
var moving: bool = false
# probably need to set-up a mini state-machine
# to differentiate between setting random targets for wandering
# and when the fish is interested in the bobber

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	move_target.position.x = rng.randf_range(0.0, screensize.x)
	move_target.position.y = rng.randf_range(0.0, screensize.y)
	life_timer.start(lifespan)
	move_timer.start(move_wait)
	print(lifespan)
	print(move_wait)
	print(screensize)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	var velocity := delta * move_speed
	position.x = move_toward(position.x, move_target.position.x, velocity)
	position.y = move_toward(position.y, move_target.position.y, velocity)
	pass

func _on_lifespan_t_timeout() -> void:
	queue_free()
	print("Fish says bye-bye!")

# probably better to eventually change this to a circular area
# around the fish so it seems more natural, instead of just
# targeting random points on the entire screen lol
func _on_move_t_timeout() -> void:
	move_target.position.x = rng.randf_range(0.0, screensize.x)
	move_target.position.y = rng.randf_range(0.0, screensize.y)
	print("Fish wants to move to:")
	print(move_target.position)
