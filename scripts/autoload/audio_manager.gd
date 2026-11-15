extends Node
# 全部音效与背景音乐由代码合成（正弦/三角/方波 + 噪声 + 指数包络），不使用任何外部音频。
const RATE := 22050
const HAPTIC := {"select": 8, "play": 25, "discard": 15, "buy": 15, "win": 60, "lose": 60}
var sfx := {}
var pool: Array = []
var _last := {}
var music_player: AudioStreamPlayer

func _ready() -> void:
	for b in ["Music", "SFX"]:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	apply_volumes()
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		pool.append(p)
	_build_sfx()
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.volume_db = -5.0
	add_child(music_player)
	WorkerThreadPool.add_task(_build_music)  # 后台合成，不卡启动

func apply_volumes() -> void:
	var s := SettingsManager
	_set_bus("Master", float(s.get_value("vol_master")), true)
	_set_bus("Music", float(s.get_value("vol_music")), bool(s.get_value("music_on")))
	_set_bus("SFX", float(s.get_value("vol_sfx")), bool(s.get_value("sfx_on")))

func _set_bus(bus: String, v: float, on: bool) -> void:
	var i := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_mute(i, not on or v <= 0.0)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))

func play(name: String, pitch: float = 1.0) -> void:
	if not sfx.has(name): return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(name, -1000)) < 35: return  # 防止同一音效叠得刺耳
	_last[name] = now
	for p in pool:
		if not p.playing:
			p.stream = sfx[name]
			p.pitch_scale = pitch
			p.play()
			break
	if HAPTIC.has(name) and bool(SettingsManager.get_value("haptics")): Input.vibrate_handheld(HAPTIC[name])

# ---------- 合成工具 ----------
func _hz(m: float) -> float: return 440.0 * pow(2.0, (m - 69.0) / 12.0)
func _buf(sec: float) -> PackedFloat32Array:
	var a := PackedFloat32Array()
	a.resize(int(sec * RATE))
	return a

func _tone(a: PackedFloat32Array, t0: float, dur: float, f0: float, f1: float, vol: float, wave: int = 0, atk: float = 0.004, decay: float = 6.0) -> void:
	var n := int(dur * RATE)
	var s0 := int(t0 * RATE)
	var ph := 0.0
	var an := maxf(atk * RATE, 1.0)
	for i in n:
		var idx := s0 + i
		if idx >= a.size(): break
		ph += lerpf(f0, f1, float(i) / n) / RATE
		var w := sin(TAU * ph)
		if wave == 1: w = 4.0 * absf(fposmod(ph, 1.0) - 0.5) - 1.0
		elif wave == 2: w = 0.6 if fposmod(ph, 1.0) < 0.5 else -0.6
		a[idx] += w * minf(1.0, i / an) * exp(-decay * float(i) / RATE) * vol

func _noise(a: PackedFloat32Array, t0: float, dur: float, vol: float, decay: float, coef: float) -> void:
	var n := int(dur * RATE)
	var s0 := int(t0 * RATE)
	var y := 0.0
	for i in n:
		var idx := s0 + i
		if idx >= a.size(): break
		y += (randf_range(-1.0, 1.0) - y) * coef  # 一阶低通
		a[idx] += y * exp(-decay * float(i) / RATE) * vol

