extends Area2D

signal stamina_changed(current: float, max_val: float, is_exhausted: bool)
signal fever_changed(current: float, max_val: float, is_dragon: bool)
signal player_damaged()
signal player_teleported(new_lane: int)
signal obstacle_broken(pos: Vector2)

const LANE_X = {
	-1: 500.0,
	0: 640.0,
	1: 780.0
}
const BASE_Y = 540.0

var current_lane: int = 0
var target_x: float = 640.0

var max_stamina: float = 100.0
var stamina: float = 100.0
var is_exhausted: bool = false
var is_dashing: bool = false

var fever_gauge: float = 0.0
var max_fever: float = 100.0
var is_dragon_mode: bool = false
var dragon_timer: float = 0.0

var invincibility_timer: float = 0.0
var hook_stun_timer: float = 0.0
var confusion_timer: float = 0.0
var lane_cooldown: float = 0.0
var lane_speed_modifier: float = 1.0 # Affected by rapids / updraft

var anim_time: float = 0.0

func _ready() -> void:
	position = Vector2(LANE_X[0], BASE_Y)
	target_x = LANE_X[0]
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	anim_time += delta
	if hook_stun_timer > 0.0:
		hook_stun_timer -= delta
		queue_redraw()
		return
		
	if invincibility_timer > 0.0:
		invincibility_timer -= delta
	if lane_cooldown > 0.0:
		lane_cooldown -= delta
	if confusion_timer > 0.0:
		confusion_timer = max(0.0, confusion_timer - delta)
		
	if is_dragon_mode:
		dragon_timer -= delta
		if dragon_timer <= 0.0:
			is_dragon_mode = false
			fever_gauge = 0.0
			emit_signal("fever_changed", fever_gauge, max_fever, false)
			
	_handle_input(delta)
	_update_stamina(delta)
	
	# Smooth X position
	position.x = lerp(position.x, target_x, 18.0 * delta)
	# Smooth Y recovery / bobbing
	var target_y = BASE_Y + sin(anim_time * 8.0) * 4.0
	position.y = lerp(position.y, target_y, 12.0 * delta)
	
	if has_node("DashParticles"):
		$DashParticles.emitting = (is_dashing or is_dragon_mode) and hook_stun_timer <= 0.0
	
	# Record replay
	ReplayManager.log_input(anim_time, current_lane, is_dashing)
	queue_redraw()

func _handle_input(_delta: float) -> void:
	if lane_cooldown <= 0.0:
		var move_left = Input.is_action_just_pressed("lane_left")
		var move_right = Input.is_action_just_pressed("lane_right")
		
		# 混乱タイマーが作動している間、入力を完全に「逆転」させる！
		if confusion_timer > 0.0:
			var temp = move_left
			move_left = move_right
			move_right = temp
			
		if move_left and current_lane > -1:
			change_lane(current_lane - 1)
			lane_cooldown = 0.15
		elif move_right and current_lane < 1:
			change_lane(current_lane + 1)
			lane_cooldown = 0.15
		
	var dash_pressed = Input.is_action_pressed("dash")
	if dash_pressed and not is_exhausted and stamina > 5.0:
		if not is_dashing:
			AudioManager.play_sound("dash")
		is_dashing = true
	else:
		is_dashing = false

func change_lane(new_lane: int) -> void:
	current_lane = clamp(new_lane, -1, 1)
	target_x = LANE_X[current_lane]

func _update_stamina(delta: float) -> void:
	if is_dragon_mode:
		stamina = max_stamina
		is_exhausted = false
		emit_signal("stamina_changed", stamina, max_stamina, is_exhausted)
		return
		
	if is_dashing:
		stamina -= 38.0 * delta
		if stamina <= 0.0:
			stamina = 0.0
			is_exhausted = true
			is_dashing = false
	else:
		stamina += 15.0 * delta
		if stamina >= max_stamina:
			stamina = max_stamina
		if is_exhausted and stamina >= 35.0:
			is_exhausted = false
			
	emit_signal("stamina_changed", stamina, max_stamina, is_exhausted)

