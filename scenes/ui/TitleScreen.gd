extends Control

# タイトル画面の「奥行き」と動的ビジュアル（JUICYビジュアル）を統合制御するスクリプト

var anim_time: float = 0.0
var koi_pos := Vector2(360, 600)
var koi_velocity := Vector2.ZERO
var target_koi_pos := Vector2(360, 600)
var koi_angle: float = 0.0
var is_transitioning: float = false
var transition_foam_y: float = 1300.0

@onready var layer1_waterfall: Control = $Layer1_Waterfall
@onready var layer2_cliffs: Control = $Layer2_Cliffs
@onready var layer3_interactive: Control = $Layer3_Interactive
@onready var ripple_effect: Control = $Layer3_Interactive/RippleEffect
@onready var layer4_ui: Control = $Layer4_UI
@onready var layer5_foreground: Control = $Layer5_Foreground
@onready var start_btn: Button = $Layer4_UI/VBox/StartButton
@onready var select_btn: Button = $Layer4_UI/VBox/SelectButton

var koi_texture: Texture2D

func _ready() -> void:
	if ResourceLoader.exists("res://assets/svg/player_koi.svg"):
		koi_texture = load("res://assets/svg/player_koi.svg")
		
	if is_instance_valid(layer3_interactive):
		layer3_interactive.draw.connect(func(): draw_koi(layer3_interactive))
		
	start_btn.pressed.connect(_on_start_pressed)
	if is_instance_valid(select_btn):
		select_btn.pressed.connect(_on_select_pressed)
	if ripple_effect and ripple_effect.has_signal("tapped"):
		ripple_effect.tapped.connect(_on_screen_tapped)
		
	# クリア進捗の集計と表示
	if layer4_ui.has_node("ProgressLabel"):
		var cleared_count = 0
		for i in range(1, 11):
			if GameManager.get_best_time(i) <= 900.0:
				cleared_count += 1
		layer4_ui.get_node("ProgressLabel").text = "👑 クリア進捗: %d / 10 ステージ" % cleared_count
		
	GameManager.set_state(GameManager.GameState.TITLE)

func _on_screen_tapped(pos: Vector2) -> void:
	target_koi_pos = pos

func _process(delta: float) -> void:
	anim_time += delta
	
	# タイトルとサブタイトルの動的浮遊（呼吸アニメーション）
	if is_instance_valid(layer4_ui):
		if layer4_ui.has_node("TitleLabel"):
			layer4_ui.get_node("TitleLabel").position.y = 120.0 + sin(anim_time * 2.2) * 6.0
		if layer4_ui.has_node("SubTitleLabel"):
			layer4_ui.get_node("SubTitleLabel").position.y = 210.0 + sin(anim_time * 2.2 - 0.6) * 4.0
	
	# パララックス（視差）効果の計算
	var mouse_pos = get_viewport().get_mouse_position()
	var center_offset = mouse_pos - Vector2(360, 640)
	
	if is_instance_valid(layer1_waterfall):
		var bg_node = layer1_waterfall.get_node_or_null("WaterfallBackground")
		if bg_node:
			bg_node.position = bg_node.position.lerp(-center_offset * 0.005, delta * 5.0)
		else:
			layer1_waterfall.position = layer1_waterfall.position.lerp(-center_offset * 0.005, delta * 5.0)
			layer1_waterfall.queue_redraw()
			
	# Layer2_CliffsはWaterfallBackgroundに含まれるようになったため、非表示/位置のみ補正
	if is_instance_valid(layer2_cliffs):
		layer2_cliffs.position = layer2_cliffs.position.lerp(-center_offset * 0.02, delta * 5.0)
		
	if is_instance_valid(layer5_foreground):
		layer5_foreground.position = layer5_foreground.position.lerp(-center_offset * 0.04, delta * 5.0)
		
	# 鯉（コイノスケ）のなめらかな移動ロジック
	var dist = koi_pos.distance_to(target_koi_pos)
	if dist > 15.0:
		var dir = (target_koi_pos - koi_pos).normalized()
		koi_velocity = koi_velocity.lerp(dir * min(dist * 2.5, 380.0), delta * 4.0)
		koi_angle = lerp_angle(koi_angle, koi_velocity.angle(), delta * 8.0)
	else:
		# 待機中は退屈そうにゆらゆら泳ぐ
		var wander = Vector2(sin(anim_time * 1.5) * 40.0, cos(anim_time * 2.0) * 20.0)
		target_koi_pos = Vector2(360, 600) + wander
		koi_velocity = koi_velocity.lerp(Vector2.ZERO, delta * 2.0)
		koi_angle = lerp_angle(koi_angle, sin(anim_time * 2.0) * 0.3, delta * 4.0)
		
	koi_pos += koi_velocity * delta
	if is_instance_valid(layer3_interactive):
		layer3_interactive.queue_redraw()
		
	if is_transitioning:
		queue_redraw()



