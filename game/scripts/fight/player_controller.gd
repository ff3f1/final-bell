class_name PlayerController
extends RefCounted










var me: Fighter
var enabled: = true


const FLICK_WINDOW: = 0.14
const FLICK_MIN: = 34.0
const CLICK_GRACE: = 0.045
var _motion: Array = []
var _clock: = 0.0
var _pending: Dictionary = {}
var _wheel_lean: = 0
var _wheel_t: = 0.0
var _last_thrown: = ""
var _last_thrown_t: = -10.0


var _s_active: = false
var _s_pts: Array[Vector2] = []
var _s_cooldown: = 0.0


func setup(fighter: Fighter) -> void :
	me = fighter


func _sens() -> float:
	return maxf(Game.setting_f("mouse_sens"), 0.2) if Game.settings.has("mouse_sens") else 1.0


func mouse_enabled() -> bool:
	return Game.setting_b("mouse_punch")


func handle_event(event: InputEvent) -> void :
	if not enabled or me == null:
		return
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_motion.append([_clock, (event as InputEventMouseMotion).relative * _sens()])
		return
	if event is InputEventMouseButton and event.pressed:
		var mb: = event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				_wheel_lean = Fighter.Lean.DUCK
				_wheel_t = 0.32
				return
			MOUSE_BUTTON_WHEEL_UP:
				_wheel_lean = Fighter.Lean.BACK
				_wheel_t = 0.32
				return
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				if mouse_enabled():
					_mouse_click(mb.button_index == MOUSE_BUTTON_LEFT)
				return
	if event.is_echo():
		return
	if event.is_action_pressed("clinch"):
		me.request_clinch()
		return
	var type: = -1
	if event.is_action_pressed("punch_jab"):
		type = Punches.Type.JAB
	elif event.is_action_pressed("punch_cross"):
		type = Punches.Type.CROSS
	elif event.is_action_pressed("punch_lead_hook"):
		type = Punches.Type.LEAD_HOOK
	elif event.is_action_pressed("punch_rear_hook"):
		type = Punches.Type.REAR_HOOK
	elif event.is_action_pressed("punch_lead_upper"):
		type = Punches.Type.LEAD_UPPER
	elif event.is_action_pressed("punch_rear_upper"):
		type = Punches.Type.REAR_UPPER
	if type >= 0:
		_throw(type, Input.is_action_pressed("mod_body"), Input.is_action_pressed("mod_power"))


func _throw(type: int, body: bool, pw: bool) -> void :
	me.request_punch(type, body, pw)
	_last_thrown = Punches.display_name(type, body, pw)
	_last_thrown_t = _clock



func last_thrown(max_age: float = 1.2) -> String:
	return _last_thrown if _clock - _last_thrown_t <= max_age else ""




func _recent_motion() -> Vector2:
	var v: = Vector2.ZERO
	for m in _motion:
		var item: Array = m
		if _clock - float(item[0]) <= FLICK_WINDOW:
			v += item[1] as Vector2
	return v




static func classify_flick(v: Vector2) -> Dictionary:
	if v.length() < FLICK_MIN:
		return {"kind": "straight", "body": false}
	var ang: = rad_to_deg(atan2(v.x, - v.y))
	var a: = absf(ang)
	if a <= 50.0:
		return {"kind": "upper", "body": false}
	if a >= 148.0:
		return {"kind": "straight", "body": true}
	if a >= 108.0:
		return {"kind": "hook", "body": true}
	return {"kind": "hook", "body": false}


static func punch_for(kind: String, lead: bool) -> int:
	match kind:
		"hook":
			return Punches.Type.LEAD_HOOK if lead else Punches.Type.REAR_HOOK
		"upper":
			return Punches.Type.LEAD_UPPER if lead else Punches.Type.REAR_UPPER
	return Punches.Type.JAB if lead else Punches.Type.CROSS


func _mouse_click(lead: bool) -> void :
	var v: = _recent_motion()
	if v.length() >= FLICK_MIN:
		_fire(lead, v)
	else:

		if not _pending.is_empty():
			_fire(bool(_pending["lead"]), _recent_motion())
		_pending = {"lead": lead, "t": _clock}


func _fire(lead: bool, v: Vector2) -> void :
	var g: = classify_flick(v)
	var t: = punch_for(str(g["kind"]), lead)
	var body: = bool(g["body"]) or Input.is_action_pressed("mod_body")
	_throw(t, body, Input.is_action_pressed("mod_power"))
	_motion.clear()


