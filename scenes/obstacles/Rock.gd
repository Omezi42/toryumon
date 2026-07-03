@tool
extends "res://scenes/obstacles/Obstacle.gd"

@export var radius: float = 40.0
@export var points_count: int = 8
@export var jaggedness: float = 0.35 # 凹凸の激しさ
@export var fill_color: Color = Color("2c3e50") # 岩のベース（濃い濃紺）
@export var line_color: Color = Color("ecf0f1") # 和風のハイライト線（白）

var polygon_points: PackedVector2Array = PackedVector2Array()

func _ready() -> void:
	super._ready()
	obstacle_type = "rock"
	generate_rock()

# 岩の輪郭（多角形）をランダム（シード値に基づく）に生成
func generate_rock() -> void:
	polygon_points.clear()
	# 決定論的に、座標などをシードにして岩の形を固定（エディタでも個性が出る）
	var seed_val = global_position.x * 13.0 + global_position.y * 7.0
	if seed_val == 0.0:
		seed_val = randi()
	var rng = RandomNumberGenerator.new()
	rng.seed = int(seed_val)
	
	for i in range(points_count):
		var angle = (float(i) / float(points_count)) * TAU
		# 円にランダムな凹凸を加える
		var offset = rng.randf_range(1.0 - jaggedness, 1.0 + jaggedness)
		var r = radius * offset
		var p = Vector2(cos(angle) * r, sin(angle) * r)
		polygon_points.append(p)
	
	queue_redraw()

func _draw() -> void:
	if polygon_points.size() < 3:
		return
		
	# 1. 岩の本体（塗りつぶし）
	draw_colored_polygon(polygon_points, fill_color)
	
	# 2. 外枠（浮世絵風の力強い白の輪郭線）
	# 輪郭線を閉じさせるため、始点を終点に繋ぐ
	var outline = polygon_points
	outline.append(polygon_points[0])
	draw_polyline(outline, line_color, 4.0, true) # 太さ4のクッキリした線
