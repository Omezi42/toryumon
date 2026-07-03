# **AIコード生成グラフィック戦略（手作業ゼロ化）**

本書は、AI画像生成における「手作業（切り抜き、リサイズ、テイスト調整）」と「AI臭」を完全に排除するため、「AIにコード（SVG、Shader、GDScript描画）を出力させ、プログラム側でグラフィックを動的生成する」ための実践的ガイドラインです。

## **1\. 3つの「コード側グラフィック生成」アプローチ**

画像ファイルを一切使わず、ゲーム画面を構築するための3つのアプローチです。

\[コードで描くゲーム画面のイメージ\]  
┌───────────────────────────────────────┐  
│ \[崖（コードによる多角形描画 \+ 揺れる草）\] │  
│                                       │  
│    \[滝背景（1枚の板にShaderで水流を描画）\]│  
│                                       │  
│          ▲ \[障害物: UFO (SVGアセット)\] │  
│                                       │  
│          ◎ \[プレイヤー: 鯉 (SVGアセット)\]│  
│                                       │  
└───────────────────────────────────────┘

### **アプローチ①：AIに「SVGコード」を直接書かせる（静的・動的アセット）**

* **仕組み**：AI（GeminiやClaudeなど）は、ベクター形式の画像を表すSVGコード（XML）を非常に高い精度で出力できます。  
* **手作業ゼロ**：AIが出力したテキストをコピーし、拡張子を .svg にしてGodotにドラッグ＆ドロップするだけで、透過済みの高解像度アセットとして即座に使用可能。  
* **対象**：プレイヤー（鯉）、障害物（岩、サルの石、釣り針、UFOなど）。

### **アプローチ②：Godotの「Shader（シェーダー）」で描く（背景・水流エフェクト）**

* **仕組み**：GodotのGPU用言語（Shading Language）を使用します。AIに「和風の滝の流れを表現する2Dシェーダーを書いて」と頼みます。  
* **手作業ゼロ**：ColorRect（単なる色付きの四角）にそのシェーダーを貼るだけで、無限にスクロールする美しく滑らかな滝や急流がコードだけで完成します。  
* **対象**：滝の背景、水しぶき、急流や上昇気流のエリアエフェクト。

### **アプローチ③：Godotの \_draw() 関数で描く（動的生成、和風の線・崖）**

* **仕組み**：GDScript内の \_draw() 関数を使い、数学的に線や多角形を描画します。  
* **手作業ゼロ**：例えば「画面端の崖の岩肌」を、少しノイズ（ランダムな凹凸）を加えた多角形としてコードで描画します。和風の「掠れ（かすれ）線」や「筆文字」のような太さの強弱を動的にプログラムで描画します。  
* **対象**：画面両端の崖、ダッシュ時のスタミナゲージ、UI、レーンの境界線。

## **2\. 実践①：AIに「SVGコード」を出力させてアセット化する**

AIに以下のプロンプトを投げることで、完全に透過され、かつトリミング済みの綺麗なフラットベタ塗りアセットが手に入ります。

### **【プロンプト例：フラット和モダンな「鯉」のSVG生成】**

**Prompt:**

Please generate a complete, valid raw SVG code for a 2D game asset of a stylized Japanese koi fish (carp).

**Design Requirements:**

* Style: Modern Japanese minimalist / flat design (no gradients, no 3D effects, no shadows, no AI-like airbrushing).  
* Colors: Use bold, flat colors (Vibrant Red, Pure White, and accented with Dark Gray/Black for outlines).  
* Shape & Orientation: The koi should be swimming upward, clean curves, iconic and easily recognizable even when small.  
* Technical constraints:  
  * Ensure it has a transparent background (no background rect).  
  * The viewport/viewBox should perfectly fit the boundaries of the fish (no empty padding around it).  
  * Output ONLY the clean, well-formatted XML SVG code inside a single code block. Do not explain.

#### **💡 AIが出力するコードのイメージ（そのまま .svg で保存可能）**

