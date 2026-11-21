class_name MixamoRig
extends BoxerRig








const MODEL_DIR: = "res://assets/boxers/"
const ANIM_DIR: = "res://assets/anims/"
const INFO_PATH: = "res://assets/anims/anim_info.json"
const LOOPED: = ["idle", "idle_calm", "idle_stance", "walk_forward", "walk_back", "walk_left", "walk_right", 
	"stunned", "victory", "ref_idle", "ref_walk", "ref_walk_back", "ref_strafe_left", "ref_strafe_right", "ref_wave"]

const ROOT_KEEP: = {"walk_forward": 0.0, "walk_back": 0.0, "walk_left": 0.0, "walk_right": 0.0, 
	"idle": 0.0, "idle_calm": 0.0, "idle_stance": 0.0, "stunned": 0.15, "victory": 0.0, "taunt": 0.0, 
	"block": 0.2, "block_body": 0.2, "warmup": 0.0, "entry": 0.0, 
	"ref_idle": 0.0, "ref_walk": 0.0, "ref_walk_back": 0.0, "ref_strafe_left": 0.0, "ref_strafe_right": 0.0, 
	"ref_wave": 0.0, "ref_point": 0.0, "ref_push": 0.0, "ref_count": 0.25}

static var _raw_cache: Dictionary = {}
static var _lib_cache: Dictionary = {}
static var _info: Dictionary = {}

var pivot: Node3D
var model: Node3D
var skeleton: Skeleton3D
var anim: AnimationPlayer
var mod: BoxerPoseModifier
var available: = {}
var current: = ""
var _sk_scale: = 1.0


var mode: = "loco"
var lock: = 0.0
var _p_t: = 0.0
var _p_windup: = 0.2
var _p_active: = 0.08
var _p_speed2: = 1.0
var _p_phase: = 0
var _p_start: = 0.0
var _p_impact: = 0.0
var _p_end: = 0.0
var _p_rec: = 0.3
var _hold_at: = -1.0
var _getup_left: = 0.0
var _side_sm: = 0.0
var _duck_sm: = 0.0
var _back_sm: = 0.0
var _stun_sm: = 0.0
var _mats: = {}

static var _reach_cache: Dictionary = {}
var _reach: Dictionary = {}
var _warp: = 0.0
var _warp_target: = 0.0
var _warp_kind: = 0
var _p_name: = ""
var anim_prefix: = ""
var anim_dir: = ANIM_DIR


static func model_path_for_def(def: Dictionary) -> String:
	var id: String = str(def.get("model", def.get("id", "")))
	for cand in [id, "career_0", "hammer"]:
		for ext in [".gltf", ".glb"]:
			var p: String = MODEL_DIR + str(cand) + str(ext)
			if ResourceLoader.exists(p):
				return p
	return ""


static func has_assets_for(def: Dictionary) -> bool:
	return model_path_for_def(def) != "" and ResourceLoader.exists(ANIM_DIR + "idle.glb")


static func has_assets(_corner: int = 0) -> bool:
	return ResourceLoader.exists(ANIM_DIR + "idle.glb") and model_path_for_def({"id": "hammer"}) != ""


static func info(name: String) -> Dictionary:
	if _info.is_empty() and FileAccess.file_exists(INFO_PATH):
		var txt: = FileAccess.get_file_as_string(INFO_PATH)
		var parsed: Variant = JSON.parse_string(txt)
		if parsed is Dictionary:
			_info = parsed
	var d: Variant = _info.get(name, {})
	return d if d is Dictionary else {}


func setup(def: Dictionary, f: Fighter) -> void :
	fighter = f
	anim_prefix = str(def.get("anim_prefix", ""))
	anim_dir = str(def.get("anim_dir", ANIM_DIR))
	pivot = Node3D.new()
	add_child(pivot)
	var path: String = str(def["model_path"]) if def.has("model_path") else model_path_for_def(def)
	var ps: = load(path) as PackedScene
	if ps == null:
		push_warning("Модель не загрузилась: " + path)
		return
	model = ps.instantiate() as Node3D
	pivot.add_child(model)
	model.rotation.y = PI
	skeleton = _find_skeleton(model)
	if skeleton == null:
		push_warning("В модели нет скелета: " + path)
		return
	var old: = _find_anim_player(model)
	if old:
		old.queue_free()
	anim = AnimationPlayer.new()
	anim.name = "BoxAnim"
	model.add_child(anim)
	anim.root_node = anim.get_path_to(model)
	_fit_height(float(def.get("height", 1.8)))
	if int(def.get("stance", 1)) == -1:
		pivot.scale.x = -1.0
	_build_library(path)
	_measure_reach(path)
	mod = BoxerPoseModifier.new()
	skeleton.add_child(mod)
	mod.setup_bones(skeleton)
	mod.side_sign = 1.0 if int(def.get("stance", 1)) == 1 else -1.0
	if str(def.get("id", "")) != "referee":
		mod.guard = Guards.get_data(Guards.for_def(def))
		var trng: = RandomNumberGenerator.new()
		trng.seed = hash(str(def.get("name", def.get("id", ""))))
		mod.tempo = trng.randf_range(0.88, 1.12)
		if anim:
			_idle_speed = trng.randf_range(0.85, 1.15)
	_apply_colors(def)
	_play("idle", 0.0)




static func _find_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n as Skeleton3D
	for c in n.get_children():
		var s: = _find_skeleton(c)
		if s:
			return s
	return null


static func _find_anim_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c in n.get_children():
		var a: = _find_anim_player(c)
		if a:
			return a
	return null


static func _bone_key(bn: String) -> String:
	var s: = bn.to_lower()
	if s.begins_with("mixamorig"):
		var c1: = s.find(":")
		var c2: = s.find("_")
		var cut: = c1
		if c1 < 0 or (c2 >= 0 and c2 < c1):
			cut = c2
		if cut >= 0:
			s = s.substr(cut + 1)
	return s


func _bone_idx(key: String) -> int:
	if skeleton == null:
		return -1
	for i in skeleton.get_bone_count():
		if _bone_key(skeleton.get_bone_name(i)) == key:
			return i
	return -1


func _fit_height(h: float) -> void :
	var head_idx: = _bone_idx("head")
	if head_idx < 0:
		return
	var head_pos: Vector3 = skeleton.global_transform * skeleton.get_bone_global_rest(head_idx).origin
	var head_y: = head_pos.y - global_position.y
	if head_y > 0.0001:
		model.scale *= (h * 0.875) / head_y
	_sk_scale = maxf(skeleton.global_transform.basis.get_scale().x, 0.0001)


