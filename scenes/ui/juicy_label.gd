# juicy_label.gd
# スコアやスタミナが変化した時、文字を生きているように弾ませるコントロール
extends Label

var last_value: int = 0
var base_scale := Vector2.ONE

func _ready() -> void:
	pivot_offset = size / 2.0
	resized.connect(func(): pivot_offset = size / 2.0)

# スコア更新時にこれを呼び出す
func update_juicy_text(new_text: String, new_val: int) -> void:
	text = new_text
	if new_val != last_value:
		last_value = new_val
		bounce_animation()

func bounce_animation() -> void:
	# 一瞬縦に伸びて、横に縮みながら元のスケールにバウンドして戻る
	scale = Vector2(0.85, 1.35)
	modulate = Color("#F1C40F") # 一瞬黄金色に光る
	
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", base_scale, 0.35)
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)
