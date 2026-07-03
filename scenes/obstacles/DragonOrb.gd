extends "res://scenes/obstacles/Obstacle.gd"

var anim_time: float = 0.0

func _ready() -> void:
	obstacle_type = "orb"

func scroll_update(delta: float, scroll_speed: float) -> void:
	anim_time += delta
	position.y += scroll_speed * delta
	if position.y > 850.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var pulse = 16.0 + sin(anim_time * 6.0) * 4.0
	draw_circle(Vector2.ZERO, pulse + 6.0, Color(1.0, 0.8, 0.2, 0.3))
	draw_circle(Vector2.ZERO, pulse, Color(1.0, 0.85, 0.2))
	draw_circle(Vector2(-4, -4), pulse * 0.4, Color(1.0, 1.0, 0.8))
