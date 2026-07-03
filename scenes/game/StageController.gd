extends Node2D

@export var player_path: NodePath
var player: Node2D

var stage_data: Dictionary = {}
var obstacles_to_spawn: Array = []
var active_obstacles: Node2D

var current_distance: float = 0.0
var stage_length: float = 300.0
var elapsed_time: float = 0.0
var score: int = 0
var base_scroll_speed: float = 1000.0
var target_time: float = 30.0

var is_game_over: bool = false
var is_cleared: bool = false

var bg_scroll_offset: float = 0.0
var _custom_font: Font = preload("res://assets/fonts/default_font.tres")

# Preload obstacle scenes
var scene_map = {
	"rock": preload("res://scenes/obstacles/Rock.tscn"),
	"breakable": preload("res://scenes/obstacles/BreakableObstacle.tscn"),
	"monkey": preload("res://scenes/obstacles/MonkeyThrower.tscn"),
	"salmon": preload("res://scenes/obstacles/BearSalmon.tscn"),
	"hook": preload("res://scenes/obstacles/FishingHook.tscn"),
	"ufo": preload("res://scenes/obstacles/UFOBeam.tscn"),
	"rapids": preload("res://scenes/obstacles/LaneEffectZone.tscn"),
	"updraft": preload("res://scenes/obstacles/LaneEffectZone.tscn")
}

const LANE_X = {
	-1: 190.0,
	0: 360.0,
	1: 530.0
}

func _ready() -> void:
	if has_node("Player"):
		player = get_node("Player")
	elif player_path and has_node(player_path):
		player = get_node(player_path)
		
	active_obstacles = Node2D.new()
	active_obstacles.name = "ActiveObstacles"
	add_child(active_obstacles)
	
	if player:
		player.player_damaged.connect(_on_player_damaged)
		player.obstacle_broken.connect(_on_obstacle_broken)
		
	_load_stage()
	
	# Start recording
	ReplayManager.start_recording()
	WebBridge.start_video_recording()

func _load_stage() -> void:
	if GameManager.is_custom_stage:
		stage_data = GameManager.current_custom_stage_data.duplicate()
	else:
		var file_path = "res://data/stages/stage_%d.json" % GameManager.current_stage_id
		if FileAccess.file_exists(file_path):
			var file = FileAccess.open(file_path, FileAccess.READ)
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				stage_data = json.get_data()
				
	if stage_data.is_empty():
		# 絶妙な手応えの30秒黄金比フォールバックステージ
		stage_data = {
			"title": "激流・登竜門の試練",
			"length": 3450.0,
			"target_time": 120.0,
			"obstacles": [
				# [0s-5s] 導入：スクロールスピードに目を慣らす
				{"type": "rock", "lane": 0, "dist": 60.0},
				{"type": "rock", "lane": -1, "dist": 150.0},
				{"type": "rock", "lane": 1, "dist": 240.0},
				# [5s-15s] 最初の難所：単一ギミックの回避・ダッシュ判断
				{"type": "monkey", "lane": -1, "dist": 350.0},
				{"type": "breakable", "lane": 0, "dist": 480.0},
				{"type": "salmon", "lane": 1, "dist": 620.0},
				{"type": "monkey", "lane": 1, "dist": 760.0},
				# [15s-22s] 中盤突入：障害物の回避とダッシュ活用
				{"type": "rock", "lane": 0, "dist": 950.0},
				{"type": "breakable", "lane": -1, "dist": 1120.0},
				{"type": "salmon", "lane": 1, "dist": 1280.0},
				# [22s-28s] 中盤：コンボ（挟み込み＆誘導釣り針）
				{"type": "rock", "lane": -1, "dist": 1420.0},
				{"type": "monkey", "lane": 1, "dist": 1450.0},
				{"type": "rapids", "lane": 1, "dist": 1560.0},
				{"type": "hook", "lane": 0, "dist": 1590.0},
				{"type": "salmon", "lane": -1, "dist": 1680.0},
				# [28s-45s] 後半への展開：複合ラッシュ
				{"type": "monkey", "lane": 0, "dist": 1800.0},
				{"type": "ufo", "lane": 1, "dist": 1920.0},
				{"type": "rock", "lane": -1, "dist": 2040.0},
				{"type": "salmon", "lane": 1, "dist": 2160.0},
				{"type": "hook", "lane": 0, "dist": 2280.0},
				{"type": "monkey", "lane": -1, "dist": 2400.0},
				{"type": "updraft", "lane": 0, "dist": 2520.0},
				{"type": "rock", "lane": 1, "dist": 2640.0},
				{"type": "breakable", "lane": -1, "dist": 2760.0},
				{"type": "ufo", "lane": 0, "dist": 2880.0},
				{"type": "salmon", "lane": 1, "dist": 3000.0},
				{"type": "hook", "lane": -1, "dist": 3120.0},
				{"type": "breakable", "lane": 0, "dist": 3240.0},
				{"type": "updraft", "lane": -1, "dist": 3350.0},
				{"type": "updraft", "lane": 1, "dist": 3350.0}
			]
		}
		
	stage_length = float(stage_data.get("length", 3450.0))
	target_time = float(stage_data.get("target_time", 120.0))
	obstacles_to_spawn = stage_data.get("obstacles", []).duplicate()
	# Sort obstacles by dist
	obstacles_to_spawn.sort_custom(func(a, b): return float(a.get("dist", 0.0)) < float(b.get("dist", 0.0)))

