extends Control

func _ready() -> void:
	$VBox/NextButton.pressed.connect(_on_next_pressed)
	$VBox/ReplayButton.pressed.connect(_on_replay_pressed)
	$VBox/SelectButton.pressed.connect(_on_select_pressed)
	$VBox/SubButtonBox/ShareIconButton.pressed.connect(_on_share_icon_pressed)
	
	$SharePopup/PopupCard/Margin/PopupVBox/SaveVideoButton.pressed.connect(_on_save_video_pressed)
	$SharePopup/PopupCard/Margin/PopupVBox/ShareButton.pressed.connect(_on_share_pressed)
	$SharePopup/PopupCard/Margin/PopupVBox/CloseButton.pressed.connect(_close_share_popup)
	$SharePopup/Overlay.gui_input.connect(_on_overlay_gui_input)
	
	$SharePopup.visible = false
	
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color("#111A2E")
	card_style.border_color = Color("#F1C40F")
	card_style.set_border_width_all(3)
	card_style.set_corner_radius_all(14)
	card_style.shadow_color = Color(0, 0, 0, 0.6)
	card_style.shadow_size = 12
	$SharePopup/PopupCard.add_theme_stylebox_override("panel", card_style)
	
	var juicy_script = load("res://scenes/ui/juicy_button.gd")
	if juicy_script:
		for child in $VBox.get_children():
			if child is Button:
				child.set_script(juicy_script)
		if $VBox/SubButtonBox/ShareIconButton is Button:
			$VBox/SubButtonBox/ShareIconButton.set_script(juicy_script)
		for child in $SharePopup/PopupCard/Margin/PopupVBox.get_children():
			if child is Button:
				child.set_script(juicy_script)
				
	_setup_result_display()
	GameManager.set_state(GameManager.GameState.RESULT)

func _setup_result_display() -> void:
	var stage_name = "STAGE %d" % GameManager.current_stage_id
	if GameManager.is_stage_failed:
		$HeaderLabel.text = "💀 挑戦失敗 / TIME UP 💀"
		$HeaderLabel.modulate = Color("#E74C3C")
		$StageNameLabel.text = "無念の脱落: %s" % stage_name
		$StageNameLabel.modulate = Color("#E74C3C")
		$TimeLabel.text = "結果: スタミナ切れ / タイムオーバー"
		$ScoreLabel.text = "獲得スコア: %d PTS" % GameManager.last_score
		$RankLabel.text = "評価: 無念 (ダッシュの使い所とスタミナ管理を見極めよ！)"
		$RankLabel.add_theme_font_size_override("font_size", 26)
		$VBox/NextButton.visible = false
		if has_node("ConfettiParticles"):
			$ConfettiParticles.emitting = false
	else:
		$HeaderLabel.text = "🎉 STAGE CLEAR! 龍門突破 🎉"
		$HeaderLabel.modulate = Color("#F1C40F")
		$StageNameLabel.modulate = Color.WHITE
		$StageNameLabel.text = "クリアステージ: %s" % stage_name
		$TimeLabel.text = "クリアタイム: %05.2f 秒" % GameManager.last_clear_time
		$ScoreLabel.text = "スコア: %d PTS" % GameManager.last_score
		var stars = "★".repeat(GameManager.last_rank) + "☆".repeat(3 - GameManager.last_rank)
		$RankLabel.text = "評価: " + stars
		$RankLabel.add_theme_font_size_override("font_size", 44)
		$VBox/NextButton.visible = true
		if has_node("ConfettiParticles"):
			$ConfettiParticles.emitting = true
			
	_play_staggered_reveal()

