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
var base_scroll_speed: float = 280.0

var is_game_over: bool = false
var is_cleared: bool = false

var bg_scroll_offset: float = 0.0

# Preload obstacle scenes
var scene_map = {
	"rock": preload("res://scenes/obstacles/Rock.tscn"),
	"breakable": preload("res://scenes/obstacles/BreakableObstacle.tscn"),
	"monkey": preload("res://scenes/obstacles/MonkeyThrower.tscn"),
	"salmon": preload("res://scenes/obstacles/BearSalmon.tscn"),
	"hook": preload("res://scenes/obstacles/FishingHook.tscn"),
	"ufo": preload("res://scenes/obstacles/UFOBeam.tscn"),
	"orb": preload("res://scenes/obstacles/DragonOrb.tscn"),
	"rapids": preload("res://scenes/obstacles/LaneEffectZone.tscn"),
	"updraft": preload("res://scenes/obstacles/LaneEffectZone.tscn")
}

const LANE_X = {
	-1: 500.0,
	0: 640.0,
	1: 780.0
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
		# Fallback stage data
		stage_data = {
			"title": "始まりの滝",
			"length": 280.0,
			"target_time": 20.0,
			"obstacles": [
				{"type": "rock", "lane": 0, "dist": 40.0},
				{"type": "breakable", "lane": -1, "dist": 70.0},
				{"type": "orb", "lane": 1, "dist": 90.0},
				{"type": "rock", "lane": 1, "dist": 130.0},
				{"type": "rapids", "lane": 0, "dist": 160.0},
				{"type": "rock", "lane": -1, "dist": 200.0}
			]
		}
		
	stage_length = float(stage_data.get("length", 300.0))
	obstacles_to_spawn = stage_data.get("obstacles", []).duplicate()
	# Sort obstacles by dist
	obstacles_to_spawn.sort_custom(func(a, b): return float(a["dist"]) < float(b["dist"]))

func _process(delta: float) -> void:
	if is_game_over or is_cleared:
		return
		
	elapsed_time += delta
	var speed_mult = player.get_speed_multiplier() if player else 1.0
	var current_speed = base_scroll_speed * speed_mult
	
	current_distance += (current_speed * delta) / 10.0 # scale unit distance
	score = int(current_distance * 10)
	
	bg_scroll_offset += current_speed * delta
	
	# Check lane effects on player
	if player:
		var effect_mod = 1.0
		for child in active_obstacles.get_children():
			if child.has_method("get_obstacle_type") and child.get_obstacle_type() == "lane_effect":
				if child.lane == player.current_lane and abs(child.position.y - player.position.y) < 90.0:
					effect_mod = child.get_speed_mod()
					break
		player.lane_speed_modifier = effect_mod
	
	# Spawn obstacles
	while obstacles_to_spawn.size() > 0 and float(obstacles_to_spawn[0]["dist"]) <= current_distance + 35.0:
		var obs_info = obstacles_to_spawn.pop_front()
		_spawn_obstacle(obs_info)
		
	# Update active obstacles
	for child in active_obstacles.get_children():
		if child.has_method("scroll_update"):
			child.scroll_update(delta, current_speed)
			
	queue_redraw()
	
	# Check goal
	if current_distance >= stage_length:
		_on_stage_cleared()

func _spawn_obstacle(info: Dictionary) -> void:
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
	# Knockback penalty
	current_distance = max(0.0, current_distance - 8.0)
	score = max(0, score - 50)

func _on_obstacle_broken(_pos: Vector2) -> void:
	score += 100

func _on_stage_cleared() -> void:
	is_cleared = true
	var replay_log = ReplayManager.stop_recording()
	WebBridge.stop_and_download_video()
	AudioManager.play_sound("clear")
	GameManager.complete_stage(elapsed_time, score)

func _draw() -> void:
	# Draw Waterfall background (Central area x=430 to 850)
	draw_rect(Rect2(430, 0, 420, 720), Color(0.08, 0.35, 0.55)) # Deep water
	
	# Flowing foam / streaks
	for i in range(15):
		var x = 445.0 + float(i) * 26.0
		var y = fmod(bg_scroll_offset * 1.2 + float(i * 137), 720.0)
		draw_line(Vector2(x, y), Vector2(x, y + 40), Color(0.3, 0.7, 0.9, 0.4), 2.5)
		
	# Lane divider lines
	draw_line(Vector2(570, 0), Vector2(570, 720), Color(1, 1, 1, 0.2), 2.0)
	draw_line(Vector2(710, 0), Vector2(710, 720), Color(1, 1, 1, 0.2), 2.0)
	
	# Rocky cliffs left (0 to 430) and right (850 to 1280)
	draw_rect(Rect2(0, 0, 430, 720), Color(0.18, 0.16, 0.15))
	draw_rect(Rect2(850, 0, 430, 720), Color(0.18, 0.16, 0.15))
	
	# Cliff edges
	draw_line(Vector2(430, 0), Vector2(430, 720), Color(0.4, 0.38, 0.35), 6.0)
	draw_line(Vector2(850, 0), Vector2(850, 720), Color(0.4, 0.38, 0.35), 6.0)
	
	# Goal line indicator if getting close
	var dist_remaining = stage_length - current_distance
	if dist_remaining < 35.0:
		var goal_y = float(dist_remaining / 35.0) * 600.0
		if goal_y >= 0 and goal_y <= 720:
			draw_line(Vector2(430, goal_y), Vector2(850, goal_y), Color(1.0, 0.84, 0.0), 8.0)
			draw_string(ThemeDB.fallback_font, Vector2(580, goal_y - 10), "🏁 GOAL 🏁", HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color.YELLOW)