func get_speed_multiplier() -> float:
	if hook_stun_timer > 0.0:
		return -0.5 # Dragged backwards down the waterfall
	var mult = 1.0
	if is_dragon_mode:
		mult = 2.2
	elif is_dashing:
		mult = 1.5
	elif is_exhausted:
		mult = 0.65
	return mult * lane_speed_modifier

func apply_ufo_confusion(duration: float) -> void:
	confusion_timer = duration

func add_fever(amount: float) -> void:
	if is_dragon_mode:
		return
	fever_gauge = min(max_fever, fever_gauge + amount)
	if fever_gauge >= max_fever:
		is_dragon_mode = true
		dragon_timer = 6.0
		AudioManager.play_sound("clear")
	emit_signal("fever_changed", fever_gauge, max_fever, is_dragon_mode)

func take_damage() -> void:
	if is_dragon_mode or invincibility_timer > 0.0:
		return
	invincibility_timer = 1.2
	AudioManager.play_sound("hit")
	emit_signal("player_damaged")

func _on_area_entered(other: Area2D) -> void:
	if not other.has_method("get_obstacle_type"):
		return
	var type = other.get_obstacle_type()
	match type:
		"rock":
			take_damage()
		"breakable":
			if is_dashing or is_dragon_mode:
				AudioManager.play_sound("splash")
				emit_signal("obstacle_broken", other.global_position)
				other.destroy()
			else:
				take_damage()
		"monkey_rock":
			if is_dragon_mode or is_dashing:
				AudioManager.play_sound("splash")
				other.destroy()
			else:
				take_damage()
		"salmon":
			AudioManager.play_sound("hit")
			# Bounce to adjacent lane
			var bounce_lane = current_lane + (1 if current_lane <= 0 else -1)
			change_lane(bounce_lane)
			other.destroy()
		"hook":
			if is_dragon_mode:
				other.destroy()
			else:
				if other.has_method("catch_player"):
					other.catch_player(self)
				else:
					AudioManager.play_sound("hit")
					hook_stun_timer = 1.5
		"ufo_beam":
			if other.has_method("apply_ufo_warp"):
				other.apply_ufo_warp(self)
			else:
				AudioManager.play_sound("dash")
				var warp_lane = -current_lane if current_lane != 0 else (1 if randf() > 0.5 else -1)
				change_lane(warp_lane)
				emit_signal("player_teleported", current_lane)
				apply_ufo_confusion(2.5)
				other.destroy()
		"orb":
			AudioManager.play_sound("orb")
			add_fever(25.0)
			other.destroy()

