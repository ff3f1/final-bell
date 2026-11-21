class_name BloodFx
extends Node3D




const CANVAS_Y: = 0.0
const RING_HALF: = 3.45
const MAX_DECALS: = 110
const MAX_DROPS: = 60
const DECAL_LAYER: = 2
const BLOOD_FRESH: = Color(0.46, 0.025, 0.03, 0.95)
const BLOOD_DRY: = Color(0.2, 0.045, 0.035, 0.92)
const SWEAT: = Color(0.3, 0.31, 0.34, 0.28)

static var _splats: Array[Texture2D] = []

var _drops: Array = []
var _decals: Array = []
var _drip_t: = {}
var _blood_mesh: SphereMesh
var _sweat_mesh: SphereMesh
var _rng: = RandomNumberGenerator.new()


func _ready() -> void :
	_rng.randomize()
	if _splats.is_empty():
		for i in 8:
			_splats.append(load("res://assets/fx/splat_%d.png" % i))
	_blood_mesh = _drop_mesh(Color(0.26, 0.01, 0.012), 0.3)
	_sweat_mesh = _drop_mesh(Color(0.7, 0.73, 0.77, 0.32), 0.18)


static func _drop_mesh(c: Color, rough: float) -> SphereMesh:
	var sm: = SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 6
	sm.rings = 3
	var m: = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic_specular = 0.35
	if c.a < 1.0:

		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.metallic_specular = 0.25
	m.shadow_to_opacity = false
	sm.material = m
	return sm




func spray(origin: Vector3, dir: Vector3, dmg: float, bleed: float, sweat: float) -> void :
	var d: = dir
	d.y = 0.0
	d = d.normalized() if d.length() > 0.01 else Vector3.FORWARD
	var side: = d.cross(Vector3.UP)
	var n_sweat: = int(clampf(sweat * dmg * 0.3, 0.0, 7.0))
	for i in n_sweat:
		var v: = d * _rng.randf_range(1.2, 3.2) + side * _rng.randf_range(-1.2, 1.2) + Vector3.UP * _rng.randf_range(0.3, 1.8)
		_add_drop(origin, v, _rng.randf_range(0.003, 0.006), false)
	if bleed <= 0.04:
		return
	var n_blood: = int(clampf(bleed * (2.0 + dmg * 0.45), 1.0, 12.0))
	for i in n_blood:
		var v: = d * _rng.randf_range(0.8, 3.0) + side * _rng.randf_range(-0.9, 0.9) + Vector3.UP * _rng.randf_range(-0.2, 1.4)
		_add_drop(origin + side * _rng.randf_range(-0.03, 0.03), v, _rng.randf_range(0.005, 0.013) * (0.7 + bleed * 0.6), true)



func tick_fighter(f: Fighter, delta: float) -> void :
	var level: = maxf(f.cut / 100.0 * 0.95, f.nose_blood)
	if level < 0.32 or not f.visible:
		return
	var key: = f.get_instance_id()
	var t: float = float(_drip_t.get(key, _rng.randf_range(0.5, 3.0))) - delta
	if t <= 0.0:
		var fwd: = Vector3.FORWARD
		if f.opponent:
			fwd = f.opponent.global_position - f.global_position
			fwd.y = 0.0
			fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
		var o: = f.head_global() + fwd * 0.09 + Vector3(0, -0.11, 0)
		_add_drop(o, f.velocity * 0.8 + Vector3(_rng.randf_range(-0.1, 0.1), -0.2, _rng.randf_range(-0.1, 0.1)), 
			_rng.randf_range(0.005, 0.009) * (1.5 if f.is_down() else 1.0), true)
		t = _rng.randf_range(1.2, 4.0) / (0.3 + (level - 0.3) * 2.5)
		if f.is_down():
			t *= 0.35
	_drip_t[key] = t


func _add_drop(pos: Vector3, vel: Vector3, size: float, blood: bool) -> void :
	if _drops.size() >= MAX_DROPS:
		var old: Dictionary = _drops.pop_front()
		(old["mi"] as Node).queue_free()
	var mi: = MeshInstance3D.new()
	mi.mesh = _blood_mesh if blood else _sweat_mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = pos
	mi.scale = Vector3.ONE * size
	_drops.append({"mi": mi, "vel": vel, "size": size, "blood": blood})


func _process(delta: float) -> void :
	if delta <= 0.0:
		return
	var i: = 0
	while i < _drops.size():
		var dr: Dictionary = _drops[i]
		var mi: MeshInstance3D = dr["mi"]
		var v: Vector3 = dr["vel"]
		v += Vector3(0, -9.8, 0) * delta
		v *= 1.0 - 0.4 * delta
		var p: = mi.global_position + v * delta
		dr["vel"] = v

		var sp: = v.length()
		var sz: float = dr["size"]
		if sp > 0.5:
			mi.look_at(p + v, Vector3.UP if absf(v.normalized().y) < 0.95 else Vector3.RIGHT)
			mi.scale = Vector3(sz, sz, sz * clampf(1.0 + sp * 0.35, 1.0, 2.6))
		if p.y <= CANVAS_Y + 0.003:
			if absf(p.x) < RING_HALF and absf(p.z) < RING_HALF:
				_splat(Vector3(p.x, CANVAS_Y, p.z), v, sz, bool(dr["blood"]))
			mi.queue_free()
			_drops.remove_at(i)
			continue
		mi.global_position = p
		i += 1

	var j: = 0
	while j < _decals.size():
		var e: Dictionary = _decals[j]
		e["age"] = float(e["age"]) + delta
		var dc: Decal = e["d"]
		if bool(e["blood"]):
			var k: = clampf(float(e["age"]) / 80.0, 0.0, 1.0)
			dc.modulate = BLOOD_FRESH.lerp(BLOOD_DRY, k)
		else:
			var a: = 1.0 - clampf((float(e["age"]) - 15.0) / 30.0, 0.0, 1.0)
			if a <= 0.0:
				dc.queue_free()
				_decals.remove_at(j)
				continue
			var c: = SWEAT
			c.a *= a
			dc.modulate = c
		j += 1


func _splat(pos: Vector3, vel: Vector3, size: float, blood: bool) -> void :
	var h: = Vector2(vel.x, vel.z)
	var streak: = h.length() > 1.3
	var tex: Texture2D = _splats[(4 + _rng.randi() % 4) if streak else (_rng.randi() % 4)]
	var d: = Decal.new()
	d.texture_albedo = tex
	d.cull_mask = DECAL_LAYER
	d.albedo_mix = 1.0
	d.upper_fade = 0.3
	d.lower_fade = 0.3
	d.normal_fade = 0.5
	var base: = size * (15.0 if blood else 9.0) * _rng.randf_range(0.8, 1.35)
	if streak:
		d.size = Vector3(base * clampf(1.0 + h.length() * 0.35, 1.4, 2.6), 0.08, base)
	else:
		d.size = Vector3(base, 0.08, base)
	d.modulate = BLOOD_FRESH if blood else SWEAT
	add_child(d)
	d.global_position = pos + Vector3(0, 0.01, 0)

	d.rotation.y = atan2( - h.y, h.x) if streak else _rng.randf_range(0.0, TAU)
	_decals.append({"d": d, "age": 0.0, "blood": blood})
	if _decals.size() > MAX_DECALS:

		var idx: = 0
		for k in _decals.size():
			if not bool(_decals[k]["blood"]):
				idx = k
				break
		var gone: Dictionary = _decals[idx]
		(gone["d"] as Node).queue_free()
		_decals.remove_at(idx)
