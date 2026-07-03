shader_type canvas_item;

// 和モダンな滝流（水流）シェーダー
uniform vec4 bg_color : source_color = vec4(0.05, 0.15, 0.25, 1.0); // 深い紺青
uniform vec4 stream_color : source_color = vec4(0.3, 0.6, 0.8, 0.6); // 水色
uniform vec4 foam_color : source_color = vec4(0.9, 0.95, 1.0, 0.8); // 白（泡）
uniform float flow_speed = 2.5;

// 擬似ランダムノイズ
float hash(float n) {
	return fract(sin(n) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n = i.x + i.y * 57.0;
	return mix(mix(hash(n + 0.0), hash(n + 1.0), f.x),
			   mix(hash(n + 57.0), hash(n + 58.0), f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	// 縦方向に時間経過でオフセットを加え、上から下へ流す
	uv.y -= TIME * flow_speed;
	
	// 縦長のストライプ状のノイズを生成（和風の「水流の線」を表現）
	float n1 = noise(vec2(uv.x * 25.0, uv.y * 2.0));
	float n2 = noise(vec2(uv.x * 40.0 + 15.0, uv.y * 4.0));
	
	vec4 final_color = bg_color;
	
	// 水流の線をブレンド
	if (n1 > 0.55) {
		final_color = mix(final_color, stream_color, (n1 - 0.55) * 2.0);
	}
	// 白い泡・波頭の線をブレンド（和紙・浮世絵的なパキッとした白線）
	if (n2 > 0.7) {
		final_color = mix(final_color, foam_color, step(0.72, n2));
	}
	
	COLOR = final_color;
}
