extends Node2D

var anim_time: float = 0.0
var particles_data: Array = []

func _ready() -> void:
	AudioManager.play_sound("hit")
	AudioManager.play_sound("splash")
	
	# Create CPU particles for juicy splash
	var p = CPUParticles2D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = 45
	p.lifetime = 0.85
	p.explosiveness = 0.95
	p.spread = 180.0
	p.initial_velocity_min = 280.0
	p.initial_velocity_max = 520.0
	p.gravity = Vector2(0, 650)
	p.scale_amount_min = 6.0
	p.scale_amount_max = 14.0
	p.color = Color("#E74C3C") # Wa-modern crimson
	add_child(p)
	p.emitting = true
	
	var p2 = CPUParticles2D.new()
	p2.emitting = false
	p2.one_shot = true
	p2.amount = 35
	p2.lifetime = 0.95
	p2.explosiveness = 0.9
	p2.spread = 180.0
	p2.initial_velocity_min = 200.0
	p2.initial_velocity_max = 380.0
	p2.gravity = Vector2(0, 550)
	p2.scale_amount_min = 4.0
	p2.scale_amount_max = 9.0
	p2.color = Color("#F1C40F") # Wa-modern gold
	add_child(p2)
	p2.emitting = true
	
	# Also generate custom drawn debris (koi scales & fragments)
	for i in range(20):
		var ang = randf() * TAU
		var spd = randf_range(220.0, 580.0)
		particles_data.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"rot": randf() * TAU,
			"rot_spd": randf_range(-12.0, 12.0),
			"size": randf_range(8.0, 18.0),
			"color": Color("#E74C3C") if i % 2 == 0 else Color("#FFFFFF")
		})

func _process(delta: float) -> void:
	anim_time += delta
	for p in particles_data:
		p["pos"] += p["vel"] * delta
		p["vel"].y += 680.0 * delta # gravity
		p["rot"] += p["rot_spd"] * delta
	queue_redraw()
	
	if anim_time >= 1.6:
		queue_free()

func _draw() -> void:
	var alpha = max(0.0, 1.0 - (anim_time / 1.3))
	for p in particles_data:
		var c = p["color"]
		c.a = alpha
		draw_set_transform(p["pos"], p["rot"], Vector2.ONE)
		var s = p["size"]
		# Draw koi scale fragment
		var pts = PackedVector2Array([Vector2(-s/2.0, -s/2.0), Vector2(s/2.0, -s/2.0), Vector2(0, s/2.0)])
		draw_colored_polygon(pts, c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
