class_name MenuNav
extends Node








signal device_changed(pad: bool)

const REPEAT_DELAY: = 0.36
const REPEAT_RATE: = 0.09
const STICK_ON: = 0.6
const STICK_OFF: = 0.35
const SCROLL_SPEED: = 1500.0
const DIRS: = {"ui_left": Vector2.LEFT, "ui_right": Vector2.RIGHT, "ui_up": Vector2.UP, "ui_down": Vector2.DOWN}
const DPAD: = {JOY_BUTTON_DPAD_LEFT: "ui_left", JOY_BUTTON_DPAD_RIGHT: "ui_right", 
	JOY_BUTTON_DPAD_UP: "ui_up", JOY_BUTTON_DPAD_DOWN: "ui_down"}

var keyboard_nav: = false
var using_pad: = false
var ring: FocusRing
var _layer: CanvasLayer
var _axes: = {}
var _held: = ""
var _held_src: = ""
var _held_t: = 0.0
var _rep_t: = 0.0


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 99
	add_child(_layer)
	ring = FocusRing.new()
	ring.nav = self
	_layer.add_child(ring)




func _input(event: InputEvent) -> void :
	if event is InputEventJoypadMotion:
		var jm: = event as InputEventJoypadMotion
		var d: Dictionary = _axes.get(jm.device, {})
		d[jm.axis] = jm.axis_value
		_axes[jm.device] = d
		if absf(jm.axis_value) > 0.5:
			_set_device(true, true)
	elif event is InputEventJoypadButton:
		var jb: = event as InputEventJoypadButton
		_set_device(true, true)
		if DPAD.has(jb.button_index):
			var dir: String = DPAD[jb.button_index]
			if jb.pressed:
				_held = dir
				_held_src = "dpad"
				_held_t = 0.0
				_rep_t = 0.0
			elif _held == dir and _held_src == "dpad":
				_held = ""
		if jb.pressed:
			_wake(event)
	elif event is InputEventKey:
		if (event as InputEventKey).pressed:
			_set_device(true, false)
			_wake(event)
	elif event is InputEventMouseMotion:
		if (event as InputEventMouseMotion).relative.length() > 2.0:
			_set_device(false, false)
			_hover_focus.call_deferred()
	elif event is InputEventMouseButton:
		_set_device(false, false)


func _set_device(kb_nav: bool, pad: bool) -> void :
	keyboard_nav = kb_nav
	if pad != using_pad:
		using_pad = pad
		device_changed.emit(pad)



func _wake(event: InputEvent) -> void :
	var nav_ev: = false
	for a in ["ui_up", "ui_down", "ui_left", "ui_right", "ui_accept"]:
		if event.is_action_pressed(a):
			nav_ev = true
			break
	if not nav_ev:
		return
	var fo: = get_viewport().gui_get_focus_owner()
	if fo != null and fo.is_visible_in_tree():
		return
	if _active_root() != null:
		recover_focus()
		get_viewport().set_input_as_handled()



func _hover_focus() -> void :
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		return
	var vp: = get_viewport()
	var h: = vp.gui_get_hovered_control()
	var t: = _focus_target(h)
	if t and t != vp.gui_get_focus_owner():
		t.grab_focus()


static func _focus_target(c: Control) -> Control:
	var n: Node = c
	var depth: = 0
	while n and depth < 6:
		if n is Control:
			var cc: = n as Control
			if cc.has_meta("nav_owner"):
				var o: Variant = cc.get_meta("nav_owner")
				if o is Control and is_instance_valid(o):
					return o
			if (cc is BaseButton or cc is Slider) and cc.focus_mode != Control.FOCUS_NONE and cc.is_visible_in_tree():
				return cc
			if cc.has_meta("nav_item") and cc.focus_mode != Control.FOCUS_NONE:
				return cc
		n = n.get_parent()
		depth += 1
	return null





func menu_active() -> bool:
	if get_viewport().gui_get_focus_owner() != null:
		return true
	return _active_root() != null


func _active_root() -> Control:
	var best: Control = null
	var best_p: = -1
	for n in get_tree().get_nodes_in_group("nav_root"):
		var c: = n as Control
		if c and c.is_visible_in_tree() and _has_focusable(c):

			var p: = _layer_of(c) * 100 + int(c.get_meta("nav_prio", 0))
			if p >= best_p:
				best = c
				best_p = p
	return best


static func _layer_of(c: Node) -> int:
	var n: = c.get_parent()
	while n:
		if n is CanvasLayer:
			return (n as CanvasLayer).layer
		n = n.get_parent()
	return 0



func recover_focus() -> void :
	var vp: = get_viewport()
	var fo: = vp.gui_get_focus_owner()
	if fo != null and fo.is_visible_in_tree():
		return
	var r: = _active_root()
	if r:
		var f: = first_focusable(r)
		if f:
			f.grab_focus()



static func first_focusable(root: Control) -> Control:
	var list: Array = []
	collect_focusable(root, list)
	if list.is_empty():
		return null
	list.sort_custom( func(a: Control, b: Control) -> bool:
		var ra: = a.get_global_rect()
		var rb: = b.get_global_rect()
		if absf(ra.position.y - rb.position.y) > 12.0:
			return ra.position.y < rb.position.y
		return ra.position.x < rb.position.x)
	return list[0]


static func _has_focusable(n: Node) -> bool:
	for ch in n.get_children():
		if ch is CanvasItem and not (ch as CanvasItem).visible:
			continue
		if ch is Control and (ch as Control).focus_mode != Control.FOCUS_NONE:
			return true
		if _has_focusable(ch):
			return true
	return false


