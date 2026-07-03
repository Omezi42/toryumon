extends "res://scenes/obstacles/Obstacle.gd"

var is_from_left: bool = true
var alert_timer: float = 0.45
var banana_x: float = 0.0
var banana_y: float = 0.0
var banana_speed_x: float = 400.0
var banana_speed_y: float = 250.0
var banana_rotation: float = 0.0

func _ready() -> void:
	obstacle_type = "monkey_rock"
	is_from_left = (lane < 0) or (randf() > 0.5 if lane == 0 else false)
	if is_from_left:
		position.x = 50.0
		banana_speed_x = 420.0
	else:
		position.x = 670.0
		banana_speed_x = -420.0
	banana_speed_y = 350.0
	banana_x = 0.0
	banana_y = 0.0

func scroll_update(delta: float, scroll_speed: float) -> void:
	position.y += scroll_speed * delta
	if alert_timer > 0.0:
		alert_timer -= delta
	else:
		banana_x += banana_speed_x * delta
		banana_y += banana_speed_y * delta
		banana_rotation += 8.0 * delta
		
	if (position.y + banana_y) > 1400.0 or abs(banana_x) > 700.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	# Draw Monkey on cliff at (0,0)
	draw_circle(Vector2.ZERO, 20.0, Color(0.55, 0.35, 0.15)) # Body
	draw_circle(Vector2(0, -15), 14.0, Color(0.65, 0.45, 0.25)) # Head
	draw_circle(Vector2(-12, -18), 6.0, Color(0.8, 0.6, 0.4)) # Left ear
	draw_circle(Vector2(12, -18), 6.0, Color(0.8, 0.6, 0.4)) # Right ear
	# Arms raised for throwing pose
	var arm_dir = 1.0 if is_from_left else -1.0
	draw_line(Vector2(0, -5), Vector2(arm_dir * 18, -22), Color(0.55, 0.35, 0.15), 5.0)
	
	if alert_timer > 0.0:
		# Flashing alert sign
		if int(alert_timer * 10.0) % 2 == 0:
			var dir = 1.0 if is_from_left else -1.0
			draw_string(ThemeDB.fallback_font, Vector2(dir * 35.0, -5.0), "⚠️ 落石注意!", HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color.YELLOW)
			draw_line(Vector2(dir * 25.0, 0), Vector2(dir * 60.0, 0), Color.RED, 4.0)
	else:
		# Draw spinning banana at (banana_x, banana_y)
		var bp = Vector2(banana_x, banana_y)
		_draw_banana(bp, banana_rotation)
		
		# Update collision shape offset to match banana
		$CollisionShape2D.position = Vector2(banana_x, banana_y)

func _draw_banana(center: Vector2, rot: float) -> void:
	var banana_color = Color(1.0, 0.88, 0.15)
	var banana_highlight = Color(1.0, 0.95, 0.45)
	var banana_tip = Color(0.55, 0.38, 0.08)
	
	# Draw banana as a thick arc (crescent shape), rotated
	var points = PackedVector2Array()
	var inner_points = PackedVector2Array()
	var arc_segments = 10
	for i in range(arc_segments + 1):
		var t = float(i) / float(arc_segments)
		var angle = rot + deg_to_rad(-80.0 + t * 160.0)
		var outer_r = 18.0
		var inner_r = 11.0
		points.append(center + Vector2(cos(angle) * outer_r, sin(angle) * outer_r))
		inner_points.append(center + Vector2(cos(angle) * inner_r, sin(angle) * inner_r))
	
	# Draw outer banana body
	draw_polyline(points, banana_color, 12.0)
	# Highlight stripe
	draw_polyline(inner_points, banana_highlight, 4.0)
	# Tips (brown ends)
	draw_circle(points[0], 5.0, banana_tip)
	draw_circle(points[arc_segments], 4.0, banana_tip)
