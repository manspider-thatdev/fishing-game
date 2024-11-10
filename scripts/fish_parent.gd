extends Node

var rng := RandomNumberGenerator.new()
var fish_scene = preload("res://scenes/fish.tscn")
@export var FishDatas: Array[FishData] # add in editor UI

@onready var time_since_last_check = 0;

# I changed these to exports for when we make new stages - Watson
@export var spawn_area: Rect2
@export var FISH_CAP = 5
@export var TIME_BETWEEN_CHECKS = 0.05


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rng.randomize()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_since_last_check += delta
	if(time_since_last_check >= TIME_BETWEEN_CHECKS):
		time_since_last_check = 0
		if(get_child_count() < FISH_CAP):
			spawn_fish()


# Spawns a fish at a random location.
func spawn_fish():
	var new_fish = fish_scene.instantiate()
	var pos := Vector2(rng.randf_range(spawn_area.position.x, spawn_area.end.x), 
		rng.randf_range(spawn_area.position.y, spawn_area.end.y))
	new_fish.set_values(pos, FishDatas.pick_random(), spawn_area)
	add_child(new_fish)
