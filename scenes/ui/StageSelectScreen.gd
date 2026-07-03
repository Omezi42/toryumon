extends Control

var stage_titles = [
	"1. 始まりの滝 (岩とダッシュ)",
	"2. 逆風と急流 (レーン変化)",
	"3. 落石注意の崖 (サルの投石)",
	"4. サケ飛び交う急流 (クマのサケ)",
	"5. 釣り人の縄張り (釣り針)",
	"6. 未知との遭遇 (UFOワープ)",
	"7. サルの悪巧み (投石＋急流)",
	"8. クマと釣り針の迷宮 (複合)",
	"9. カオスの急流滝 (全ギミック)",
	"10. 登竜門 (最難関・覚醒)"
]

func _ready() -> void:
	$BackButton.pressed.connect(_on_back_pressed)
	_populate_stages()
	_populate_shared_stages()
	GameManager.set_state(GameManager.GameState.STAGE_SELECT)

func _populate_stages() -> void:
	for child in $GridContainer.get_children():
		child.queue_free()
		
	for i in range(1, 11):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(280, 80)
		var best = GameManager.get_best_time(i)
		var best_str = "--.--" if best > 900.0 else "%05.2f秒" % best
		btn.text = "%s\nベスト: %s" % [stage_titles[i - 1], best_str]
		btn.pressed.connect(_on_stage_btn_pressed.bind(i))
		$GridContainer.add_child(btn)

func _populate_shared_stages() -> void:
	for child in $SharedContainer.get_children():
		child.queue_free()
		
	for st in FirebaseManager.cached_stages:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(340, 60)
		btn.text = "[%s] %s (作: %s)" % [st.get("code", "#000"), st.get("title", "カスタムステージ"), st.get("author", "匿名")]
		btn.pressed.connect(_on_shared_btn_pressed.bind(st))
		$SharedContainer.add_child(btn)

func _on_stage_btn_pressed(stage_id: int) -> void:
	AudioManager.play_sound("dash")
	GameManager.start_stage(stage_id)

func _on_shared_btn_pressed(stage_data: Dictionary) -> void:
	AudioManager.play_sound("orb")
	GameManager.start_custom_stage(stage_data)

func _on_back_pressed() -> void:
	AudioManager.play_sound("dash")
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
