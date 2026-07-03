shader_type canvas_item;

// 白・青・緑を基調とした、明るいきらめき清流シェーダー
uniform vec4 bg_color : source_color = vec4(0.45, 0.75, 0.85, 1.0);     // 明るい水色 (白群)
uniform vec4 stream_color : source_color = vec4(0.6, 0.85, 0.9, 0.65);   // 爽やかなコバルト
uniform vec4 foam_color : source_color = vec4(0.98, 0.98, 0.98, 0.4);   // 純白の泡 (白練) を半透明にして視認性を向上
uniform vec4 forest_reflection : source_color = vec4(0.2, 0.6, 0.3, 0.15); // 新緑の照り返し (淡い緑)
uniform float flow_speed = 4.5; // スピードを7.5から4.5に下げて見やすく調整

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
	uv.y -= TIME * flow_speed;
	
	// 縦の清流ノイズ
	float n1 = noise(vec2(uv.x * 20.0, uv.y * 1.5));
	float n2 = noise(vec2(uv.x * 35.0 + 8.0, uv.y * 3.0));
	// 陽光のきらめきシマー（横方向の光の反射）
	float shimmer = sin(UV.x * 12.0 + TIME * 8.0) * cos(UV.y * 8.0 - TIME * 4.0);
	
	vec4 final_color = bg_color;
	
	// 新緑の照り返し（左右の崖に近い部分に緑のグラデーション）
	float edge_mask = smoothstep(0.0, 0.25, UV.x) * smoothstep(1.0, 0.75, UV.x);
	final_color = mix(final_color, forest_reflection, (1.0 - edge_mask));
	
	// 水流ライン
	if (n1 > 0.5) {
		final_color = mix(final_color, stream_color, (n1 - 0.5) * 2.0);
	}
	// 陽光のきらめきをブレンド (不透明度を0.25から0.12に抑える)
	if (shimmer > 0.7) {
		final_color = mix(final_color, vec4(1.0, 1.0, 0.9, 1.0), 0.12);
	}
	// クッキリした白練の激流泡 (しきい値を上げ、ノイズ量をカット)
	if (n2 > 0.76) {
		final_color = mix(final_color, foam_color, step(0.78, n2));
	}
	
	COLOR = final_color;
}

