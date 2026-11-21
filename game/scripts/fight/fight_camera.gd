class_name FightCamera
extends Camera3D




enum Mode{BEHIND, BROADCAST, ORBIT, FOCUS, CLOSE}

const CYCLE: = [Mode.BEHIND, Mode.CLOSE, Mode.BROADCAST]
const CYCLE_NAMES: = ["За спиной", "Плечо (близко)", "Трансляция"]

var mode: int = Mode.BEHIND
var trauma: = 0.0
var shake_scale: = 1.0
var fov_kick: = 0.0
var orbit_angle: = 0.0
var orbit_speed: = 0.25
var orbit_radius: = 5.2
var orbit_height: = 2.4
var focus_target: = Vector3.ZERO
var focus_from: = Vector3.ZERO

var dolly_from: = Vector3.ZERO
var dolly_to: = Vector3.ZERO
var dolly_look_from: = Vector3.ZERO
var dolly_look_to: = Vector3.ZERO
var dolly_t: = 0.0
var dolly_len: = 0.0
var dolly_fov: = 40.0
var _side: = 1.0
var _t: = 0.0
var _pos: = Vector3(0, 2, 4)
var _look: = Vector3(0, 1.2, 0)
var _init_done: = false
var _nudge: = Vector3.ZERO
var _nudge_v: = Vector3.ZERO
var _attrs: CameraAttributesPractical


func _ready() -> void :
	fov = 50.0
	near = 0.05
	far = 120.0
	_attrs = CameraAttributesPractical.new()
	_attrs.dof_blur_far_enabled = true
	_attrs.dof_blur_far_distance = 7.0
	_attrs.dof_blur_far_transition = 5.0
	_attrs.dof_blur_amount = 0.09
	attributes = _attrs


static func cycle_index(m: int) -> int:
	return maxi(CYCLE.find(m), 0)


func add_trauma(amount: float) -> void :
	trauma = clampf(trauma + amount * shake_scale, 0.0, 1.0)


func kick(amount: float) -> void :
	fov_kick = maxf(fov_kick, amount)



func nudge(dir: Vector3, amount: float) -> void :
	_nudge_v += dir * amount * shake_scale


func snap() -> void :
	_init_done = false


