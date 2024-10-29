extends Node

var rng := RandomNumberGenerator.new()
var fish_scene = preload("res://scenes/fish.tscn")

@onready var time_since_last_check = 0;
@onready var screen_size: Vector2 = get_viewport().get_visible_rect().size

# Potentially unnecessary since get_child_count() exists.
#@onready var fish_count = 0

const FISH_CAP = 5
const TIME_BETWEEN_CHECKS = 0.05

# @onready var generic_red_fish = load("res://assets/2d/placeholder fish/FishRed.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rng.randomize()


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
	var new_fish = fish_scene.instantiate()
	new_fish.screensize = 0
	add_child(new_fish)
	var initial_position: Vector2 = Vector2(random.randf_range(0, screen_size.x), random.randf_range(0, screen_size.y))
	new_fish.set_initial_values(false, 60, 3, 40, initial_position, generic_red_fish)