static func _rel_xform(n: Node, stop: Node) -> Transform3D:
	var t: = Transform3D.IDENTITY
	var cur: = n
	while cur != null and cur != stop:
		if cur is Node3D:
			t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t





static func _rest_data(sk: Skeleton3D, root: Node) -> Dictionary:
	var skx: = _rel_xform(sk, root)
	var rots: = {}
	var parents: = {}
	var hips: = -1
	for i in sk.get_bone_count():
		var k: = _bone_key(sk.get_bone_name(i))
		var g: = skx * sk.get_bone_global_rest(i)
		rots[k] = g.basis.orthonormalized().get_rotation_quaternion()
		var p: = sk.get_bone_parent(i)
		parents[k] = _bone_key(sk.get_bone_name(p)) if p >= 0 else ""
		if k == "hips":
			hips = i
	var out: = {"skel_rot": skx.basis.orthonormalized().get_rotation_quaternion(), "skel_basis": skx.basis, 
		"rots": rots, "parents": parents, "hips_rest": Vector3.ZERO, "hips_h": 1.0}
	if hips >= 0:
		out["hips_rest"] = sk.get_bone_rest(hips).origin
		out["hips_h"] = maxf((skx * sk.get_bone_global_rest(hips)).origin.y, 0.01)
	return out


static func _load_raw(name: String, dir: String = ANIM_DIR) -> Dictionary:
	if _raw_cache.has(dir + name):
		return _raw_cache[dir + name]
	var path: = dir + name + ".glb"
	var out: = {}
	if ResourceLoader.exists(path):
		var ps: = load(path) as PackedScene
		if ps:
			var inst: = ps.instantiate()
			var ap: = _find_anim_player(inst)
			var sk: = _find_skeleton(inst)
			var a: Animation = null
			if ap:
				for lib_name in ap.get_animation_library_list():
					var l: = ap.get_animation_library(lib_name)
					for an in l.get_animation_list():
						if str(an) != "RESET":
							a = l.get_animation(an)
							break
					if a:
						break
			var rest: = {}
			if sk:
				rest = _rest_data(sk, inst)
			inst.free()
			if a and not rest.is_empty():
				out = {"anim": a, "rest": rest}
	_raw_cache[dir + name] = out
	return out


func _build_library(model_path: String) -> void :
	var root: = anim.get_node_or_null(anim.root_node)
	if root == null:
		return
	var skel_path: = str(root.get_path_to(skeleton))
	var bone_map: = {}
	for i in skeleton.get_bone_count():
		bone_map[_bone_key(skeleton.get_bone_name(i))] = skeleton.get_bone_name(i)
	var key: = model_path + "|" + skel_path + "|" + anim_prefix
	var lib: AnimationLibrary = _lib_cache.get(key)
	if lib == null:
		var tgt: = _rest_data(skeleton, model)
		lib = AnimationLibrary.new()
		var files: PackedStringArray = DirAccess.get_files_at(anim_dir) if DirAccess.dir_exists_absolute(anim_dir) else PackedStringArray()
		var names: = {}
		for fname in files:
			var fn: = str(fname).trim_suffix(".import").trim_suffix(".remap")
			if fn.get_extension().to_lower() == "glb":
				var bn: = fn.get_basename()
				if (anim_prefix == "" and not bn.begins_with("ref_") and not bn.begins_with("crowd_")) or (anim_prefix != "" and bn.begins_with(anim_prefix)):
					names[bn] = true
		for n in names.keys():
			var nm: String = n
			var raw: = _load_raw(nm, anim_dir)
			if raw.is_empty():
				continue
			var a: Animation = (raw["anim"] as Animation).duplicate(true)
			_retarget(a, skel_path, bone_map, raw["rest"], tgt, float(ROOT_KEEP.get(nm, 1.0)))
			a.loop_mode = Animation.LOOP_LINEAR if LOOPED.has(nm) else Animation.LOOP_NONE
			lib.add_animation(nm, a)
		_lib_cache[key] = lib
	anim.add_animation_library("box", lib)
	available = {}
	for n in lib.get_animation_list():
		available[str(n)] = true





func _retarget(a: Animation, skel_path: String, bone_map: Dictionary, src: Dictionary, tgt: Dictionary, keep_xz: float) -> void :
	var s_rots: Dictionary = src["rots"]
	var t_rots: Dictionary = tgt["rots"]
	var s_par: Dictionary = src["parents"]
	var c_root: Quaternion = (src["skel_rot"] as Quaternion).inverse() * (tgt["skel_rot"] as Quaternion)
	var ratio: float = float(tgt["hips_h"]) / float(src["hips_h"])
	var s_basis: Basis = src["skel_basis"]
	var t_basis_inv: Basis = (tgt["skel_basis"] as Basis).inverse()
	var s_hips_rest: Vector3 = src["hips_rest"]
	var t_hips_rest: Vector3 = tgt["hips_rest"]
	var i: = a.get_track_count() - 1
	while i >= 0:
		var path: NodePath = a.track_get_path(i)
		var bone: = str(path.get_concatenated_subnames())
		var tt: = a.track_get_type(i)
		var keyb: = _bone_key(bone)
		var bad: = bone == "" or not bone_map.has(keyb) or not s_rots.has(keyb) or not t_rots.has(keyb)
		bad = bad or not (tt == Animation.TYPE_POSITION_3D or tt == Animation.TYPE_ROTATION_3D)
		bad = bad or (tt == Animation.TYPE_POSITION_3D and keyb != "hips")
		if bad:
			a.remove_track(i)
			i -= 1
			continue
		a.track_set_path(i, NodePath(skel_path + ":" + str(bone_map[keyb])))
		var n: = a.track_get_key_count(i)
		if tt == Animation.TYPE_ROTATION_3D:
			var cb: Quaternion = (s_rots[keyb] as Quaternion).inverse() * (t_rots[keyb] as Quaternion)
			var pk: String = s_par.get(keyb, "")
			var cp: = c_root
			if pk != "" and s_rots.has(pk) and t_rots.has(pk):
				cp = (s_rots[pk] as Quaternion).inverse() * (t_rots[pk] as Quaternion)
			var cpi: = cp.inverse()
			for k in n:
				var q: Quaternion = a.track_get_key_value(i, k)
				a.track_set_key_value(i, k, (cpi * q * cb).normalized())
		elif n > 0:
			var first: Vector3 = s_basis * ((a.track_get_key_value(i, 0) as Vector3) - s_hips_rest) * ratio
			if keep_xz < 0.5 and a.length > 0.1:

				var last: Vector3 = s_basis * ((a.track_get_key_value(i, n - 1) as Vector3) - s_hips_rest) * ratio
				a.set_meta("stride_speed", Vector2(last.x - first.x, last.z - first.z).length() / a.length)
			for k in n:
				var v: Vector3 = a.track_get_key_value(i, k)
				var d: Vector3 = s_basis * (v - s_hips_rest) * ratio
				d.x = (d.x - first.x) * keep_xz
				d.z = (d.z - first.z) * keep_xz
				a.track_set_key_value(i, k, t_hips_rest + t_basis_inv * d)
		i -= 1



