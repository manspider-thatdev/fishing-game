extends Node2D

@onready var time_since_last_check = 0;
@onready var fish = preload("res://scenes/fish.tscn")
@onready var random = RandomNumberGenerator.new()
@onready var screen_size: Vector2 = get_viewport().get_visible_rect().size

# Potentially unnecessary since get_child_count() exists.
#@onready var fish_count = 0

const FISH_CAP = 5
const TIME_BETWEEN_CHECKS = 0.05

@onready var generic_red_fish = load("res://assets/2d/placeholder fish/FishRed.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	random.randomize()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_since_last_check += delta
	# Check if fish cap has been met each interval.
	if(time_since_last_check >= TIME_BETWEEN_CHECKS):
		time_since_last_check = 0
		if(get_child_count() < FISH_CAP):
			spawn_fish()

# Spawns a fish at a random location.
func spawn_fish():
	var new_fish = fish.instantiate()
	add_child(new_fish)
	new_fish.lifespan = 5
	new_fish.time_until_move = 3
	new_fish.move_speed = 40
	new_fish.position = Vector2(random.randf_range(0, screen_size.x), random.randf_range(0, screen_size.y))
	new_fish.rotation = random.randf_range(0, 360)
	new_fish.sprite.set_texture(generic_red_fish)
	new_fish.is_immortal = false
	new_fish.start_timers()