func _wav(a: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var peak := 0.001
	for x in a: peak = maxf(peak, absf(x))
	var g := 0.85 / maxf(peak, 0.85)
	var bytes := PackedByteArray()
	bytes.resize(a.size() * 2)
	for i in a.size(): bytes.encode_s16(i * 2, int(clampf(a[i] * g, -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = a.size()
	return w

# ---------- 音效 ----------
func _build_sfx() -> void:
	var a := _buf(0.14)
	_tone(a, 0, 0.1, 520, 760, 0.4, 1, 0.002, 18)
	_tone(a, 0, 0.08, 1040, 1520, 0.12, 0, 0.002, 25)
	sfx["select"] = _wav(a)
	a = _buf(0.08)
	_noise(a, 0, 0.04, 0.5, 60, 0.3)
	_tone(a, 0, 0.05, 220, 180, 0.25, 0, 0.002, 40)
	sfx["move"] = _wav(a)
	a = _buf(0.16)
	_noise(a, 0, 0.12, 0.5, 22, 0.35)
	_tone(a, 0, 0.1, 320, 190, 0.15, 1, 0.002, 25)
	sfx["flip"] = _wav(a)
	a = _buf(0.45)
	_tone(a, 0, 0.2, 140, 55, 0.9, 0, 0.002, 14)
	_noise(a, 0, 0.08, 0.35, 30, 0.5)
	for f in [262.0, 330.0, 392.0]: _tone(a, 0.02, 0.4, f, f, 0.13, 1, 0.005, 8)
	sfx["play"] = _wav(a)
	a = _buf(0.3)
	_noise(a, 0, 0.22, 0.45, 12, 0.2)
	_tone(a, 0, 0.2, 420, 120, 0.3, 1, 0.003, 12)
	sfx["discard"] = _wav(a)
	a = _buf(0.5)
	_tone(a, 0, 0.09, 988, 988, 0.4, 0, 0.002, 12)
	_tone(a, 0.07, 0.4, 1319, 1319, 0.4, 0, 0.002, 7)
	_tone(a, 0.07, 0.3, 2637, 2637, 0.08, 0, 0.002, 10)
	sfx["coin"] = _wav(a)
	a = _buf(0.6)
	var k := 0.0
	for f in [523.0, 659.0, 784.0, 1047.0]:
		_tone(a, k, 0.4, f, f, 0.28, 1, 0.003, 8)
		k += 0.06
	_tone(a, 0.2, 0.35, 1319, 1319, 0.2, 0, 0.002, 7)
	sfx["buy"] = _wav(a)
	a = _buf(0.5)
	k = 0.0
	for f in [659.0, 784.0, 988.0, 1319.0]:
		_tone(a, k, 0.3, f, f, 0.25, 1, 0.003, 9)
		_tone(a, k, 0.3, f * 2.0, f * 2.0, 0.06, 0, 0.003, 12)
		k += 0.05
	sfx["joker"] = _wav(a)
	a = _buf(0.2)
	_tone(a, 0, 0.16, 660, 700, 0.35, 0, 0.002, 14)
	_tone(a, 0, 0.12, 1320, 1400, 0.15, 1, 0.002, 18)
	sfx["combo"] = _wav(a)
	a = _buf(0.08)
	_noise(a, 0, 0.03, 0.4, 80, 0.4)
	_tone(a, 0, 0.05, 900, 900, 0.2, 0, 0.001, 40)
	sfx["score"] = _wav(a)
	a = _buf(1.6)
	var notes := [523.0, 659.0, 784.0, 1047.0]
	for i in 4: _tone(a, i * 0.12, 0.25, notes[i], notes[i], 0.3, 1, 0.004, 6)
	for f in [523.0, 659.0, 784.0, 1047.0]: _tone(a, 0.5, 1.0, f, f, 0.18, 1, 0.01, 2.5)
	sfx["win"] = _wav(a)
	a = _buf(1.5)
	notes = [440.0, 349.0, 294.0, 220.0]
	for i in 4: _tone(a, i * 0.22, 0.45, notes[i], notes[i] * 0.98, 0.3, 1, 0.01, 4)
	_tone(a, 0.9, 0.6, 110, 90, 0.3, 2, 0.02, 3)
	sfx["lose"] = _wav(a)

# ---------- 背景音乐：Am-F-C-G / Am-F-G-E，鼓点+低音+琶音+和弦垫 ----------
func _build_music() -> void:
	var beat := 60.0 / 96.0
	var bars := 8
	var a := _buf(beat * 4.0 * bars)
	var chords := [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62], [57, 60, 64], [53, 57, 60], [55, 59, 62], [52, 56, 59]]
	var roots := [45, 41, 36, 43, 45, 41, 43, 40]
	for b in bars:
		var t0 := b * beat * 4.0
		var ch: Array = chords[b]
		for n in ch: _tone(a, t0, beat * 4.0, _hz(n), _hz(n), 0.05, 0, 0.4, 0.5)
		var r := _hz(roots[b])
		_tone(a, t0, beat * 1.5, r, r, 0.22, 1, 0.01, 3.0)
		_tone(a, t0 + beat * 2.0, beat * 1.5, r * (1.5 if b % 2 == 0 else 1.0), r * (1.5 if b % 2 == 0 else 1.0), 0.2, 1, 0.01, 3.0)
		for i in 8:
			var note: int = ch[(i * (1 + b % 2)) % 3] + 12 + (12 if i % 4 == 3 else 0)
			_tone(a, t0 + i * beat * 0.5, beat * 0.5, _hz(note), _hz(note), 0.07, 1, 0.005, 9.0)
		for i in 4: _noise(a, t0 + beat * (i + 0.5), 0.05, 0.06, 40.0, 0.6)
		for i in [0, 2]: _tone(a, t0 + beat * i, 0.15, 110, 45, 0.28, 0, 0.002, 14.0)
	call_deferred("_start_music", _wav(a, true))

func _start_music(stream: AudioStreamWAV) -> void:
	music_player.stream = stream
	music_player.play()
