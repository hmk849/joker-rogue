extends Node
# 全部音效与背景音乐由代码合成（正弦/三角/方波 + 噪声 + 指数包络），不使用任何外部音频。
var _sr := 22050
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
	a.resize(int(sec * _sr))
	return a

func _tone(a: PackedFloat32Array, t0: float, dur: float, f0: float, f1: float, vol: float, wave: int = 0, atk: float = 0.004, decay: float = 6.0) -> void:
	var n := int(dur * _sr)
	var s0 := int(t0 * _sr)
	var ph := 0.0
	var an := maxf(atk * _sr, 1.0)
	for i in n:
		var idx := s0 + i
		if idx >= a.size(): break
		ph += lerpf(f0, f1, float(i) / n) / _sr
		var w := sin(TAU * ph)
		if wave == 1: w = 4.0 * absf(fposmod(ph, 1.0) - 0.5) - 1.0
		elif wave == 2: w = 0.6 if fposmod(ph, 1.0) < 0.5 else -0.6
		a[idx] += w * minf(1.0, i / an) * exp(-decay * float(i) / _sr) * vol

func _noise(a: PackedFloat32Array, t0: float, dur: float, vol: float, decay: float, coef: float) -> void:
	var n := int(dur * _sr)
	var s0 := int(t0 * _sr)
	var y := 0.0
	for i in n:
		var idx := s0 + i
		if idx >= a.size(): break
		y += (randf_range(-1.0, 1.0) - y) * coef  # 一阶低通
		a[idx] += y * exp(-decay * float(i) / _sr) * vol

