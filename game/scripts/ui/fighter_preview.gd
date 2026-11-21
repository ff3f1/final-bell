class_name FighterPreview
extends SubViewportContainer




var def: Dictionary = {}
var mirror: = false

var yaw_deg: = 0.0
var vp: SubViewport
var f: Fighter
var dummy: Fighter
var _t: = 2.5
var _rng: = RandomNumberGenerator.new()



static func make(d: Dictionary, sz: Vector2, flip: bool = false) -> Control:
	if not Game.setting_b("live_cards") or not MixamoRig.has_assets_for(d) or Game.test_flag("navtest"):
		return UIKit.portrait(str(d.get("model", d.get("id", ""))), sz, flip)
	var holder: = Control.new()
	holder.custom_minimum_size = sz
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg: = ColorRect.new()
	bg.color = Color(0.1, 0.11, 0.14, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bg)
	var p: = FighterPreview.new()
	p.def = d
	p.mirror = flip
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(p)
	var shade: = TextureRect.new()
	var st: = GradientTexture2D.new()
	var sg: = Gradient.new()
	sg.set_color(0, Color(0, 0, 0, 0))
	sg.set_color(1, Color(0, 0, 0, 0.6))
	st.gradient = sg
	st.fill_from = Vector2(0.5, 0.6)
	st.fill_to = Vector2(0.5, 1.0)
	shade.texture = st
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(shade)
	return holder


func _ready() -> void :
	_rng.randomize()
	_t = _rng.randf_range(1.5, 3.5)
	stretch = true
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var world: = Node3D.new()
	vp.add_child(world)
	var env: = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.47, 0.55)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we: = WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var sx: = -1.0 if mirror else 1.0

	var key: = DirectionalLight3D.new()
	key.light_energy = 1.6
	key.light_color = Color(1.0, 0.93, 0.84)
	key.rotation = Vector3(deg_to_rad(-38), deg_to_rad(28 * sx), 0)
	key.shadow_enabled = true
	world.add_child(key)
	var rim: = OmniLight3D.new()
	rim.position = Vector3(-1.2 * sx, 2.1, -1.4)
	rim.omni_range = 5.0
	rim.light_energy = 2.2
	rim.light_color = Color(0.55, 0.7, 1.0)
	world.add_child(rim)
	var gold: = OmniLight3D.new()
	gold.position = Vector3(1.4 * sx, 0.6, 1.2)
	gold.omni_range = 4.0
	gold.light_energy = 0.6
	gold.light_color = Color(0.95, 0.72, 0.3)
	world.add_child(gold)
	f = Fighter.new()
	world.add_child(f)
	f.setup(def, 1 if mirror else 0, false, true)

	dummy = Fighter.new()
	world.add_child(dummy)
	dummy.position = _dummy_offset()
	dummy.setup(def, 0 if mirror else 1, false, false)
	dummy.visible = false
	f.opponent = dummy
	dummy.opponent = f
	f.begin_fight_state()
	var cam: = Camera3D.new()
	world.add_child(cam)
	var h: = float(def.get("height", 1.8))
	cam.fov = 30.0
	cam.position = Vector3(0.75 * sx, h * 0.78, 3.15)
	cam.look_at(Vector3(0.0, h * 0.6, 0.0))
	cam.current = true


func _dummy_offset() -> Vector3:
	var a: = deg_to_rad(yaw_deg) * (-1.0 if mirror else 1.0) * (float(def.get("stance", 1)))
	return Vector3(sin(a), 0, cos(a)) * 1.75


func _process(delta: float) -> void :
	if f == null or not is_visible_in_tree():
		return
	var dt: = minf(delta, 0.05)
	_t -= dt
	if _t <= 0.0:
		_t = _rng.randf_range(2.6, 5.0)

		var first: = _rng.randi() % 6
		f.request_punch(first, false, _rng.randf() < 0.12)
		if _rng.randf() < 0.6:
			f.queued = {"type": _rng.randi() % 6, "body": _rng.randf() < 0.2, "power": false}
			f.queued_time = f.clock
	f.tick(dt)
	dummy.global_position = f.global_position + _dummy_offset()
	f.global_position = f.global_position.lerp(Vector3.ZERO, clampf(dt * 2.0, 0.0, 1.0))