func _measure_reach(model_path: String) -> void :
	var key: = "%s|%.3f" % [model_path, model.scale.x]
	if _reach_cache.has(key):
		_reach = _reach_cache[key]
		return
	var out: = {}
	var hl: = _bone_idx("lefthand")
	var hr: = _bone_idx("righthand")
	var inv: = global_transform.affine_inverse()
	for n in PUNCH_ANIMS + BODY_ANIMS:
		if out.has(n) or not available.has(n) or hl < 0 or hr < 0:
			continue
		var inf: = info(n)
		var ln: = _len(n)
		var hi: = hl if str(inf.get("hand", "left")) == "left" else hr

		var t0: = float(inf.get("hand_start", 0.05)) * ln
		var t1: = float(inf.get("hand_end", 0.6)) * ln
		var best_t: = float(inf.get("impact_frac", 0.3)) * ln
		var best_f: = -10.0
		anim.play("box/" + n, 0.0)
		var t: = t0
		while t <= t1:
			anim.seek(t, true)
			var gp: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(hi).origin
			var f: = - (inv * gp).z
			if f > best_f:
				best_f = f
				best_t = t
			t += 1.0 / 60.0
		out[n] = {"fwd": best_f + 0.13 * model.scale.x, "t": best_t}

	var strides: = {}
	var fl: = _bone_idx("leftfoot")
	var fr: = _bone_idx("rightfoot")
	for wn in ["walk_forward", "walk_back", "walk_left", "walk_right"]:
		if not available.has(wn) or fl < 0 or fr < 0:
			continue
		var wl: = _len(wn)
		var lat: bool = wn == "walk_left" or wn == "walk_right"
		var mins: = [1000000000.0, 1000000000.0]
		var maxs: = [-1000000000.0, -1000000000.0]
		anim.play("box/" + wn, 0.0)
		var tt: = 0.0
		while tt <= wl:
			anim.seek(tt, true)
			for j in 2:
				var fp: Vector3 = inv * (skeleton.global_transform * skeleton.get_bone_global_pose(fl if j == 0 else fr).origin)
				var c: float = fp.x if lat else fp.z
				mins[j] = minf(mins[j], c)
				maxs[j] = maxf(maxs[j], c)
			tt += 1.0 / 60.0
		var rng: float = (float(maxs[0]) - float(mins[0]) + float(maxs[1]) - float(mins[1])) * 0.5
		strides[wn] = rng / maxf(0.55 * wl, 0.1)
	out["__strides"] = strides
	anim.stop()
	_reach_cache[key] = out
	_reach = out
	if OS.is_debug_build() and not strides.is_empty():
		print("[STRIDE] ", strides)


func _update_warp(delta: float) -> void :
	var w: = 0.0
	if mode == "punch" and _reach.has(_p_name):
		var impact_t: = _p_windup + _p_active * 0.5
		if _p_t < impact_t:

			var dist: = fighter.dist_to_opp
			var max_r: = float(fighter.punch.get("reach", 1.3)) + 0.06
			var contact: = dist - ([0.12, 0.02, 0.08, 0.16][_warp_kind] as float)
			if fighter.opponent and fighter.opponent.is_bag:
				contact = dist - BagRig.RADIUS - 0.05
			var want: = minf(contact, max_r)
			_warp_target = clampf(want - float(_reach[_p_name]["fwd"]), -0.6, 0.6)
			w = smoothstep(0.0, impact_t, _p_t)
		else:
			w = 1.0 - smoothstep(impact_t + _p_active, impact_t + _p_active + maxf(lock + _p_t - impact_t - _p_active, 0.1), _p_t)
		_warp = lerpf(_warp, _warp_target * w, clampf(delta * 30.0, 0.0, 1.0))
	else:
		_warp = lerpf(_warp, 0.0, clampf(delta * 8.0, 0.0, 1.0))
	if pivot:
		pivot.position.z = - _warp


static var _detail_cache: Dictionary = {}



static func _detail_normal(kind: String) -> Texture2D:
	if _detail_cache.has(kind):
		return _detail_cache[kind]
	var n: = FastNoiseLite.new()
	var t: = NoiseTexture2D.new()
	t.width = 512
	t.height = 512
	t.seamless = true
	t.as_normal_map = true
	match kind:
		"pores":
			t.width = 2048
			t.height = 2048
			n.noise_type = FastNoiseLite.TYPE_CELLULAR
			n.frequency = 0.32
			t.bump_strength = 1.2
		"leather":
			n.noise_type = FastNoiseLite.TYPE_CELLULAR
			n.frequency = 0.06
			n.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
			t.bump_strength = 3.0
		"satin":
			n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
			n.frequency = 0.009
			n.fractal_octaves = 4
			t.bump_strength = 9.0
		"strands":
			t.width = 1024
			t.height = 1024
			n.noise_type = FastNoiseLite.TYPE_CELLULAR
			n.frequency = 0.22
			n.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
			t.bump_strength = 1.4
		"weave":
			n.noise_type = FastNoiseLite.TYPE_VALUE
			n.frequency = 0.45
			t.bump_strength = 1.6
		_:
			n.noise_type = FastNoiseLite.TYPE_SIMPLEX
			n.frequency = 0.14
			n.fractal_octaves = 2
			t.bump_strength = 2.0
	t.noise = n
	_detail_cache[kind] = t
	return t


static func _fabric(sm: StandardMaterial3D, kind: String, strength: float, uv: float) -> void :

	if sm.albedo_texture != null:
		return
	sm.normal_enabled = true
	sm.normal_texture = _detail_normal(kind)
	sm.normal_scale = strength
	sm.uv1_scale = Vector3(uv, uv, uv)