func _wav(a: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var peak := 0.001
	for x in a: peak = maxf(peak, absf(x))
	var g := 0.85 / maxf(peak, 0.85)
	var bytes := PackedByteArray()
	bytes.resize(a.size() * 2)
	for i in a.size(): bytes.encode_s16(i * 2, int(clampf(a[i] * g, -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = _sr
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

# ---------- 背景音乐：Lo-fi 爵士（84 BPM 摇摆，16 小节 A/B 两段）----------
# 电钢琴(FM)和弦 + 三角波低音 + 旋律 + 刷子鼓/踩镲 + 磁带回声 + 唱片底噪
const SW := 0.14  # 摇摆：反拍延后 0.14 拍
const CHORDS := {"Dm9": [65, 69, 72, 76], "G13": [59, 64, 65], "Cmaj9": [64, 67, 71, 74], "Am7": [64, 67, 72],
	"D7b9": [66, 69, 72], "Fmaj7": [64, 69, 72], "Em7": [62, 67, 71], "A7": [67, 73, 76]}
const ROOTS := {"Dm9": 38, "G13": 43, "Cmaj9": 36, "Am7": 45, "D7b9": 38, "Fmaj7": 41, "Em7": 40, "A7": 45}
const BARS := [["Dm9", "Dm9"], ["G13", "G13"], ["Cmaj9", "Cmaj9"], ["Am7", "D7b9"], ["Dm9", "Dm9"], ["G13", "G13"], ["Cmaj9", "Cmaj9"], ["Fmaj7", "Fmaj7"],
	["Fmaj7", "Fmaj7"], ["Em7", "A7"], ["Dm9", "Dm9"], ["G13", "G13"], ["Cmaj9", "Cmaj9"], ["Am7", "Am7"], ["Dm9", "G13"], ["Cmaj9", "Cmaj9"]]
const MELODY := [  # 每小节：[拍位, midi, 时值(拍)]
	[[0.0, 76, 1.0], [1.5, 74, 0.5], [2.0, 72, 1.0], [3.5, 69, 0.5]], [[0.0, 71, 1.5], [2.0, 72, 0.5], [2.5, 74, 1.5]],
	[[0.0, 76, 2.0], [2.5, 79, 0.5], [3.0, 76, 1.0]], [[0.0, 74, 1.0], [1.0, 72, 1.0], [2.5, 69, 1.0]],
	[[0.0, 81, 1.5], [2.0, 79, 0.5], [2.5, 77, 0.5], [3.0, 76, 1.0]], [[0.0, 74, 1.5], [2.0, 71, 1.0], [3.0, 74, 1.0]],
	[[0.0, 72, 1.0], [1.5, 76, 0.5], [2.0, 79, 2.0]], [[0.0, 77, 1.5], [2.0, 76, 0.5], [2.5, 72, 1.5]],
	[[0.5, 81, 0.5], [1.0, 79, 1.0], [2.5, 77, 0.5], [3.0, 76, 1.0]], [[0.0, 74, 1.0], [1.5, 71, 0.5], [2.0, 73, 1.0], [3.0, 76, 1.0]],
	[[0.0, 74, 2.0], [2.5, 77, 0.5], [3.0, 81, 1.0]], [[0.0, 79, 1.5], [2.0, 76, 0.5], [2.5, 74, 1.5]],
	[[0.0, 72, 1.0], [1.0, 76, 1.0], [2.0, 79, 1.0], [3.0, 83, 1.0]], [[0.0, 81, 2.0], [2.5, 79, 0.5], [3.0, 76, 1.0]],
	[[0.0, 74, 1.0], [1.0, 77, 1.0], [2.0, 71, 1.0], [3.0, 74, 1.0]], [[0.0, 76, 3.0]],
]

func _sw(x: float) -> float: return x + SW if absf(x - floorf(x) - 0.5) < 0.01 else x

func _ep(a: PackedFloat32Array, t0: float, dur: float, f: float, vol: float) -> void:  # FM 电钢琴
	var n := int(dur * _sr)
	var s0 := int(t0 * _sr)
	var ph := 0.0
	var mp := 0.0
	for i in n:
		var idx := s0 + i
		if idx >= a.size(): break
		var t := float(i) / _sr
		ph += f / _sr
		mp += f * 2.0 / _sr
		var m := sin(TAU * mp) * 1.5 * exp(-5.0 * t)
		var env := minf(1.0, t / 0.004) * exp(-1.8 * t) * minf(1.0, (dur - t) / 0.03)
		a[idx] += sin(TAU * ph + m) * env * vol * (1.0 + 0.1 * sin(TAU * 4.5 * t))

func _lead(a: PackedFloat32Array, t0: float, dur: float, f: float, vol: float) -> void:  # 带颤音的旋律
	var n := int(dur * _sr)
	var s0 := int(t0 * _sr)
	var ph := 0.0
	for i in n:
		var idx := s0 + i
		if idx >= a.size(): break
		var t := float(i) / _sr
		ph += f * (1.0 + 0.004 * sin(TAU * 5.2 * t) * minf(1.0, t * 3.0)) / _sr
		var env := minf(1.0, t / 0.025) * exp(-1.1 * t) * minf(1.0, (dur - t) / 0.05)
		a[idx] += (sin(TAU * ph) + 0.28 * sin(TAU * ph * 2.0) + 0.1 * sin(TAU * ph * 3.0)) * env * vol

func _build_music() -> void:
	_sr = 16000  # 此后只有本线程做合成（音效已在启动时生成完毕）
	var beat := 60.0 / 84.0
	var a := _buf(beat * 4.0 * 16.0)
	for bar in 16:
		var t0 := bar * 4.0 * beat
		for h in 2:
			var cn: String = BARS[bar][h]
			var notes: Array = CHORDS[cn]
			var root: int = ROOTS[cn]
			var hb := h * 2.0
			for nn in notes:
				_ep(a, t0 + _sw(hb) * beat, beat * 1.3, _hz(nn), 0.085)
				_ep(a, t0 + _sw(hb + 1.5) * beat, beat * 0.4, _hz(nn), 0.05)
			_tone(a, t0 + hb * beat, beat * 0.95, _hz(root), _hz(root), 0.24, 1, 0.01, 3.0)
			_tone(a, t0 + _sw(hb + 1.5) * beat, beat * 0.4, _hz(root + 7), _hz(root + 7), 0.18, 1, 0.01, 4.0)
		for m in MELODY[bar]: _lead(a, t0 + _sw(float(m[0])) * beat, float(m[2]) * beat * 0.95, _hz(float(m[1])), 0.11)
		for k in 8: _noise(a, t0 + _sw(k * 0.5) * beat, 0.03, 0.03 if k % 2 == 0 else 0.018, 90.0, 0.9)
		_tone(a, t0, 0.14, 120, 48, 0.32, 0, 0.002, 16.0)
		if bar % 2 == 0: _tone(a, t0 + _sw(2.5) * beat, 0.12, 110, 48, 0.24, 0, 0.002, 18.0)
		for sb in [1.0, 3.0]:
			_noise(a, t0 + sb * beat, 0.12, 0.07, 18.0, 0.5)
			_tone(a, t0 + sb * beat, 0.08, 190, 150, 0.04, 0, 0.002, 30.0)
	var n := a.size()
	var src := a.duplicate()
	var d := int(beat * 0.75 * _sr)  # 附点八分回声（循环，首尾无缝）
	for i in n: a[(i + d) % n] += src[i] * 0.22
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for k in int(n / float(_sr) * 14.0): a[rng.randi() % n] += rng.randf_range(-1.0, 1.0) * 0.02  # 唱片底噪
	for i in 160:
		a[i] *= i / 160.0
		a[n - 1 - i] *= i / 160.0
	call_deferred("_start_music", _wav(a, true))

func _start_music(stream: AudioStreamWAV) -> void:
	music_player.stream = stream
	music_player.play()
