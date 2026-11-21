class_name BagRig
extends BoxerRig



const PIVOT_Y: = 2.75
const BAG_TOP: = 1.78
const BAG_BOTTOM: = 0.6
const RADIUS: = 0.19

var swing: Node3D
var bag: Node3D
var _ang: = Vector2.ZERO
var _vel: = Vector2.ZERO
var _yaw: = 0.0
var _yaw_v: = 0.0
var _squash: = 0.0
var _squash_v: = 0.0


func setup(def: Dictionary, f: Fighter) -> void :
	fighter = f
	swing = Node3D.new()
	swing.position = Vector3(0, PIVOT_Y, 0)
	add_child(swing)
	bag = Node3D.new()
	swing.add_child(bag)
	var col: Color = def.get("color", Color(0.09, 0.08, 0.085))
	var leather: = StandardMaterial3D.new()
	leather.albedo_color = col
	leather.roughness = 0.42
	leather.metallic_specular = 0.55
	leather.clearcoat_enabled = true
	leather.clearcoat = 0.35
	leather.clearcoat_roughness = 0.3
	leather.normal_enabled = true
	leather.normal_texture = MixamoRig._detail_normal("pores")
	leather.normal_scale = 0.35
	leather.uv1_scale = Vector3(3, 3, 3)
	var h: = BAG_TOP - BAG_BOTTOM
	var body: = CylinderMesh.new()
	body.top_radius = RADIUS
	body.bottom_radius = RADIUS * 0.97
	body.height = h
	body.radial_segments = 40
	body.rings = 6
	_mi(bag, body, leather, Vector3(0, (BAG_TOP + BAG_BOTTOM) * 0.5 - PIVOT_Y, 0))

	for y in [BAG_TOP, BAG_BOTTOM]:
		var tor: = TorusMesh.new()
		tor.inner_radius = RADIUS - 0.03
		tor.outer_radius = RADIUS + 0.004
		tor.rings = 40
		tor.ring_segments = 10
		var t: = _mi(bag, tor, leather, Vector3(0, float(y) - PIVOT_Y, 0))
		t.scale = Vector3(1, 0.9, 1)
	var cap: = CylinderMesh.new()
	cap.top_radius = RADIUS - 0.02
	cap.bottom_radius = RADIUS - 0.02
	cap.height = 0.03
	cap.radial_segments = 32
	_mi(bag, cap, leather, Vector3(0, BAG_TOP - PIVOT_Y + 0.005, 0))
	_mi(bag, cap, leather, Vector3(0, BAG_BOTTOM - PIVOT_Y - 0.005, 0))

	var tape: = StandardMaterial3D.new()
	tape.albedo_color = def.get("tape", Color(0.62, 0.07, 0.06))
	tape.roughness = 0.5
	for y2 in [BAG_TOP - 0.12, BAG_BOTTOM + 0.12]:
		var band: = CylinderMesh.new()
		band.top_radius = RADIUS + 0.003
		band.bottom_radius = RADIUS + 0.003
		band.height = 0.07
		band.radial_segments = 40
		_mi(bag, band, tape, Vector3(0, float(y2) - PIVOT_Y, 0))
	var logo: = Label3D.new()
	logo.text = "FINAL\nBELL"
	logo.font_size = 64
	logo.pixel_size = 0.0028
	logo.modulate = Color(0.93, 0.72, 0.25)
	logo.outline_size = 0
	logo.shaded = true
	logo.double_sided = false
	if Game.title_font:
		logo.font = Game.title_font
	logo.position = Vector3(0, 1.25 - PIVOT_Y, RADIUS + 0.004)
	bag.add_child(logo)
	var logo2: = logo.duplicate() as Label3D
	logo2.position = Vector3(0, 1.25 - PIVOT_Y, - RADIUS - 0.004)
	logo2.rotation.y = PI
	bag.add_child(logo2)

	var metal: = StandardMaterial3D.new()
	metal.albedo_color = Color(0.55, 0.55, 0.58)
	metal.metallic = 0.9
	metal.roughness = 0.3
	var ring_y: = BAG_TOP + 0.42 - PIVOT_Y
	for i in 4:
		var a: = float(i) * PI * 0.5 + PI * 0.25
		var bottom: = Vector3(cos(a) * (RADIUS - 0.03), BAG_TOP - PIVOT_Y + 0.01, sin(a) * (RADIUS - 0.03))
		_chain(bag, bottom, Vector3(0, ring_y, 0), metal)
	var swivel: = TorusMesh.new()
	swivel.inner_radius = 0.018
	swivel.outer_radius = 0.03
	_mi(bag, swivel, metal, Vector3(0, ring_y, 0)).rotation.x = PI * 0.5
	_chain(swing, Vector3(0, ring_y, 0), Vector3(0, 0.0, 0), metal)
	var up: = CylinderMesh.new()
	up.top_radius = 0.012
	up.bottom_radius = 0.012
	up.height = 6.0
	_mi(swing, up, metal, Vector3(0, 3.0, 0))


