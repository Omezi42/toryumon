extends Control

var anim_time: float = 0.0

var stage_titles = [
	"1. 始まりの滝 (岩とレーン移動)",
	"2. 逆風と急流 (レーン変化)",
	"3. 落石注意の崖 (サルの投石)",
	"4. サケ飛び交う急流 (クマのサケ)",
	"5. 釣り人の縄張り (釣り針)",
	"6. 未知との遭遇 (UFOワープ)",
	"7. サルの悪巧み (投石＋急流)",
	"8. クマと釣り針の迷宮 (複合)",
	"9. カオスの急流滝 (全ギミック)",
	"10. 登竜門 (最難関・覚醒)"
]

func _ready() -> void:
	if has_node("BackButton"):
		$BackButton.pressed.connect(_on_back_pressed)
	_populate_stages()
	GameManager.set_state(GameManager.GameState.STAGE_SELECT)

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

func _draw() -> void:
	# 背景の美しい縦流動ストリームライン（深遠な清流）
	for i in range(16):
		var x = float(i) * 46.0 + 15.0
		var y = fmod(anim_time * 180.0 + float(i * 130), 1380.0) - 40.0
		var stream_color = Color("#71C5E8") if i % 2 == 0 else Color("#A1D8E6")
		stream_color.a = 0.15 + sin(anim_time * 2.0 + float(i)) * 0.08
		draw_line(Vector2(x, y), Vector2(x, y + 90.0), stream_color, 2.0)

func _populate_stages() -> void:
	var grid: GridContainer = null
	if has_node("ScrollContainer/GridContainer"):
		grid = $ScrollContainer/GridContainer
	elif has_node("GridContainer"):
		grid = $GridContainer
	if not grid:
		return
	for child in grid.get_children():
		child.queue_free()
		
	var cleared_count = 0
	var total_stars = 0
	var juicy_script = load("res://scenes/ui/juicy_button.gd")
	
	# スタイルボックスの構築
	var style_cleared = StyleBoxFlat.new()
	style_cleared.bg_color = Color("#14283c")
	style_cleared.border_color = Color("#F1C40F") # 黄金色
	style_cleared.set_border_width_all(2)
	style_cleared.set_corner_radius_all(6)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color("#0e1e2d")
	style_normal.border_color = Color(0.8, 0.85, 0.9, 0.5)
	style_normal.set_border_width_all(1)
	style_normal.set_corner_radius_all(6)
	
	for i in range(1, 11):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(620, 86)
		var best = GameManager.get_best_time(i)
		
		var stars_str = "☆☆☆"
		var best_str = "--.--秒"
		var prefix = "🌊 "
		
		if best <= 900.0:
			cleared_count += 1
			best_str = "%05.2f秒" % best
			prefix = "👑 "
			var rank = 1
			if best <= 25.0:
				rank = 3
			elif best <= 30.0:
				rank = 2
			total_stars += rank
			stars_str = "★".repeat(rank) + "☆".repeat(3 - rank)
			btn.add_theme_stylebox_override("normal", style_cleared)
		else:
			btn.add_theme_stylebox_override("normal", style_normal)
			
		btn.text = "%s%s\n評価: %s  |  ベスト: %s" % [prefix, stage_titles[i - 1], stars_str, best_str]
		btn.add_theme_font_size_override("font_size", 19)
		
		if juicy_script:
			btn.set_script(juicy_script)
			
		btn.pressed.connect(_on_stage_btn_pressed.bind(i))
		
		# リッチでJUICYなスタッガード（時間差）バウンド出現アニメーション
		btn.modulate.a = 0.0
		btn.scale = Vector2(0.8, 0.8)
		grid.add_child(btn)
		
		var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(btn, "modulate:a", 1.0, 0.35).set_delay(float(i) * 0.035)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.35).set_delay(float(i) * 0.035)
		
	if has_node("ProgressHeader"):
		$ProgressHeader.text = "👑 クリア進捗: %d / 10 ステージ   |   ★ 獲得スター: %d / 30" % [cleared_count, total_stars]

func _on_stage_btn_pressed(stage_id: int) -> void:
	AudioManager.play_sound("dash")
	GameManager.start_stage(stage_id)

func _on_back_pressed() -> void:
	AudioManager.play_sound("dash")
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
