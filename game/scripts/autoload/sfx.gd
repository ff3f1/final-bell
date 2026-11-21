extends Node






const RATE: = 22050
const SFX_DIR: = "res://assets/sfx/"
const MUSIC_DIR: = "res://assets/music/"

var streams: = {}
var _last_pick: = {}
var pool: Array[AudioStreamPlayer] = []
var crowd_player: AudioStreamPlayer
var cheer_player: AudioStreamPlayer
var crowd_target: = 0.35
var crowd_level: = 0.0
var _rng: = RandomNumberGenerator.new()
var _bell_long: = false

var _music: Array[AudioStreamPlayer] = []
var _music_cur: = -1
var _music_name: = ""
var _music_gain: = [0.0, 0.0]
var _music_target: = [0.0, 0.0]
var _music_fade: = [1.0, 1.0]
var music_duck: = 1.0
var _group: = ""
var _group_loop: = false
var _group_gain: = 1.0
var _group_last: = ""


const MUSIC_GROUPS: = {
	"menu": ["hiphop_main", "trap_stadium", "hiphop_rock", "electro_anthem", "phonk_drift"], 
	"career": ["lofi_camp", "montage", "hiphop_main", "hiphop_rock"], 
	"walkout": ["drill_walkout", "phonk_drift", "trap_stadium", "hiphop_rock"], 
	"tournament": ["electro_anthem", "trap_stadium", "drill_walkout"], 
	"victory": ["victory"], 
	"defeat": ["defeat"], 
}


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_build_all()
	for i in 14:
		var p: = AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	crowd_player = AudioStreamPlayer.new()
	crowd_player.stream = _pick("crowd")
	crowd_player.volume_db = -80.0
	add_child(crowd_player)
	cheer_player = AudioStreamPlayer.new()
	cheer_player.stream = _pick("cheer")
	add_child(cheer_player)
	for i in 2:
		var mp: = AudioStreamPlayer.new()
		mp.volume_db = -80.0
		add_child(mp)
		_music.append(mp)
		mp.finished.connect(_on_music_finished.bind(i))


func _process(delta: float) -> void :
	var real_delta: float = delta / maxf(Engine.time_scale, 0.05)
	crowd_level = move_toward(crowd_level, crowd_target, real_delta * 0.6)
	var cv: float = Game.setting_f("crowd_volume")
	if crowd_player.playing:
		crowd_player.volume_db = linear_to_db(maxf(crowd_level * cv, 0.0001)) - 10.0
	var mv: float = Game.setting_f("music_volume")
	for i in 2:
		var mp: = _music[i]
		_music_gain[i] = move_toward(_music_gain[i], _music_target[i], real_delta / maxf(_music_fade[i], 0.05))
		if mp.playing:
			mp.volume_db = linear_to_db(maxf(_music_gain[i] * mv * music_duck, 0.0001)) - 6.0
			if _music_gain[i] <= 0.0005 and _music_target[i] <= 0.0:
				mp.stop()


func _pick(sound: String) -> AudioStream:
	var arr: Array = streams.get(sound, [])
	if arr.is_empty():
		return null
	if arr.size() == 1:
		return arr[0]
	var last: int = _last_pick.get(sound, -1)
	var i: = _rng.randi() % arr.size()
	if i == last:
		i = (i + 1 + _rng.randi() % (arr.size() - 1)) % arr.size()
	_last_pick[sound] = i
	return arr[i]


func play(sound: String, volume_db: float = 0.0, pitch_var: float = 0.08, pitch: float = 1.0) -> AudioStreamPlayer:
	var st: = _pick(sound)
	if st == null:
		return null
	var p: AudioStreamPlayer = null
	for candidate in pool:
		if not candidate.playing:
			p = candidate
			break
	if p == null:
		p = pool[_rng.randi() % pool.size()]
	p.stream = st
	var sv: float = Game.setting_f("sfx_volume")
	p.volume_db = volume_db + linear_to_db(maxf(sv, 0.0001))
	p.pitch_scale = maxf(0.2, pitch * (1.0 + _rng.randf_range( - pitch_var, pitch_var)))
	p.play()
	return p


