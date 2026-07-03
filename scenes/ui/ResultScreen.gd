extends Control

func _ready() -> void:
	$NextButton.pressed.connect(_on_next_pressed)
	$ReplayButton.pressed.connect(_on_replay_pressed)
	$SaveVideoButton.pressed.connect(_on_save_video_pressed)
	$ShareButton.pressed.connect(_on_share_pressed)
	$SelectButton.pressed.connect(_on_select_pressed)
	
	_setup_result_display()
	GameManager.set_state(GameManager.GameState.RESULT)

func _setup_result_display() -> void:
	var stage_name = GameManager.current_custom_stage_data.get("title", "ステージ %d" % GameManager.current_stage_id)
	$StageNameLabel.text = "クリアステージ: %s" % stage_name
	$TimeLabel.text = "クリアタイム: %05.2f 秒" % GameManager.last_clear_time
	$ScoreLabel.text = "スコア: %d" % GameManager.last_score
	
	var stars = "★".repeat(GameManager.last_rank)
	$RankLabel.text = "評価: " + stars

func _on_next_pressed() -> void:
	AudioManager.play_sound("dash")
	if not GameManager.is_custom_stage and GameManager.current_stage_id < 10:
		GameManager.start_stage(GameManager.current_stage_id + 1)
	else:
		GameManager.start_stage(GameManager.current_stage_id)

func _on_replay_pressed() -> void:
	AudioManager.play_sound("orb")
	# Replay mode play
	GameManager.start_stage(GameManager.current_stage_id)

func _on_save_video_pressed() -> void:
	AudioManager.play_sound("orb")
	WebBridge.stop_and_download_video()

func _on_share_pressed() -> void:
	AudioManager.play_sound("clear")
	var stage_name = GameManager.current_custom_stage_data.get("title", "ステージ %d" % GameManager.current_stage_id)
	var stage_code = GameManager.current_custom_stage_data.get("code", "#STAGE%d" % GameManager.current_stage_id)
	var time_str = "%05.2f" % GameManager.last_clear_time
	var text = "🌊 激ムズ滝登りステージをクリア！ 🐉\nステージ名：『%s』\nクリアタイム：%s秒\n👇このコードを入力して挑戦しよう！\n【ステージコード： %s 】\n#コイの滝登り #unityroom #GodotEngine https://unityroom.com" % [stage_name, time_str, stage_code]
	var encoded = text.uri_encode()
	var url = "https://twitter.com/intent/tweet?text=" + encoded
	OS.shell_open(url)

func _on_select_pressed() -> void:
	AudioManager.play_sound("dash")
	get_tree().change_scene_to_file("res://scenes/ui/StageSelectScreen.tscn")
