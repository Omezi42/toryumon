extends CanvasLayer

@export var stage_controller_path: NodePath
var controller: Node2D
var player: Area2D

var notified_halfway: bool = false
var banner_node: Label = null

func _ready() -> void:
	if get_parent() and "target_time" in get_parent():
		controller = get_parent()
	elif has_node("../StageController"):
		controller = get_node("../StageController")
		
	if controller and controller.has_node("Player"):
		player = controller.get_node("Player")
	elif has_node("../Player"):
		player = get_node("../Player")
		
	# Setup touch / mouse UI buttons
	$LeftButton.pressed.connect(_on_left_pressed)
	$RightButton.pressed.connect(_on_right_pressed)
	$DashButton.button_down.connect(_on_dash_down)
	$DashButton.button_up.connect(_on_dash_up)
	$PauseButton.pressed.connect(_on_pause_pressed)
	
	# 和モダン・グラスモーフパネルのスタイリング
	var glass_style = StyleBoxFlat.new()
	glass_style.bg_color = Color(0.06, 0.14, 0.24, 0.85) # 半透明インディゴ
	glass_style.border_color = Color(0.95, 0.77, 0.06, 0.85) # 和モダンの金縁
	glass_style.set_border_width_all(2)
	glass_style.set_corner_radius_all(10)
	glass_style.expand_margin_left = 6
	glass_style.expand_margin_right = 6
	glass_style.expand_margin_top = 6
	glass_style.expand_margin_bottom = 6
	
	if has_node("LeftPanel"):
		$LeftPanel.add_theme_stylebox_override("panel", glass_style)
	if has_node("RightPanel"):
		$RightPanel.add_theme_stylebox_override("panel", glass_style)
		
	# バーのカラーカスタマイズ
	var style_bar_bg = StyleBoxFlat.new()
	style_bar_bg.bg_color = Color("#112233")
	style_bar_bg.set_corner_radius_all(4)
	
	var style_stamina_fill = StyleBoxFlat.new()
	style_stamina_fill.bg_color = Color("#2ECC71") # エメラルドグリーン
	style_stamina_fill.set_corner_radius_all(4)
	if has_node("LeftPanel/StaminaBar"):
		$LeftPanel/StaminaBar.add_theme_stylebox_override("background", style_bar_bg)
		$LeftPanel/StaminaBar.add_theme_stylebox_override("fill", style_stamina_fill)
		
	var juicy_script = load("res://scenes/ui/juicy_button.gd")
	for btn_name in ["LeftButton", "RightButton", "DashButton", "PauseButton"]:
		if has_node(btn_name) and juicy_script:
			get_node(btn_name).set_script(juicy_script)

func show_banner(text_str: String, color: Color) -> void:
	if not is_instance_valid(banner_node):
		banner_node = Label.new()
		banner_node.position = Vector2(60, -100)
		banner_node.custom_minimum_size = Vector2(600, 60)
		banner_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		banner_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		banner_node.add_theme_font_size_override("font_size", 28)
		banner_node.add_theme_color_override("font_outline_color", Color("#0A141E"))
		banner_node.add_theme_constant_override("outline_size", 8)
		add_child(banner_node)
		
	banner_node.text = text_str
	banner_node.modulate = color
	banner_node.position = Vector2(60, -80)
	banner_node.scale = Vector2(1.2, 0.8)
	
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(banner_node, "position:y", 240.0, 0.45)
	tween.tween_property(banner_node, "scale", Vector2(1.0, 1.0), 0.45)
	
	create_tween().tween_property(banner_node, "modulate:a", 0.0, 0.5).set_delay(2.0)

