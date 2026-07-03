extends Node

var is_recording_video: bool = false

func init_web_recorder() -> void:
	if not OS.has_feature("web"):
		return
	var js_code = """
	if (!window.toryumonRecorder) {
		window.toryumonChunks = [];
		const canvas = document.querySelector('canvas');
		if (canvas && canvas.captureStream) {
			const stream = canvas.captureStream(30);
			window.toryumonRecorder = new MediaRecorder(stream, { mimeType: 'video/webm' });
			window.toryumonRecorder.ondataavailable = (e) => {
				if (e.data && e.data.size > 0) window.toryumonChunks.push(e.data);
			};
			window.toryumonRecorder.onstop = () => {
				const blob = new Blob(window.toryumonChunks, { type: 'video/webm' });
				const url = URL.createObjectURL(blob);
				const a = document.createElement('a');
				a.href = url;
				a.download = 'toryumon_play.webm';
				document.body.appendChild(a);
				a.click();
				setTimeout(() => { document.body.removeChild(a); URL.revokeObjectURL(url); }, 100);
			};
		}
	}
	"""
	if Engine.has_singleton("JavaScriptBridge"):
		var js = Engine.get_singleton("JavaScriptBridge")
		js.eval(js_code)

func start_video_recording() -> void:
	is_recording_video = true
	if not OS.has_feature("web"):
		return
	if Engine.has_singleton("JavaScriptBridge"):
		var js = Engine.get_singleton("JavaScriptBridge")
		js.eval("if (window.toryumonRecorder) { window.toryumonChunks = []; window.toryumonRecorder.start(); }")

func stop_and_download_video() -> void:
	is_recording_video = false
	if not OS.has_feature("web"):
		print("PC版実行中: WebM録画のダウンロードはブラウザ(Webエクスポート)環境でのみ動作します。")
		return
	if Engine.has_singleton("JavaScriptBridge"):
		var js = Engine.get_singleton("JavaScriptBridge")
		js.eval("if (window.toryumonRecorder && window.toryumonRecorder.state !== 'inactive') { window.toryumonRecorder.stop(); }")