func _mi(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var m: = MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.position = pos
	parent.add_child(m)
	return m



func _chain(parent: Node3D, a: Vector3, b: Vector3, mat: Material) -> void :
	var link: = TorusMesh.new()
	link.inner_radius = 0.008
	link.outer_radius = 0.016
	link.rings = 12
	link.ring_segments = 6
	var d: = b - a
	var n: = maxi(int(d.length() / 0.03), 2)
	var dir: = d.normalized()
	var up_hint: = Vector3.RIGHT if absf(dir.dot(Vector3.UP)) > 0.98 else Vector3.UP
	var look: = Basis.looking_at(dir, up_hint)
	for i in n:
		var p: = a + d * (float(i) + 0.5) / float(n)
		var m: = _mi(parent, link, mat, p)

		var bs: = look * Basis(Vector3(0, 0, 1), PI * 0.5 * float(i % 2)) * Basis.from_scale(Vector3(1.0, 1.0, 1.7))
		m.transform = Transform3D(bs, p)


func on_bag_hit(dir: Vector3, body: bool, side: int, dmg: float, type: int) -> void :

	var local: = global_transform.basis.inverse() * dir
	var k: = clampf(dmg * 0.055, 0.08, 1.4) * (0.8 if body else 1.0)

	_vel += Vector2( - local.z, local.x) * k
	if Punches.is_hook(type):
		_yaw_v += float(side) * k * 2.2
		_vel += Vector2(0.0, float(side) * k * 0.4)
	elif Punches.is_upper(type):
		_squash_v -= k * 1.5
	_squash_v += k * 4.0


func update_rig(delta: float) -> void :
	if swing == null:
		return
	var L: = PIVOT_Y - (BAG_TOP + BAG_BOTTOM) * 0.5
	var g: = 9.8 / L
	var acc: = Vector2( - g * sin(_ang.x), - g * sin(_ang.y)) - _vel * 0.9
	_vel += acc * delta
	_ang += _vel * delta
	_ang = _ang.clamp(Vector2(-0.6, -0.6), Vector2(0.6, 0.6))
	_yaw_v += ( - _yaw * 6.0 - _yaw_v * 1.6) * delta
	_yaw += _yaw_v * delta
	_squash_v += ( - _squash * 260.0 - _squash_v * 14.0) * delta
	_squash += _squash_v * delta
	swing.rotation = Vector3(_ang.x, _yaw, _ang.y)
	var s: = clampf(_squash, -0.4, 0.4) * 0.06
	bag.scale = Vector3(1.0 + s, 1.0 - s * 0.5, 1.0 + s)


func get_head_global() -> Vector3:
	if bag:
		return bag.global_transform * Vector3(0, 1.45 - PIVOT_Y, 0)
	return global_position + Vector3(0, 1.45, 0)


func get_glove_global(_lead: bool) -> Vector3:
	return get_head_global()