# レイヤー3：緋鯉描画
func draw_koi(canvas: CanvasItem) -> void:
	if koi_texture:
		canvas.draw_set_transform(koi_pos, koi_angle + PI/2.0, Vector2(1.2, 1.2))
		canvas.draw_texture(koi_texture, -koi_texture.get_size() / 2.0)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		# 代替の美麗な緋鯉描画
		canvas.draw_set_transform(koi_pos, koi_angle, Vector2.ONE)
		canvas.draw_circle(Vector2.ZERO, 22.0, Color("#FCFCFC")) # 白練
		canvas.draw_circle(Vector2(6, -4), 14.0, Color("#D13438")) # 真朱の模様
		canvas.draw_circle(Vector2(14, 0), 8.0, Color("#FCFCFC")) # 頭
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# 画面遷移：「滝登りフェード」
func _on_start_pressed() -> void:
	if is_transitioning:
		return
	_start_waterfall_climb_transition("res://scenes/ui/StageSelectScreen.tscn")

func _on_select_pressed() -> void:
	if is_transitioning:
		return
	_start_waterfall_climb_transition("res://scenes/ui/StageSelectScreen.tscn")

func _start_waterfall_climb_transition(target_scene: String) -> void:
	is_transitioning = true
	AudioManager.play_sound("drum")
	
	# UIボタンがサッと退場
	var tween_ui = create_tween().set_parallel(true).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween_ui.tween_property(start_btn, "position:x", -600.0, 0.35)
	if is_instance_valid(select_btn):
		tween_ui.tween_property(select_btn, "position:x", 800.0, 0.35)
	if layer4_ui.has_node("TitleLabel"):
		tween_ui.tween_property(layer4_ui.get_node("TitleLabel"), "modulate:a", 0.0, 0.3)
	if layer4_ui.has_node("SubTitleLabel"):
		tween_ui.tween_property(layer4_ui.get_node("SubTitleLabel"), "modulate:a", 0.0, 0.3)
	
	await get_tree().create_timer(0.15).timeout
	AudioManager.play_sound("waterfall_rise")
	
	# 白い泡の波頭が下から上へ一気にスクロール
	transition_foam_y = 1300.0
	var tween_foam = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween_foam.tween_property(self, "transition_foam_y", -150.0, 0.65)
	
	await tween_foam.finished
	get_tree().change_scene_to_file(target_scene)

func _draw() -> void:
	if is_transitioning and transition_foam_y < 1300.0:
		# 画面下部から昇り上がってくる白い泡（白練色 ＋ 水しぶき効果）
		draw_rect(Rect2(0, transition_foam_y, 720, 1400), Color("#FCFCFC"))
		for i in range(12):
			var rx = float(i) * 65.0 + 30.0
			var ry = transition_foam_y + sin(anim_time * 20.0 + float(i)) * 25.0
			draw_circle(Vector2(rx, ry), 50.0, Color("#FCFCFC"))
