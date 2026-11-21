class_name ProceduralRig
extends BoxerRig





const L_UPPER: = 0.31
const L_FORE: = 0.34
const L_THIGH: = 0.44
const L_SHIN: = 0.43
const HIP_Y: = 0.95
const TORSO_Y: = 0.1
const HEAD_Y: = 0.62
const SHOULDER: = Vector3(0.2, 0.43, 0.0)

var is_referee: = false
var ext_move: = Vector2.ZERO
var ref_action: = ""
var ref_pulse: = 0.0

var _hf: = 1.0
var _stance: = 1
var _t: = 0.0
var _rng: = RandomNumberGenerator.new()


var pivot: Node3D
var hips: Node3D
var torso: Node3D
var head: Node3D
var upper_arms: Array[MeshInstance3D] = []
var fore_arms: Array[MeshInstance3D] = []
var gloves: Array[MeshInstance3D] = []
var cuffs: Array[MeshInstance3D] = []
var thighs: Array[MeshInstance3D] = []
var shins: Array[MeshInstance3D] = []
var shoes: Array[MeshInstance3D] = []
var cut_marks: Array[MeshInstance3D] = []
var swell_marks: Array[MeshInstance3D] = []
var skin_mat: StandardMaterial3D
var face_mat: StandardMaterial3D
var skin_color: = Color(0.8, 0.6, 0.45)


var glove_pos: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _glove_init: = false
var p_active: = false
var p_type: = 0
var p_body: = false
var p_power: = false
var p_time: = 0.0
var p_windup: = 0.2
var p_act: = 0.08
var p_rec: = 0.25
var _step_phase: = 0.0
var _clinch: = false
var _victory: = false


var head_spring: = Vector3.ZERO
var head_vel: = Vector3.ZERO
var torso_spring: = Vector3.ZERO
var torso_vel: = Vector3.ZERO
var recoil: = 0.0
var recoil_vel: = 0.0


var kd_k: = 0.0
var kd_mode: = 0
var kd_body: = false
var kd_time: = 0.0
var kd_dur: = 0.7


func setup(def: Dictionary, f: Fighter) -> void :
	fighter = f
	_rng.randomize()
	_stance = int(def.get("stance", 1))
	var h: float = float(def.get("height", 1.8))
	_hf = h / 1.8
	scale = Vector3.ONE * _hf
	skin_color = def.get("skin", Color(0.8, 0.6, 0.45))
	var trunks_c: Color = def.get("trunks", Color(0.7, 0.1, 0.1))
	var trim_c: Color = def.get("trim", Color(0.95, 0.8, 0.2))
	var glove_c: Color = def.get("gloves", Color(0.7, 0.05, 0.05))
	var hair_c: Color = def.get("hair", Color(0.1, 0.07, 0.05))
	var bald: bool = def.get("bald", false)
	is_referee = def.get("referee", false)
	_build(trunks_c, trim_c, glove_c, hair_c, bald)


