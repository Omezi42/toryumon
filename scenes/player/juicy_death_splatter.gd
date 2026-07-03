# juicy_death_splatter.gd
# プレイヤーが障害物に激突した瞬間にスポーンさせるエフェクト
extends Node2D

func _ready() -> void:
	# 決定打の和太鼓＆炸裂クラッシュ音を鳴らす
	AudioManager.play_sound("hit")
	AudioManager.play_sound("drum")
	
	# 1. 純白の激しい水しぶき
	var water_spurt = _create_spurt(Color("#FCFCFC"), 28, 1.2, 280.0)
	add_child(water_spurt)
	
	# 2. 朱色のウロコ
	var scale_spurt = _create_spurt(Color("#E74C3C"), 16, 0.9, 220.0)
	scale_spurt.scale_amount_min = 0.4
	scale_spurt.scale_amount_max = 0.8
	add_child(scale_spurt)
	
	# 3. 黄金のフィーバーオーブ四散（ジュース感の最大化）
	var coin_spurt = _create_spurt(Color("#F1C40F"), 12, 1.5, 340.0)
	add_child(coin_spurt)
	
	# 画面を激しく揺らす（カメラシェイク）
	_shake_camera()
	
	# パーティクルの放出が終わったら自動消去
	await get_tree().create_timer(1.6).timeout
	queue_free()

func _create_spurt(color: Color, count: int, lifetime: float, velocity: float) -> CPUParticles2D:
	var p = CPUParticles2D.new()
	p.amount = count
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = lifetime
	p.spread = 180.0 # 全方向に爆散
	p.direction = Vector2.DOWN # 重力で下に落ちる
	p.gravity = Vector2(0, 500)
	p.initial_velocity_min = velocity * 0.6
	p.initial_velocity_max = velocity
	p.damping_min = 10.0
	p.damping_max = 30.0
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.7
	p.color = color
	
	# 円形テクスチャの動的割り当て（画像不要）
	if ResourceLoader.exists("res://assets/svg/shironeri_drop.svg"):
		p.texture = load("res://assets/svg/shironeri_drop.svg")
		
	p.emitting = true
	return p

func _shake_camera() -> void:
	var cam = get_viewport().get_camera_2d()
	if cam:
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		for i in range(5):
			var offset = Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))
			tween.tween_property(cam, "offset", offset, 0.05)
		tween.tween_property(cam, "offset", Vector2.ZERO, 0.1)
