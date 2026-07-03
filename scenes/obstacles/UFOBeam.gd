extends "res://scenes/obstacles/Obstacle.gd"

var anim_time: float = 0.0

func _ready() -> void:
	obstacle_type = "ufo_beam"

func scroll_update(delta: float, scroll_speed: float) -> void:
	anim_time += delta
	position.y += scroll_speed * delta
	if position.y > 850.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	# Draw UFO saucer
	draw_custom_ellipse(Vector2(0, -40), Vector2(35, 12), Color(0.6, 0.6, 0.7))
	draw_custom_ellipse(Vector2(0, -45), Vector2(18, 10), Color(0.3, 0.9, 0.5)) # Dome
	# Lights blinking
	var c = Color.YELLOW if int(anim_time * 8.0) % 2 == 0 else Color.CYAN
	draw_circle(Vector2(-20, -38), 3.0, c)
	draw_circle(Vector2(0, -36), 3.0, c)
	draw_circle(Vector2(20, -38), 3.0, c)
	
	# Tractor beam downwards
	var beam_pts = PackedVector2Array([
		Vector2(-15, -30), Vector2(15, -30),
		Vector2(45, 50), Vector2(-45, 50)
	])
	var beam_cols = PackedColorArray()
	for k in range(beam_pts.size()):
		beam_cols.append(Color(0.2, 1.0, 0.4, 0.3))
	draw_polygon(beam_pts, beam_cols)

func draw_custom_ellipse(center: Vector2, size: Vector2, color: Color) -> void:
	var pts = PackedVector2Array()
	var cols = PackedColorArray()
	for i in range(16):
		var ang = float(i) / 16.0 * 2.0 * PI
		pts.append(center + Vector2(cos(ang) * size.x, sin(ang) * size.y))
		cols.append(color)
	draw_polygon(pts, cols)
