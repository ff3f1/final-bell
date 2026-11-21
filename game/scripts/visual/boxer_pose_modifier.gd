class_name BoxerPoseModifier
extends SkeletonModifier3D




var side: = 0.0
var duck: = 0.0
var back: = 0.0
var stun: = 0.0
var side_sign: = 1.0
var head_kick: = Vector3.ZERO
var head_vel: = Vector3.ZERO
var body_kick: = Vector3.ZERO
var body_vel: = Vector3.ZERO


var neck_kick: = Vector3.ZERO
var neck_vel: = Vector3.ZERO
var dip: = 0.0
var _dip_v: = 0.0
var flail: = 0.0
var _limp: = 0.0
var _t: = 0.0

var guard: Dictionary = {}
var guard_w: = 0.0
var tempo: = 1.0
var _phase: = 0.0
var _paw_t: = 2.0
var _paw: = 0.0

var _feint_t: = 1.5
var _feint: = 0.0
var _feint_kind: = 0

var block_w: = 0.0
var block_low: = 0.0

var block_recoil: = 0.0
var _recoil_v: = 0.0

var punch_twist: = 0.0

var guard_broken: = 0.0


var clinch_w: = 0.0
var clinch_lead: = Vector3.ZERO
var clinch_rear: = Vector3.ZERO
var clinch_side: = 1.0
var clinch_push: = 0.0

var _ids: = {}
var _thigh_len: = 0.45
var _shin_len: = 0.45


const BLOCK_HI_LEAD: = Vector3(0.085, -0.035, 0.165)
const BLOCK_HI_REAR: = Vector3(-0.08, -0.05, 0.145)
const BLOCK_LO_LEAD: = Vector3(0.1, -0.2, 0.15)
const BLOCK_LO_REAR: = Vector3(-0.1, -0.215, 0.13)


func setup_bones(sk: Skeleton3D) -> void :
	for key in ["hips", "spine", "spine1", "spine2", "neck", "head", "leftupleg", "leftleg", "leftfoot", 
			"rightupleg", "rightleg", "rightfoot", "leftshoulder", "rightshoulder", "leftarm", "leftforearm", "lefthand", 
			"rightarm", "rightforearm", "righthand"]:
		_ids[key] = _find(sk, key)
	var a: int = _ids["leftupleg"]
	var b: int = _ids["leftleg"]
	var c: int = _ids["leftfoot"]
	if a >= 0 and b >= 0 and c >= 0:
		_thigh_len = sk.get_bone_global_rest(a).origin.distance_to(sk.get_bone_global_rest(b).origin)
		_shin_len = sk.get_bone_global_rest(b).origin.distance_to(sk.get_bone_global_rest(c).origin)


static func _find(sk: Skeleton3D, key: String) -> int:
	for i in sk.get_bone_count():
		var n: = sk.get_bone_name(i).to_lower()
		var cut: = n.rfind("_")
		var cut2: = n.rfind(":")
		var k: = n.substr(maxi(cut, cut2) + 1)
		if k == key:
			return i
	return -1


func impulse_head(v: Vector3) -> void :
	head_vel += v


func impulse_body(v: Vector3) -> void :
	body_vel += v


func impulse_block(v: float) -> void :
	_recoil_v += v




func hit_react(dir: Vector3, strength: float, zone: String, kind: int) -> void :
	var s: = clampf(strength, 0.0, 1.6)
	var d: = dir
	d.y = 0.0
	d = d.normalized() if d.length() > 0.01 else Vector3(0, 0, -1)
	var lat: = d.x
	var push_back: = - d.z
	var k: Dictionary = Balance.HIT_REACT
	if zone == "body":
		s *= float(k["body"])
		body_vel += Vector3(5.5 * s * maxf(push_back, 0.3), - lat * 2.0 * s, - lat * 3.0 * s)
		_dip_v += 0.9 * s + (0.5 * s if s > 0.8 else 0.0)
		head_vel += Vector3(-2.5 * s, 0.0, 0.0)
	else:
		s *= float(k["head"])
		match kind:
			2:
				head_vel += Vector3(10.5 * s, - lat * 2.0 * s, - lat * 1.5 * s)
				body_vel += Vector3(2.2 * s, 0.0, 0.0)
			1:
				head_vel += Vector3(2.0 * s, - lat * 10.5 * s, - lat * 5.0 * s)
				body_vel += Vector3(0.8 * s, - lat * 2.4 * s, - lat * 1.4 * s)
			_:
				head_vel += Vector3(9.0 * s * maxf(push_back, 0.4), - lat * 5.0 * s, - lat * 2.5 * s)
				body_vel += Vector3(1.8 * s * maxf(push_back, 0.4), - lat * 1.2 * s, 0.0)
		if s > 0.7:
			_dip_v += (s - 0.7) * 1.2
	_limp = clampf(maxf(_limp, (s - 0.45) * 1.1), 0.0, float(k["max"]) - 0.4)
	flail = maxf(flail, clampf((s - 0.7) * 1.2, 0.0, 0.6))