func _process(delta: float) -> void:
	if is_game_over or is_cleared:
		return
		
	elapsed_time += delta
	var speed_mult = player.get_speed_multiplier() if player else 1.0
	var current_speed = base_scroll_speed * speed_mult
	
	current_distance += (current_speed * delta) / 5.8 # scale unit distance
	score = int(current_distance * 10)
	
	bg_scroll_offset += current_speed * delta
	
	# Check lane effects on player
	if player and is_instance_valid(active_obstacles):
		var effect_mod = 1.0
		for child in active_obstacles.get_children():
			if child.has_method("get_obstacle_type") and child.get_obstacle_type() == "lane_effect":
				if child.lane == player.current_lane and abs(child.position.y - player.position.y) < 90.0:
					effect_mod = child.get_speed_mod()
					break
		player.lane_speed_modifier = effect_mod
	
	# Spawn obstacles
	while obstacles_to_spawn.size() > 0 and float(obstacles_to_spawn[0].get("dist", 0.0)) <= current_distance + 45.0:
		var obs_info = obstacles_to_spawn.pop_front()
		_spawn_obstacle(obs_info)
		
	# Update active obstacles
	if is_instance_valid(active_obstacles):
		for child in active_obstacles.get_children():
			if child.has_method("scroll_update"):
				child.scroll_update(delta, current_speed)
			
	queue_redraw()
	
	# Check goal or time over
	if current_distance >= stage_length:
		_on_stage_cleared()
	elif elapsed_time >= target_time:
		_on_stage_failed()

func _spawn_obstacle(info: Dictionary) -> void:
	if not is_instance_valid(active_obstacles):
		return
	var type = str(info.get("type", "rock"))
	var lane = int(info.get("lane", 0))
	if not scene_map.has(type):
		type = "rock"
	var inst = scene_map[type].instantiate()
	inst.lane = lane
	if type in ["rapids", "updraft"]:
		inst.effect_type = type
	if lane in LANE_X:
		inst.position = Vector2(LANE_X[lane], -60.0)
	else:
		inst.position = Vector2(LANE_X[0], -60.0)
	active_obstacles.add_child(inst)

func _on_player_damaged() -> void:
	if is_game_over or is_cleared:
		return
		
	is_game_over = true
	
	# 1. 派手なジュース爆散エフェクトをプレイヤーの位置に生成
	if player:
		spawn_juicy_death_splatter(player.global_position)
		# 2. プレイヤーを画面から非表示にする
		player.visible = false
	
	# 3. 録画の停止
	ReplayManager.stop_recording()
	WebBridge.stop_and_download_video()
	
	# 4. 即死ゲームオーバー画面への高速遷移、またはその場で「Rキー/スペースで1秒リトライ」
	_show_fast_retry_hud()

