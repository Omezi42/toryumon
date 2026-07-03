extends Node

var is_recording: bool = false
var is_playing_replay: bool = false
var current_recording: Array = []
var active_replay_data: Array = []
var playback_index: int = 0

func start_recording() -> void:
	is_recording = true
	is_playing_replay = false
	current_recording.clear()

func stop_recording() -> Array:
	is_recording = false
	return current_recording.duplicate()

func log_input(time_sec: float, lane: int, is_dashing: bool) -> void:
	if not is_recording:
		return
	# Store frame / state snapshot only when changed or every few frames
	if current_recording.size() > 0:
		var last = current_recording[-1]
		if last["lane"] == lane and last["dash"] == is_dashing and (time_sec - last["t"]) < 0.1:
			return
	current_recording.append({
		"t": time_sec,
		"lane": lane,
		"dash": is_dashing
	})

func start_playback(replay_data: Array) -> void:
	active_replay_data = replay_data
	playback_index = 0
	is_playing_replay = true
	is_recording = false

func stop_playback() -> void:
	is_playing_replay = false

func get_replay_state_at(time_sec: float) -> Dictionary:
	if not is_playing_replay or active_replay_data.is_empty():
		return {}
	while playback_index < active_replay_data.size() - 1:
		if active_replay_data[playback_index + 1]["t"] <= time_sec:
			playback_index += 1
		else:
			break
	return active_replay_data[playback_index]
