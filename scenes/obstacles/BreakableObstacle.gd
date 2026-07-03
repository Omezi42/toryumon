@tool
extends "res://scenes/obstacles/Obstacle.gd"

var is_ice: bool = false
var shape_points: PackedVector2Array = PackedVector2Array()

func _ready() -> void:
	super._ready()
	obstacle_type = "breakable"
	if Engine.is_editor_hint():
		is_ice = false
	else:
		is_ice = randf() > 0.5
	generate_shape()

func generate_shape() -> void:
	shape_points.clear()
	var seed_val = global_position.x * 19.0 + global_position.y * 3.0
	if seed_val == 0.0:
		seed_val = randi()
	var rng = RandomNumberGenerator.new()
	rng.seed = int(seed_val)
	
	if is_ice:
		# 和モダン六角氷結晶風の凹凸シェイプ
		var count = 6
		for i in range(count):
			var angle = (float(i) / float(count)) * TAU
			var r = rng.randf_range(24.0, 32.0)
			shape_points.append(Vector2(cos(angle) * r, sin(angle) * r))
	else:
		# 流木（木片の多角形）
		var w = rng.randf_range(30.0, 40.0)
		var h = rng.randf_range(12.0, 16.0)
		shape_points.append(Vector2(-w, -h + rng.randf_range(-3, 3)))
		shape_points.append(Vector2(w, -h + rng.randf_range(-3, 3)))
		shape_points.append(Vector2(w - 5, h + rng.randf_range(-3, 3)))
		shape_points.append(Vector2(-w + 5, h + rng.randf_range(-3, 3)))
	queue_redraw()

func _draw() -> void:
	if shape_points.size() < 3:
		return
		
	if is_ice:
		# 氷の和モダン描画（半透明のシアン＆クッキリした浮世絵白線）
		draw_colored_polygon(shape_points, Color("3498db", 0.85))
		var outline = shape_points
		outline.append(shape_points[0])
		draw_polyline(outline, Color("ecf0f1"), 3.0, true)
		# 内部のハイライト線
		draw_line(Vector2(-10, -10), Vector2(10, 10), Color(1, 1, 1, 0.9), 2.0)
	else:
		# 流木（濃茶ベース＆和風の力強いハイライト線）
		draw_colored_polygon(shape_points, Color("8e44ad" if randf() < 0.1 else "6e2c00"))
		var outline = shape_points
		outline.append(shape_points[0])
		draw_polyline(outline, Color("f39c12"), 3.0, true)
		# 木目ライン
		draw_line(Vector2(-20, -3), Vector2(20, -3), Color("d35400"), 2.0)
