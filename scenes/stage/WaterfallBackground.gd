@tool
extends Node2D

@export var flow_speed: float = 2.5:
	set(val):
		flow_speed = val
		if $ColorRect and $ColorRect.material:
			$ColorRect.material.set_shader_parameter("flow_speed", flow_speed)

var left_cliff_points: PackedVector2Array = PackedVector2Array()
var right_cliff_points: PackedVector2Array = PackedVector2Array()
var anim_time: float = 0.0

func _ready() -> void:
	generate_cliffs()

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		anim_time += delta
		queue_redraw()

func generate_cliffs() -> void:
	left_cliff_points.clear()
	right_cliff_points.clear()
	
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345 # 固定シードで決定論的に美しい崖フレームを構築
	
	# 左側の崖 (X: 0 ～ 430)
	left_cliff_points.append(Vector2(0, 0))
	for y in range(0, 730, 40):
		var x_offset = rng.randf_range(380.0, 430.0)
		left_cliff_points.append(Vector2(x_offset, float(y)))
	left_cliff_points.append(Vector2(0, 720))
	
	# 右側の崖 (X: 850 ～ 1280)
	right_cliff_points.append(Vector2(1280, 0))
	for y in range(0, 730, 40):
		var x_offset = rng.randf_range(850.0, 900.0)
		right_cliff_points.append(Vector2(x_offset, float(y)))
	right_cliff_points.append(Vector2(1280, 720))
	
	queue_redraw()

func _draw() -> void:
	# 1. 左右の崖（岩肌ベタ塗り＆和風浮世絵輪郭線）
	if left_cliff_points.size() > 2:
		draw_colored_polygon(left_cliff_points, Color("1a252f"))
		var left_outline = left_cliff_points
		draw_polyline(left_outline, Color("ecf0f1"), 3.5, true)
		
	if right_cliff_points.size() > 2:
		draw_colored_polygon(right_cliff_points, Color("1a252f"))
		var right_outline = right_cliff_points
		draw_polyline(right_outline, Color("ecf0f1"), 3.5, true)
	
	# 2. レーン境界線（和風の掠れ破線）
	var lane_dividers = [570.0, 710.0]
	for x in lane_dividers:
		for y in range(0, 720, 60):
			var scroll_y = fmod(float(y) + anim_time * 200.0, 720.0)
			var start_p = Vector2(x, scroll_y)
			var end_p = Vector2(x, scroll_y + 30.0)
			draw_line(start_p, end_p, Color(1.0, 1.0, 1.0, 0.35), 2.0)
