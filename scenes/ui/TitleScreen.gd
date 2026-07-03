extends Control

# タイトル画面の「奥行き」と動的ビジュアル（JUICYビジュアル）を統合制御するスクリプト

var anim_time: float = 0.0
var koi_pos := Vector2(640, 480)
var koi_velocity := Vector2.ZERO
var target_koi_pos := Vector2(640, 480)
var koi_angle: float = 0.0
var is_transitioning: float = false
var transition_foam_y: float = 750.0

@onready var layer1_waterfall: Control = $Layer1_Waterfall
@onready var layer2_cliffs: Control = $Layer2_Cliffs
@onready var layer3_interactive: Control = $Layer3_Interactive
@onready var ripple_effect: Control = $Layer3_Interactive/RippleEffect
@onready var layer4_ui: Control = $Layer4_UI
@onready var layer5_foreground: Control = $Layer5_Foreground
@onready var start_btn: Button = $Layer4_UI/VBox/StartButton
@onready var editor_btn: Button = $Layer4_UI/VBox/EditorButton

var koi_texture: Texture2D

func _ready() -> void:
	if ResourceLoader.exists("res://assets/svg/player_koi.svg"):
		koi_texture = load("res://assets/svg/player_koi.svg")
		
	if is_instance_valid(layer1_waterfall):
		layer1_waterfall.draw.connect(func(): draw_waterfall(layer1_waterfall))
	if is_instance_valid(layer2_cliffs):
		layer2_cliffs.draw.connect(func(): draw_cliffs(layer2_cliffs))
	if is_instance_valid(layer3_interactive):
		layer3_interactive.draw.connect(func(): draw_koi(layer3_interactive))
		
	start_btn.pressed.connect(_on_start_pressed)
	editor_btn.pressed.connect(_on_editor_pressed)
	if ripple_effect and ripple_effect.has_signal("tapped"):
		ripple_effect.tapped.connect(_on_screen_tapped)
		
	GameManager.set_state(GameManager.GameState.TITLE)

func _on_screen_tapped(pos: Vector2) -> void:
	target_koi_pos = pos

func _process(delta: float) -> void:
	anim_time += delta
	
	# パララックス（視差）効果の計算
	var mouse_pos = get_viewport().get_mouse_position()
	var center_offset = mouse_pos - Vector2(640, 360)
	
	if is_instance_valid(layer1_waterfall):
		layer1_waterfall.position = layer1_waterfall.position.lerp(-center_offset * 0.005, delta * 5.0)
		layer1_waterfall.queue_redraw()
	if is_instance_valid(layer2_cliffs):
		layer2_cliffs.position = layer2_cliffs.position.lerp(-center_offset * 0.02, delta * 5.0)
		layer2_cliffs.queue_redraw()
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
		target_koi_pos = Vector2(640, 480) + wander
		koi_velocity = koi_velocity.lerp(Vector2.ZERO, delta * 2.0)
		koi_angle = lerp_angle(koi_angle, sin(anim_time * 2.0) * 0.3, delta * 4.0)
		
	koi_pos += koi_velocity * delta
	if is_instance_valid(layer3_interactive):
		layer3_interactive.queue_redraw()
		
	if is_transitioning:
		queue_redraw()

# レイヤー1：滝の高速流動描画
func draw_waterfall(canvas: CanvasItem) -> void:
	# 新橋色と藍墨色による滝背景
	canvas.draw_rect(Rect2(-50, -50, 1380, 820), Color("#1A212E"))
	for i in range(32):
		var x = float(i) * 42.0 - 20.0
		var y = fmod(anim_time * 450.0 + float(i * 110), 820.0) - 50.0
		var stream_color = Color("#46A0B0")
		stream_color.a = 0.25 + sin(float(i)) * 0.1
		canvas.draw_line(Vector2(x, y), Vector2(x, y + 140.0), stream_color, 4.0)

# レイヤー2：ゴツゴツした左右の岩崖描画
func draw_cliffs(canvas: CanvasItem) -> void:
	var cliff_color = Color("#0D1117")
	# 左側の崖
	var left_points = PackedVector2Array([
		Vector2(-30, -30), Vector2(160, -30), Vector2(120, 180),
		Vector2(180, 340), Vector2(110, 520), Vector2(190, 750), Vector2(-30, 750)
	])
	canvas.draw_polygon(left_points, PackedColorArray([cliff_color, cliff_color, cliff_color, cliff_color, cliff_color, cliff_color, cliff_color]))
	
	# 右側の崖
	var right_points = PackedVector2Array([
		Vector2(1310, -30), Vector2(1120, -30), Vector2(1160, 200),
		Vector2(1090, 380), Vector2(1170, 550), Vector2(1110, 750), Vector2(1310, 750)
	])
	canvas.draw_polygon(right_points, PackedColorArray([cliff_color, cliff_color, cliff_color, cliff_color, cliff_color, cliff_color, cliff_color]))

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

func _on_editor_pressed() -> void:
	if is_transitioning:
		return
	_start_waterfall_climb_transition("res://scenes/editor/StageEditorScreen.tscn")

func _start_waterfall_climb_transition(target_scene: String) -> void:
	is_transitioning = true
	AudioManager.play_sound("drum")
	
	# UIボタンが左右にサッと退場
	var tween_ui = create_tween().set_parallel(true).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween_ui.tween_property(start_btn, "position:x", -600.0, 0.35)
	tween_ui.tween_property(editor_btn, "position:x", 1400.0, 0.35)
	tween_ui.tween_property(layer4_ui.get_node("TitleLabel"), "modulate:a", 0.0, 0.3)
	tween_ui.tween_property(layer4_ui.get_node("SubTitleLabel"), "modulate:a", 0.0, 0.3)
	tween_ui.tween_property(layer4_ui.get_node("InfoLabel"), "modulate:a", 0.0, 0.3)
	
	await get_tree().create_timer(0.15).timeout
	AudioManager.play_sound("waterfall_rise")
	
	# 白い泡の波頭が下から上へ一気にスクロール
	transition_foam_y = 750.0
	var tween_foam = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween_foam.tween_property(self, "transition_foam_y", -150.0, 0.65)
	
	await tween_foam.finished
	get_tree().change_scene_to_file(target_scene)

func _draw() -> void:
	if is_transitioning and transition_foam_y < 750.0:
		# 画面下部から昇り上がってくる白い泡（白練色 ＋ 水しぶき効果）
		draw_rect(Rect2(0, transition_foam_y, 1280, 850), Color("#FCFCFC"))
		for i in range(16):
			var rx = float(i) * 80.0 + 40.0
			var ry = transition_foam_y + sin(anim_time * 20.0 + float(i)) * 25.0
			draw_circle(Vector2(rx, ry), 50.0, Color("#FCFCFC"))
