extends "res://scenes/obstacles/Obstacle.gd"

var salmon_offset_x: float = 0.0
var salmon_vx: float = 680.0
var throw_delay: float = 0.45
var is_thrown: bool = false
var throw_dual: bool = false
var salmon_area_1: Area2D = null
var salmon_area_2: Area2D = null
var _custom_font: Font = preload("res://assets/fonts/default_font.tres")

func _ready() -> void:
	obstacle_type = "bear"
	if has_node("CollisionShape2D") and $CollisionShape2D.shape is CircleShape2D:
		$CollisionShape2D.shape.radius = 24.0
	
	if lane < 0:
		salmon_vx = 680.0
		throw_dual = false
	elif lane > 0:
		salmon_vx = -680.0
		throw_dual = false
	else:
		salmon_vx = 680.0
		throw_dual = true

func scroll_update(delta: float, scroll_speed: float) -> void:
	position.y += scroll_speed * delta
	if throw_delay > 0.0:
		throw_delay -= delta
	elif not is_thrown:
		is_thrown = true
		AudioManager.play_sound("splash")
		salmon_area_1 = _create_salmon_projectile(salmon_vx)
		if throw_dual:
			salmon_area_2 = _create_salmon_projectile(-salmon_vx)
	else:
		salmon_offset_x += salmon_vx * delta
		if is_instance_valid(salmon_area_1):
			salmon_area_1.position = Vector2(salmon_offset_x, 0)
			if abs(salmon_offset_x) > 650.0:
				salmon_area_1.queue_free()
		if throw_dual and is_instance_valid(salmon_area_2):
			salmon_area_2.position = Vector2(-salmon_offset_x, 0)
			if abs(salmon_offset_x) > 650.0:
				salmon_area_2.queue_free()
		
	if position.y > 1400.0:
		queue_free()
	queue_redraw()

func _create_salmon_projectile(vx: float) -> Area2D:
	var area = Area2D.new()
	area.set_script(preload("res://scenes/obstacles/Obstacle.gd"))
	area.obstacle_type = "salmon"
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 24.0
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	return area

func _draw() -> void:
	# Draw river rock underneath bear
	draw_circle(Vector2(0, 8), 28.0, Color(0.45, 0.45, 0.48))
	draw_circle(Vector2(-8, 4), 16.0, Color(0.50, 0.50, 0.53))
	
	# Draw muscular fierce Bear sitting on rock
	draw_circle(Vector2(0, 2), 26.0, Color(0.32, 0.18, 0.08)) # Body
	draw_circle(Vector2(0, -16), 18.0, Color(0.38, 0.22, 0.10)) # Head
	draw_circle(Vector2(-14, -26), 7.0, Color(0.32, 0.18, 0.08)) # Left ear
	draw_circle(Vector2(14, -26), 7.0, Color(0.32, 0.18, 0.08)) # Right ear
	draw_circle(Vector2(-14, -26), 4.0, Color(0.55, 0.35, 0.20)) # Inner ear
	draw_circle(Vector2(14, -26), 4.0, Color(0.55, 0.35, 0.20)) # Inner ear
	
	# Glowing fierce red/yellow eyes
	draw_circle(Vector2(-6, -18), 3.5, Color(1.0, 0.85, 0.1))
	draw_circle(Vector2(6, -18), 3.5, Color(1.0, 0.85, 0.1))
	draw_circle(Vector2(-6, -18), 1.5, Color(0.9, 0.1, 0.1))
	draw_circle(Vector2(6, -18), 1.5, Color(0.9, 0.1, 0.1))
	
	# Muzzle
	draw_custom_ellipse(Vector2(0, -11), Vector2(8, 5), Color(0.50, 0.35, 0.22))
	draw_circle(Vector2(0, -13), 2.5, Color(0.1, 0.1, 0.1))
	
	if throw_delay > 0.0:
		# Flashing alert sign and danger line
		if int(throw_delay * 10.0) % 2 == 0:
			draw_string(_custom_font, Vector2(-90.0, -32.0), "⚠️ 凶暴クマ・高速サケ飛来注意!", HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color.YELLOW)
			if throw_dual:
				draw_line(Vector2(-200.0, 0), Vector2(200.0, 0), Color.RED, 4.0)
			else:
				var dir = 1.0 if salmon_vx > 0 else -1.0
				draw_line(Vector2(dir * 25.0, 0), Vector2(dir * 350.0, 0), Color.RED, 4.0)
		else:
			if throw_dual:
				draw_custom_ellipse(Vector2(-22, -6), Vector2(18, 8), Color(0.98, 0.40, 0.50))
				draw_custom_ellipse(Vector2(22, -6), Vector2(18, 8), Color(0.98, 0.40, 0.50))
			else:
				var hold_x = 22.0 if salmon_vx > 0 else -22.0
				draw_custom_ellipse(Vector2(hold_x, -6), Vector2(18, 8), Color(0.98, 0.40, 0.50))
	elif is_thrown:
		if is_instance_valid(salmon_area_1):
			draw_flying_salmon(salmon_offset_x, salmon_vx)
		if throw_dual and is_instance_valid(salmon_area_2):
			draw_flying_salmon(-salmon_offset_x, -salmon_vx)

func draw_flying_salmon(pos_x: float, vx: float) -> void:
	var tail_dir = -1.0 if vx > 0 else 1.0
	draw_line(Vector2(pos_x + tail_dir * 25, 0), Vector2(pos_x + tail_dir * 65, 0), Color(1.0, 0.6, 0.7, 0.6), 5.0)
	draw_line(Vector2(pos_x + tail_dir * 28, -8), Vector2(pos_x + tail_dir * 55, -8), Color(1.0, 0.8, 0.8, 0.4), 2.5)
	draw_line(Vector2(pos_x + tail_dir * 28, 8), Vector2(pos_x + tail_dir * 55, 8), Color(1.0, 0.8, 0.8, 0.4), 2.5)
	
	draw_custom_ellipse(Vector2(pos_x, 0), Vector2(24, 10), Color(0.98, 0.38, 0.48))
	draw_custom_ellipse(Vector2(pos_x, 2), Vector2(18, 5), Color(1.0, 0.75, 0.80))
	
	var pts = PackedVector2Array([
		Vector2(pos_x + tail_dir * 20, 0),
		Vector2(pos_x + tail_dir * 32, -12),
		Vector2(pos_x + tail_dir * 32, 12)
	])
	var cols = PackedColorArray([Color(0.88, 0.28, 0.38), Color(0.88, 0.28, 0.38), Color(0.88, 0.28, 0.38)])
	draw_polygon(pts, cols)
	
	var eye_x = pos_x - tail_dir * 14
	draw_circle(Vector2(eye_x, -3), 2.5, Color.WHITE)
	draw_circle(Vector2(eye_x - tail_dir * 0.5, -3), 1.2, Color.BLACK)

func draw_custom_ellipse(center: Vector2, size: Vector2, color: Color) -> void:
	var pts = PackedVector2Array()
	var cols = PackedColorArray()
	for i in range(16):
		var ang = float(i) / 16.0 * 2.0 * PI
		pts.append(center + Vector2(cos(ang) * size.x, sin(ang) * size.y))
		cols.append(color)
	draw_polygon(pts, cols)
