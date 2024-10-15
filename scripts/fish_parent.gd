extends Node2D

@onready var time_until_next_check = $NextCheck
@onready var fish = preload("res://scenes/fish.tscn")

const FISH_CAP = 5
const TIME_BETWEEN_CHECKS = 0.05

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	time_until_next_check.wait_time = TIME_BETWEEN_CHECKS


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#TODO: Create a function that spawns fish.
func spawn_fish():
	pass