func step(delta: float) -> void :
	_t += delta
	if delta <= 0.0:
		return
	_phase += delta * tempo

	if not guard.is_empty() and float(guard.get("paw", 0.0)) > 0.0:
		_paw_t -= delta * float(guard["paw"])
		if _paw_t <= 0.0:
			_paw_t = randf_range(1.4, 3.2)
			_paw = 1.0
	_paw = maxf(0.0, _paw - delta * 3.2)
	_feint_t -= delta * tempo
	if _feint_t <= 0.0:
		_feint_t = randf_range(1.4, 4.0)
		_feint = 1.0
		_feint_kind = randi() % 3
	_feint = maxf(0.0, _feint - delta * 4.5)

	_limp = maxf(0.0, _limp - delta * 1.4)
	var limp: = clampf(maxf(_limp, stun * 0.5), 0.0, 1.0)
	var hk: = lerpf(140.0, 48.0, limp)
	var hc: = lerpf(14.0, 6.5, limp)
	head_vel += ( - head_kick * hk - head_vel * hc) * delta
	head_kick += head_vel * delta

	neck_vel += ((head_kick * 0.55 - neck_kick) * 95.0 - neck_vel * 12.0) * delta
	neck_kick += neck_vel * delta
	body_vel += ( - body_kick * lerpf(90.0, 50.0, limp) - body_vel * lerpf(11.0, 7.0, limp)) * delta
	body_kick += body_vel * delta

	head_kick = head_kick.clamp(Vector3(-0.62, -0.75, -0.6), Vector3(0.62, 0.75, 0.6))
	neck_kick = neck_kick.clamp(Vector3(-0.32, -0.4, -0.32), Vector3(0.32, 0.4, 0.32))
	body_kick = body_kick.clamp(Vector3(-0.5, -0.5, -0.5), Vector3(0.5, 0.5, 0.5))

	_dip_v += ( - dip * 120.0 - _dip_v * 13.0) * delta
	dip = clampf(dip + _dip_v * delta, 0.0, 0.16)
	flail = maxf(0.0, flail - delta * 2.2)
	_recoil_v += ( - block_recoil * 260.0 - _recoil_v * 20.0) * delta
	block_recoil = clampf(block_recoil + _recoil_v * delta, -0.02, 0.09)


func _rotate_global(sk: Skeleton3D, idx: int, axis: Vector3, angle: float) -> void :
	if idx < 0 or absf(angle) < 0.0001:
		return
	var g: = sk.get_bone_global_pose(idx)
	var parent: = sk.get_bone_parent(idx)
	var pg: = Transform3D.IDENTITY if parent < 0 else sk.get_bone_global_pose(parent)
	var nb: = Basis(axis.normalized(), angle) * g.basis
	var local: = pg.basis.inverse() * nb
	sk.set_bone_pose_rotation(idx, local.get_rotation_quaternion())


