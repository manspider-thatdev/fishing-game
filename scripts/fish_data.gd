extends Resource
class_name FishData

@export var is_immortal: bool = false
@export var lifespan: float = 60.0
@export var time_until_move: float = 3.0
@export var move_speed: float = 40.0
@export var flee_wait: float = time_until_move
@export var texture2D: Texture2D = preload("res://assets/2d/fish/FishRed.png")
@export var anim_frames: int = 2