\<svg xmlns="\[http://www.w3.org/2000/svg\](http://www.w3.org/2000/svg)" viewBox="0 0 100 150" width="100%" height="100%"\>  
  \<\!-- 鯉の体（白） \--\>  
  \<path d="M50 10 C35 40 30 90 50 140 C70 90 65 40 50 10 Z" fill="\#FFFFFF" stroke="\#2C3E50" stroke-width="3"/\>  
  \<\!-- 赤い模様 \--\>  
  \<path d="M50 25 C42 45 42 65 50 80 C58 65 58 45 50 25 Z" fill="\#E74C3C"/\>  
  \<circle cx="50" cy="110" r="8" fill="\#E74C3C"/\>  
  \<\!-- ひれ \--\>  
  \<path d="M35 50 C20 55 15 70 32 75 Z" fill="\#FFFFFF" stroke="\#2C3E50" stroke-width="2"/\>  
  \<path d="M65 50 C80 55 85 70 68 75 Z" fill="\#FFFFFF" stroke="\#2C3E50" stroke-width="2"/\>  
  \<\!-- 目 \--\>  
  \<circle cx="43" cy="30" r="3" fill="\#2C3E50"/\>  
  \<circle cx="57" cy="30" r="3" fill="\#2C3E50"/\>  
\</svg\>

これをテキストエディタに貼り付け、player\_koi.svg と保存してGodotのファイルシステムに入れるだけで、ベクターのクリーンな鯉アセットになります！

## **3\. 実践②：滝のスクロール背景を「Shader」で自動生成する**

Godot 4で、滝の流れをコード（シェーダー）だけで表現します。画像アセットは一切不要。AIに以下のコードを生成させ、ColorRectに割り当てます。

### **【Godot 4.x対応：和モダンな「滝流」シェーダーコード】**

shader\_type canvas\_item;

// 和風の滝（水流）を表現するプログラム  
uniform vec4 bg\_color : source\_color \= vec4(0.05, 0.15, 0.25, 1.0); // 深い紺青  
uniform vec4 stream\_color : source\_color \= vec4(0.3, 0.6, 0.8, 0.6); // 水色  
uniform vec4 foam\_color : source\_color \= vec4(0.9, 0.95, 1.0, 0.8); // 白（泡）  
uniform float flow\_speed \= 2.5;

// 擬似ランダムノイズ（線を描くためのシンプルなハッシュ）  
float hash(float n) {  
    return fract(sin(n) \* 43758.5453123);  
}

float noise(vec2 p) {  
    vec2 i \= floor(p);  
    vec2 f \= fract(p);  
    f \= f \* f \* (3.0 \- 2.0 \* f);  
    float n \= i.x \+ i.y \* 57.0;  
    return mix(mix(hash(n \+ 0.0), hash(n \+ 1.0), f.x),  
               mix(hash(n \+ 57.0), hash(n \+ 58.0), f.x), f.y);  
}

void fragment() {  
    vec2 uv \= UV;  
    // 縦方向に時間経過でオフセットを加え、上から下へ流す  
    uv.y \-= TIME \* flow\_speed;  
      
    // 縦長のストライプ状のノイズを生成（和風の「水流の線」を表現）  
    float n1 \= noise(vec2(uv.x \* 25.0, uv.y \* 2.0));  
    float n2 \= noise(vec2(uv.x \* 40.0 \+ 15.0, uv.y \* 4.0));  
      
    vec4 final\_color \= bg\_color;  
      
    // 水流の線をブレンド  
    if (n1 \> 0.55) {  
        final\_color \= mix(final\_color, stream\_color, (n1 \- 0.55) \* 2.0);  
    }  
    // 白い泡・波頭の線をブレンド（和紙・浮世絵的なパキッとした白線）  
    if (n2 \> 0.7) {  
        final\_color \= mix(final\_color, foam\_color, step(0.72, n2));  
    }  
      
    COLOR \= final\_color;  
}

#### **💡 設定手順（作業時間：30秒）**