func _process_modification() -> void :
	var sk: = get_skeleton()
	if sk == null or _ids.is_empty():
		return

	var feet: = {}
	for pre in ["left", "right"]:
		var fi: int = _ids[pre + "foot"]
		if fi >= 0:
			feet[pre] = sk.get_bone_global_pose(fi)
	var gw: = guard_w if not guard.is_empty() else 0.0
	if gw > 0.01:
		_apply_guard(sk, gw)
	if block_w > 0.01:
		_apply_block(sk, block_w)
	var gbw: = maxf(guard_broken, flail)
	if gbw > 0.01:
		_apply_guard_break(sk, gbw)

	var fwd: = Vector3(0, 0, 1)
	var right: = Vector3(-1, 0, 0)
	var s: = side * side_sign

	var wob: = stun * sin(_t * 2.4) * 0.12
	var wob2: = stun * sin(_t * 1.7 + 0.6) * 0.08

	var weave: = 0.0
	var g_twist: = 0.0
	var g_up: = 0.0
	var g_sh: = 0.0
	var roll: = 0.0
	var nod: = 0.0
	if gw > 0.01:
		weave = float(guard.get("weave", 0.0)) * sin(_phase * TAU * float(guard.get("weave_hz", 0.0))) * gw
		g_twist = float(guard.get("twist", 0.0)) * gw
		var bh: = float(guard.get("bounce_hz", 1.5))
		roll = sin(_phase * TAU * bh * 0.5) * 0.045 * gw + sin(_phase * TAU * 0.23) * 0.03 * gw
		nod = sin(_phase * TAU * bh + 0.6) * 0.035 * gw
		g_up = float(guard.get("upright", 0.0)) * gw
		g_sh = float(guard.get("shoulder", 0.0)) * gw
	s += weave

	var b_crunch: = block_w * lerpf(0.1, 0.24, block_low)
	var cw: = clinch_w
	var sway: = sin(_t * 1.9) * 0.05 * cw + clinch_push * 0.06
	var bend_side: = - s * 0.42 + wob - g_sh + cw * clinch_side * 0.1 * side_sign
	var bend_fwd: = duck * 0.55 + absf(s) * 0.14 - back * 0.38 + wob2 + body_kick.x - g_up + b_crunch + cw * (0.34 + sway)
	var twist: = s * 0.2 + body_kick.y + g_twist + punch_twist + block_w * block_low * 0.08 + cw * sin(_t * 1.3) * 0.06 + roll
	for key in ["spine", "spine1", "spine2"]:
		var i: int = _ids[key]
		_rotate_global(sk, i, fwd, bend_side / 3.0 + body_kick.z / 3.0)
		_rotate_global(sk, i, right, bend_fwd / 3.0)
		_rotate_global(sk, i, Vector3.UP, twist / 3.0)

	var h: int = _ids["head"]
	var n: int = _ids["neck"]
	var chin_tuck: = block_w * 0.14 + cw * 0.12

	var cs: = clinch_side * side_sign * cw
	_rotate_global(sk, n, right, - neck_kick.x * 0.7 + chin_tuck * 0.5)
	_rotate_global(sk, n, Vector3.UP, neck_kick.y * 0.6 + cs * 0.3)
	_rotate_global(sk, n, fwd, neck_kick.z * 0.6 - cs * 0.12)
	_rotate_global(sk, h, right, - (head_kick.x - neck_kick.x * 0.7) * 0.85 - back * 0.1 + chin_tuck * 0.5 - duck * 0.12 + nod)
	_rotate_global(sk, h, Vector3.UP, head_kick.y - neck_kick.y * 0.6 + cs * 0.35)
	_rotate_global(sk, h, fwd, head_kick.z - neck_kick.z * 0.6 + wob * 0.8 + s * 0.12 - cs * 0.16)

	var drop: = duck * 0.24 + absf(s) * 0.06 + stun * 0.03 + block_w * block_low * 0.05 + block_w * 0.015 + dip
	if gw > 0.01:
		var bz: = float(guard.get("bounce", 0.0)) * (0.5 + 0.5 * sin(_phase * TAU * float(guard.get("bounce_hz", 1.5))))
		drop += (float(guard.get("crouch", 0.0)) + bz) * gw
		drop = maxf(drop, 0.0)
	var hips: int = _ids["hips"]
	var moved: = false
	if hips >= 0 and drop > 0.001:
		var p: = sk.get_bone_pose_position(hips)
		sk.set_bone_pose_position(hips, p - Vector3(0, drop, 0) * _scale_to_local(sk, hips))
		moved = true
	var shift: = - fwd * back * 0.07 + right * s * 0.035 - fwd * cw * 0.05
	if hips >= 0 and shift.length() > 0.0005:
		var p2: = sk.get_bone_pose_position(hips)

		sk.set_bone_pose_position(hips, p2 + shift * _scale_to_local(sk, hips))
		moved = true

	if cw > 0.01:
		_apply_clinch(sk, cw)

	if moved:
		for pre in ["left", "right"]:
			if feet.has(pre):
				_ik_leg(sk, _ids[pre + "upleg"], _ids[pre + "leg"], _ids[pre + "foot"], feet[pre])