func play_bell(times: int = 3) -> void :
	if _bell_long:

		var p: = play("bell", -1.0, 0.0)
		if p and times == 1:
			var tw: = create_tween().set_ignore_time_scale(true)
			tw.tween_interval(0.75)
			tw.tween_property(p, "volume_db", -60.0, 0.45)
			tw.tween_callback(p.stop)
		elif p and times > 3:
			get_tree().create_timer(1.1, true, false, true).timeout.connect( func(): play("bell", -3.0, 0.0))
		return
	for i in times:
		get_tree().create_timer(0.32 * i, true, false, true).timeout.connect( func(): play("bell", -2.0, 0.0))



func hit(sound: String, volume_db: float = 0.0, pitch_var: float = 0.07) -> void :
	play(sound, volume_db, pitch_var)


func start_crowd() -> void :
	if not crowd_player.playing:
		crowd_player.play()
	crowd_target = 0.35


func stop_crowd() -> void :
	crowd_target = 0.0


func set_crowd(level: float) -> void :
	crowd_target = clampf(level, 0.0, 1.0)


func cheer(strength: float = 1.0) -> void :
	var cv: float = Game.setting_f("crowd_volume")
	var st: = _pick("cheer")
	if strength < 0.8 and streams.has("ooh") and _rng.randf() < 0.6:
		st = _pick("ooh")
	if st:
		cheer_player.stream = st
	cheer_player.volume_db = linear_to_db(maxf(clampf(strength, 0.05, 1.5) * cv, 0.0001)) - 8.0
	cheer_player.pitch_scale = _rng.randf_range(0.94, 1.06)
	cheer_player.play()




func has_music(name: String) -> bool:
	for ext: String in ["mp3", "ogg"]:
		if ResourceLoader.exists(MUSIC_DIR + name + "." + ext):
			return true
	return false


func play_music(name: String, fade: float = 1.5, loop: bool = true, gain: float = 1.0) -> void :
	if name == _music_name and _music_cur >= 0 and _music[_music_cur].playing:
		_music_target[_music_cur] = gain
		return
	var st: AudioStream = null
	for ext: String in ["mp3", "ogg"]:
		var path: = MUSIC_DIR + name + "." + ext
		if ResourceLoader.exists(path):
			st = load(path)
			break
	if st == null:
		stop_music(fade)
		return
	if st is AudioStreamMP3:
		(st as AudioStreamMP3).loop = loop
	elif st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = loop
	if _music_cur >= 0:
		_music_target[_music_cur] = 0.0
		_music_fade[_music_cur] = fade
	_music_cur = 0 if _music_cur != 0 else 1
	var mp: = _music[_music_cur]
	mp.stream = st
	mp.volume_db = -80.0
	_music_gain[_music_cur] = 0.0
	_music_target[_music_cur] = gain
	_music_fade[_music_cur] = fade
	mp.play()
	_music_name = name
	_group = ""


func stop_music(fade: float = 1.5) -> void :
	for i in 2:
		_music_target[i] = 0.0
		_music_fade[i] = fade
	_music_name = ""
	_group = ""



func play_group(group: String, fade: float = 1.5, gain: float = 1.0, loop: bool = true) -> void :
	if group == _group and _music_name != "":
		return
	var list: Array = []
	for n in MUSIC_GROUPS.get(group, [group]):
		if has_music(str(n)):
			list.append(str(n))
	if list.is_empty():

		play_music(group, fade, loop, gain)
		return
	var pick: String = list[_rng.randi() % list.size()]
	if list.size() > 1 and pick == _group_last:
		pick = list[(list.find(pick) + 1) % list.size()]
	_group = group
	_group_loop = loop
	_group_gain = gain
	_group_last = pick
	play_music(pick, fade, false, gain)
	_group = group


