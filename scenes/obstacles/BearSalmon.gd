extends "res://scenes/obstacles/Obstacle.gd"

var salmon_offset_x: float = 0.0
var salmon_vx: float = 300.0
var throw_delay: float = 0.6
var is_thrown: bool = false

func _ready() -> void:
	obstacle_type = "salmon"
	salmon_vx = 320.0 if randf() > 0.5 else -320.0

func scroll_update(delta: float, scroll_speed: float) -> void:
	position.y += scroll_speed * delta
	if throw_delay > 0.0:
		throw_delay -= delta
	else:
		is_thrown = true
		salmon_offset_x += salmon_vx * delta
		$CollisionShape2D.position = Vector2(salmon_offset_x, 0)
		
	if position.y > 850.0 or abs(salmon_offset_x) > 500.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	# Draw Bear sitting on rock
	draw_circle(Vector2(0, 5), 24.0, Color(0.35, 0.22, 0.12)) # Bear body
	draw_circle(Vector2(0, -12), 16.0, Color(0.4, 0.25, 0.14)) # Bear head
	draw_circle(Vector2(-12, -22), 6.0, Color(0.35, 0.22, 0.12))
	draw_circle(Vector2(12, -22), 6.0, Color(0.35, 0.22, 0.12))
	
	if not is_thrown:
		# Holding pink salmon
		draw_custom_ellipse(Vector2(18, -5), Vector2(15, 6), Color(0.95, 0.5, 0.6))
	else:
		# Flying pink salmon at salmon_offset_x
		draw_custom_ellipse(Vector2(salmon_offset_x, 0), Vector2(20, 8), Color(0.95, 0.45, 0.55))
		# Salmon tail
		var tail_dir = -1.0 if salmon_vx > 0 else 1.0
		var pts = PackedVector2Array([
			Vector2(salmon_offset_x + tail_dir * 18, 0),
			Vector2(salmon_offset_x + tail_dir * 26, -8),
			Vector2(salmon_offset_x + tail_dir * 26, 8)
		])
		var cols = PackedColorArray()
		for k in range(pts.size()):
			cols.append(Color(0.85, 0.35, 0.45))
		draw_polygon(pts, cols)

func draw_custom_ellipse(center: Vector2, size: Vector2, color: Color) -> void:
	var pts = PackedVector2Array()
	var cols = PackedColorArray()
	for i in range(16):
		var ang = float(i) / 16.0 * 2.0 * PI
		pts.append(center + Vector2(cos(ang) * size.x, sin(ang) * size.y))
		cols.append(color)
	draw_polygon(pts, cols)