1. Godotで ColorRect ノードを画面いっぱいに配置。  
2. インスペクターの Material \-\> New ShaderMaterial を作成。  
3. そのMaterialの中に New Shader を作成し、上のコードを貼り付ける。  
4. これだけで、ゲーム実行時に上から下に和風の美しい水流が無限に流れ続けます！

## **4\. 実践③：障害物を「プログラムのDraw関数」で描く（岩の自動生成）**

Godotの2Dノードには \_draw() という直接画面に図形を描画する関数があります。これを利用して、「毎回形が微妙に変わる、和風の輪郭線を持った岩」をコードだけで動的に生成します。

### **【Godot 4.x対応：和風の「岩」を動的描画するGDScript】**

@tool  
extends Node2D

@export var radius: float \= 40.0  
@export var points\_count: int \= 8  
@export var jaggedness: float \= 0.35 \# 凹凸の激しさ  
@export var fill\_color: Color \= Color("2c3e50") \# 岩のベース（濃い濃紺）  
@export var line\_color: Color \= Color("ecf0f1") \# 和風のハイライト線（白）

var polygon\_points: PackedVector2Array \= PackedVector2Array()

func \_ready():  
	generate\_rock()

\# 岩の輪郭（多角形）をランダム（シード値に基づく）に生成  
func generate\_rock():  
	polygon\_points.clear()  
	\# 決定論的に、座標などをシードにして岩の形を固定  
	var seed\_val \= global\_position.x \+ global\_position.y  
	var rng \= RandomNumberGenerator.new()  
	rng.seed \= int(seed\_val)  
	  
	for i in range(points\_count):  
		var angle \= (float(i) / points\_count) \* TAU  
		\# 円にランダムな凹凸を加える  
		var offset \= rng.randf\_range(1.0 \- jaggedness, 1.0 \+ jaggedness)  
		var r \= radius \* offset  
		var p \= Vector2(cos(angle) \* r, sin(angle) \* r)  
		polygon\_points.append(p)  
	  
	\# 再描画をトリガー  
	queue\_redraw()

func \_draw():  
	if polygon\_points.size() \< 3:  
		return  
		  
	\# 1\. 岩の本体（塗りつぶし）  
	draw\_colored\_polygon(polygon\_points, fill\_color)  
	  
	\# 2\. 外枠（浮世絵風の力強い黒・白の輪郭線）  
	\# 輪郭線を閉じさせるため、始点を終点に繋ぐ  
	var outline \= polygon\_points  
	outline.append(polygon\_points\[0\])  
	draw\_polyline(outline, line\_color, 4.0, true) \# 太さ4のクッキリした線

#### **💡 メリット**

* 岩の画像を1枚も用意する必要がありません。このスクリプトを貼った岩ノードをステージ上に配置するだけで、配置された場所（座標）に応じて**自動で異なる形の個性的な岩が描画されます**。

## **5\. 開発全体の効率化ガイドライン**

手作業を極限まで減らして、ゲーム全体の完成度を上げるためのタスク配分です。

1. **ビジュアルアセットは「SVG」か「コード生成」に絞る**  
   * png画像やjpg画像をネットから探したり、AI画像生成からトリミングする作業を全廃。  
   * AI（Gemini等）に「〇〇のSVGコードをフラット和モダン調で作って」と依頼。  
2. **UIはGodotのデフォルトコントロール（StyleBoxFlat）を組み合わせる**  
   * ボタンのデザインも画像を使わず、角丸、太い境界線、ベタ塗りをインスペクターで設定。  
   * フォントはGoogle Fontsからフリーの和風モダンフォント（「デラゴシック（Dela Gothic One）」など）を1つダウンロードして設定するだけ。  
3. **パーティクル（エフェクト）もGodot標準機能を使用**  
   * 水しぶきやスタミナダッシュ時の気流は、Godotの GPUParticles2D を使い、単純な丸（白や薄い青）を大量に放出させて表現。これも画像アセット不要。