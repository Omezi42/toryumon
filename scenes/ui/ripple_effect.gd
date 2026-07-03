# ripple_effect.gd
# タイトル画面の背景ノード（Node2D/Control）に貼ることで、水紋と飛沫を動的描画します。
extends Control

signal tapped(pos: Vector2)

class Ripple:
	var position: Vector2
	var radius: float = 0.0
	var max_radius: float = 130.0
	var alpha: float = 0.9
	var speed: float = 260.0 # 1秒間に広がるピクセル数

class Sparkle:
	var position: Vector2
	var velocity: Vector2
	var radius: float = 4.0
	var alpha: float = 1.0
	var color: Color

var ripples: Array[Ripple] = []
var sparkles: Array[Sparkle] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _gui_input(event: InputEvent) -> void:
	_handle_input(event)

func _unhandled_input(event: InputEvent) -> void:
	_handle_input(event)

func _handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		spawn_ripple(event.position)

func spawn_ripple(pos: Vector2) -> void:
	var new_ripple = Ripple.new()
	new_ripple.position = pos
	ripples.append(new_ripple)
	
	# 水しぶきの輝き（スパークル粒子）を8〜12個放出
	for i in range(10):
		var sp = Sparkle.new()
		sp.position = pos
		var angle = randf() * TAU
		var spd = randf_range(60.0, 180.0)
		sp.velocity = Vector2(cos(angle), sin(angle)) * spd
		sp.radius = randf_range(2.0, 5.5)
		sp.color = Color("#FCFCFC") if randf() > 0.4 else Color("#F1C40F") # 白練と黄金
		sparkles.append(sp)
		
	AudioManager.play_sound("hover_drop")
	tapped.emit(pos)

func _process(delta: float) -> void:
	var needs_redraw = false
	
	if not ripples.is_empty():
		needs_redraw = true
		var to_remove = []
		for ripple in ripples:
			ripple.radius += ripple.speed * delta
			ripple.alpha = 1.0 - (ripple.radius / ripple.max_radius)
			if ripple.radius >= ripple.max_radius:
				to_remove.append(ripple)
		for r in to_remove:
			ripples.erase(r)
			
	if not sparkles.is_empty():
		needs_redraw = true
		var to_remove_sp = []
		for sp in sparkles:
			sp.position += sp.velocity * delta
			sp.velocity *= 0.92 # 抵抗で減速
			sp.alpha -= delta * 1.8
			if sp.alpha <= 0.0:
				to_remove_sp.append(sp)
		for s in to_remove_sp:
			sparkles.erase(s)
			
	if needs_redraw:
		queue_redraw()

func _draw() -> void:
	for ripple in ripples:
		# 和モダンに合わせた「白練色（純白）」の繊細な細い円を描く
		var color = Color(0.98, 0.98, 0.98, ripple.alpha)
		draw_arc(ripple.position, ripple.radius, 0.0, TAU, 64, color, 2.5, true)
		# 2重の波紋
		if ripple.radius > 25.0:
			var sub_color = Color(0.63, 0.85, 0.9, ripple.alpha * 0.6) # 白群色
			draw_arc(ripple.position, ripple.radius * 0.75, 0.0, TAU, 48, sub_color, 1.8, true)
			
	for sp in sparkles:
		var c = sp.color
		c.a = max(0.0, sp.alpha)
		draw_circle(sp.position, sp.radius * max(0.2, sp.alpha), c)