func _process(_delta: float) -> void:
	if not is_instance_valid(controller) or not is_instance_valid(player):
		if get_parent() and "target_time" in get_parent():
			controller = get_parent()
		elif has_node("../StageController"):
			controller = get_node("../StageController")
		if is_instance_valid(controller) and controller.has_node("Player"):
			player = controller.get_node("Player")
		elif has_node("../Player"):
			player = get_node("../Player")
		if not is_instance_valid(controller) or not is_instance_valid(player):
			return
		
	# Update Time & Progress
	var time_left = max(0.0, controller.target_time - controller.elapsed_time)
	$RightPanel/TimeLabel.text = "TIME: %05.2f / %02d" % [controller.elapsed_time, int(controller.target_time)]
	
	# 残り時間10秒以下で心音鼓動＆レッドアラート演出
	if time_left < 10.0:
		$RightPanel/TimeLabel.modulate = Color("#FF2A4B") if int(time_left * 8.0) % 2 == 0 else Color("#F1C40F")
		$RightPanel/TimeLabel.pivot_offset = $RightPanel/TimeLabel.size / 2.0
		var throb = 1.0 + sin(Time.get_ticks_msec() * 0.015) * 0.12
		$RightPanel/TimeLabel.scale = Vector2(throb, throb)
	else:
		$RightPanel/TimeLabel.modulate = Color.WHITE
		$RightPanel/TimeLabel.scale = Vector2.ONE
		
	var prog = clamp(controller.current_distance / max(1.0, controller.stage_length) * 100.0, 0.0, 100.0)
	$RightPanel/ProgressBar.value = prog
	
	if prog >= 50.0 and not notified_halfway:
		notified_halfway = true
		show_banner("🌊 中間地点突破！一気に登り切れ！ 🌊", Color("#00E5FF"))
		
	if $RightPanel/ScoreLabel.has_method("update_juicy_text"):
		$RightPanel/ScoreLabel.update_juicy_text("SCORE: %d" % controller.score, controller.score)
	else:
		$RightPanel/ScoreLabel.text = "SCORE: %d" % controller.score
	
	# Update Stamina
	$LeftPanel/StaminaBar.value = player.stamina
	if player.is_exhausted:
		$LeftPanel/StatusLabel.text = "⚠️ 息切れ中! (回復待機)"
		$LeftPanel/StatusLabel.modulate = Color.RED
	elif player.is_dashing:
		$LeftPanel/StatusLabel.text = "⚠️ 疲労困憊！ (スタミナ回復待ち)"
	elif player.dash_timer > 0.0:
		$LeftPanel/StatusLabel.text = "💨 登竜ダッシュ中！ (無敵 残り %.1f秒)" % player.dash_timer
	elif player.has_dashed:
		$LeftPanel/StatusLabel.text = " 通常状態 (ダッシュ使用済)"
		$LeftPanel/StatusLabel.modulate = Color("7f8c8d")
	else:
		$LeftPanel/StatusLabel.text = " 通常状態 (ダッシュ使用可)"
		$LeftPanel/StatusLabel.modulate = Color.WHITE
		
	if has_node("DashButton"):
		if player.dash_timer > 0.0:
			$DashButton.text = "💨 登竜ダッシュ中！\n(無敵 残り %.1f秒)" % player.dash_timer
			$DashButton.modulate = Color("00ffff")
		elif player.has_dashed:
			$DashButton.text = "💨 ダッシュ使用済\n(再使用不可)"
			$DashButton.modulate = Color("556677")
		else:
			$DashButton.text = "💨 登竜ダッシュ発動\n(3秒間無敵/1回限定)"
			$DashButton.disabled = false
			$DashButton.modulate = Color.WHITE
		


func _on_left_pressed() -> void:
	if player:
		player.change_lane(player.current_lane - 1)

func _on_right_pressed() -> void:
	if player:
		player.change_lane(player.current_lane + 1)

func _on_dash_down() -> void:
	if is_instance_valid(player) and player.has_method("trigger_dash"):
		player.trigger_dash()
	var ev = InputEventAction.new()
	ev.action = "dash"
	ev.pressed = true
	Input.parse_input_event(ev)

func _on_dash_up() -> void:
	var ev = InputEventAction.new()
	ev.action = "dash"
	ev.pressed = false
	Input.parse_input_event(ev)

func _on_pause_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
