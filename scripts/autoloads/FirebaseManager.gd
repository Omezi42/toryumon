extends Node

const CACHE_PATH = "user://shared_stages_cache.json"

var cached_stages: Array = []
var http_client: HTTPRequest

signal stages_fetched(stages: Array)
signal stage_uploaded(success: bool, stage_code: String)

func _ready() -> void:
	http_client = HTTPRequest.new()
	add_child(http_client)
	http_client.request_completed.connect(_on_request_completed)
	load_local_cache()
	if cached_stages.is_empty():
		_add_sample_custom_stage()

func _add_sample_custom_stage() -> void:
	# Default sample shared stage
	var sample = {
		"code": "#123456",
		"title": "サルの大暴れ滝（コミュニティ投稿例）",
		"author": "コイキングマスター",
		"target_time": 25.0,
		"obstacles": [
			{"type": "rock", "lane": 0, "dist": 30.0},
			{"type": "monkey", "lane": -1, "dist": 60.0},
			{"type": "monkey", "lane": 1, "dist": 90.0},
			{"type": "salmon", "lane": 0, "dist": 130.0},
			{"type": "hook", "lane": 0, "dist": 170.0},
			{"type": "ufo", "lane": -1, "dist": 210.0}
		],
		"length": 260.0
	}
	cached_stages.append(sample)
	save_local_cache()

func load_local_cache() -> void:
	if FileAccess.file_exists(CACHE_PATH):
		var file = FileAccess.open(CACHE_PATH, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK and typeof(json.get_data()) == TYPE_ARRAY:
				cached_stages = json.get_data()

func save_local_cache() -> void:
	var file = FileAccess.open(CACHE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(cached_stages, "\t"))

func fetch_shared_stages() -> void:
	# In a live Web build with Firebase configured, we could request via Firestore REST API.
	# Here we return cached/local shared stages immediately while simulating quick cloud sync.
	emit_signal("stages_fetched", cached_stages)

func upload_stage(title: String, author: String, obstacles: Array, length: float, target_time: float) -> void:
	var code = "#" + str(randi() % 899999 + 100000)
	var stage_data = {
		"code": code,
		"title": title,
		"author": author if author != "" else "名無し鯉",
		"target_time": target_time,
		"obstacles": obstacles,
		"length": length
	}
	cached_stages.push_front(stage_data)
	save_local_cache()
	emit_signal("stage_uploaded", true, code)

func _on_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	pass
