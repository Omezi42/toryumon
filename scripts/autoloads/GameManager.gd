extends Node

enum GameState {
	TITLE,
	STAGE_SELECT,
	PLAYING,
	RESULT,
	EDITOR
}

var current_state: GameState = GameState.TITLE
var current_stage_id: int = 1
var current_custom_stage_data: Dictionary = {}
var is_custom_stage: bool = false
var is_stage_failed: bool = false

var last_clear_time: float = 0.0
var last_score: int = 0
var last_rank: int = 1 # 3=★3, 2=★2, 1=★1

var save_data: Dictionary = {
	"best_times": {}, # stage_id -> float
	"unlocked_stage": 1,
	"custom_stages": []
}

signal game_state_changed(new_state)
signal stage_cleared(stage_id, clear_time, score)
signal stage_failed()

const SAVE_PATH = "user://toryumon_save.json"

func _ready() -> void:
	load_game()

func set_state(new_state: GameState) -> void:
	current_state = new_state
	emit_signal("game_state_changed", new_state)

func start_stage(stage_id: int) -> void:
	current_stage_id = stage_id
	is_custom_stage = false
	set_state(GameState.PLAYING)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/game/MainGame.tscn")

func start_custom_stage(stage_data: Dictionary) -> void:
	current_custom_stage_data = stage_data
	is_custom_stage = true
	set_state(GameState.PLAYING)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/game/MainGame.tscn")

func complete_stage(clear_time: float, score: int) -> void:
	is_stage_failed = false
	last_clear_time = clear_time
	last_score = score
	
	# Evaluate rank based on time
	if clear_time <= 25.0:
		last_rank = 3
	elif clear_time <= 30.0:
		last_rank = 2
	else:
		last_rank = 1
		
	if not is_custom_stage:
		var stage_key = str(current_stage_id)
		if not save_data["best_times"].has(stage_key) or clear_time < save_data["best_times"][stage_key]:
			save_data["best_times"][stage_key] = clear_time
		if current_stage_id >= save_data["unlocked_stage"] and current_stage_id < 10:
			save_data["unlocked_stage"] = current_stage_id + 1
		save_game()
		
	emit_signal("stage_cleared", current_stage_id, clear_time, score)
	set_state(GameState.RESULT)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/ResultScreen.tscn")

func fail_stage() -> void:
	is_stage_failed = true
	emit_signal("stage_failed")
	set_state(GameState.RESULT)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/ResultScreen.tscn")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var json = JSON.new()
		if json.parse(text) == OK and typeof(json.get_data()) == TYPE_DICTIONARY:
			save_data = json.get_data()

func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))

func get_best_time(stage_id: int) -> float:
	var key = str(stage_id)
	if save_data["best_times"].has(key):
		return float(save_data["best_times"][key])
	return 999.99