static func collect_focusable(n: Node, out: Array) -> void :
	for ch in n.get_children():
		if ch is CanvasItem and not (ch as CanvasItem).visible:
			continue
		if ch is Control and (ch as Control).focus_mode != Control.FOCUS_NONE:
			out.append(ch)
		collect_focusable(ch, out)




func _stick(axis_x: int, axis_y: int) -> Vector2:
	var best: = Vector2.ZERO
	for dev in _axes.keys():
		var d: Dictionary = _axes[dev]
		var v: = Vector2(float(d.get(axis_x, 0.0)), float(d.get(axis_y, 0.0)))
		if v.length() > best.length():
			best = v
	return best


func _process(delta: float) -> void :
	var dt: = minf(delta, 0.1)
	var active: = menu_active()

	var s: = _stick(JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y)
	var sdir: = ""
	if _held_src == "stick" and _held != "":
		var keep: Vector2 = DIRS[_held]
		if s.dot(keep) > STICK_OFF:
			sdir = _held
	if sdir == "" and s.length() > STICK_ON:
		if absf(s.x) > absf(s.y):
			sdir = "ui_right" if s.x > 0.0 else "ui_left"
		else:
			sdir = "ui_down" if s.y > 0.0 else "ui_up"
	if sdir != "":
		if not (_held == sdir and _held_src == "stick"):
			_held = sdir
			_held_src = "stick"
			_held_t = 0.0
			_rep_t = 0.0
			if active:
				var fo: = get_viewport().gui_get_focus_owner()
				if fo == null or not fo.is_visible_in_tree():
					recover_focus()
				else:
					_emit(sdir)
	elif _held_src == "stick":
		_held = ""
		_held_src = ""

	if _held != "" and active:
		_held_t += dt
		if _held_t >= REPEAT_DELAY:
			_rep_t -= dt
			if _rep_t <= 0.0:
				_rep_t = REPEAT_RATE
				_emit(_held)

	var r: = _stick(JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y)
	if active and absf(r.y) > 0.25:
		var sc: = scroll_target()
		if sc:
			sc.scroll_vertical += int(r.y * SCROLL_SPEED * dt)


func _emit(action: String) -> void :
	var ev: = InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	var up: = InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)



func scroll_target() -> ScrollContainer:
	var fo: = get_viewport().gui_get_focus_owner()
	var n: Node = fo
	while n:
		if n is ScrollContainer and _scrollable(n as ScrollContainer):
			return n
		n = n.get_parent()
	var best: ScrollContainer = null
	for root in get_tree().get_nodes_in_group("nav_root"):
		var list: Array = []
		_collect_scrolls(root, list)
		for sc in list:
			var s2: = sc as ScrollContainer
			if best == null or s2.size.y > best.size.y:
				best = s2
	return best


static func _scrollable(sc: ScrollContainer) -> bool:
	var vb: = sc.get_v_scroll_bar()
	return sc.is_visible_in_tree() and vb != null and vb.max_value - vb.page > 1.0


static func _collect_scrolls(n: Node, out: Array) -> void :
	for ch in n.get_children():
		if ch is ScrollContainer and _scrollable(ch as ScrollContainer):
			out.append(ch)
		if ch is CanvasItem and not (ch as CanvasItem).visible:
			continue
		_collect_scrolls(ch, out)



class FocusRing:
	extends Control

	var nav: MenuNav
	var _rect: = Rect2()
	var _target: Control
	var _t: = 0.0
	var _alpha: = 0.0

	func _init() -> void :
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _process(delta: float) -> void :
		_t += delta
		var fo: = get_viewport().gui_get_focus_owner()
		var show: = nav != null and nav.keyboard_nav and fo != null and fo.is_visible_in_tree()\
		and not fo.has_meta("nav_no_ring")
		var want: = 1.0 if show else 0.0
		_alpha = move_toward(_alpha, want, delta * 8.0)
		if show:
			var r: = fo.get_global_rect().grow(6.0)
			r = _clip(fo, r)
			if fo != _target or _rect.size == Vector2.ZERO or _rect.position.distance_to(r.position) > 900.0:
				if _target == null or not is_instance_valid(_target) or _alpha < 0.05:
					_rect = r
			_target = fo
			var k: = clampf(delta * 20.0, 0.0, 1.0)
			_rect = Rect2(_rect.position.lerp(r.position, k), _rect.size.lerp(r.size, k))
		queue_redraw()

	static func _clip(c: Control, r: Rect2) -> Rect2:
		var n: = c.get_parent()
		while n:
			if n is ScrollContainer:
				var sr: = (n as Control).get_global_rect().grow(4.0)
				return r.intersection(sr) if r.intersects(sr) else r
			n = n.get_parent()
		return r

	func _draw() -> void :
		if _alpha <= 0.01 or _rect.size.x < 2.0:
			return
		var pulse: = 0.75 + 0.25 * sin(_t * 6.0)
		var col: = Color(0.98, 0.8, 0.32, _alpha * pulse)
		var r: = _rect
		var l: = clampf(minf(r.size.x, r.size.y) * 0.32, 8.0, 26.0)
		var w: = 3.0
		var pts: = [
			[r.position, Vector2(1, 0), Vector2(0, 1)], 
			[Vector2(r.end.x, r.position.y), Vector2(-1, 0), Vector2(0, 1)], 
			[Vector2(r.position.x, r.end.y), Vector2(1, 0), Vector2(0, -1)], 
			[r.end, Vector2(-1, 0), Vector2(0, -1)], 
		]
		for p in pts:
			var o: Vector2 = p[0]
			draw_line(o, o + (p[1] as Vector2) * l, col, w, true)
			draw_line(o, o + (p[2] as Vector2) * l, col, w, true)
		draw_rect(r, Color(1, 0.85, 0.4, 0.07 * _alpha), true)