func _apply_colors(def: Dictionary) -> void :
	var trunks: Color = def.get("trunks", Color(0.7, 0.1, 0.1))
	var trim: Color = def.get("trim", Color(0.95, 0.8, 0.25))
	var gloves: Color = def.get("gloves", Color(0.75, 0.06, 0.06))
	var boots: Color = def.get("boots", Color(0.06, 0.06, 0.07) if trunks.v > 0.6 else Color(0.93, 0.93, 0.93))
	var skin_tint: Color = def.get("skin_tint", Color(1, 1, 1))
	var hair_tint: Color = def.get("hair_tint", Color(1, 1, 1))
	for mi in _all_meshes(model):
		var m3: = mi as MeshInstance3D
		if m3.mesh == null:
			continue
		m3.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

		m3.lod_bias = 128.0
		for s in m3.mesh.get_surface_count():
			var src: = m3.mesh.surface_get_material(s)
			if src == null:
				continue
			var mname: = src.resource_name.get_slice(".", 0)
			var m: = src.duplicate() as Material
			var sm: = m as StandardMaterial3D
			if sm:
				sm.rim_enabled = false
				match mname:
					"Trunks":

						sm.cull_mode = BaseMaterial3D.CULL_DISABLED
						sm.albedo_color = trunks
						sm.roughness = 0.58
						sm.metallic_specular = 0.34
						sm.anisotropy_enabled = true
						sm.anisotropy = 0.55

						sm.rim_enabled = true
						sm.rim = 0.18
						sm.rim_tint = 0.85
						sm.clearcoat_enabled = false
						_fabric(sm, "satin", 0.55, 3.0)
					"TrunksTrim":
						sm.albedo_color = trim
						sm.metallic = 0.12
						sm.roughness = 0.46
						_fabric(sm, "weave", 0.4, 10.0)
					"Glove":

						sm.albedo_color = _leather_tone(gloves)
						sm.roughness = 0.46
						sm.metallic_specular = 0.45
						sm.clearcoat_enabled = true
						sm.clearcoat = 0.14
						sm.clearcoat_roughness = 0.42
						_fabric(sm, "pores", 0.22, 2.2)
					"GlovePalm":
						sm.albedo_color = _leather_tone(gloves).darkened(0.22)
						sm.roughness = 0.55
						sm.metallic_specular = 0.45
						_fabric(sm, "pores", 0.2, 2.6)
					"GloveCuff":
						sm.albedo_color = def.get("glove_cuff", Color(0.9, 0.9, 0.88) if gloves.v < 0.85 else gloves.darkened(0.1))
						sm.roughness = 0.5
						sm.clearcoat_enabled = true
						sm.clearcoat = 0.1
						sm.clearcoat_roughness = 0.45
						_fabric(sm, "pores", 0.18, 2.2)
					"GloveStrap":
						sm.albedo_color = def.get("glove_strap", gloves.darkened(0.5))
						sm.roughness = 0.72
						_fabric(sm, "weave", 0.6, 12.0)
					"GloveTrim":
						sm.albedo_color = def.get("glove_trim", Color(0.95, 0.95, 0.95))
						sm.roughness = 0.5
					"GloveLogo":

						sm.albedo_color = def.get("glove_logo", Color(0.95, 0.94, 0.9) if gloves.v < 0.8 else Color(0.08, 0.08, 0.09))
						if sm.albedo_texture != null:
							sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
							sm.alpha_scissor_threshold = 0.4
						sm.metallic = 0.0
						sm.roughness = 0.42
						sm.clearcoat_enabled = true
						sm.clearcoat = 0.2
						sm.clearcoat_roughness = 0.35
					"Boots":
						sm.cull_mode = BaseMaterial3D.CULL_DISABLED
						sm.albedo_color = boots
						sm.roughness = 0.55
						sm.metallic_specular = 0.4
						_fabric(sm, "leather", 0.22, 3.0)
					"BootSole":
						sm.cull_mode = BaseMaterial3D.CULL_DISABLED
						sm.roughness = 0.85
					"Skin":

						var skm: = ShaderMaterial.new()
						skm.shader = SKIN_SHADER
						skm.set_shader_parameter("albedo_tex", sm.albedo_texture)
						skm.set_shader_parameter("tint", sm.albedo_color * skin_tint)
						skm.set_shader_parameter("pores_tex", _detail_normal("pores"))
						skm.set_shader_parameter("dmg_mask", DMG_MASK)
						skm.set_shader_parameter("grain_tex", _grain())
						skm.set_shader_parameter("zones_tex", ZONES)
						skm.set_shader_parameter("detail_nrm", BODY_NRM)
						skm.set_shader_parameter("cavity_tex", BODY_CAV)
						skm.set_shader_parameter("micro_nrm", SKIN_MICRO)
						_mats["skin"] = skm
						m = skm
					"Hair":
						sm.albedo_color = sm.albedo_color * hair_tint

						sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
						sm.alpha_scissor_threshold = 0.35
						sm.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE_AND_TO_ONE
						sm.alpha_antialiasing_edge = 0.3
						sm.cull_mode = BaseMaterial3D.CULL_DISABLED
						sm.roughness = 0.62
						sm.metallic_specular = 0.28
						sm.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
						sm.anisotropy_enabled = true
						sm.anisotropy = 0.85
						sm.rim_enabled = true
						sm.rim = 0.12
						sm.rim_tint = 1.0
						sm.alpha_scissor_threshold = 0.42
					"Eyes":

						var em: = ShaderMaterial.new()
						em.shader = EYE_SHADER
						em.set_shader_parameter("albedo_tex", sm.albedo_texture)
						em.set_shader_parameter("tint", sm.albedo_color)
						if not _mats.has("eyes"):
							_mats["eyes"] = []
						(_mats["eyes"] as Array).append(em)
						m = em
					"Eyebrows", "Eyelashes":

						sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
						sm.alpha_scissor_threshold = 0.3
						sm.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE_AND_TO_ONE
						sm.alpha_antialiasing_edge = 0.25
						sm.roughness = 0.75
						sm.cull_mode = BaseMaterial3D.CULL_DISABLED
					"Shirt":

						sm.cull_mode = BaseMaterial3D.CULL_DISABLED
						sm.albedo_texture = null
						sm.albedo_color = Color(0.74, 0.8, 0.88)
						sm.roughness = 0.88
						sm.metallic_specular = 0.3
						_fabric(sm, "cotton", 0.3, 6.0)
					"Trousers":
						sm.cull_mode = BaseMaterial3D.CULL_DISABLED
						sm.roughness = 0.78
						sm.metallic_specular = 0.3
						_fabric(sm, "cotton", 0.3, 6.0)
					"Shoes":
						sm.cull_mode = BaseMaterial3D.CULL_DISABLED
						sm.albedo_color = Color(0.2, 0.18, 0.17)
						sm.roughness = 0.35
						sm.clearcoat_enabled = true
						sm.clearcoat = 0.3
					"Belt", "BowTie":
						sm.cull_mode = BaseMaterial3D.CULL_DISABLED
						sm.roughness = 0.4
			m3.set_surface_override_material(s, m)


