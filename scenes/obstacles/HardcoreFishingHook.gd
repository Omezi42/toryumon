extends "res://scenes/obstacles/Obstacle.gd"

var is_struggling: bool = false
var target_player: Area2D = null
var struggle_progress: float = 0.0
var struggle_required: float = 100.0

func _ready() -> void:
	obstacle_type = "hook"

func scroll_update(delta: float, scroll_speed: float) -> void:
	if is_struggling and is_instance_valid(target_player):
		# プレイヤーを拘束している間、障害物もプレイヤーと一緒に少し下流へ下がる
		position.y += (scroll_speed * 1.3) * delta
		target_player.position.y = position.y
		
		# 脱出のための連打判定
		if Input.is_action_just_pressed("dash") or Input.is_action_just_pressed("lane_left") or Input.is_action_just_pressed("lane_right"):
			struggle_progress += 15.0
			AudioManager.play_sound("splash")
			# ぷるぷる揺れる演出
			position.x += randf_range(-6.0, 6.0)
			
		# 自然減算（連打をサボると戻る）
		struggle_progress = max(0.0, struggle_progress - 25.0 * delta)
		
		# 制限時間が激しく削られる焦燥ギミック
		var stage = target_player.get_parent()
		if stage and "elapsed_time" in stage:
			stage.elapsed_time += delta * 2.5
		
		if struggle_progress >= struggle_required:
			_release_player()
	else:
		position.y += scroll_speed * delta
		
	if position.y > 850.0:
		if is_struggling and is_instance_valid(target_player):
			target_player.take_damage()
		queue_free()
	queue_redraw()

func catch_player(player: Area2D) -> void:
	if is_struggling:
		return
	is_struggling = true
	target_player = player
	struggle_progress = 0.0
	
	# プレイヤーの自由操作を奪う（スタン状態にする）
	player.hook_stun_timer = 999.0 # 無限スタン（脱出するまで）
	player.is_dashing = false
	AudioManager.play_sound("hit")

func _release_player() -> void:
	if is_instance_valid(target_player):
		target_player.hook_stun_timer = 0.0 # スタン解除
		target_player.invincibility_timer = 1.0 # 少しの無敵時間
	is_struggling = false
	AudioManager.play_sound("clear")
	queue_free()

func _draw() -> void:
	# 釣り糸の描画
	draw_line(Vector2(0, -position.y), Vector2(0, -10), Color(0.9, 0.9, 0.9, 0.7), 2.0)
	# 鋭い黄金の鮎針
	draw_arc(Vector2(0, 4), 14.0, 0.0, PI * 1.3, 16, Color("#F1C40F"), 3.5)
	
	# 連打ゲージの描画（拘束中のみ頭上に表示してハラハラ感を煽る）
	if is_struggling:
		var ratio = struggle_progress / struggle_required
		# ゲージ背景
		draw_rect(Rect2(-40, -40, 80, 8), Color(0.1, 0.1, 0.1, 0.8))
		# ゲージ中身（燃えるイエローレッド）
		draw_rect(Rect2(-40, -40, 80 * ratio, 8), Color("#E74C3C").lerp(Color("#F1C40F"), ratio))
		# 連打表示テキスト
		draw_string(ThemeDB.fallback_font, Vector2(-40, -50), "ボタン連打で脱出!!", HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.YELLOW)
