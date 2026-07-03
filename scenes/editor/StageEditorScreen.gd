extends Control

var obstacles: Array = []
var selected_type: String = "rock"
var selected_lane: int = 0
var stage_title: String = "創作・龍門の滝"
var author_name: String = "名無しのコイ"
var target_time: float = 25.0
var stage_length: float = 300.0

var type_names = {
	"rock": "岩 (固定障害物)",
	"breakable": "流木/氷 (ダッシュで破壊)",
	"monkey": "サルの投石 (両端から)",
	"salmon": "クマのサケハント (弾き)",
	"hook": "釣り人の釣り針 (スクロール停止)",
	"ufo": "UFOビーム (強制ワープ)",
	"rapids": "急流ゾーン (減速)",
	"updraft": "上昇気流ゾーン (スピードアップ)"
}

func _ready() -> void:
	$AddButton.pressed.connect(_on_add_pressed)
	$ClearButton.pressed.connect(_on_clear_pressed)
	$TestButton.pressed.connect(_on_test_pressed)
	$UploadButton.pressed.connect(_on_upload_pressed)
	$BackButton.pressed.connect(_on_back_pressed)
	
	FirebaseManager.stage_uploaded.connect(_on_stage_uploaded)
	
	# Populate type option button
	for key in type_names:
		$TypeOption.add_item(type_names[key])
		
	# Populate lane option
	$LaneOption.add_item("左レーン (-1)")
	$LaneOption.add_item("中央レーン (0)")
	$LaneOption.add_item("右レーン (+1)")
	$LaneOption.selected = 1
	
	_update_list()
	GameManager.set_state(GameManager.GameState.EDITOR)

func _on_add_pressed() -> void:
	AudioManager.play_sound("orb")
	var idx = $TypeOption.selected
	var keys = type_names.keys()
	var t = keys[idx] if idx >= 0 and idx < keys.size() else "rock"
	
	var l_idx = $LaneOption.selected
	var l = -1 if l_idx == 0 else (1 if l_idx == 2 else 0)
	
	var dist = float($DistSpin.value)
	obstacles.append({"type": t, "lane": l, "dist": dist})
	obstacles.sort_custom(func(a, b): return float(a["dist"]) < float(b["dist"]))
	_update_list()

func _on_clear_pressed() -> void:
	AudioManager.play_sound("hit")
	obstacles.clear()
	_update_list()

func _update_list() -> void:
	$ItemList.clear()
	for obs in obstacles:
		var t_str = type_names.get(obs["type"], str(obs["type"]))
		var l_str = "左" if obs["lane"] < 0 else ("右" if obs["lane"] > 0 else "中")
		$ItemList.add_item("距離 %03d : [%sレーン] %s" % [int(obs["dist"]), l_str, t_str])

func _on_test_pressed() -> void:
	AudioManager.play_sound("dash")
	var custom_data = {
		"title": $TitleInput.text if $TitleInput.text != "" else stage_title,
		"author": $AuthorInput.text if $AuthorInput.text != "" else author_name,
		"target_time": float($TimeSpin.value),
		"length": float($LengthSpin.value),
		"obstacles": obstacles.duplicate()
	}
	GameManager.start_custom_stage(custom_data)

func _on_upload_pressed() -> void:
	AudioManager.play_sound("clear")
	var t = $TitleInput.text if $TitleInput.text != "" else stage_title
	var a = $AuthorInput.text if $AuthorInput.text != "" else author_name
	FirebaseManager.upload_stage(t, a, obstacles.duplicate(), float($LengthSpin.value), float($TimeSpin.value))

func _on_stage_uploaded(_success: bool, code: String) -> void:
	$StatusLabel.text = "✅ 投稿完了! 共有ステージコード: " + code

func _on_back_pressed() -> void:
	AudioManager.play_sound("dash")
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