const SKIN_SHADER: = preload("res://scripts/visual/skin.gdshader")
const EYE_SHADER: = preload("res://scripts/visual/eye.gdshader")
const SKIN_MICRO: = preload("res://assets/fx/skin_micro_nrm.png")
const DMG_MASK: = preload("res://assets/fx/face_damage_mask.png")
const ZONES: = preload("res://assets/fx/skin_zones.png")
const BODY_NRM: = preload("res://assets/fx/body_detail_nrm.png")
const BODY_CAV: = preload("res://assets/fx/body_cavity.png")
static var _grain_tex: NoiseTexture2D


static func _grain() -> NoiseTexture2D:
	if _grain_tex == null:
		var n: = FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.frequency = 0.012
		n.fractal_octaves = 4
		_grain_tex = NoiseTexture2D.new()
		_grain_tex.width = 256
		_grain_tex.height = 256
		_grain_tex.seamless = true
		_grain_tex.noise = n
	return _grain_tex



static func _leather_tone(c: Color) -> Color:
	var h: = c.h
	var sat: = minf(c.s, 0.88)
	var val: = c.v * (0.82 if c.v > 0.5 else 1.0)
	return Color.from_hsv(h, sat, val)


static func _all_meshes(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_all_meshes(c))
	return out




func _play(n: String, blend: float = 0.12, spd: float = 1.0, restart: bool = false, from: float = 0.0) -> bool:
	if anim == null or not available.has(n):
		return false
	if current == n and not restart and anim.is_playing():
		anim.speed_scale = spd
		return true
	anim.play("box/" + n, blend)
	anim.speed_scale = spd
	if from > 0.0 or restart:
		anim.seek(from, true)
	current = n
	_hold_at = -1.0
	return true


func _len(n: String) -> float:
	if anim and anim.has_animation("box/" + n):
		return anim.get_animation("box/" + n).length
	return 1.0



var _gaze: = Vector2.ZERO
var _gaze_to: = Vector2.ZERO
var _gaze_t: = 0.5


func _update_eyes(delta: float) -> void :
	if not _mats.has("eyes"):
		return
	_gaze_t -= delta
	if _gaze_t <= 0.0:
		_gaze_t = randf_range(0.35, 2.2)
		var r: = 0.012 if randf() < 0.8 else 0.028
		_gaze_to = Vector2(randf_range( - r, r), randf_range( - r, r) * 0.6)
	var stun: = fighter.stun_timer if fighter else 0.0
	var want: = _gaze_to
	if stun > 0.0:
		want = Vector2(sin(Time.get_ticks_msec() * 0.0021) * 0.02, cos(Time.get_ticks_msec() * 0.0017) * 0.012)

	_gaze = _gaze.lerp(want, clampf(delta * 28.0, 0.0, 1.0))
	for em in _mats["eyes"]:
		(em as ShaderMaterial).set_shader_parameter("gaze", _gaze)


func update_rig(delta: float) -> void :
	if anim == null or fighter == null:
		return
	_update_eyes(delta)
	lock -= delta
	_smooth_layers(delta)
	_update_warp(delta)
	if mod:
		mod.step(delta)
	if _hold_at >= 0.0 and anim.current_animation_position >= _hold_at:
		anim.speed_scale = 0.0
	match mode:
		"punch":
			_p_t += delta
			var imp_t: = _p_windup + _p_active * 0.5
			if _p_phase == 0 and _p_t >= imp_t:
				_p_phase = 1


			if current == _p_name and anim.is_playing():


				var pos: = _punch_curve(_p_t, imp_t)
				var nxt: = _punch_curve(_p_t + 1.0 / 60.0, imp_t)
				anim.speed_scale = clampf((nxt - pos) * 60.0, 0.05, 8.0)
				anim.seek(pos, false)
			if lock <= 0.0:
				mode = "loco"
		"hit", "parried", "show":
			if lock <= 0.0:
				mode = "loco"
		"defeat":
			return
		"down":
			return
		"getup":
			_getup_left -= delta
			if _getup_left <= 0.0:
				mode = "loco"
			return
		"victory":
			_play("victory", 0.3)
			return
	if mode != "loco":
		return
	var st: = fighter.state
	if st == Fighter.State.KO or st == Fighter.State.DOWN:
		return
	if st == Fighter.State.CLINCH:
		_play("idle", 0.25, _idle_speed)
		return
	if fighter.stun_timer > 0.0 and not fighter.blocking and available.has("stunned"):
		_play("stunned", 0.25)
		return
	var m: = fighter.local_move
	var hv: = fighter.velocity
	hv.y = 0.0
	var mps: = hv.length()
	if mps > 0.18 and fighter.lean_amount < 0.3:
		var wn: = ""
		if absf(m.y) >= absf(m.x) * 0.8:
			wn = "walk_forward" if m.y > 0.0 else "walk_back"
		else:
			wn = "walk_right" if m.x > 0.0 else "walk_left"

		var native: = _stride_speed(wn)
		var top: = 3.2 if (wn == "walk_left" or wn == "walk_right") else 2.6
		var sp: = clampf(mps / native, 0.45, top) if native > 0.05 else clampf(m.length() * 1.15, 0.6, 1.5)
		_play(wn, 0.2, sp)
	else:
		_play("idle", 0.25, _idle_speed)



func _punch_curve(t: float, imp_t: float) -> float:
	if t < imp_t:
		var pp: = clampf(t / maxf(imp_t, 0.01), 0.0, 1.0)
		return lerpf(_p_start, _p_impact, 0.2 * pp + 0.8 * pow(pp, 2.4))
	var q: = clampf((t - imp_t) / maxf(_p_rec, 0.05), 0.0, 1.0)
	return lerpf(_p_impact, _p_end, 1.0 - pow(1.0 - q, 2.3))


func _stride_speed(n: String) -> float:
	var st: Dictionary = _reach.get("__strides", {})
	return float(st.get(n, 0.0))