func _draw() -> void:
	# 被弾時やスタン時の点滅演出
	if invincibility_timer > 0.0 and int(invincibility_timer * 15.0) % 2 == 0:
		return
		
	var tail_swing = sin(anim_time * (22.0 if is_dashing or is_dragon_mode else 12.0)) * 14.0
	var outline_color = Color("2c3e50") # 和モダン浮世絵輪郭線
	
	if is_dragon_mode:
		# 和モダン龍（ゴールド＆シアンオーラ＋力強い輪郭線）
		draw_circle(Vector2.ZERO, 38.0, Color("00ffff", 0.25)) # 神気オーラ
		
		# 胴体セグメント（尾から頭に向かって描画し、重なりを綺麗に）
		for i in range(4, -1, -1):
			var seg_y = float(i) * 16.0
			var seg_x = sin(anim_time * 14.0 - float(i) * 0.8) * 10.0
			var seg_pos = Vector2(seg_x, seg_y)
			var r = 18.0 - float(i) * 2.2
			draw_circle(seg_pos, r + 3.0, outline_color) # 輪郭
			draw_circle(seg_pos, r, Color("1abc9c") if i % 2 == 0 else Color("f1c40f")) # 鱗配色
			
		# 龍の頭部
		draw_circle(Vector2(0, -12), 21.0, outline_color)
		draw_circle(Vector2(0, -12), 18.0, Color("f39c12"))
		
		# 龍のヒゲ（力強い金色ライン）
		draw_line(Vector2(-12, -18), Vector2(-32, -35), outline_color, 4.5)
		draw_line(Vector2(-12, -18), Vector2(-32, -35), Color("f1c40f"), 2.5)
		draw_line(Vector2(12, -18), Vector2(32, -35), outline_color, 4.5)
		draw_line(Vector2(12, -18), Vector2(32, -35), Color("f1c40f"), 2.5)
		
		# 鋭い龍の眼（赤光）
		draw_circle(Vector2(-7, -16), 4.5, outline_color)
		draw_circle(Vector2(-7, -16), 3.0, Color("e74c3c"))
		draw_circle(Vector2(7, -16), 4.5, outline_color)
		draw_circle(Vector2(7, -16), 3.0, Color("e74c3c"))
	else:
		# フラット和モダン鯉（白・緋色 #e74c3c・濃紺 #2c3e50）
		var red_color = Color("e74c3c") if not is_exhausted else Color("7f8c8d")
		
		if is_dashing:
			draw_circle(Vector2.ZERO, 30.0, Color("e67e22", 0.35)) # ダッシュ気流オーラ
			
		# 尾ひれ（ポリゴン＋輪郭）
		var tail_pts = PackedVector2Array([
			Vector2(tail_swing * 0.4, 18.0),
			Vector2(tail_swing - 14.0, 46.0),
			Vector2(tail_swing + 14.0, 46.0)
		])
		draw_colored_polygon(tail_pts, red_color)
		var tail_outline = tail_pts
		tail_outline.append(tail_pts[0])
		draw_polyline(tail_outline, outline_color, 3.0, true)
		
		# 胴体（白ベースの楕円調ポリゴン）
		var body_pts = PackedVector2Array([
			Vector2(0, -28), Vector2(16, -10), Vector2(16, 12),
			Vector2(0, 24), Vector2(-16, 12), Vector2(-16, -10)
		])
		draw_colored_polygon(body_pts, Color.WHITE)
		
		# 緋鯉の赤い模様（フラットベタ塗り）
		var pattern_pts = PackedVector2Array([
			Vector2(-14, -12), Vector2(14, -12), Vector2(12, 6), Vector2(-12, 6)
		])
		draw_colored_polygon(pattern_pts, red_color)
		draw_circle(Vector2(0, -20), 7.0, red_color)
		
		# 胸ひれ（左右）
		var left_fin = PackedVector2Array([Vector2(-14, -4), Vector2(-30, 6), Vector2(-14, 12)])
		var right_fin = PackedVector2Array([Vector2(14, -4), Vector2(30, 6), Vector2(14, 12)])
		draw_colored_polygon(left_fin, Color.WHITE)
		draw_colored_polygon(right_fin, Color.WHITE)
		var l_fin_out = left_fin; l_fin_out.append(left_fin[0])
		var r_fin_out = right_fin; r_fin_out.append(right_fin[0])
		draw_polyline(l_fin_out, outline_color, 2.5, true)
		draw_polyline(r_fin_out, outline_color, 2.5, true)
		
		# 胴体の外枠（浮世絵風輪郭線）
		var body_outline = body_pts
		body_outline.append(body_pts[0])
		draw_polyline(body_outline, outline_color, 3.5, true)
		
		# 鯉の目
		draw_circle(Vector2(-6, -20), 3.0, outline_color)
		draw_circle(Vector2(6, -20), 3.0, outline_color)
		
		if hook_stun_timer > 0.0:
			# スタン時のピヨピヨ演出（黄色い星マーク風ライン）
			draw_line(Vector2(-12, -36), Vector2(12, -36), Color("f1c40f"), 3.0)
			draw_line(Vector2(-6, -42), Vector2(6, -30), Color("f1c40f"), 3.0)
		if confusion_timer > 0.0:
			draw_string(ThemeDB.fallback_font, Vector2(-45, -45), "❓左右反転❓", HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color("#9B59B6"))
