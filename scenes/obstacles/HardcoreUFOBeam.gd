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

func apply_ufo_warp(player: Area2D) -> void:
	# 現在と異なるランダムなレーンへテレポート
	var available_lanes = [-1, 0, 1]
	available_lanes.erase(player.current_lane)
	var next_lane = available_lanes[randi() % available_lanes.size()]
	
	player.change_lane(next_lane)
	if player.has_signal("player_teleported"):
		player.emit_signal("player_teleported", next_lane)
	
	# プレイヤーに「操作混乱状態（左右入力の逆転）」を付与する
	if player.has_method("apply_ufo_confusion"):
		player.apply_ufo_confusion(2.5) # 2.5秒間、左右操作が反転
		
	# 派手なワープSEとエフェクト
	AudioManager.play_sound("dash")
	destroy()

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
		beam_cols.append(Color(0.9, 0.2, 0.9, 0.35) if int(anim_time * 12.0) % 2 == 0 else Color(0.2, 1.0, 0.4, 0.3))
	draw_polygon(beam_pts, beam_cols)

func draw_custom_ellipse(center: Vector2, size: Vector2, color: Color) -> void:
	var pts = PackedVector2Array()
	var cols = PackedColorArray()
	for i in range(16):
		var ang = float(i) / 16.0 * 2.0 * PI
		pts.append(center + Vector2(cos(ang) * size.x, sin(ang) * size.y))
		cols.append(color)
	draw_polygon(pts, cols)
