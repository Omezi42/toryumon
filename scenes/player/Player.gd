extends Area2D

signal stamina_changed(current: float, max_val: float, is_exhausted: bool)
signal player_damaged()
signal player_teleported(new_lane: int)
signal obstacle_broken(pos: Vector2)

const LANE_X = {
	-1: 190.0,
	0: 360.0,
	1: 530.0
}
const BASE_Y = 1000.0
var _custom_font: Font = preload("res://assets/fonts/default_font.tres")

var current_lane: int = 0
var target_x: float = 360.0

var max_stamina: float = 100.0
var stamina: float = 100.0
var is_exhausted: bool = false
var is_dashing: bool = false
var dash_used: bool = false
var dash_timer: float = 0.0


var invincibility_timer: float = 0.0
var hook_stun_timer: float = 0.0
var confusion_timer: float = 0.0
var lane_cooldown: float = 0.0
var lane_speed_modifier: float = 1.0 # Affected by rapids / updraft

var anim_time: float = 0.0
var touch_start_pos: Vector2 = Vector2.ZERO
var is_touching: bool = false

func _ready() -> void:
	position = Vector2(LANE_X[0], BASE_Y)
	target_x = LANE_X[0]
	area_entered.connect(_on_area_entered)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event.pressed:
			is_touching = true
			touch_start_pos = event.position
		else:
			is_touching = false
	elif (event is InputEventScreenDrag or (event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0)) and is_touching:
		var delta_x = event.position.x - touch_start_pos.x
		if abs(delta_x) > 55.0 and lane_cooldown <= 0.0:
			var move_left = delta_x < 0
			var move_right = delta_x > 0
			if confusion_timer > 0.0:
				var temp = move_left
				move_left = move_right
				move_right = temp
			if move_left and current_lane > -1:
				change_lane(current_lane - 1)
				lane_cooldown = 0.18
				touch_start_pos = event.position
			elif move_right and current_lane < 1:
				change_lane(current_lane + 1)
				lane_cooldown = 0.18
				touch_start_pos = event.position

func _process(delta: float) -> void:
	anim_time += delta
	if hook_stun_timer > 0.0:
		hook_stun_timer -= delta
		queue_redraw()
		return
		
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			dash_timer = 0.0
		
	if invincibility_timer > 0.0:
		invincibility_timer -= delta
	if lane_cooldown > 0.0:
		lane_cooldown -= delta
	if confusion_timer > 0.0:
		confusion_timer = max(0.0, confusion_timer - delta)
		
	_handle_input(delta)
	_update_stamina(delta)
	
	# Smooth X position
	position.x = lerp(position.x, target_x, 18.0 * delta)
	# Smooth Y recovery / bobbing
	var target_y = BASE_Y + sin(anim_time * 8.0) * 4.0
	position.y = lerp(position.y, target_y, 12.0 * delta)
	
	if has_node("DashParticles"):
		$DashParticles.emitting = is_dashing and hook_stun_timer <= 0.0
	
	# Record replay
	ReplayManager.log_input(anim_time, current_lane, is_dashing)
	queue_redraw()

func trigger_dash() -> void:
	if dash_used or is_dashing or hook_stun_timer > 0.0:
		return
	dash_used = true
	is_dashing = true
	dash_timer = 3.0
	AudioManager.play_sound("dash")

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
		
	if Input.is_action_just_pressed("dash"):
		trigger_dash()

func change_lane(new_lane: int) -> void:
	current_lane = clamp(new_lane, -1, 1)
	target_x = LANE_X[current_lane]

func _update_stamina(delta: float) -> void:
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
	if is_dashing:
		mult = 1.8
	elif is_exhausted:
		mult = 0.65
	return mult * lane_speed_modifier

func apply_ufo_confusion(duration: float) -> void:
	confusion_timer = duration

func take_damage() -> void:
	if is_dashing or invincibility_timer > 0.0:
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
			if is_dashing:
				AudioManager.play_sound("splash")
				emit_signal("obstacle_broken", other.global_position)
				other.destroy()
			else:
				take_damage()
		"breakable":
			if is_dashing:
				AudioManager.play_sound("splash")
				emit_signal("obstacle_broken", other.global_position)
				other.destroy()
			else:
				take_damage()
		"monkey_rock":
			if is_dashing:
				AudioManager.play_sound("splash")
				emit_signal("obstacle_broken", other.global_position)
				other.destroy()
			else:
				take_damage()
		"bear":
			if is_dashing:
				AudioManager.play_sound("splash")
				emit_signal("obstacle_broken", other.global_position)
				other.destroy()
			else:
				take_damage()
		"salmon":
			if is_dashing:
				AudioManager.play_sound("splash")
				emit_signal("obstacle_broken", other.global_position)
				other.destroy()
			else:
				take_damage()
		"hook":
			if is_dashing:
				AudioManager.play_sound("splash")
				emit_signal("obstacle_broken", other.global_position)
				other.destroy()
			else:
				if other.has_method("catch_player"):
					other.catch_player(self)
				else:
					AudioManager.play_sound("hit")
					hook_stun_timer = 1.5
		"ufo_beam":
			if is_dashing:
				AudioManager.play_sound("splash")
				emit_signal("obstacle_broken", other.global_position)
				other.destroy()
			else:
				if other.has_method("apply_ufo_warp"):
					other.apply_ufo_warp(self)
				else:
					AudioManager.play_sound("dash")
					var warp_lane = -current_lane if current_lane != 0 else (1 if randf() > 0.5 else -1)
					change_lane(warp_lane)
					emit_signal("player_teleported", current_lane)
					apply_ufo_confusion(2.5)
					other.destroy()

func _draw() -> void:
	# 被弾時やスタン時の点滅演出
	if invincibility_timer > 0.0 and int(invincibility_timer * 15.0) % 2 == 0:
		return
		
	var tail_swing = sin(anim_time * (22.0 if is_dashing else 12.0)) * 14.0
	var outline_color = Color("2c3e50") # 和モダン浮世絵輪郭線
	
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
		draw_string(_custom_font, Vector2(-45, -45), "❓左右反転❓", HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color("#9B59B6"))