func _apply_guard(sk: Skeleton3D, w: float) -> void :
	var u: = 1.0 / maxf(absf(sk.global_transform.basis.get_scale().x), 0.0001)
	var lead: Vector3 = guard.get("lead", Vector3.ZERO)
	var rear: Vector3 = guard.get("rear", Vector3.ZERO)
	if _paw > 0.0:
		var k: = sin(_paw * PI)
		lead += Vector3(0.0, 0.04, 0.16) * k

	var ph: = _phase * TAU
	lead += Vector3(sin(ph * 0.53 + 0.4) * 0.014, sin(ph * 0.81) * 0.016, sin(ph * 0.37 + 1.3) * 0.022)
	rear += Vector3(sin(ph * 0.47 + 2.1) * 0.01, sin(ph * 0.71 + 0.9) * 0.013, sin(ph * 0.29 + 0.2) * 0.012)

	if _feint > 0.0:
		var fk: = sin(_feint * PI)
		match _feint_kind:
			0:
				lead += Vector3(0.0, -0.03, 0.09) * fk
			1:
				lead += Vector3(0.015, 0.035, 0.04) * fk
			_:
				rear += Vector3(0.0, -0.02, 0.05) * fk

	var chest: int = _ids["spine2"]
	var cb: = sk.get_bone_global_pose(chest).basis.orthonormalized() if chest >= 0 else Basis.IDENTITY
	var cb_rest: = sk.get_bone_global_rest(chest).basis.orthonormalized() if chest >= 0 else Basis.IDENTITY
	var rot: = cb * cb_rest.inverse()
	if lead.length() > 0.001:
		_ik_arm(sk, _ids["leftarm"], _ids["leftforearm"], _ids["lefthand"], rot * (lead * u), Vector3(0.35, -1.0, -0.25), w)
	if rear.length() > 0.001:
		_ik_arm(sk, _ids["rightarm"], _ids["rightforearm"], _ids["righthand"], rot * (rear * u), Vector3(-0.35, -1.0, -0.25), w)



func _apply_block(sk: Skeleton3D, w: float) -> void :
	var hi: int = _ids["head"]
	if hi < 0:
		return
	var u: = 1.0 / maxf(absf(sk.global_transform.basis.get_scale().x), 0.0001)

	var chest: int = _ids["spine2"]
	var cb: = sk.get_bone_global_pose(chest).basis.orthonormalized() if chest >= 0 else Basis.IDENTITY
	var cb_rest: = sk.get_bone_global_rest(chest).basis.orthonormalized() if chest >= 0 else Basis.IDENTITY
	var rot: = cb * cb_rest.inverse()
	var H: = sk.get_bone_global_pose(hi).origin
	var rec: = Vector3(0, 0.01, -1.0) * block_recoil
	var lo: = clampf(block_low, 0.0, 1.0)
	var lead_t: = H + rot * ((BLOCK_HI_LEAD.lerp(BLOCK_LO_LEAD, lo) + rec) * u)
	var rear_t: = H + rot * ((BLOCK_HI_REAR.lerp(BLOCK_LO_REAR, lo) + rec) * u)
	var lh: int = _ids["lefthand"]
	var rh: int = _ids["righthand"]
	if lh >= 0:
		var cur: = sk.get_bone_global_pose(lh).origin
		_ik_arm(sk, _ids["leftarm"], _ids["leftforearm"], lh, lead_t - cur, rot * Vector3(0.05, -1.0, 0.35), w)
	if rh >= 0:
		var cur2: = sk.get_bone_global_pose(rh).origin
		_ik_arm(sk, _ids["rightarm"], _ids["rightforearm"], rh, rear_t - cur2, rot * Vector3(-0.05, -1.0, 0.35), w)



func _apply_guard_break(sk: Skeleton3D, w: float) -> void :
	var u: = 1.0 / maxf(absf(sk.global_transform.basis.get_scale().x), 0.0001)
	_ik_arm(sk, _ids["leftarm"], _ids["leftforearm"], _ids["lefthand"], Vector3(0.12, -0.16, -0.04) * u, Vector3(0.6, -1.0, -0.2), w)
	_ik_arm(sk, _ids["rightarm"], _ids["rightforearm"], _ids["righthand"], Vector3(-0.12, -0.18, -0.04) * u, Vector3(-0.6, -1.0, -0.2), w)




