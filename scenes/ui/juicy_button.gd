# juicy_button.gd
# 触るだけで気持ちいいボタンのロジック。Buttonノードにアタッチして使用。
extends Button

@export var hover_scale := Vector2(1.08, 1.08)
@export var press_scale := Vector2(1.15, 0.85)
@export var original_scale := Vector2(1.0, 1.0)
@export var tween_duration := 0.15

func _ready() -> void:
	# ボタンのピボット（変形の中心点）を中央に設定
	pivot_offset = size / 2.0
	resized.connect(func(): pivot_offset = size / 2.0)
	
	# シグナルの接続
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

# マウスが乗った時（ぷっくり膨らむ）
func _on_mouse_entered() -> void:
	AudioManager.play_sound("hover_drop")
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", hover_scale, tween_duration)

# マウスが離れた時（元に戻る）
func _on_mouse_exited() -> void:
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", original_scale, tween_duration)

# 押し込んだ時（グッと潰れる）
func _on_button_down() -> void:
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", press_scale, 0.1)

# 指を離した時（バウンドしながら元に戻る）
func _on_button_up() -> void:
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(self, "scale", hover_scale, 0.2)
	_spawn_water_particles()

# ボタンの後ろから水しぶきを放出（手作業ゼロで華やかに）
func _spawn_water_particles() -> void:
	var particles = CPUParticles2D.new()
	if ResourceLoader.exists("res://assets/svg/shironeri_drop.svg"):
		particles.texture = load("res://assets/svg/shironeri_drop.svg")
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = 12
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(size.x * 0.4, size.y * 0.2)
	particles.position = size / 2.0
	particles.direction = Vector2(0, -1)
	particles.spread = 70.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 180.0
	particles.gravity = Vector2(0, 350)
	particles.scale_amount_min = 0.2
	particles.scale_amount_max = 0.6
	particles.color = Color(0.98, 0.98, 0.98, 0.95) # 白練色
	add_child(particles)
	particles.emitting = true
	
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(particles):
		particles.queue_free()
