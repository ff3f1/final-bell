class_name RefereeRig
extends MixamoRig





var ref_action: = ""
var ref_pulse: = 0.0
var _t: = 0.0
var ext_move: = Vector2.ZERO
var _last_pulse: = -1.0
var _count_n: = 0
var _beats: Array = []
var _was_action: = ""

const WALK_SPEED: = {"ref_walk": 1.35, "ref_walk_back": 1.0, "ref_strafe_left": 1.05, "ref_strafe_right": 1.05}


static func available_model() -> bool:
	return model_path_for_def({"id": "referee"}) != "" and ResourceLoader.exists(ANIM_DIR + "ref_idle.glb")


func setup_referee() -> void :
	setup({"id": "referee", "model": "referee", "height": 1.78, "stance": 1, "anim_prefix": "ref_"}, null)

	if mod:
		mod.active = false
	_find_beats()
	_play("ref_idle", 0.0)



func _find_beats() -> void :
	_beats = []
	if not available.has("ref_count") or skeleton == null:
		return
	var ln: = _len("ref_count")
	var hr: = _bone_idx("righthand")
	var hl: = _bone_idx("lefthand")
	if hr < 0 or hl < 0:
		return
	var ys: = {hr: [], hl: []}
	var times: Array = []
	anim.play("box/ref_count", 0.0)
	var t: = 0.0
	while t < ln:
		anim.seek(t, true)
		times.append(t)
		for hi in [hr, hl]:
			(ys[hi] as Array).append((skeleton.get_bone_global_pose(hi).origin).y)
		t += 1.0 / 30.0
	anim.stop()

	var best: = hr
	var best_var: = -1.0
	for hi in [hr, hl]:
		var arr: Array = ys[hi]
		var mn: = 1000000000.0
		var mx: = -1000000000.0
		for v in arr:
			mn = minf(mn, v)
			mx = maxf(mx, v)
		if mx - mn > best_var:
			best_var = mx - mn
			best = hi
	var y: Array = ys[best]
	var amp: = best_var
	var last_t: = -10.0
	for i in range(3, y.size() - 3):
		var v: float = y[i]
		if v <= y[i - 1] and v <= y[i + 1] and v <= y[i - 2] and v <= y[i + 2]:
			var peak: = v
			for j in range(maxi(0, i - 18), i):
				peak = maxf(peak, y[j])
			if peak - v > amp * 0.25 and float(times[i]) - last_t > 0.6:
				_beats.append(times[i])
				last_t = times[i]
	if _beats.size() < 6:
		_beats = []
		for k in 10:
			_beats.append(ln * (0.08 + 0.88 * float(k) / 9.0))


func update_rig(delta: float) -> void :
	_t += delta
	if anim == null:
		return
	if _hold_at >= 0.0 and anim.current_animation_position >= _hold_at:
		anim.speed_scale = 0.0
	if ref_action != _was_action:
		_was_action = ref_action
		_count_n = 0
		_last_pulse = -1.0
		match ref_action:
			"start":
				_play("ref_point", 0.25, 1.1, true)
			"separate":
				if _play("ref_push", 0.15, 1.0, true):
					_hold_at = _len("ref_push") * 0.5
			"wave":
				_play("ref_wave", 0.25, 1.0, true)
	match ref_action:
		"count":
			if ref_pulse != _last_pulse:
				_last_pulse = ref_pulse
				_count_n += 1
				if not _beats.is_empty():
					var i: = clampi(_count_n - 1, 0, _beats.size() - 1)
					var from: float = _beats[i]
					var to: float = _beats[mini(i + 1, _beats.size() - 1)]
					var spd: = clampf((to - from) / 1.0, 0.4, 2.5) if to > from else 1.0
					_play("ref_count", 0.18 if _count_n == 1 else 0.08, spd, true, maxf(from - 0.05, 0.0))
			return
		"start", "separate", "wave":
			if ref_action == "start" and current == "ref_point" and anim.current_animation_position >= _len("ref_point") * 0.85:
				_play("ref_idle", 0.4)
			return
	var spd_ms: = ext_move.length() * 2.0
	if spd_ms > 0.25:
		var n: = ""
		if absf(ext_move.y) >= absf(ext_move.x):
			n = "ref_walk" if ext_move.y > 0.0 else "ref_walk_back"
		else:
			n = "ref_strafe_right" if ext_move.x > 0.0 else "ref_strafe_left"
		_play(n, 0.3, clampf(spd_ms / float(WALK_SPEED.get(n, 1.2)), 0.5, 1.8))
	else:
		_play("ref_idle", 0.4)
