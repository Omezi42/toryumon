extends "res://scenes/obstacles/Obstacle.gd"

var anim_time: float = 0.0
var sway_amp: float = 70.0
var base_x: float = 0.0

func _ready() -> void:
	obstacle_type = "hook"
	base_x = position.x

func scroll_update(delta: float, scroll_speed: float) -> void:
	anim_time += delta
	position.y += scroll_speed * delta
	position.x = base_x + sin(anim_time * 6.2) * sway_amp + cos(anim_time * 3.1) * (sway_amp * 0.35)
	if position.y > 850.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	# Fishing line from top edge
	draw_line(Vector2(0, -position.y), Vector2(0, -10), Color(0.9, 0.9, 0.9, 0.6), 1.5)
	# Metallic sharp hook
	draw_arc(Vector2(0, 4), 12.0, 0.0, PI * 1.2, 16, Color(0.8, 0.85, 0.9), 3.0)
	draw_circle(Vector2(11, -1), 3.0, Color(0.9, 0.2, 0.2)) # Barb / bait
