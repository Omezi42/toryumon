extends Control

func _ready() -> void:
	$VBox/NextButton.pressed.connect(_on_next_pressed)
	$VBox/ReplayButton.pressed.connect(_on_replay_pressed)
	$VBox/SaveVideoButton.pressed.connect(_on_save_video_pressed)
	$VBox/ShareButton.pressed.connect(_on_share_pressed)
	$VBox/SelectButton.pressed.connect(_on_select_pressed)
	
	_setup_result_display()
	GameManager.set_state(GameManager.GameState.RESULT)

func _setup_result_display() -> void:
	var stage_name = GameManager.current_custom_stage_data.get("title", "ステージ %d" % GameManager.current_stage_id)
	if GameManager.is_stage_failed:
		$StageNameLabel.text = "挑戦失敗: %s" % stage_name
		$StageNameLabel.modulate = Color("e74c3c")
		$TimeLabel.text = "結果: TIME UP / スタミナオーバー"
		$ScoreLabel.text = "スコア: %d" % GameManager.last_score
		$RankLabel.text = "評価: 挑戦失敗 (ダッシュと息切れのバランスを見極めろ!)"
		$VBox/NextButton.visible = false
	else:
		$StageNameLabel.modulate = Color.WHITE
		$StageNameLabel.text = "クリアステージ: %s" % stage_name
		$TimeLabel.text = "クリアタイム: %05.2f 秒" % GameManager.last_clear_time
		$ScoreLabel.text = "スコア: %d" % GameManager.last_score
		var stars = "★".repeat(GameManager.last_rank)
		$RankLabel.text = "評価: " + stars
		$VBox/NextButton.visible = true

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
	var text = ""
	if GameManager.is_stage_failed:
		text = "🌊 激ムズ滝登りステージで無念のタイムアップ！ 🐉\nステージ名：『%s』\n次はスタミナ管理とコンボ見切りで絶対クリアする！\n👇挑戦者求む！\n【ステージコード： %s 】\n#コイの滝登り #unityroom #GodotEngine https://unityroom.com" % [stage_name, stage_code]
	else:
		var time_str = "%05.2f" % GameManager.last_clear_time
		text = "🌊 激ムズ滝登りステージをクリア！ 🐉\nステージ名：『%s』\nクリアタイム：%s秒\n👇このコードを入力して挑戦しよう！\n【ステージコード： %s 】\n#コイの滝登り #unityroom #GodotEngine https://unityroom.com" % [stage_name, time_str, stage_code]
	var encoded = text.uri_encode()
	var url = "https://twitter.com/intent/tweet?text=" + encoded
	OS.shell_open(url)

func _on_select_pressed() -> void:
	AudioManager.play_sound("dash")
	get_tree().change_scene_to_file("res://scenes/ui/StageSelectScreen.tscn")
