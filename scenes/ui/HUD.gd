extends CanvasLayer

@export var stage_controller_path: NodePath
var controller: Node2D
var player: Area2D

func _ready() -> void:
	if has_node("../StageController"):
		controller = get_node("../StageController")
	if has_node("../Player"):
		player = get_node("../Player")
		
	# Setup touch / mouse UI buttons
	$LeftButton.pressed.connect(_on_left_pressed)
	$RightButton.pressed.connect(_on_right_pressed)
	$DashButton.button_down.connect(_on_dash_down)
	$DashButton.button_up.connect(_on_dash_up)
	$PauseButton.pressed.connect(_on_pause_pressed)

func _process(_delta: float) -> void:
	if not controller or not player:
		if has_node("../StageController"):
			controller = get_node("../StageController")
		if has_node("../Player"):
			player = get_node("../Player")
		return
		
	# Update Time & Progress
	var time_left = max(0.0, controller.target_time - controller.elapsed_time)
	$RightPanel/TimeLabel.text = "TIME: %05.2f / %02d" % [controller.elapsed_time, int(controller.target_time)]
	if time_left < 6.0 and int(time_left * 5.0) % 2 == 0:
		$RightPanel/TimeLabel.modulate = Color.RED
	else:
		$RightPanel/TimeLabel.modulate = Color.WHITE
	var prog = clamp(controller.current_distance / max(1.0, controller.stage_length) * 100.0, 0.0, 100.0)
	$RightPanel/ProgressBar.value = prog
	$RightPanel/ScoreLabel.text = "SCORE: %d" % controller.score
	
	# Update Stamina
	$LeftPanel/StaminaBar.value = player.stamina
	if player.is_exhausted:
		$LeftPanel/StatusLabel.text = "⚠️ 息切れ中! (回復待機)"
		$LeftPanel/StatusLabel.modulate = Color.RED
	elif player.is_dragon_mode:
		$LeftPanel/StatusLabel.text = "🐉 龍モード発動中! 🐉"
		$LeftPanel/StatusLabel.modulate = Color.YELLOW
	elif player.is_dashing:
		$LeftPanel/StatusLabel.text = "💨 ダッシュ中 (障害物破壊可)"
		$LeftPanel/StatusLabel.modulate = Color.CYAN
	else:
		$LeftPanel/StatusLabel.text = " 通常泳ぎ (スタミナ回復中)"
		$LeftPanel/StatusLabel.modulate = Color.WHITE
		
	# Update Fever
	$RightPanel/FeverBar.value = player.fever_gauge

func _on_left_pressed() -> void:
	if player:
		player.change_lane(player.current_lane - 1)

func _on_right_pressed() -> void:
	if player:
		player.change_lane(player.current_lane + 1)

func _on_dash_down() -> void:
	# Simulate dash key press
	var ev = InputEventAction.new()
	ev.action = "dash"
	ev.pressed = true
	Input.parse_input_event(ev)

func _on_dash_up() -> void:
	var ev = InputEventAction.new()
	ev.action = "dash"
	ev.pressed = false
	Input.parse_input_event(ev)

func _on_pause_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