func _on_music_finished(idx: int) -> void :
	if idx != _music_cur or _group == "" or not _group_loop:
		return
	var g: = _group
	_group = ""
	_music_name = ""
	play_group(g, 0.5, _group_gain, true)




func _build_all() -> void :
	streams["punch_light"] = _impact(0.09, 95.0, 1800.0, 0.55, 0.9)
	streams["punch_heavy"] = _impact(0.17, 62.0, 1100.0, 0.9, 1.0)
	streams["punch_body"] = _impact(0.16, 55.0, 650.0, 1.0, 0.75)
	streams["block"] = _impact(0.07, 130.0, 520.0, 0.45, 0.45)
	streams["parry"] = _parry()
	streams["whoosh"] = _whoosh(0.2)
	streams["bell"] = _bell(1.4, 820.0)
	streams["tick"] = _bell(0.25, 1600.0)
	streams["thud"] = _impact(0.38, 42.0, 380.0, 1.0, 0.6)
	streams["crowd"] = _crowd_loop(4.0)
	streams["cheer"] = _cheer(3.2)
	for key in streams.keys():
		streams[key] = [streams[key]]
	streams["ooh"] = []
	streams["boo"] = []
	streams["bag"] = []
	streams["exhale"] = []
	streams["rope"] = []

	for key in streams.keys():
		var k: String = key
		var found: Array = []
		for suffix: String in ["", "_1", "_2", "_3", "_4", "_5", "_6", "_7", "_8", "_9", "_10", "_11", "_12"]:
			for ext: String in ["wav", "ogg", "mp3"]:
				var path: = SFX_DIR + k + suffix + "." + ext
				if ResourceLoader.exists(path):
					var s: AudioStream = load(path)
					if s:
						found.append(s)
					break
		if not found.is_empty():
			streams[k] = found
	for k in streams.keys().duplicate():
		if (streams[k] as Array).is_empty():
			streams.erase(k)
	var cr: Array = streams.get("crowd", [])
	for c in cr:
		if c is AudioStreamWAV:
			var w: = c as AudioStreamWAV
			if w.loop_mode == AudioStreamWAV.LOOP_DISABLED:
				w.loop_mode = AudioStreamWAV.LOOP_FORWARD
				w.loop_begin = 0
				w.loop_end = int(w.get_length() * w.mix_rate)
	var bl: Array = streams.get("bell", [])
	_bell_long = not bl.is_empty() and (bl[0] as AudioStream).get_length() > 1.6


func _make_wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var data: = PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var v: int = int(clampf(samples[i], -1.0, 1.0) * 32000.0)
		data.encode_s16(i * 2, v)
	var w: = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w



func _impact(length: float, thump_hz: float, cutoff: float, thump_amt: float, noise_amt: float) -> AudioStreamWAV:
	var n: = int(length * RATE)
	var out: = PackedFloat32Array()
	out.resize(n)
	var lp: = 0.0
	var a: float = clampf(cutoff / float(RATE) * 6.28, 0.01, 0.99)
	var phase: = 0.0
	for i in n:
		var t: float = float(i) / RATE
		var env_noise: float = exp( - t * 55.0)
		var env_thump: float = exp( - t * 22.0)
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * a
		var f: float = thump_hz * (1.0 + 1.5 * exp( - t * 40.0))
		phase += TAU * f / RATE
		var s: float = sin(phase) * env_thump * thump_amt + lp * env_noise * noise_amt * 2.2

		out[i] = tanh(s * 1.6) * 0.9
	return _make_wav(out)


func _parry() -> AudioStreamWAV:
	var n: = int(0.22 * RATE)
	var out: = PackedFloat32Array()
	out.resize(n)
	var lp: = 0.0
	for i in n:
		var t: float = float(i) / RATE
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.25
		var s: float = lp * exp( - t * 70.0) * 1.4
		s += sin(TAU * 240.0 * t) * exp( - t * 25.0) * 0.5
		s += sin(TAU * 960.0 * t) * exp( - t * 30.0) * 0.12
		out[i] = tanh(s)
	return _make_wav(out)