func _hold_anim(n: String, blend: float) -> void :
	if current == n:
		return
	var inf: = info(n)
	var ln: = _len(n)
	var start: = float(inf.get("hand_start", 0.0)) * ln
	var peak: = float(inf.get("impact_frac", 0.3)) * ln
	if _play(n, blend, 1.6, true, start):
		_hold_at = peak


var _dmg_bruise: = 0.0
var _guard_w: = 0.0
var _block_w: = 0.0
var _block_lo: = 0.0
var _gb_w: = 0.0
var _tw_amt: = 0.0

const TWIST: = [-0.05, 0.13, -0.2, 0.22, -0.09, 0.12]
var _idle_speed: = 1.0
var _dmg_cut: = 0.0
var _dmg_blood: = 0.0


func _smooth_layers(delta: float) -> void :
	if mod == null:
		return
	var lv: = fighter.lean_vec
	var k: = clampf(delta * 16.0, 0.0, 1.0)
	_side_sm = lerpf(_side_sm, clampf(lv.x, -1.0, 1.0), k)
	_duck_sm = lerpf(_duck_sm, clampf(lv.y, 0.0, 1.0), k)
	_back_sm = lerpf(_back_sm, clampf( - lv.y, 0.0, 1.0), k)
	_stun_sm = lerpf(_stun_sm, 1.0 if fighter.stun_timer > 0.0 else 0.0, clampf(delta * 3.0, 0.0, 1.0))
	mod.side = _side_sm
	mod.duck = _duck_sm
	mod.back = _back_sm
	mod.stun = _stun_sm

	var gt: = 0.0
	if mode == "loco" and fighter.state == Fighter.State.IDLE and not fighter.blocking and fighter.stun_timer <= 0.0:
		gt = 1.0
	_guard_w = move_toward(_guard_w, gt, delta * (4.0 if gt > _guard_w else 16.0))
	mod.guard_w = _guard_w

	var bt: = 0.0
	var blo: = 0.0
	if fighter.blocking and (mode == "loco" or mode == "hit"):
		bt = 1.0
		blo = 1.0 if fighter.block_low else 0.0

	var ct: = 1.0 if fighter.state == Fighter.State.CLINCH else 0.0
	_clinch_w = move_toward(_clinch_w, ct, delta * (3.2 if ct > _clinch_w else 4.5))
	mod.clinch_w = _clinch_w
	if _clinch_w > 0.001:
		_update_clinch_targets()
	_block_w = move_toward(_block_w, bt, delta * (14.0 if bt > _block_w else 7.0))
	_block_lo = move_toward(_block_lo, blo, delta * 8.0)
	mod.block_w = _block_w
	mod.block_low = _block_lo
	_gb_w = move_toward(_gb_w, 1.0 if fighter.guard_break_t > 0.45 else 0.0, delta * (10.0 if fighter.guard_break_t > 0.45 else 3.0))

	mod.guard_broken = maxf(_gb_w, _stun_sm * 0.6)

	var tw: = 0.0
	if mode == "punch":
		var impact_t: = _p_windup + _p_active * 0.5
		if _p_t < impact_t:
			tw = _tw_amt * smoothstep(0.0, impact_t, _p_t)
		else:
			tw = _tw_amt * (1.0 - smoothstep(impact_t, impact_t + maxf(lock + _p_t - impact_t, 0.1), _p_t))
	mod.punch_twist = lerpf(mod.punch_twist, tw, clampf(delta * 24.0, 0.0, 1.0))
	if _mats.has("skin"):
		var sk: ShaderMaterial = _mats["skin"]

		var kb: = clampf(delta * 1.5, 0.0, 1.0)

		_dmg_peak = maxf(_dmg_peak - delta * 0.004, (1.0 - fighter.head_ratio()) * 0.85)
		_dmg_bruise = lerpf(_dmg_bruise, clampf((1.0 - fighter.head_max_ratio()) * 2.4 + _dmg_peak * 0.7 + (1.0 - fighter.head_ratio()) * 0.3, 0.0, 1.0), kb)
		_dmg_cut = lerpf(_dmg_cut, clampf(fighter.cut / 100.0, 0.0, 1.0), kb)
		_dmg_blood = lerpf(_dmg_blood, maxf(fighter.nose_blood, 0.0), kb)
		sk.set_shader_parameter("bruise", _dmg_bruise)
		sk.set_shader_parameter("cut", _dmg_cut)
		sk.set_shader_parameter("blood", _dmg_blood)
		sk.set_shader_parameter("sweat", fighter.sweat)
		var opp_spill: = fighter.opponent.blood_spill if fighter.opponent else 0.0
		sk.set_shader_parameter("spatter", clampf((fighter.blood_spill * 0.6 + opp_spill * 0.3) / 30.0, 0.0, 0.5))


var _clinch_w: = 0.0


func _bone_world(key: String) -> Vector3:
	var idx: = _bone_idx(key)
	if idx < 0 or skeleton == null:
		return global_position + Vector3(0, 1.3, 0)
	return skeleton.global_transform * skeleton.get_bone_global_pose(idx).origin




func _update_clinch_targets() -> void :
	var opp: = fighter.opponent
	if opp == null or not (opp.rig is MixamoRig):
		mod.clinch_lead = Vector3.ZERO
		mod.clinch_rear = Vector3.ZERO
		return
	var o: = opp.rig as MixamoRig
	var me_c: = _bone_world("spine2")
	var o_chest: = o._bone_world("spine2")
	var o_neck: = o._bone_world("neck")
	var o_low: = o._bone_world("spine").lerp(o_chest, 0.45)
	var fwd: = o_chest - me_c
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else - global_transform.basis.z
	var lat: = Vector3.UP.cross(fwd).normalized()

	var l_side: = signf((_bone_world("leftarm") - me_c).dot(lat))
	var r_side: = signf((_bone_world("rightarm") - me_c).dot(lat))
	if l_side == 0.0:
		l_side = 1.0
	if r_side == 0.0:
		r_side = - l_side
	var t: = Time.get_ticks_msec() * 0.001
	var jig: = Vector3(0, sin(t * 2.3 + float(fighter.corner)) * 0.02, 0)
	if fighter.clinch_initiator:
		mod.clinch_lead = o_neck + fwd * 0.1 + lat * l_side * 0.13 + Vector3(0, -0.04, 0) + jig
		mod.clinch_rear = o_chest + fwd * 0.13 + lat * r_side * 0.12 + Vector3(0, -0.1, 0) - jig
	else:
		mod.clinch_lead = o_low + fwd * 0.12 + lat * l_side * 0.17 + Vector3(0, 0.06, 0) - jig
		mod.clinch_rear = o_low + fwd * 0.12 + lat * r_side * 0.17 + Vector3(0, 0.02, 0) + jig

	mod.clinch_side = 1.0




