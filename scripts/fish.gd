extends Area2D

@onready var life_timer: Timer = $Sprite2D/LifespanT
@export var lifespan: float = 10.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	life_timer.start(lifespan)
	print(lifespan)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_lifespan_t_timeout() -> void:
	queue_free()
	print("Fish go bye-bye!")