func update_camera(delta: float, a: Fighter, b: Fighter) -> void :
	_t += delta
	var want_pos: = _pos
	var want_look: = _look
	var base_fov: = 50.0
	var far_dof: = 7.0
	match mode:
		Mode.BEHIND:
			if a and b:
				var ap: = a.global_position
				var bp: = b.global_position
				var dir: = bp - ap
				dir.y = 0.0
				if dir.length() < 0.01:
					dir = Vector3(0, 0, -1)
				dir = dir.normalized()
				var right: = dir.cross(Vector3.UP)
				var dist: = ap.distance_to(bp)
				var back: = 2.3 + clampf(dist - 1.2, 0.0, 2.0) * 0.5
				want_pos = ap - dir * back + right * 0.62 + Vector3(0, 1.95, 0)
				want_look = ap.lerp(bp, 0.62) + Vector3(0, 1.38, 0)
				far_dof = back + dist + 2.2
		Mode.CLOSE:

			base_fov = 56.0
			if a and b:
				var ap2: = a.global_position
				var bp2: = b.global_position
				var dir2: = bp2 - ap2
				dir2.y = 0.0
				if dir2.length() < 0.01:
					dir2 = Vector3(0, 0, -1)
				dir2 = dir2.normalized()
				var right2: = dir2.cross(Vector3.UP)
				var head_y: = a.height_m * 0.93
				var dist2: = ap2.distance_to(bp2)
				want_pos = ap2 - dir2 * (1.05 + clampf(dist2 - 1.2, 0.0, 1.5) * 0.25) + right2 * 0.42 + Vector3(0, head_y + 0.16, 0)
				var opp_head: = bp2 + Vector3(0, b.height_m * 0.82, 0)
				want_look = opp_head.lerp(ap2 + Vector3(0, head_y, 0), 0.18)
				far_dof = 1.3 + dist2 + 1.6
		Mode.BROADCAST:
			base_fov = 42.0
			if a and b:
				var mid: = (a.global_position + b.global_position) * 0.5
				var d2: = b.global_position - a.global_position
				d2.y = 0.0
				if d2.length() < 0.01:
					d2 = Vector3(1, 0, 0)
				var perp: = d2.normalized().cross(Vector3.UP) * _side

				want_pos = mid + perp * 4.6 + Vector3(0, 2.2, 0)
				want_look = mid + Vector3(0, 1.25, 0)
				far_dof = 7.5
		Mode.ORBIT:
			orbit_angle += delta * orbit_speed
			want_pos = Vector3(sin(orbit_angle) * orbit_radius, orbit_height, cos(orbit_angle) * orbit_radius)
			want_look = Vector3(0, 1.1, 0)
			if a and b:
				want_look = (a.global_position + b.global_position) * 0.5 + Vector3(0, 1.2, 0)
			base_fov = 45.0
			far_dof = orbit_radius + 2.5
		Mode.FOCUS:
			want_pos = focus_from
			want_look = focus_target
			base_fov = 40.0
			if dolly_len > 0.0:
				dolly_t = minf(dolly_t + delta, dolly_len)
				var e: = smoothstep(0.0, 1.0, dolly_t / dolly_len)
				want_pos = dolly_from.lerp(dolly_to, e)
				want_look = dolly_look_from.lerp(dolly_look_to, e)
				focus_from = want_pos
				focus_target = want_look
				base_fov = dolly_fov
			far_dof = want_pos.distance_to(want_look) + 2.0

	if not _init_done:
		_pos = want_pos
		_look = want_look
		_init_done = true
	var follow: = 4.0
	if mode == Mode.CLOSE:
		follow = 7.0
	elif mode == Mode.FOCUS and dolly_len > 0.0:
		follow = 30.0
	elif mode != Mode.BEHIND:
		follow = 2.5
	var k: = clampf(delta * follow, 0.0, 1.0)
	_pos = _pos.lerp(want_pos, k)
	_look = _look.lerp(want_look, clampf(delta * (9.0 if mode == Mode.CLOSE else 6.0), 0.0, 1.0))

	trauma = maxf(0.0, trauma - delta * 1.7)
	fov_kick = move_toward(fov_kick, 0.0, delta * 30.0)
	_nudge_v += ( - _nudge * 160.0 - _nudge_v * 16.0) * delta
	_nudge += _nudge_v * delta
	_nudge = _nudge.limit_length(0.12)
	var sh: = trauma * trauma
	var off: = Vector3(
		sin(_t * 37.0) + sin(_t * 23.0 + 1.3) * 0.5, 
		sin(_t * 41.0 + 0.7) + sin(_t * 17.0) * 0.5, 
		0.0) * sh * 0.06
	var final_pos: = _pos + off + _nudge
	global_position = final_pos
	var look_dir: = _look - final_pos
	if look_dir.length() > 0.01 and absf(look_dir.normalized().dot(Vector3.UP)) < 0.98:
		look_at(_look + _nudge * 0.5, Vector3.UP)
	rotation.z += sin(_t * 29.0) * sh * 0.035
	fov = base_fov - fov_kick
	if _attrs:
		_attrs.dof_blur_far_distance = lerpf(_attrs.dof_blur_far_distance, far_dof, clampf(delta * 3.0, 0.0, 1.0))



func dolly(from: Vector3, to: Vector3, look_from: Vector3, look_to: Vector3, secs: float, fov_deg: float = 40.0) -> void :
	mode = Mode.FOCUS
	dolly_from = from
	dolly_to = to
	dolly_look_from = look_from
	dolly_look_to = look_to
	dolly_t = 0.0
	dolly_len = maxf(secs, 0.01)
	dolly_fov = fov_deg
	snap()


func stop_dolly() -> void :
	dolly_len = 0.0


func cycle_mode() -> void :
	var i: = CYCLE.find(mode)
	mode = CYCLE[(i + 1) % CYCLE.size()] if i >= 0 else Mode.BEHIND


func flip_side() -> void :
	_side = - _side
