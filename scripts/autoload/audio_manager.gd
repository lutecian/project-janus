extends Node

# Procedural horror audio: every stream is synthesized at runtime (no assets).
# Dark ambient drone + tension layer + event stingers, all deterministic.

const RATE := 22050

var music_player: AudioStreamPlayer
var tension_player: AudioStreamPlayer
var _sfx_pool: Array = []
var _sfx_idx := 0
var streams := {}
var current_mode := ""
var _tension_on := false

func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -16.0
	tension_player = AudioStreamPlayer.new()
	tension_player.volume_db = -20.0
	add_child(music_player)
	add_child(tension_player)
	for i in range(4):
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		_sfx_pool.append(p)
	_build_all()
	_load_volume()
	EventBus.incident_occurred.connect(_on_incident_sound)
	EventBus.scientist_died.connect(_on_death_sound)

func _load_volume():
	var cfg := ConfigFile.new()
	var vol := 100.0
	if cfg.load("user://settings.cfg") == OK:
		vol = float(cfg.get_value("audio", "volume", 100.0))
	apply_volume(vol)

func apply_volume(vol: float):
	var db := -80.0
	if vol > 0.0:
		db = linear_to_db(clampf(vol / 100.0, 0.01, 1.0))
	AudioServer.set_bus_volume_db(0, db)

# --- synthesis helpers ---
func _pack(samples: PackedFloat32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v: int = int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		if v < 0:
			v += 65536
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	return bytes

func _to_stream(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = _pack(samples)
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = samples.size()
	return s

func _sine(freq: float, dur: float, vol: float, decay: float = 0.0) -> PackedFloat32Array:
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in range(n):
		var t: float = float(i) / RATE
		var env := 1.0
		if decay > 0.0:
			env = exp(-t * decay)
		out[i] = vol * sin(TAU * freq * t) * env
	return out

func _noise_hit(dur: float, vol: float, smooth: int, decay: float) -> PackedFloat32Array:
	var n := int(RATE * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var acc := 0.0
	for i in range(n):
		var t: float = float(i) / RATE
		acc = acc + (randf() * 2.0 - 1.0 - acc) / float(maxi(smooth, 1))
		out[i] = vol * acc * exp(-t * decay)
	return out

func _mix_into(dst: PackedFloat32Array, src: PackedFloat32Array, at: int = 0):
	for i in range(src.size()):
		var j: int = at + i
		if j >= 0 and j < dst.size():
			dst[j] = clampf(dst[j] + src[i], -1.0, 1.0)

func _blank(dur: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(RATE * dur))
	return out

func _crossfade_loop(samples: PackedFloat32Array, fade_sec: float):
	var fade := int(RATE * fade_sec)
	var n := samples.size()
	if fade * 2 >= n:
		return
	for i in range(fade):
		var k: float = float(i) / float(fade)
		samples[i] = samples[i] * k + samples[n - fade + i] * (1.0 - k)

func _build_all():
	# Dark drone: detuned lows + breathy noise swell, 8s seamless loop.
	var drone := _blank(8.0)
	_mix_into(drone, _sine(55.0, 8.0, 0.35))
	_mix_into(drone, _sine(55.7, 8.0, 0.35))
	_mix_into(drone, _sine(110.4, 8.0, 0.16))
	_mix_into(drone, _sine(27.5, 8.0, 0.22))
	var breath := _noise_hit(8.0, 0.10, 400, 0.0)
	for i in range(breath.size()):
		var t: float = float(i) / RATE
		breath[i] = breath[i] * (0.5 + 0.5 * sin(TAU * t / 8.0))
	_mix_into(drone, breath)
	_crossfade_loop(drone, 1.0)
	streams["drone"] = _to_stream(drone, true)
	# Tension layer: dissonant cluster with tremolo, 6s loop.
	var tension := _blank(6.0)
	_mix_into(tension, _sine(220.0, 6.0, 0.22))
	_mix_into(tension, _sine(233.1, 6.0, 0.22))
	_mix_into(tension, _sine(466.2, 6.0, 0.10))
	for i in range(tension.size()):
		var t2: float = float(i) / RATE
		tension[i] = tension[i] * (0.55 + 0.45 * sin(TAU * 2.0 * t2))
	_crossfade_loop(tension, 0.75)
	streams["tension"] = _to_stream(tension, true)
	# Stingers.
	var hit := _blank(1.2)
	_mix_into(hit, _sine(110.0, 1.2, 0.5, 4.0))
	_mix_into(hit, _sine(116.5, 1.2, 0.5, 4.0))
	_mix_into(hit, _noise_hit(1.2, 0.35, 40, 6.0))
	streams["incident"] = _to_stream(hit)
	var knell := _blank(3.0)
	_mix_into(knell, _sine(65.4, 3.0, 0.55, 1.6))
	_mix_into(knell, _sine(130.8, 3.0, 0.25, 2.0))
	_mix_into(knell, _sine(180.5, 3.0, 0.15, 2.4))
	streams["death"] = _to_stream(knell)
	var win := _blank(1.6)
	var notes := [261.6, 329.6, 392.0, 523.25]
	for ni in range(notes.size()):
		_mix_into(win, _sine(notes[ni], 1.0, 0.35, 3.0), int(ni * 0.14 * RATE))
	streams["victory"] = _to_stream(win)
	var lose := _blank(1.8)
	var down := [220.0, 174.6, 146.8]
	for di in range(down.size()):
		_mix_into(lose, _sine(down[di], 1.0, 0.4, 2.5), int(di * 0.3 * RATE))
	streams["defeat"] = _to_stream(lose)
	streams["click"] = _to_stream(_sine(880.0, 0.07, 0.25, 30.0))
	var buy := _blank(0.5)
	_mix_into(buy, _sine(523.25, 0.3, 0.3, 6.0))
	_mix_into(buy, _sine(784.0, 0.4, 0.3, 6.0), int(0.12 * RATE))
	streams["buyout"] = _to_stream(buy)
	var alarm := _blank(1.5)
	for ai in range(3):
		_mix_into(alarm, _sine(660.0, 0.25, 0.3, 2.0), int(ai * 0.5 * RATE))
		_mix_into(alarm, _sine(520.0, 0.25, 0.3, 2.0), int((ai * 0.5 + 0.25) * RATE))
	streams["alarm"] = _to_stream(alarm)
	var res := _blank(0.6)
	_mix_into(res, _sine(392.0, 0.3, 0.3, 5.0))
	_mix_into(res, _sine(523.25, 0.4, 0.3, 5.0), int(0.15 * RATE))
	streams["resolve"] = _to_stream(res)

# --- playback API ---
func start_music(mode: String):
	if mode == current_mode and music_player.playing:
		return
	current_mode = mode
	if mode == "none" or not streams.has("drone"):
		music_player.stop()
		return
	music_player.stream = streams["drone"]
	music_player.volume_db = -18.0 if mode == "menu" else -14.0
	music_player.play()

func stop_music():
	current_mode = "none"
	music_player.stop()
	set_tension(false)

func set_tension(on: bool):
	if on == _tension_on:
		return
	_tension_on = on
	if on and streams.has("tension"):
		tension_player.stream = streams["tension"]
		tension_player.play()
	else:
		tension_player.stop()

func play_sfx(sfx_name: String):
	if not streams.has(sfx_name):
		return
	var p: AudioStreamPlayer = _sfx_pool[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % _sfx_pool.size()
	p.stream = streams[sfx_name]
	p.play()

func _on_incident_sound(_record: Dictionary):
	play_sfx("incident")

func _on_death_sound(_dead_name: String):
	play_sfx("death")