func _mouse_tick(_delta: float) -> void :
	while not _motion.is_empty() and _clock - float((_motion[0] as Array)[0]) > FLICK_WINDOW:
		_motion.pop_front()
	if _pending.is_empty():
		return
	var v: = _recent_motion()
	if v.length() >= FLICK_MIN or _clock - float(_pending["t"]) >= CLICK_GRACE:
		var lead: = bool(_pending["lead"])
		_pending = {}
		_fire(lead, v)



func flick_preview() -> Dictionary:
	var v: = _recent_motion()
	var g: = classify_flick(v)
	return {"vec": (v / (FLICK_MIN * 2.5)).limit_length(1.0), "kind": g["kind"], "body": g["body"], 
		"power": Input.is_action_pressed("mod_power")}




func _stick_tick(delta: float) -> void :
	_s_cooldown = maxf(0.0, _s_cooldown - delta)
	var v: = Input.get_vector("rs_left", "rs_right", "rs_up", "rs_down")
	if not _s_active:
		if v.length() > 0.55 and _s_cooldown <= 0.0:
			_s_active = true
			_s_pts = [Vector2.ZERO, v]
		return
	_s_pts.append(v)
	if v.length() < 0.25 or _s_pts.size() > 40:
		_s_active = false
		var g: = _classify_stick(_s_pts)
		if not g.is_empty():
			_throw(int(g["type"]), bool(g["body"]) or Input.is_action_pressed("mod_body"), Input.is_action_pressed("mod_power"))
			_s_cooldown = 0.08




func _classify_stick(pts: Array[Vector2]) -> Dictionary:
	var peak: = Vector2.ZERO
	var had_down: = false
	var up_after_down: = false
	var angs: Array[float] = []
	var sx: = 0.0
	for p in pts:
		if p.length() > peak.length():
			peak = p
		if p.y > 0.55:
			had_down = true
		elif had_down and p.y < -0.5:
			up_after_down = true
		if p.length() > 0.5:
			angs.append(atan2(p.x, - p.y))
			sx += p.x
	if peak.length() < 0.5:
		return {}
	var side: = 1.0 if me.stance_sign >= 0 else -1.0
	if up_after_down:
		return {"type": Punches.Type.LEAD_UPPER if sx * side <= 0.0 else Punches.Type.REAR_UPPER, "body": false, "len": 1.0}
	if angs.size() >= 3:
		var sweep: = 0.0
		var upper: = true
		for i in range(1, angs.size()):
			sweep += wrapf(angs[i] - angs[i - 1], - PI, PI)
			if absf(angs[i]) > deg_to_rad(125.0):
				upper = false
		if absf(sweep) > deg_to_rad(70.0):
			var lead_h: = sweep * side > 0.0
			return {"type": Punches.Type.LEAD_HOOK if lead_h else Punches.Type.REAR_HOOK, "body": not upper, "len": 1.0}
	var lead: = peak.x * side <= absf(peak.y) * 0.15
	return {"type": Punches.Type.JAB if lead else Punches.Type.CROSS, "body": peak.y > 0.3, "len": 1.0}




func tick(delta: float) -> void :
	if me == null:
		return
	_clock += delta
	if not enabled:
		me.clear_inputs()
		return
	_mouse_tick(delta)
	_stick_tick(delta)
	var mv: = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var lean_vec: = Vector2.ZERO

	if Input.is_action_pressed("head_move") or Input.is_action_pressed("head_move_kb"):
		lean_vec = mv
		mv = Vector2.ZERO
	me.move_input = mv
	me.lean_vec_input = lean_vec
	var block: = Input.is_action_pressed("block")
	me.want_block = block
	me.want_block_low = Input.is_action_pressed("mod_body") or (block and Input.is_action_pressed("mod_power"))
	var lean: = Fighter.Lean.NONE
	if Input.is_action_pressed("duck"):
		lean = Fighter.Lean.DUCK
	elif Input.is_action_pressed("lean_back"):
		lean = Fighter.Lean.BACK
	elif Input.is_action_pressed("slip_left"):
		lean = Fighter.Lean.LEFT
	elif Input.is_action_pressed("slip_right"):
		lean = Fighter.Lean.RIGHT
	_wheel_t = maxf(0.0, _wheel_t - delta)
	if lean == Fighter.Lean.NONE and _wheel_t > 0.0:
		lean = _wheel_lean
	me.lean_input = lean



static func rumble(weak: float, strong: float, duration: float) -> void :
	if not Game.setting_b("vibration"):
		return
	for id in Input.get_connected_joypads():
		Input.start_joy_vibration(int(id), clampf(weak, 0.0, 1.0), clampf(strong, 0.0, 1.0), duration)
