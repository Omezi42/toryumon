# ripple_effect.gd
# タイトル画面の背景ノード（Node2D/Control）に貼ることで、水紋を動的描画します。
extends Control

signal tapped(pos: Vector2)

class Ripple:
	var position: Vector2
	var radius: float = 0.0
	var max_radius: float = 120.0
	var alpha: float = 0.8
	var speed: float = 250.0 # 1秒間に広がるピクセル数

var ripples: Array[Ripple] = []

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
	AudioManager.play_sound("hover_drop")
	tapped.emit(pos)

func _process(delta: float) -> void:
	if ripples.is_empty():
		return
		
	var to_remove = []
	for ripple in ripples:
		ripple.radius += ripple.speed * delta
		ripple.alpha = 1.0 - (ripple.radius / ripple.max_radius)
		
		if ripple.radius >= ripple.max_radius:
			to_remove.append(ripple)
			
	for r in to_remove:
		ripples.erase(r)
		
	queue_redraw()

func _draw() -> void:
	for ripple in ripples:
		# 和モダンに合わせた「白練色（純白）」の繊細な細い円を描く
		var color = Color(0.98, 0.98, 0.98, ripple.alpha)
		# 太さ2.5ピクセルの綺麗な円を描画
		draw_arc(ripple.position, ripple.radius, 0.0, TAU, 64, color, 2.5, true)