func _on_obstacle_broken(_pos: Vector2) -> void:
	score += 100

func _on_stage_cleared() -> void:
	is_cleared = true
	var replay_log = ReplayManager.stop_recording()
	WebBridge.stop_and_download_video()
	AudioManager.play_sound("clear")
	GameManager.complete_stage(elapsed_time, score)

func _on_stage_failed() -> void:
	if is_game_over or is_cleared:
		return
	is_game_over = true
	if player:
		spawn_juicy_death_splatter(player.global_position)
		player.visible = false
	ReplayManager.stop_recording()
	WebBridge.stop_and_download_video()
	AudioManager.play_sound("hit")
	_show_fast_retry_hud()

func _show_fast_retry_hud() -> void:
	var retry_label = Label.new()
	retry_label.text = "無念…！激流に沈む 💀\n\n画面タップ / [SPACE] で\n即座に再挑戦"
	retry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	retry_label.add_theme_font_size_override("font_size", 36)
	retry_label.add_theme_color_override("font_color", Color("#E74C3C"))
	retry_label.add_theme_color_override("font_outline_color", Color("#FCFCFC"))
	retry_label.add_theme_constant_override("outline_size", 6)
	retry_label.position = Vector2(40, 520)
	retry_label.custom_minimum_size = Vector2(640, 200)
	add_child(retry_label)
	
	retry_label.scale = Vector2.ZERO
	retry_label.pivot_offset = Vector2(320, 100)
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(retry_label, "scale", Vector2.ONE, 0.35)
	
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if is_game_over:
		if event.is_action_pressed("dash") or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
			AudioManager.play_sound("dash")
			get_tree().call_deferred("reload_current_scene")

func spawn_juicy_death_splatter(pos: Vector2) -> void:
	var splatter_scene = load("res://scenes/effects/JuicyDeathSplatter.tscn")
	if splatter_scene:
		var inst = splatter_scene.instantiate()
		inst.global_position = pos
		add_child(inst)
	else:
		var splatter_script = load("res://scenes/player/juicy_death_splatter.gd")
		if splatter_script:
			var inst = Node2D.new()
			inst.set_script(splatter_script)
			inst.global_position = pos
			add_child(inst)

func _draw() -> void:
	if not has_node("WaterfallBackground"):
		# スマホ縦画面向け・陽光きらめく新緑清流フォールバック描画
		draw_rect(Rect2(80, 0, 560, 1280), Color("#A1D8E6")) # 白群
		for i in range(20):
			var x = 100.0 + float(i) * 26.0
			var y = fmod(bg_scroll_offset * 1.2 + float(i * 137), 1280.0)
			draw_line(Vector2(x, y), Vector2(x, y + 40), Color("#FCFCFC", 0.65), 2.5) # 白練
		draw_line(Vector2(275, 0), Vector2(275, 1280), Color(1, 1, 1, 0.3), 2.0)
		draw_line(Vector2(445, 0), Vector2(445, 1280), Color(1, 1, 1, 0.3), 2.0)
		draw_rect(Rect2(0, 0, 80, 1280), Color("#2E7D32")) # 常盤緑
		draw_rect(Rect2(640, 0, 80, 1280), Color("#2E7D32")) # 常盤緑
		draw_line(Vector2(80, 0), Vector2(80, 1280), Color("#FCFCFC"), 5.0)
		draw_line(Vector2(640, 0), Vector2(640, 1280), Color("#FCFCFC"), 5.0)
	
	# Goal line indicator if getting close
	var dist_remaining = stage_length - current_distance
	if dist_remaining < 35.0:
		var goal_y = float(dist_remaining / 35.0) * 1100.0
		if goal_y >= 0 and goal_y <= 1280:
			draw_line(Vector2(80, goal_y), Vector2(640, goal_y), Color("#F1C40F"), 8.0) # 黄金
			draw_string(_custom_font, Vector2(360, goal_y - 10), "🏁 GOAL 🏁", HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER, -1, 28, Color("#F1C40F"))