func _play_staggered_reveal() -> void:
	# 要素の初期状態セット
	for lbl in [$HeaderLabel, $StageNameLabel, $TimeLabel, $ScoreLabel, $RankLabel]:
		lbl.modulate.a = 0.0
	$VBox.modulate.a = 0.0
	$HeaderLabel.scale = Vector2(2.0, 2.0)
	$HeaderLabel.pivot_offset = $HeaderLabel.size / 2.0
	
	# スタッガード（順次スタンプ）アニメーション
	var tween = create_tween().set_parallel(true)
	
	# Header 登場 (0.0s)
	tween.tween_property($HeaderLabel, "modulate:a", 1.0, 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_property($HeaderLabel, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Stage & Time 登場 (0.25s)
	tween.tween_property($StageNameLabel, "modulate:a", 1.0, 0.35).set_delay(0.25)
	tween.tween_property($TimeLabel, "modulate:a", 1.0, 0.35).set_delay(0.45)
	tween.tween_property($ScoreLabel, "modulate:a", 1.0, 0.35).set_delay(0.65)
	
	# Rank スタンプ (0.85s)
	$RankLabel.scale = Vector2(1.8, 1.8)
	$RankLabel.pivot_offset = $RankLabel.size / 2.0
	tween.tween_property($RankLabel, "modulate:a", 1.0, 0.3).set_delay(0.85)
	tween.tween_property($RankLabel, "scale", Vector2(1.0, 1.0), 0.35).set_delay(0.85).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	
	# Action Buttons 登場 (1.1s)
	tween.tween_property($VBox, "modulate:a", 1.0, 0.4).set_delay(1.1)

func _on_next_pressed() -> void:
	AudioManager.play_sound("dash")
	if not GameManager.is_custom_stage and GameManager.current_stage_id < 10:
		GameManager.start_stage(GameManager.current_stage_id + 1)
	else:
		GameManager.start_stage(GameManager.current_stage_id)

func _on_replay_pressed() -> void:
	AudioManager.play_sound("orb")
	GameManager.start_stage(GameManager.current_stage_id)

func _on_save_video_pressed() -> void:
	AudioManager.play_sound("orb")
	WebBridge.stop_and_download_video()
	_close_share_popup()

func _on_share_pressed() -> void:
	AudioManager.play_sound("clear")
	var stage_name = "STAGE %d" % GameManager.current_stage_id
	var text = ""
	if GameManager.is_stage_failed:
		text = "🌊 激流アクション『登竜門！爆走コイキング』\n%s で無念のタイムアップ！ 🐉\n次こそは激流を制し、龍へと昇る！\n#コイの滝登り #GodotEngine https://unityroom.com" % stage_name
	else:
		var time_str = "%05.2f" % GameManager.last_clear_time
		text = "🌊 激流アクション『登竜門！爆走コイキング』\n%s をクリア！ 🐉\nクリアタイム：%s秒\n激流を駆け上がる、魂のコイ登りアクション！\n#コイの滝登り #GodotEngine https://unityroom.com" % [stage_name, time_str]
	var encoded = text.uri_encode()
	var url = "https://twitter.com/intent/tweet?text=" + encoded
	OS.shell_open(url)
	_close_share_popup()

func _on_select_pressed() -> void:
	AudioManager.play_sound("dash")
	get_tree().change_scene_to_file("res://scenes/ui/StageSelectScreen.tscn")

func _on_share_icon_pressed() -> void:
	AudioManager.play_sound("orb")
	_open_share_popup()

func _open_share_popup() -> void:
	$SharePopup.visible = true
	$SharePopup/Overlay.modulate.a = 0.0
	var card = $SharePopup/PopupCard
	card.scale = Vector2(0.6, 0.6)
	card.pivot_offset = card.size / 2.0
	card.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property($SharePopup/Overlay, "modulate:a", 1.0, 0.25)
	tween.tween_property(card, "modulate:a", 1.0, 0.25)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _close_share_popup() -> void:
	if not $SharePopup.visible:
		return
	var card = $SharePopup/PopupCard
	card.pivot_offset = card.size / 2.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property($SharePopup/Overlay, "modulate:a", 0.0, 0.2)
	tween.tween_property(card, "modulate:a", 0.0, 0.2)
	tween.tween_property(card, "scale", Vector2(0.8, 0.8), 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(func(): $SharePopup.visible = false)

func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		AudioManager.play_sound("orb")
		_close_share_popup()
