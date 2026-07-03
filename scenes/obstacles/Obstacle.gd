extends Area2D

@export var obstacle_type: String = "rock"
var lane: int = 0
var base_speed: float = 300.0

func _ready() -> void:
	pass

func get_obstacle_type() -> String:
	return obstacle_type

func scroll_update(delta: float, scroll_speed: float) -> void:
	position.y += scroll_speed * delta
	if position.y > 1400.0:
		queue_free()

func destroy() -> void:
	queue_free()
