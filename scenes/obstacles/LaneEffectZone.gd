extends "res://scenes/obstacles/Obstacle.gd"

var effect_type: String = "rapids" # or "updraft"
var anim_time: float = 0.0

func _ready() -> void:
	obstacle_type = "lane_effect"

func scroll_update(delta: float, scroll_speed: float) -> void:
	anim_time += delta
	position.y += scroll_speed * delta
	if position.y > 850.0:
		queue_free()
	queue_redraw()

func get_speed_mod() -> float:
	if effect_type == "rapids":
		return 0.55
	else:
		return 1.45

func _draw() -> void:
	# Draw a long lane zone indicator (130 wide, 160 tall)
	var col = Color(1.0, 0.2, 0.2, 0.2) if effect_type == "rapids" else Color(0.2, 0.8, 1.0, 0.2)
	draw_rect(Rect2(-65, -80, 130, 160), col)
	
	# Flow arrows
	var num_arrows = 3
	var dir = 1.0 if effect_type == "rapids" else -1.0
	var arrow_col = Color(1.0, 0.4, 0.3, 0.8) if effect_type == "rapids" else Color(0.3, 0.9, 1.0, 0.8)
	for i in range(num_arrows):
		var y_off = -50.0 + i * 50.0 + fmod(anim_time * 60.0 * dir, 50.0)
		if y_off > -75.0 and y_off < 75.0:
			var pts = PackedVector2Array([
				Vector2(0, y_off + dir * 15.0),
				Vector2(-18, y_off - dir * 10.0),
				Vector2(18, y_off - dir * 10.0)
			])
			var cols = PackedColorArray([arrow_col, arrow_col, arrow_col])
			draw_polygon(pts, cols)
