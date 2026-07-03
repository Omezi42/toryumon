extends Node

const CACHE_PATH = "user://shared_stages_cache.json"

const FIREBASE_CONFIG = {
	"apiKey": "AIzaSyDyNPfss6EYj9duQr1wZ7QUotB_CaOVxi4",
	"authDomain": "toryumon-993a6.firebaseapp.com",
	"projectId": "toryumon-993a6",
	"storageBucket": "toryumon-993a6.firebasestorage.app",
	"messagingSenderId": "818491758076",
	"appId": "1:818491758076:web:46970c7338ebafafa00e79",
	"measurementId": "G-5LRBEHD4MY"
}

var cached_stages: Array = []
var http_client: HTTPRequest
var upload_http: HTTPRequest

signal stages_fetched(stages: Array)
signal stage_uploaded(success: bool, stage_code: String)

func _ready() -> void:
	http_client = HTTPRequest.new()
	add_child(http_client)
	http_client.request_completed.connect(_on_fetch_completed)
	
	upload_http = HTTPRequest.new()
	add_child(upload_http)
	upload_http.request_completed.connect(_on_upload_completed)
	
	load_local_cache()
	if cached_stages.is_empty():
		_add_sample_custom_stage()
	
	init_web_firebase()

func init_web_firebase() -> void:
	if not OS.has_feature("web") or not Engine.has_singleton("JavaScriptBridge"):
		return
	var js = Engine.get_singleton("JavaScriptBridge")
	var js_script = """
		window.firebaseConfig = {
			apiKey: "%s",
			authDomain: "%s",
			projectId: "%s",
			storageBucket: "%s",
			messagingSenderId: "%s",
			appId: "%s",
			measurementId: "%s"
		};
		if (typeof firebase !== 'undefined' && !firebase.apps.length) {
			firebase.initializeApp(window.firebaseConfig);
			console.log("Firebase initialized via Godot WebBridge!");
		}
	""" % [
		FIREBASE_CONFIG["apiKey"],
		FIREBASE_CONFIG["authDomain"],
		FIREBASE_CONFIG["projectId"],
		FIREBASE_CONFIG["storageBucket"],
		FIREBASE_CONFIG["messagingSenderId"],
		FIREBASE_CONFIG["appId"],
		FIREBASE_CONFIG["measurementId"]
	]
	js.eval(js_script)

func _add_sample_custom_stage() -> void:
	# Default sample shared stage
	var sample = {
		"code": "#123456",
		"title": "サルの大暴れ滝（コミュニティ投稿例）",
		"author": "コイキングマスター",
		"target_time": 25.0,
		"obstacles": [
			{"type": "rock", "lane": 0, "dist": 30.0},
			{"type": "monkey", "lane": -1, "dist": 60.0},
			{"type": "monkey", "lane": 1, "dist": 90.0},
			{"type": "salmon", "lane": 0, "dist": 130.0},
			{"type": "hook", "lane": 0, "dist": 170.0},
			{"type": "ufo", "lane": -1, "dist": 210.0}
		],
		"length": 260.0
	}
	cached_stages.append(sample)
	save_local_cache()

func load_local_cache() -> void:
	if FileAccess.file_exists(CACHE_PATH):
		var file = FileAccess.open(CACHE_PATH, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK and typeof(json.get_data()) == TYPE_ARRAY:
				cached_stages = json.get_data()

func save_local_cache() -> void:
	var file = FileAccess.open(CACHE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(cached_stages, "\t"))

func get_firestore_url(collection_id: String) -> String:
	return "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/%s?key=%s" % [
		FIREBASE_CONFIG["projectId"],
		collection_id,
		FIREBASE_CONFIG["apiKey"]
	]

func fetch_shared_stages() -> void:
	# Immediately emit current cache for responsive UI
	emit_signal("stages_fetched", cached_stages)
	
	# Request latest stages via Firestore REST API
	if http_client.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		http_client.request(get_firestore_url("shared_stages"))

func upload_stage(title: String, author: String, obstacles: Array, length: float, target_time: float) -> void:
	var code = "#" + str(randi() % 899999 + 100000)
	var stage_data = {
		"code": code,
		"title": title,
		"author": author if author != "" else "名無し鯉",
		"target_time": target_time,
		"obstacles": obstacles,
		"length": length
	}
	cached_stages.push_front(stage_data)
	save_local_cache()
	emit_signal("stage_uploaded", true, code)
	
	# Upload to Firestore REST API
	if upload_http.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		var firestore_doc = {
			"fields": {
				"code": {"stringValue": code},
				"title": {"stringValue": stage_data["title"]},
				"author": {"stringValue": stage_data["author"]},
				"target_time": {"doubleValue": target_time},
				"length": {"doubleValue": length},
				"obstacles": {"stringValue": JSON.stringify(obstacles)}
			}
		}
		var headers = ["Content-Type: application/json"]
		upload_http.request(get_firestore_url("shared_stages"), headers, HTTPClient.METHOD_POST, JSON.stringify(firestore_doc))

func _on_fetch_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK and typeof(json.get_data()) == TYPE_DICTIONARY:
			var data = json.get_data()
			if data.has("documents") and typeof(data["documents"]) == TYPE_ARRAY:
				var fetched_list = []
				for doc in data["documents"]:
					if typeof(doc) == TYPE_DICTIONARY:
						var parsed_stage = _parse_firestore_document(doc)
						if not parsed_stage.is_empty():
							fetched_list.append(parsed_stage)
				if not fetched_list.is_empty():
					cached_stages = fetched_list
					save_local_cache()
					emit_signal("stages_fetched", cached_stages)

func _on_upload_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
		print("Firestoreステージ投稿成功! (HTTP: ", response_code, ")")
	else:
		print("Firestore通信結果: ", response_code, " (ローカルキャッシュには保存完了)")

func _parse_firestore_document(doc: Dictionary) -> Dictionary:
	var stage_data = {}
	if not doc.has("fields") or typeof(doc["fields"]) != TYPE_DICTIONARY:
		return stage_data
	var fields = doc["fields"]
	stage_data["code"] = str(_get_field_value(fields.get("code", {}), "#000000"))
	stage_data["title"] = str(_get_field_value(fields.get("title", {}), "カスタムステージ"))
	stage_data["author"] = str(_get_field_value(fields.get("author", {}), "匿名"))
	stage_data["target_time"] = float(_get_field_value(fields.get("target_time", {}), 30.0))
	stage_data["length"] = float(_get_field_value(fields.get("length", {}), 200.0))
	
	var obs_val = _get_field_value(fields.get("obstacles", {}), "[]")
	if typeof(obs_val) == TYPE_STRING:
		var json = JSON.new()
		if json.parse(obs_val) == OK and typeof(json.get_data()) == TYPE_ARRAY:
			stage_data["obstacles"] = json.get_data()
		else:
			stage_data["obstacles"] = []
	elif typeof(obs_val) == TYPE_ARRAY:
		stage_data["obstacles"] = obs_val
	else:
		stage_data["obstacles"] = []
		
	return stage_data

func _get_field_value(field: Variant, default_val: Variant) -> Variant:
	if typeof(field) != TYPE_DICTIONARY:
		return default_val
	if field.has("stringValue"):
		return field["stringValue"]
	elif field.has("doubleValue"):
		return float(field["doubleValue"])
	elif field.has("integerValue"):
		return int(field["integerValue"])
	return default_val
