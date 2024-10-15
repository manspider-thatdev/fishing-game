extends Node2D

@onready var time_since_last_check = 0;
@onready var fish = preload("res://scenes/fish.tscn")
@onready var fish_count = 0

const FISH_CAP = 5
const TIME_BETWEEN_CHECKS = 0.05

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_since_last_check += delta
	# Check if fish cap has been met each interval.
	if(time_since_last_check >= TIME_BETWEEN_CHECKS):
		#spawn_fish()
		time_since_last_check = 0

#TODO: Create a function that spawns fish.
func spawn_fish():
	pass
