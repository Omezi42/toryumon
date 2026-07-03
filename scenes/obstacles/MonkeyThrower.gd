extends "res://scenes/obstacles/Obstacle.gd"

var is_from_left: bool = true
var alert_timer: float = 1.0
var rock_x: float = 0.0
var rock_speed_x: float = 400.0

func _ready() -> void:
	obstacle_type = "monkey_rock"
	is_from_left = (lane < 0) or (randf() > 0.5 if lane == 0 else false)
	if is_from_left:
		position.x = 420.0
		rock_speed_x = 450.0
	else:
		position.x = 860.0
		rock_speed_x = -450.0
	rock_x = 0.0

func scroll_update(delta: float, scroll_speed: float) -> void:
	position.y += scroll_speed * delta
	if alert_timer > 0.0:
		alert_timer -= delta
	else:
		rock_x += rock_speed_x * delta
		
	if position.y > 850.0 or abs(rock_x) > 600.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	# Draw Monkey on cliff at (0,0)
	draw_circle(Vector2.ZERO, 20.0, Color(0.55, 0.35, 0.15)) # Body
	draw_circle(Vector2(0, -15), 14.0, Color(0.65, 0.45, 0.25)) # Head
	draw_circle(Vector2(-12, -18), 6.0, Color(0.8, 0.6, 0.4)) # Left ear
	draw_circle(Vector2(12, -18), 6.0, Color(0.8, 0.6, 0.4)) # Right ear
	
	if alert_timer > 0.0:
		# Flashing alert arrow sign !
		if int(alert_timer * 10.0) % 2 == 0:
			var dir = 1.0 if is_from_left else -1.0
			draw_string(ThemeDB.fallback_font, Vector2(dir * 35.0, -5.0), "⚠️ 落石注意!", HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color.YELLOW)
			draw_line(Vector2(dir * 25.0, 0), Vector2(dir * 60.0, 0), Color.RED, 4.0)
	else:
		# Draw rolling rock at rock_x
		draw_circle(Vector2(rock_x, 0), 22.0, Color(0.5, 0.48, 0.45))
		draw_circle(Vector2(rock_x - 5, -5), 6.0, Color(0.6, 0.58, 0.55))
		
		# Update collision shape offset to match rolling rock
		$CollisionShape2D.position = Vector2(rock_x, 0)