const PUNCH_ANIMS: = ["jab", "cross", "lead_hook", "rear_hook", "lead_uppercut", "rear_uppercut"]
const BODY_ANIMS: = ["body_jab", "body_jab_cross", "body_hook_short", "rear_uppercut", "lead_uppercut", "rear_uppercut"]


func on_punch_start(type: int, body: bool, power: bool, windup: float, active: float, recovery: float) -> void :
	_tw_amt = float(TWIST[type]) * (1.4 if power else 1.0) * (0.8 if body else 1.0)
	var n: String = BODY_ANIMS[type] if body else PUNCH_ANIMS[type]
	if not available.has(n):
		n = PUNCH_ANIMS[type]
	if not available.has(n):
		return
	var inf: = info(n)
	var ln: = _len(n)
	var start: = float(inf.get("hand_start", 0.05)) * ln
	var impact: = float(inf.get("impact_frac", 0.3)) * ln
	if _reach.has(n):
		impact = float(_reach[n]["t"])
	var end: = maxf(float(inf.get("hand_end", 0.6)) * ln, impact + 0.15)
	var sp1: = clampf((impact - start) / maxf(windup, 0.04), 0.5, 5.0)
	_p_speed2 = clampf((end - impact) / maxf(recovery + active * 0.5, 0.05), 0.5, 5.0)
	_play(n, 0.05, sp1, true, start)
	_p_start = start
	_p_impact = impact
	_p_end = end
	_p_rec = recovery + active * 0.5
	_p_name = n
	_warp_kind = 3 if body else (1 if Punches.is_hook(type) else (2 if Punches.is_upper(type) else 0))
	_p_t = 0.0
	_p_windup = windup
	_p_active = active
	_p_phase = 0
	mode = "punch"
	lock = windup + active + recovery
	if mod:
		mod.impulse_body(Vector3(0.0, 0.0, 0.0))


func on_punch_cancel() -> void :
	if mode == "punch":
		mode = "loco"
		lock = 0.0


func on_hit(body: bool, incoming_side: int, strength: float, type: int) -> void :
	var n: = "hit_body"
	if body:
		n = "hit_body_big" if strength > 0.8 else "hit_body"
	elif Punches.is_upper(type):
		n = "hit_upper" if strength > 0.9 else "hit_head_big"
	elif Punches.is_hook(type):
		if strength > 0.85:
			n = "hit_head_big_left" if incoming_side > 0 else "hit_head_big_right"
		else:
			n = "hit_head_left" if incoming_side > 0 else "hit_head_right"
	else:
		n = "hit_head_big" if strength > 0.9 else ("hit_head" if strength > 0.45 else "hit_head_light")
	if not available.has(n):
		n = "hit_head"
	var inf: = info(n)
	var ln: = _len(n)
	var start: = float(inf.get("head_start", 0.0)) * ln
	var end: = float(inf.get("head_end", 0.8)) * ln
	var spd: = 1.25 + strength * 0.2
	if _play(n, 0.04, spd, true, start):
		mode = "hit"
		lock = minf((end - start) / spd, 0.35 + strength * 0.45)
	if mod:

		var dir: = Vector3(0, 0, -1)
		var sk: = mod.get_skeleton()
		if fighter and fighter.opponent and sk:
			var w: = fighter.global_position - fighter.opponent.global_position
			dir = sk.global_transform.basis.inverse() * w
			dir.y = 0.0
			dir = dir.normalized()
		if Punches.is_hook(type) and not body:
			dir = (dir + Vector3( - float(incoming_side), 0, 0) * 1.6).normalized()
		var kind: = 2 if Punches.is_upper(type) else (1 if Punches.is_hook(type) else 0)
		mod.hit_react(dir, strength, "body" if body else "head", kind)


func on_blocked_hit(strength: float) -> void :
	if mod:
		mod.impulse_body(Vector3(3.0 * strength, 0.0, 0.0))
		mod.impulse_head(Vector3(2.2 * strength, 0.0, 0.0))
		mod.impulse_block(1.6 * strength)


func on_parried() -> void :
	mode = "parried"
	lock = 0.35
	_play("hit_head_light", 0.05, 1.4, true)
	if mod:
		mod.impulse_body(Vector3(3.5, 0.0, 0.0))


func on_knockdown(body_kd: bool) -> void :
	mode = "down"
	var n: = "knockdown_body" if body_kd else ("knockdown" if randf() < 0.6 else "knockdown_punch")
	if not available.has(n):
		n = "knockdown"
	var inf: = info(n)
	var ln: = _len(n)
	_play(n, 0.06, 1.15, true, float(inf.get("head_start", 0.0)) * ln * 0.8)
	_hold_at = ln * 0.97


func on_getup(duration: float) -> void :
	mode = "getup"
	_getup_left = duration
	var n: = "getup_b" if available.has("getup_b") else "getup"
	var inf: = info(n)
	var ln: = _len(n)
	var start: = float(inf.get("hand_start", 0.1)) * ln
	var spd: = clampf((ln - start) / maxf(duration, 0.3), 0.4, 4.0)
	_play(n, 0.25, spd, true, start)


func on_victory() -> void :
	mode = "victory"
	_play("victory", 0.3)


func play_show(n: String) -> float:
	if not available.has(n):
		return 0.0
	if _play(n, 0.3, 1.0, true):
		mode = "show"
		lock = _len(n)
		return lock
	return 0.0


func on_defeat() -> void :
	if available.has("defeat") and _play("defeat", 0.35, 1.0, true):
		mode = "defeat"


func on_clinch(active: bool) -> void :
	if not active and mode == "loco":
		current = ""


func on_reset() -> void :
	stop_ragdoll()
	mode = "loco"
	lock = 0.0
	_hold_at = -1.0
	current = ""
	_play("idle", 0.2)




var _ragdoll: PhysicalBoneSimulator3D
var _dmg_peak: = 0.0

