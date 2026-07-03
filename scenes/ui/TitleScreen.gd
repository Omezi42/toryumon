extends Control

var anim_time: float = 0.0

func _ready() -> void:
	$VBox/StartButton.pressed.connect(_on_start_pressed)
	$VBox/EditorButton.pressed.connect(_on_editor_pressed)
	GameManager.set_state(GameManager.GameState.TITLE)

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

func _on_start_pressed() -> void:
	AudioManager.play_sound("dash")
	get_tree().change_scene_to_file("res://scenes/ui/StageSelectScreen.tscn")

func _on_editor_pressed() -> void:
	AudioManager.play_sound("orb")
	get_tree().change_scene_to_file("res://scenes/editor/StageEditorScreen.tscn")

func _draw() -> void:
	# Waterfall gradient background
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.05, 0.2, 0.38))
	for i in range(25):
		var x = float(i) * 52.0
		var y = fmod(anim_time * 200.0 + float(i * 90), 720.0)
		draw_line(Vector2(x, y), Vector2(x, y + 80), Color(0.2, 0.6, 0.85, 0.3), 3.0)
		
	# Decorative swimming Koi at bottom
	var koi_x = 640.0 + sin(anim_time * 2.0) * 300.0
	var koi_y = 580.0 + cos(anim_time * 3.0) * 30.0
	draw_circle(Vector2(koi_x, koi_y), 25.0, Color(0.95, 0.4, 0.15))
	draw_circle(Vector2(koi_x + 10, koi_y - 5), 18.0, Color.WHITE)
