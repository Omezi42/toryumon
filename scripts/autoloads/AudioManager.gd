extends Node

var sfx_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer
var sfx_generator: AudioStreamGenerator
var sfx_playback: AudioStreamGeneratorPlayback

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_generator = AudioStreamGenerator.new()
	sfx_generator.mix_rate = 44100
	sfx_generator.buffer_length = 0.5
	sfx_player.stream = sfx_generator
	add_child(sfx_player)
	sfx_player.play()
	sfx_playback = sfx_player.get_stream_playback()

func play_sound(type: String) -> void:
	if not sfx_playback:
		return
	var sample_rate = 44100.0
	match type:
		"dash":
			# High pitch swoop
			var duration = 0.15
			var samples = int(sample_rate * duration)
			for i in range(samples):
				var t = float(i) / sample_rate
				var freq = lerp(400.0, 880.0, t / duration)
				var val = sin(2.0 * PI * freq * t) * (1.0 - t / duration) * 0.3
				sfx_playback.push_frame(Vector2(val, val))
		"hit":
			# Noise burst + low sine
			var duration = 0.25
			var samples = int(sample_rate * duration)
			for i in range(samples):
				var t = float(i) / sample_rate
				var env = (1.0 - t / duration)
				var noise = (randf() * 2.0 - 1.0) * env * 0.4
				var tone = sin(2.0 * PI * 120.0 * t) * env * 0.4
				var val = (noise + tone) * 0.5
				sfx_playback.push_frame(Vector2(val, val))
		"splash":
			# Water splash noise
			var duration = 0.2
			var samples = int(sample_rate * duration)
			for i in range(samples):
				var t = float(i) / sample_rate
				var env = (1.0 - t / duration)
				var val = (randf() * 2.0 - 1.0) * env * 0.35
				sfx_playback.push_frame(Vector2(val, val))
		"orb":
			# Arpeggio chime
			var duration = 0.2
			var samples = int(sample_rate * duration)
			for i in range(samples):
				var t = float(i) / sample_rate
				var freq = 660.0 if t < 0.1 else 990.0
				var env = (1.0 - (t - (0.0 if t < 0.1 else 0.1)) * 10.0) # decay
				var val = sin(2.0 * PI * freq * t) * max(0.0, env) * 0.3
				sfx_playback.push_frame(Vector2(val, val))
		"clear":
			# Fanfare arpeggio
			var duration = 0.4
			var samples = int(sample_rate * duration)
			for i in range(samples):
				var t = float(i) / sample_rate
				var freq = 523.25 # C5
				if t > 0.1: freq = 659.25 # E5
				if t > 0.2: freq = 783.99 # G5
				if t > 0.3: freq = 1046.50 # C6
				var val = sin(2.0 * PI * freq * t) * 0.35
				sfx_playback.push_frame(Vector2(val, val))