func _ik_arm(sk: Skeleton3D, up_i: int, fo_i: int, ha_i: int, offset: Vector3, pole: Vector3, w: float) -> void :
	if up_i < 0 or fo_i < 0 or ha_i < 0:
		return
	var S: = sk.get_bone_global_pose(up_i).origin
	var E: = sk.get_bone_global_pose(fo_i).origin
	var hg: = sk.get_bone_global_pose(ha_i)
	var H: = hg.origin
	var a: = S.distance_to(E)
	var b: = E.distance_to(H)
	if a < 0.0001 or b < 0.0001:
		return
	var T: = H + offset * w
	var st: = T - S
	var d: = clampf(st.length(), absf(a - b) + a * 0.01, (a + b) * 0.995)
	var dir: = st.normalized()
	var cur: = E - S
	var perp: = cur - dir * cur.dot(dir)
	var pn: = pole.normalized()
	pn = pn - dir * pn.dot(dir)
	if perp.length() < 0.0001:
		perp = pn
	perp = (perp.normalized() + pn.normalized() * 0.35).normalized()
	var cos_s: = clampf((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0)
	var ang: = acos(cos_s)
	var E2: = S + (dir * cos(ang) + perp * sin(ang)) * a
	_rotate_from_to(sk, up_i, E - S, E2 - S)
	var e_now: = sk.get_bone_global_pose(fo_i).origin
	var h_now: = sk.get_bone_global_pose(ha_i).origin
	_rotate_from_to(sk, fo_i, h_now - e_now, (S + dir * d) - e_now)


	var parent: = sk.get_bone_parent(ha_i)
	if parent >= 0:
		var pg: = sk.get_bone_global_pose(parent)
		var keep_world: = (pg.basis.orthonormalized().inverse() * hg.basis.orthonormalized()).get_rotation_quaternion()
		var local_now: = sk.get_bone_pose_rotation(ha_i)
		sk.set_bone_pose_rotation(ha_i, local_now.slerp(keep_world, 0.25 * w))




func _ik_leg(sk: Skeleton3D, up_i: int, lo_i: int, ft_i: int, foot: Transform3D) -> void :
	if up_i < 0 or lo_i < 0 or ft_i < 0:
		return
	var S: = sk.get_bone_global_pose(up_i).origin
	var K: = sk.get_bone_global_pose(lo_i).origin
	var F: = sk.get_bone_global_pose(ft_i).origin
	var a: = S.distance_to(K)
	var b: = K.distance_to(F)
	if a < 0.0001 or b < 0.0001:
		return
	var T: = foot.origin
	var st: = T - S
	var d: = clampf(st.length(), absf(a - b) + a * 0.02, (a + b) * 0.999)
	var dir: = st.normalized()

	var perp: = (K - S) - dir * (K - S).dot(dir)
	if perp.length() < 0.0001:
		perp = Vector3(0, 0, 1) - dir * dir.z
	perp = perp.normalized()
	var cos_s: = clampf((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0)
	var ang: = acos(cos_s)
	var K2: = S + (dir * cos(ang) + perp * sin(ang)) * a
	_rotate_from_to(sk, up_i, K - S, K2 - S)
	var k_now: = sk.get_bone_global_pose(lo_i).origin
	var f_now: = sk.get_bone_global_pose(ft_i).origin
	_rotate_from_to(sk, lo_i, f_now - k_now, T - k_now)
	var parent: = sk.get_bone_parent(ft_i)
	if parent >= 0:
		var pg: = sk.get_bone_global_pose(parent)
		sk.set_bone_pose_rotation(ft_i, (pg.basis.orthonormalized().inverse() * foot.basis.orthonormalized()).get_rotation_quaternion())



func _apply_clinch(sk: Skeleton3D, w: float) -> void :
	var inv: = sk.global_transform.affine_inverse()
	var lh: int = _ids["lefthand"]
	var rh: int = _ids["righthand"]
	if lh >= 0 and clinch_lead != Vector3.ZERO:
		var cur: = sk.get_bone_global_pose(lh).origin
		_ik_arm(sk, _ids["leftarm"], _ids["leftforearm"], lh, inv * clinch_lead - cur, Vector3(0.8, -0.6, 0.0), w)
	if rh >= 0 and clinch_rear != Vector3.ZERO:
		var cur2: = sk.get_bone_global_pose(rh).origin
		_ik_arm(sk, _ids["rightarm"], _ids["rightforearm"], rh, inv * clinch_rear - cur2, Vector3(-0.8, -0.6, 0.0), w)


func _rotate_from_to(sk: Skeleton3D, idx: int, from: Vector3, to: Vector3) -> void :
	if from.length() < 1e-05 or to.length() < 1e-05:
		return
	var f: = from.normalized()
	var t: = to.normalized()
	if f.dot(t) > 0.99999:
		return
	var axis: = f.cross(t)
	if axis.length() < 1e-05:
		return
	_rotate_global(sk, idx, axis.normalized(), f.angle_to(t))



func _scale_to_local(sk: Skeleton3D, idx: int) -> float:
	var parent: = sk.get_bone_parent(idx)
	var sc: = absf(sk.global_transform.basis.get_scale().x)
	if parent >= 0:
		sc *= absf(sk.get_bone_global_pose(parent).basis.get_scale().x)
	return 1.0 / maxf(sc, 0.0001)