static func _mat(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m: = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi: = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	parent.add_child(mi)
	return mi


static func _capsule(r: float, h: float) -> CapsuleMesh:
	var c: = CapsuleMesh.new()
	c.radius = r
	c.height = maxf(h, r * 2.0 + 0.001)
	c.radial_segments = 16
	c.rings = 6
	return c


static func _sphere(r: float, hemi: bool = false) -> SphereMesh:
	var s: = SphereMesh.new()
	s.radius = r
	s.height = r * (1.0 if hemi else 2.0)
	s.is_hemisphere = hemi
	s.radial_segments = 20
	s.rings = 12
	return s


static func _cyl(r_top: float, r_bot: float, h: float) -> CylinderMesh:
	var c: = CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = 18
	return c


static func _box(size: Vector3) -> BoxMesh:
	var b: = BoxMesh.new()
	b.size = size
	return b


func _build(trunks_c: Color, trim_c: Color, glove_c: Color, hair_c: Color, bald: bool) -> void :
	skin_mat = _mat(skin_color, 0.58)
	skin_mat.rim_enabled = true
	skin_mat.rim = 0.25
	skin_mat.rim_tint = 0.6
	face_mat = skin_mat.duplicate() as StandardMaterial3D
	var trunks_mat: = _mat(trunks_c, 0.32, 0.15)
	var trim_mat: = _mat(trim_c, 0.3, 0.3)
	var glove_mat: = _mat(glove_c, 0.22, 0.05)
	glove_mat.clearcoat_enabled = true
	glove_mat.clearcoat = 0.8
	var hair_mat: = _mat(hair_c, 0.85)
	var dark_mat: = _mat(Color(0.05, 0.04, 0.04), 0.4)
	var shoe_mat: = _mat(Color(0.92, 0.92, 0.92) if not is_referee else Color(0.03, 0.03, 0.03), 0.5)
	var shirt_mat: = _mat(Color(0.93, 0.93, 0.95), 0.8)
	var pants_mat: = _mat(Color(0.05, 0.05, 0.06), 0.7)
	var tape_mat: = _mat(Color(0.96, 0.96, 0.96), 0.7)

	pivot = Node3D.new()
	add_child(pivot)
	hips = Node3D.new()
	hips.position = Vector3(0, HIP_Y, 0)
	pivot.add_child(hips)

	if is_referee:
		_mesh(hips, _cyl(0.165, 0.175, 0.26), pants_mat)
	else:
		_mesh(hips, _cyl(0.165, 0.185, 0.27), trunks_mat)
		_mesh(hips, _cyl(0.172, 0.172, 0.06), trim_mat, Vector3(0, 0.12, 0))

		_mesh(hips, _box(Vector3(0.02, 0.25, 0.03)), trim_mat, Vector3(0.175, -0.01, 0))
		_mesh(hips, _box(Vector3(0.02, 0.25, 0.03)), trim_mat, Vector3(-0.175, -0.01, 0))

	torso = Node3D.new()
	torso.position = Vector3(0, TORSO_Y, 0)
	hips.add_child(torso)
	var torso_mat: Material = shirt_mat if is_referee else skin_mat
	_mesh(torso, _capsule(0.13, 0.42), torso_mat, Vector3(0, 0.18, 0), Vector3(1.2, 1, 0.85))
	_mesh(torso, _capsule(0.15, 0.4), torso_mat, Vector3(0, 0.33, 0.0), Vector3(1.35, 1, 0.9))
	var sh: = _mesh(torso, _capsule(0.085, 0.48), torso_mat, Vector3(0, 0.44, 0))
	sh.rotation.z = PI * 0.5
	if not is_referee:

		_mesh(torso, _sphere(0.085), skin_mat, Vector3(0.075, 0.37, -0.1), Vector3(1.1, 0.75, 0.55))
		_mesh(torso, _sphere(0.085), skin_mat, Vector3(-0.075, 0.37, -0.1), Vector3(1.1, 0.75, 0.55))
	else:
		_mesh(torso, _box(Vector3(0.07, 0.03, 0.02)), dark_mat, Vector3(0, 0.52, -0.1))
	_mesh(torso, _cyl(0.055, 0.06, 0.13), skin_mat, Vector3(0, 0.53, 0))

	head = Node3D.new()
	head.position = Vector3(0, HEAD_Y, -0.01)
	torso.add_child(head)
	_mesh(head, _sphere(0.105), face_mat, Vector3(0, 0.01, 0), Vector3(0.95, 1.12, 1.0))
	_mesh(head, _sphere(0.08), face_mat, Vector3(0, -0.06, -0.025), Vector3(1.0, 0.8, 1.05))
	if not bald:
		var hair: = _mesh(head, _sphere(0.109, true), hair_mat, Vector3(0, 0.035, 0.008), Vector3(0.97, 1.0, 1.02))
		hair.rotation.x = -0.15
	_mesh(head, _sphere(0.013), dark_mat, Vector3(0.036, 0.018, -0.094))
	_mesh(head, _sphere(0.013), dark_mat, Vector3(-0.036, 0.018, -0.094))
	_mesh(head, _box(Vector3(0.035, 0.008, 0.012)), hair_mat if not bald else dark_mat, Vector3(0.037, 0.04, -0.096))
	_mesh(head, _box(Vector3(0.035, 0.008, 0.012)), hair_mat if not bald else dark_mat, Vector3(-0.037, 0.04, -0.096))
	_mesh(head, _box(Vector3(0.024, 0.045, 0.03)), face_mat, Vector3(0, -0.005, -0.104))
	_mesh(head, _sphere(0.022), face_mat, Vector3(0.1, 0.0, 0.0), Vector3(0.45, 1.0, 0.75))
	_mesh(head, _sphere(0.022), face_mat, Vector3(-0.1, 0.0, 0.0), Vector3(0.45, 1.0, 0.75))
	if not is_referee:
		var blood_mat: = _mat(Color(0.45, 0.02, 0.02), 0.25)
		for side in [-1.0, 1.0]:
			var sd: float = side
			var cm: = _mesh(head, _sphere(0.012), blood_mat, Vector3(sd * 0.05, 0.05, -0.093), Vector3(2.2, 0.5, 0.5))
			cm.visible = false
			cut_marks.append(cm)
			var sw: = _mesh(head, _sphere(0.02), face_mat, Vector3(sd * 0.038, 0.012, -0.088), Vector3(1.0, 0.8, 0.6))
			sw.visible = false
			swell_marks.append(sw)

	for i in 2:
		upper_arms.append(_mesh(pivot, _capsule(0.055, L_UPPER + 0.1), shirt_mat if is_referee else skin_mat))
		fore_arms.append(_mesh(pivot, _capsule(0.047, L_FORE + 0.04), skin_mat))
		if is_referee:
			gloves.append(_mesh(pivot, _sphere(0.045), skin_mat))
			cuffs.append(_mesh(pivot, _sphere(0.001), skin_mat))
		else:
			gloves.append(_mesh(pivot, _sphere(0.088), glove_mat, Vector3.ZERO, Vector3(0.95, 1.0, 1.3)))
			cuffs.append(_mesh(pivot, _cyl(0.058, 0.055, 0.08), tape_mat))
		thighs.append(_mesh(pivot, _capsule(0.08, L_THIGH + 0.12), pants_mat if is_referee else skin_mat))
		shins.append(_mesh(pivot, _capsule(0.06, L_SHIN + 0.08), pants_mat if is_referee else skin_mat))
		shoes.append(_mesh(pivot, _box(Vector3(0.1, 0.09, 0.25)), shoe_mat))
	_update_pose(0.0)




func on_punch_start(type: int, body: bool, power: bool, windup: float, active: float, recovery: float) -> void :
	p_active = true
	p_type = type
	p_body = body
	p_power = power
	p_time = 0.0
	p_windup = maxf(windup, 0.01)
	p_act = active
	p_rec = maxf(recovery, 0.01)


func on_punch_cancel() -> void :
	p_active = false


func on_hit(body: bool, incoming_side: int, strength: float, type: int) -> void :
	var s: = strength
	if body:
		torso_vel.x -= 7.0 * s
		torso_vel.z += float(incoming_side) * 2.5 * s
		recoil_vel += 0.9 * s
	else:
		if Punches.is_hook(type):
			head_vel.y += float(incoming_side) * 11.0 * s
			head_vel.z += float(incoming_side) * 6.0 * s
			torso_vel.y += float(incoming_side) * 2.5 * s
		elif Punches.is_upper(type):
			head_vel.x += 15.0 * s
			torso_vel.x += 3.0 * s
		else:
			head_vel.x += 10.0 * s
			head_vel.y += _rng.randf_range(-2.0, 2.0) * s
		recoil_vel += 1.2 * s
	p_active = false


func on_blocked_hit(strength: float) -> void :
	torso_vel.x += 2.5 * strength
	head_vel.x += 1.5 * strength
	recoil_vel += 0.5 * strength


func on_parried() -> void :
	p_active = false
	torso_vel.x += 4.0
	torso_vel.y += _rng.randf_range(-3.0, 3.0)


func on_knockdown(body_kd: bool) -> void :
	p_active = false
	kd_mode = 1
	kd_body = body_kd
	kd_time = 0.0
	kd_dur = 0.65 if body_kd else 0.75


func on_getup(duration: float) -> void :
	kd_mode = 3
	kd_time = 0.0
	kd_dur = maxf(duration, 0.2)


func on_victory() -> void :
	_victory = true


func on_clinch(active: bool) -> void :
	_clinch = active


func on_reset() -> void :
	kd_mode = 0
	kd_k = 0.0
	_victory = false
	_clinch = false
	p_active = false


func get_head_global() -> Vector3:
	if head:
		return head.global_position
	return global_position + Vector3(0, 1.65 * _hf, 0)


func get_glove_global(lead: bool) -> Vector3:
	var idx: = 0 if lead else 1
	if gloves.size() > idx:
		return gloves[idx].global_position
	return global_position + Vector3(0, 1.4, -0.4)




func update_rig(delta: float) -> void :
	_update_pose(delta)


func _update_pose(delta: float) -> void :
	_t += delta
	if p_active:
		p_time += delta
		if p_time > p_windup + p_act + p_rec:
			p_active = false

	match kd_mode:
		1:
			kd_time += delta
			var u: = clampf(kd_time / kd_dur, 0.0, 1.0)
			kd_k = 1.0 - pow(1.0 - u, 3.0)
			if u >= 1.0:
				kd_mode = 2
		2:
			kd_k = 1.0
		3:
			kd_time += delta
			var u2: = clampf(kd_time / kd_dur, 0.0, 1.0)
			kd_k = 1.0 - u2 * u2 * (3.0 - 2.0 * u2)
			if u2 >= 1.0:
				kd_mode = 0
				kd_k = 0.0
	_springs(delta)

	var blocking: = false
	var block_low: = false
	var lean: int = Fighter.Lean.NONE
	var lean_amt: = 0.0
	var move: = ext_move
	var stunned: = false
	var fatigue: = 0.0
	var dist: = 1.15
	var damage: = 0.0
	var cut: = 0.0
	if fighter:
		blocking = fighter.blocking
		block_low = fighter.block_low
		lean = fighter.lean
		lean_amt = fighter.lean_amount
		move = fighter.local_move
		stunned = fighter.stun_timer > 0.0
		fatigue = clampf(1.0 - fighter.stamina / 45.0, 0.0, 1.0)
		dist = fighter.dist_to_opp
		damage = 1.0 - fighter.head_ratio()
		cut = fighter.cut
		skin_mat.roughness = 0.6 - fighter.sweat * 0.4
		face_mat.roughness = skin_mat.roughness
	var dist_u: = dist / _hf

	var lead_side: = - _stance
	var rear_side: = _stance


	var hips_pos: = Vector3(0, HIP_Y, 0)
	var hips_rot: = Vector3.ZERO
	var torso_rot: = Vector3(-0.06, float(lead_side) * 0.3, 0.0)
	var head_rot: = Vector3(0.05, - float(lead_side) * 0.22, 0.0)
	if is_referee:
		torso_rot = Vector3.ZERO
		head_rot = Vector3.ZERO
	var pivot_pos: = Vector3.ZERO

	var mv_len: = move.length()
	var bounce_amp: = 0.016 if not is_referee else 0.004
	if stunned:
		bounce_amp = 0.0
	if _victory:
		bounce_amp = 0.05
	hips_pos.y += -0.035 + sin(_t * 7.5) * bounce_amp - fatigue * 0.03
	_step_phase += delta * (4.0 + mv_len * 7.0)

	if stunned:
		torso_rot.z += sin(_t * 2.6) * 0.14
		torso_rot.x += sin(_t * 1.9) * 0.06
		head_rot.z += sin(_t * 2.6 + 0.6) * 0.18
		hips_pos.y -= 0.04 + absf(sin(_t * 1.7)) * 0.05
		hips_pos.x += sin(_t * 2.6) * 0.04


	if lean == Fighter.Lean.LEFT:
		torso_rot.z += 0.42 * lean_amt
		hips_pos.x -= 0.06 * lean_amt
		hips_pos.y -= 0.04 * lean_amt
	elif lean == Fighter.Lean.RIGHT:
		torso_rot.z -= 0.42 * lean_amt
		hips_pos.x += 0.06 * lean_amt
		hips_pos.y -= 0.04 * lean_amt
	elif lean == Fighter.Lean.DUCK:
		hips_pos.y -= 0.24 * lean_amt
		hips_pos.z -= 0.04 * lean_amt
		torso_rot.x -= 0.5 * lean_amt
		torso_rot.z += sin(_t * 6.0) * 0.08 * lean_amt
	elif lean == Fighter.Lean.BACK:
		torso_rot.x += 0.36 * lean_amt
		hips_pos.z += 0.08 * lean_amt

	if blocking:
		torso_rot.x -= 0.1 if not block_low else 0.24
		head_rot.x -= 0.15
		if block_low:
			hips_pos.y -= 0.06

	if _clinch:
		torso_rot.x -= 0.25
		pivot_pos.z -= 0.08


	var e: = 0.0
	var hand: = 0
	if p_active:
		e = _extension()
		var lead_hand: = Punches.is_lead(p_type)
		hand = lead_side if lead_hand else rear_side
		var k: = 0.25 if lead_hand else 0.55
		if Punches.is_hook(p_type):
			k = 0.55 if lead_hand else 0.7
		elif Punches.is_upper(p_type):
			k = 0.3 if lead_hand else 0.45
		if p_power:
			k *= 1.3
		torso_rot.y += float(hand) * k * e - float(lead_side) * 0.3 * e * 0.5

		var lunge: = 0.1 + clampf(dist_u - 1.05, 0.0, 0.28)
		if Punches.is_hook(p_type):
			lunge = 0.06 + clampf(dist_u - 0.95, 0.0, 0.15)
		elif Punches.is_upper(p_type):
			lunge = 0.05 + clampf(dist_u - 0.9, 0.0, 0.12)
		if p_power:
			lunge += 0.05
		pivot_pos.z -= lunge * maxf(e, 0.0)
		if p_body:
			hips_pos.y -= 0.09 * maxf(e, 0.0)
			torso_rot.x -= 0.2 * maxf(e, 0.0)
			torso_rot.z += float(hand) * 0.12 * maxf(e, 0.0)
		if Punches.is_upper(p_type):
			var dip: = sin(clampf(p_time / p_windup, 0.0, 1.0) * PI) * 0.07
			hips_pos.y -= dip
			torso_rot.x += 0.08 * maxf(e, 0.0)
		if Punches.is_hook(p_type):
			torso_rot.z -= float(hand) * 0.1 * maxf(e, 0.0)


	torso_rot += torso_spring
	head_rot += head_spring
	pivot_pos.z += recoil


	var pivot_rot: = Vector3.ZERO
	if kd_k > 0.0:
		if kd_body:
			hips_pos.y = lerpf(hips_pos.y, HIP_Y - 0.43, kd_k)
			torso_rot = torso_rot.lerp(Vector3(-0.55, 0.0, 0.1), kd_k)
			head_rot = head_rot.lerp(Vector3(-0.3, 0.0, 0.2), kd_k)
			pivot_pos.z = lerpf(pivot_pos.z, -0.05, kd_k)
		else:
			pivot_rot.x = lerpf(0.0, 1.5, kd_k)
			pivot_pos.y = lerpf(0.0, 0.17, kd_k)
			pivot_pos.z = lerpf(pivot_pos.z, 0.35, kd_k)
			torso_rot = torso_rot.lerp(Vector3(0.0, 0.0, 0.15), kd_k)
			head_rot = head_rot.lerp(Vector3(0.25, 0.6, 0.0), kd_k)
			hips_pos.y = lerpf(hips_pos.y, HIP_Y - 0.02, kd_k)

	pivot.position = pivot_pos
	pivot.rotation = pivot_rot
	hips.position = hips_pos
	hips.rotation = hips_rot
	torso.rotation = torso_rot
	head.rotation = head_rot


	var torso_xf: Transform3D = hips.transform * torso.transform
	for i in 2:
		var side: int = lead_side if i == 0 else rear_side
		var foot: = Vector3(float(side) * 0.14, 0.09, -0.17) if i == 0 else Vector3(float(side) * 0.16, 0.09, 0.2)
		if is_referee:
			foot = Vector3(float(side) * 0.13, 0.09, 0.0)
		if mv_len > 0.05 and kd_k < 0.5:
			var ph: = _step_phase + (0.0 if i == 0 else PI)
			var dir3: = Vector3(move.x, 0.0, - move.y).normalized()
			foot += dir3 * sin(ph) * 0.09 * minf(mv_len, 1.0)
			foot.y += maxf(0.0, cos(ph)) * 0.05 * minf(mv_len, 1.0)
		if kd_k > 0.0 and kd_body:

			foot = foot.lerp(Vector3(float(side) * 0.15, 0.06, 0.45), kd_k)
		var hip_joint: = hips.transform * Vector3(float(side) * 0.095, -0.07, 0.0)
		var leg: = _ik(hip_joint, foot, L_THIGH, L_SHIN, Vector3(float(side) * 0.15, 0.0, -1.0))
		var knee: Vector3 = leg[0]
		var ankle: Vector3 = leg[1]
		_place_segment(thighs[i], hip_joint, knee)
		_place_segment(shins[i], knee, ankle)
		shoes[i].position = ankle + Vector3(0, -0.045, -0.05)
		shoes[i].rotation = Vector3(0, torso_rot.y * 0.2, 0)


	for i in 2:
		var side2: int = lead_side if i == 0 else rear_side
		var shoulder: = torso_xf * Vector3(float(side2) * SHOULDER.x, SHOULDER.y, SHOULDER.z)
		var guard_local: = _guard_local(i, side2, blocking, block_low, stunned, fatigue)
		var target: = torso_xf * guard_local
		var pole: = torso_xf.basis * Vector3(float(side2) * 0.7, -1.0, 0.3)
		var is_punch_hand: = p_active and ((i == 0) == Punches.is_lead(p_type))
		if is_punch_hand:
			var pt: = _punch_target(side2, dist_u)
			var ee: = clampf(e, -0.3, 1.0)
			if Punches.is_hook(p_type):
				var ctrl: = Vector3(float(side2) * 0.58, pt.y + 0.03, -0.28)
				var u: = clampf(ee, 0.0, 1.0)
				var bez: = target * (1.0 - u) * (1.0 - u) + ctrl * 2.0 * (1.0 - u) * u + pt * u * u
				target = bez if ee >= 0.0 else target + (target - ctrl).normalized() * ee * 0.2
				pole = pole.lerp(Vector3(float(side2) * 0.6, 0.6, 0.4), u)
			elif Punches.is_upper(p_type):
				var ctrl2: = Vector3(float(side2) * 0.16, 1.02, -0.26)
				var u2: = clampf(ee, 0.0, 1.0)
				target = target * (1.0 - u2) * (1.0 - u2) + ctrl2 * 2.0 * (1.0 - u2) * u2 + pt * u2 * u2
				pole = pole.lerp(Vector3(float(side2) * 0.8, -0.6, 0.5), u2)
			else:
				if ee < 0.0:
					target = target + Vector3(0, -0.03, 0.12) * - ee
				else:
					target = target.lerp(pt, ee)
				pole = pole.lerp(Vector3(float(side2) * 0.9, -0.5, 0.2), clampf(ee, 0.0, 1.0))
		if _victory:
			target = torso_xf * Vector3(float(side2) * 0.22, 0.95 + sin(_t * 9.0 + float(i)) * 0.05, -0.05)
			pole = Vector3(float(side2), 0.0, 0.3)
		if is_referee:
			target = _referee_hand(i, side2, torso_xf)
		if kd_k > 0.0:
			var down_t: = torso_xf * Vector3(float(side2) * 0.42, 0.25, 0.05)
			if kd_body and i == 0:
				down_t = Vector3(float(side2) * 0.22, 0.06, -0.38)
			target = target.lerp(down_t, kd_k)
		if not _glove_init:
			glove_pos[i] = target
		var rate: = 60.0 if is_punch_hand else 22.0
		glove_pos[i] = glove_pos[i].lerp(target, clampf(rate * delta, 0.0, 1.0)) if delta > 0.0 else target
		var arm: = _ik(shoulder, glove_pos[i], L_UPPER, L_FORE, pole)
		var elbow: Vector3 = arm[0]
		var hand_p: Vector3 = arm[1]
		_place_segment(upper_arms[i], shoulder, elbow)
		_place_segment(fore_arms[i], elbow, hand_p)
		var fdir: = (hand_p - elbow).normalized()
		gloves[i].position = hand_p + fdir * 0.02
		cuffs[i].position = hand_p - fdir * 0.07
		var up_hint: = Vector3.UP if absf(fdir.dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
		gloves[i].basis = Basis.looking_at(fdir, up_hint) * Basis.from_scale(Vector3(0.95, 1.0, 1.3)) if not is_referee else Basis.IDENTITY
		var cuff_basis: = Basis(_arc(Vector3.UP, fdir))
		cuffs[i].basis = cuff_basis
	_glove_init = true


	if not is_referee and cut_marks.size() == 2:
		cut_marks[0].visible = cut > 30.0
		cut_marks[1].visible = cut > 60.0
		swell_marks[0].visible = damage > 0.35
		swell_marks[1].visible = damage > 0.55
		var sw: = 0.8 + damage * 0.8
		swell_marks[0].scale = Vector3(1.0, 0.8, 0.6) * sw
		swell_marks[1].scale = Vector3(1.0, 0.8, 0.6) * sw
		face_mat.albedo_color = skin_color.lerp(Color(0.75, 0.25, 0.22), clampf(damage * 0.45, 0.0, 0.45))


func _extension() -> float:
	var t: = p_time
	if t < p_windup:
		var u: = t / p_windup
		var e: = pow(u, 1.7)
		if p_power:
			e = pow(u, 2.3) - 0.22 * sin(u * PI) * (1.0 - u)
		return e
	if t < p_windup + p_act:
		return 1.0
	var r: = clampf((t - p_windup - p_act) / p_rec, 0.0, 1.0)
	return 1.0 - r * r * (3.0 - 2.0 * r)


func _guard_local(i: int, side: int, blocking: bool, block_low: bool, stunned: bool, fatigue: float) -> Vector3:
	var g: Vector3
	if i == 0:
		g = Vector3(float(side) * 0.12, 0.47, -0.33)
	else:
		g = Vector3(float(side) * 0.1, 0.45, -0.2)
	if blocking:
		if block_low:
			g = Vector3(float(side) * (0.13 if i == 0 else 0.12), 0.17, -0.2)
		else:
			g = Vector3(float(side) * 0.075, 0.56, -0.25 if i == 0 else -0.23)
	if _clinch:
		g = Vector3(float(side) * 0.24, 0.32, -0.45)
	var drop: = fatigue * 0.08 + (0.14 if stunned else 0.0)
	g.y -= drop

	g += Vector3(sin(_t * 3.1 + float(i) * 1.7) * 0.012, sin(_t * 7.5 + float(i)) * 0.01, cos(_t * 2.3 + float(i)) * 0.015)
	return g


func _punch_target(side: int, dist_u: float) -> Vector3:

	var head_y: = 1.6
	if fighter and fighter.opponent:
		head_y = (fighter.opponent.head_global().y - fighter.global_position.y) / _hf - 0.04
		head_y = clampf(head_y, 0.9, 1.9)
	var body_y: = head_y * 0.73
	var y: = body_y if p_body else head_y
	var x: = float(side) * 0.04
	var z: = - (dist_u - 0.18)
	if Punches.is_hook(p_type):
		x = - float(side) * 0.06
		y = body_y if p_body else head_y - 0.02
		z = - (dist_u - 0.26)
	elif Punches.is_upper(p_type):
		x = float(side) * 0.03
		y = body_y + 0.06 if p_body else head_y - 0.04
		z = - (dist_u - 0.24)
	z = clampf(z, -1.05, -0.3)
	return Vector3(x, y, z)


func _referee_hand(i: int, side: int, torso_xf: Transform3D) -> Vector3:
	var rest: = torso_xf * Vector3(float(side) * 0.24, -0.12, -0.04)
	match ref_action:
		"count":
			if i == 1:
				var pulse: = clampf(1.0 - (_t - ref_pulse) / 0.45, 0.0, 1.0)
				return torso_xf * Vector3(float(side) * 0.25, lerpf(0.35, 0.85, pulse), -0.3)
		"separate":
			return torso_xf * Vector3(float(side) * 0.18, 0.3, -0.5)
		"wave":
			var w: = sin(_t * 10.0) * 0.25
			return torso_xf * Vector3(float(side) * (0.15 + w * float(side)), 0.75, -0.25)
		"start":
			if i == 1:
				return torso_xf * Vector3(float(side) * 0.1, 0.35, -0.5)
	return rest


func _springs(delta: float) -> void :
	if delta <= 0.0:
		return
	var k: = 120.0
	var c: = 13.0
	head_vel += ( - head_spring * k - head_vel * c) * delta
	head_spring += head_vel * delta
	torso_vel += ( - torso_spring * 90.0 - torso_vel * 11.0) * delta
	torso_spring += torso_vel * delta
	recoil_vel += ( - recoil * 60.0 - recoil_vel * 10.0) * delta
	recoil += recoil_vel * delta
	head_spring = head_spring.clamp(Vector3(-0.9, -0.9, -0.9), Vector3(0.9, 0.9, 0.9))
	torso_spring = torso_spring.clamp(Vector3(-0.6, -0.6, -0.6), Vector3(0.6, 0.6, 0.6))
	recoil = clampf(recoil, -0.3, 0.4)




static func _arc(from: Vector3, to: Vector3) -> Quaternion:
	var d: = from.dot(to)
	if d < -0.9999:
		return Quaternion(Vector3.RIGHT, PI)
	if d > 0.9999:
		return Quaternion.IDENTITY
	return Quaternion(from, to)


func _place_segment(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void :
	var dir: = b - a
	var seg_len: = dir.length()
	if seg_len < 0.0001:
		return
	mi.transform = Transform3D(Basis(_arc(Vector3.UP, dir / seg_len)), (a + b) * 0.5)



static func _ik(s: Vector3, t: Vector3, l1: float, l2: float, pole: Vector3) -> Array:
	var d: = t - s
	var dist: = d.length()
	if dist < 0.001:
		d = Vector3(0, -1, 0)
		dist = 0.001
	var dir: = d / dist
	var reach: = clampf(dist, absf(l1 - l2) + 0.01, l1 + l2 - 0.001)
	var end: = s + dir * reach
	var a: = (l1 * l1 - l2 * l2 + reach * reach) / (2.0 * reach)
	var h: = sqrt(maxf(l1 * l1 - a * a, 0.0))
	var pp: = pole - dir * dir.dot(pole)
	if pp.length() < 0.001:
		pp = dir.cross(Vector3.RIGHT)
		if pp.length() < 0.001:
			pp = dir.cross(Vector3.FORWARD)
	pp = pp.normalized()
	return [s + dir * a + pp * h, end]