const RAG_BONES: = [
	["hips", "spine", 0.13, 11.0, 0.0], 
	["spine1", "spine2", 0.13, 9.0, 18.0], 
	["spine2", "neck", 0.15, 10.0, 18.0], 
	["head", "headtop_end", 0.105, 5.0, 40.0], 
	["leftarm", "leftforearm", 0.055, 2.2, 75.0], 
	["leftforearm", "lefthand", 0.048, 1.5, 70.0], 
	["lefthand", "lefthandmiddle1", 0.075, 0.9, 30.0], 
	["rightarm", "rightforearm", 0.055, 2.2, 75.0], 
	["rightforearm", "righthand", 0.048, 1.5, 70.0], 
	["righthand", "righthandmiddle1", 0.075, 0.9, 30.0], 
	["leftupleg", "leftleg", 0.085, 8.0, 55.0], 
	["leftleg", "leftfoot", 0.06, 4.0, 60.0], 
	["rightupleg", "rightleg", 0.085, 8.0, 55.0], 
	["rightleg", "rightfoot", 0.06, 4.0, 60.0], 
]


func is_ragdoll() -> bool:
	return _ragdoll != null



func start_ragdoll(impulse: Vector3) -> bool:
	if skeleton == null or _ragdoll != null:
		return false

	if pivot and pivot.scale.x < 0.0:
		pivot.scale.x = 1.0
	var sim: = PhysicalBoneSimulator3D.new()
	sim.name = "Ragdoll"
	skeleton.add_child(sim)
	var unit: = 1.0 / maxf(absf(skeleton.global_transform.basis.get_scale().x), 0.0001)
	var bodies: = {}
	for row in RAG_BONES:
		var r: Array = row
		var bi: = _bone_idx(str(r[0]))
		if bi < 0:
			continue
		var ci: = _bone_idx(str(r[1]))
		var child_off: = Vector3(0, 0.12 * unit, 0)
		if ci >= 0:
			child_off = skeleton.get_bone_rest(ci).origin
		else:

			var par: = skeleton.get_bone_parent(bi)
			if par >= 0:
				var gb: = skeleton.get_bone_global_rest(bi)
				var gp: = skeleton.get_bone_global_rest(par)
				var dir_g: = (gb.origin - gp.origin).normalized()
				child_off = (gb.basis.inverse() * dir_g).normalized() * 0.2 * unit
		if child_off.length() < 0.0001:
			continue
		var half: = child_off.length() * 0.5
		var rad: = float(r[2]) * unit
		var pb: = PhysicalBone3D.new()
		pb.name = "PB_" + str(r[0])
		pb.bone_name = skeleton.get_bone_name(bi)
		pb.mass = float(r[3])
		pb.friction = 0.9
		pb.bounce = 0.05
		pb.linear_damp = 0.6
		pb.angular_damp = 4.0
		pb.collision_layer = 8
		pb.collision_mask = 1
		var up: = Vector3.UP
		if up.cross(child_off).length() < 0.0001:
			up = Vector3(0, 0, 1)
		var bb: = Basis.looking_at(child_off, up)
		pb.body_offset = Transform3D(bb, bb * Vector3(0, 0, - half))
		pb.joint_offset = Transform3D(Basis.IDENTITY, Vector3(0, 0, half))
		var cap: = CapsuleShape3D.new()
		cap.radius = rad
		cap.height = maxf(half * 2.0 + rad, rad * 2.05)
		var cs: = CollisionShape3D.new()
		cs.shape = cap
		cs.transform = Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)), Vector3.ZERO)
		pb.add_child(cs)
		var span: = float(r[4])
		if span > 0.0:
			pb.joint_type = PhysicalBone3D.JOINT_TYPE_CONE
			pb.set("joint_constraints/swing_span", span)
			pb.set("joint_constraints/twist_span", span * 0.4)
			pb.set("joint_constraints/softness", 0.8)
			pb.set("joint_constraints/relaxation", 1.0)
		else:
			pb.joint_type = PhysicalBone3D.JOINT_TYPE_NONE
		sim.add_child(pb)
		bodies[str(r[0])] = pb
	if bodies.is_empty():
		sim.queue_free()
		return false
	_ragdoll = sim
	mode = "down"
	if mod:
		mod.active = false
	if anim:
		anim.speed_scale = 0.0
	sim.physical_bones_start_simulation()
	var dir: = impulse
	dir.y = 0.0
	var force: = clampf(impulse.length(), 0.5, 3.0)
	dir = dir.normalized() if dir.length() > 0.001 else - global_transform.basis.z
	if bodies.has("head"):
		(bodies["head"] as PhysicalBone3D).apply_central_impulse((dir * 2.4 + Vector3(0, 0.6, 0)) * force * 3.0)
	if bodies.has("spine2"):
		(bodies["spine2"] as PhysicalBone3D).apply_central_impulse((dir * 1.4) * force * 7.0)
	return true




func _process(_delta: float) -> void :
	if _ragdoll and skeleton:
		var h: = _bone_idx("hips")
		if h >= 0:
			skeleton.set_bone_pose_position(h, skeleton.get_bone_pose_position(h))


func stop_ragdoll() -> void :
	if _ragdoll:
		_ragdoll.physical_bones_stop_simulation()
		_ragdoll.queue_free()
		_ragdoll = null
		if mod:
			mod.active = true


func get_head_global() -> Vector3:


	if _ragdoll:
		var pbh: = _ragdoll.get_node_or_null("PB_head") as Node3D
		if pbh:
			return pbh.global_position
	var idx: = _bone_idx("head")
	if idx >= 0 and skeleton:
		return skeleton.global_transform * skeleton.get_bone_global_pose(idx).origin + Vector3(0, 0.06, 0)
	return global_position + Vector3(0, 1.65, 0)


const ROPE_PTS: = [["hips", 0.17], ["spine2", 0.19], ["head", 0.12], ["leftforearm", 0.06], ["rightforearm", 0.06], ["leftleg", 0.08], ["rightleg", 0.08], ["lefthand", 0.08], ["righthand", 0.08]]


func rope_points() -> Array:
	var out: Array = []
	for row in ROPE_PTS:
		var bn: String = row[0]
		var rad: float = row[1]
		var p: = Vector3.ZERO
		var ok: = false
		if _ragdoll:
			var pb: = _ragdoll.get_node_or_null("PB_" + bn) as Node3D
			if pb:
				p = pb.global_position
				ok = true
		if not ok:
			var idx: = _bone_idx(bn)
			if idx < 0 or skeleton == null:
				continue
			p = skeleton.global_transform * skeleton.get_bone_global_pose(idx).origin
		out.append(Vector4(p.x, p.y, p.z, rad))
	return out


func get_glove_global(lead: bool) -> Vector3:
	var key: = "lefthand" if lead else "righthand"
	var idx: = _bone_idx(key)
	if idx >= 0 and skeleton:
		return skeleton.global_transform * skeleton.get_bone_global_pose(idx).origin
	return global_position + Vector3(0, 1.4, -0.4)