func _whoosh(length: float) -> AudioStreamWAV:
	var n: = int(length * RATE)
	var out: = PackedFloat32Array()
	out.resize(n)
	var lp1: = 0.0
	var lp2: = 0.0
	for i in n:
		var t: float = float(i) / n
		var cutoff: float = lerpf(0.04, 0.35, sin(t * PI))
		var x: float = _rng.randf_range(-1.0, 1.0)
		lp1 += (x - lp1) * cutoff
		lp2 += (lp1 - lp2) * cutoff
		var env: float = sin(t * PI) * sin(t * PI)
		out[i] = (lp1 - lp2) * env * 2.4
	return _make_wav(out)



func _bell(length: float, base_hz: float) -> AudioStreamWAV:
	var n: = int(length * RATE)
	var out: = PackedFloat32Array()
	out.resize(n)
	var partials: = [1.0, 2.76, 5.4, 8.93, 1.5, 2.0]
	var amps: = [1.0, 0.55, 0.32, 0.18, 0.22, 0.25]
	var decays: = [3.0, 4.5, 7.0, 9.0, 3.5, 4.0]
	for i in n:
		var t: float = float(i) / RATE
		var s: = 0.0
		for p in partials.size():
			var ph: float = partials[p]
			var am: float = amps[p]
			var dc: float = decays[p]
			s += sin(TAU * base_hz * ph * t) * am * exp( - t * dc)
		var strike: float = _rng.randf_range(-1.0, 1.0) * exp( - t * 300.0) * 0.4
		out[i] = (s * 0.32 + strike) * minf(1.0, t * 800.0)
	return _make_wav(out)



func _crowd_loop(length: float) -> AudioStreamWAV:
	var n: = int(length * RATE)
	var out: = PackedFloat32Array()
	out.resize(n)
	var b0: = 0.0
	var b1: = 0.0
	var b2: = 0.0
	var lp: = 0.0
	var voices: = []
	for v in 6:
		voices.append({"f": _rng.randf_range(160.0, 420.0), "ph": 0.0, "rate": _rng.randf_range(0.4, 1.6), "off": _rng.randf_range(0.0, TAU)})
	for i in n:
		var t: float = float(i) / RATE
		var w: float = _rng.randf_range(-1.0, 1.0)
		b0 = 0.99765 * b0 + w * 0.099046
		b1 = 0.963 * b1 + w * 0.2965164
		b2 = 0.57 * b2 + w * 1.0526913
		var pink: float = (b0 + b1 + b2 + w * 0.1848) * 0.18
		lp += (pink - lp) * 0.22
		var s: float = lp
		for v in voices:
			var vd: Dictionary = v
			var f: float = vd["f"]
			var rate: float = vd["rate"]
			var off: float = vd["off"]
			var amp: float = maxf(0.0, sin(TAU * rate * t / length * 4.0 + off))
			s += sin(TAU * f * t + off) * amp * 0.012 * (0.5 + 0.5 * sin(TAU * 5.0 * t + off))

		var edge: float = minf(1.0, minf(t, length - t) / 0.25)
		out[i] = s * (0.6 + 0.4 * edge)
	return _make_wav(out, true)



func _cheer(length: float) -> AudioStreamWAV:
	var n: = int(length * RATE)
	var out: = PackedFloat32Array()
	out.resize(n)
	var lp: = 0.0
	var lp2: = 0.0
	for i in n:
		var t: float = float(i) / RATE
		var env: float = minf(1.0, t / 0.18) * exp( - maxf(0.0, t - 0.4) * 1.3)
		var x: float = _rng.randf_range(-1.0, 1.0)
		lp += (x - lp) * 0.32
		lp2 += (lp - lp2) * 0.08
		var s: float = (lp - lp2 * 0.6) * 0.9
		s += sin(TAU * (300.0 + 40.0 * sin(t * 9.0)) * t) * 0.05 * env
		out[i] = tanh(s * env * 1.8) * 0.85
	return _make_wav(out)
