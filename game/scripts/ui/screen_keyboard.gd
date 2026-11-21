class_name ScreenKeyboard
extends Control




const ROWS: = ["1234567890", "QWERTYUIOP", "ASDFGHJKL-", "ZXCVBNM'."]
const ALLOWED: = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -'."

var text: = ""
var max_len: = 24
var on_done: Callable
var from: Control
var shift_manual: = false
var _display: Label
var _count: Label
var _keys: Array = []
var _disabled: Array = []
var _t: = 0.0
var _closing: = false


static func open(from_ctl: Control, title: String, txt: String, maxl: int, cb: Callable) -> ScreenKeyboard:
	var k: = ScreenKeyboard.new()
	k.text = txt
	k.max_len = maxl
	k.on_done = cb
	k.from = from_ctl
	var host: Node = from_ctl
	while host.get_parent() is Control:
		host = host.get_parent()

	for ch in host.get_children():
		if ch is Control:
			var c: = ch as Control
			if c.focus_behavior_recursive != Control.FOCUS_BEHAVIOR_DISABLED:
				c.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
				k._disabled.append(c)
	host.add_child(k)
	k._build(title)
	return k


func _build(title: String) -> void :
	name = "ScreenKeyboard"
	add_to_group("nav_root")
	set_meta("nav_prio", 10)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim: = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var card: = UIKit.card(0.0, Color(0.03, 0.035, 0.05, 0.98), UIKit.GOLD, 28)
	card.position = Vector2(960 - 520, 150)
	card.custom_minimum_size = Vector2(1040, 0)
	add_child(card)
	var v: = UIKit.vbox(14)
	card.add_child(v)
	v.add_child(UIKit.tlabel(title.to_upper(), 34, UIKit.GOLD))
	var disp: = PanelContainer.new()
	disp.add_theme_stylebox_override("panel", UIKit.sbox(Color(0.08, 0.08, 0.1, 1), 0.0, Color(1, 1, 1, 0.25), 2, 14.0, 4))
	var dh: = UIKit.hbox(10)
	disp.add_child(dh)
	_display = UIKit.tlabel("", 46, Game.TEXT)
	_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dh.add_child(_display)
	_count = UIKit.label("", 18, Game.TEXT_DIM)
	_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dh.add_child(_count)
	v.add_child(disp)
	var grid: = GridContainer.new()
	grid.columns = 10
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	v.add_child(grid)
	var first: Button = null
	for r in ROWS:
		var row: String = r
		for i in row.length():
			var ch: String = row[i]
			var b: = _key(ch, 92.0)
			b.pressed.connect( func(): _type(ch))
			grid.add_child(b)
			_keys.append([b, ch])
			if first == null and row == ROWS[1]:
				first = b
	var bottom: = UIKit.hbox(8)
	v.add_child(bottom)
	var shift: = _key("Aa", 150.0)
	shift.pressed.connect(_toggle_shift)
	bottom.add_child(shift)
	var sp: = _key("ПРОБЕЛ", 270.0)
	sp.pressed.connect( func(): _type(" "))
	bottom.add_child(sp)
	var bs: = _key("⌫ СТЕРЕТЬ", 200.0)
	bs.pressed.connect(_backspace)
	bottom.add_child(bs)
	var ok: = UIKit.sbutton("Готово", func(): finish(true), 190, true, 26)
	ok.custom_minimum_size.y = 66
	bottom.add_child(ok)
	var cancel: = UIKit.sbutton("Отмена", func(): finish(false), 150, false, 22)
	cancel.custom_minimum_size.y = 66
	bottom.add_child(cancel)
	var hint: = UIKit.hint_bar(v, [["Enter", "Готово", "START"], ["Backspace", "Стереть"], ["Пробел", "Пробел"], 
		["Shift", "Регистр", "LB / RB"], ["Esc", "Отмена"]])
	hint.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hint.offset_left = 0
	_refresh()
	if first:
		first.grab_focus()


func _key(t: String, w: float) -> Button:
	var b: = Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(w, 66)
	if Game.title_font:
		b.add_theme_font_override("font", Game.title_font)
	b.add_theme_font_size_override("font_size", 30)
	UIKit._btn_styles(b, Color(0.08, 0.085, 0.11, 0.95), Color(0.2, 0.15, 0.06, 0.98), 0.0, 6.0, Color(1, 1, 1, 0.1))
	return b


func _upper() -> bool:
	var auto: = text == "" or text.ends_with(" ") or text.ends_with("-")
	return auto != shift_manual


func _type(ch: String) -> void :
	if text.length() >= max_len:
		Sfx.play("tick", -18.0, 0.0, 0.7)
		return
	text += ch.to_upper() if _upper() else ch.to_lower()
	shift_manual = false
	Sfx.play("tick", -16.0, 0.0, 2.0)
	_refresh()


func _type_raw(ch: String) -> void :
	if text.length() >= max_len:
		return
	text += ch
	shift_manual = false
	_refresh()


func _backspace() -> void :
	if text.length() > 0:
		text = text.substr(0, text.length() - 1)
		Sfx.play("tick", -16.0, 0.0, 1.2)
	_refresh()


func _toggle_shift() -> void :
	shift_manual = not shift_manual
	_refresh()


func _refresh() -> void :
	var up: = _upper()
	for k in _keys:
		var ch: String = k[1]
		(k[0] as Button).text = ch.to_upper() if up else ch.to_lower()
	_count.text = "%d / %d" % [text.length(), max_len]
	_display.text = text + ("_" if fmod(_t, 1.0) < 0.55 else " ")


func _process(delta: float) -> void :
	_t += delta
	if _display:
		_display.text = text + ("_" if fmod(_t, 1.0) < 0.55 else " ")


func _input(e: InputEvent) -> void :
	if _closing:
		return
	if e is InputEventKey and (e as InputEventKey).pressed:
		var k: = e as InputEventKey
		match k.keycode:
			KEY_ESCAPE:
				finish(false)
			KEY_ENTER, KEY_KP_ENTER:
				finish(true)
			KEY_BACKSPACE:
				_backspace()
			KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_TAB:
				return
			_:
				if k.unicode >= 32:
					var ch: = char(k.unicode)
					if ALLOWED.contains(ch):
						_type_raw(ch)
				elif k.keycode == KEY_SHIFT:
					return
		get_viewport().set_input_as_handled()
	elif e is InputEventJoypadButton and (e as InputEventJoypadButton).pressed:
		match (e as InputEventJoypadButton).button_index:
			JOY_BUTTON_X:
				_backspace()
			JOY_BUTTON_Y:
				_type(" ")
			JOY_BUTTON_START:
				finish(true)
			JOY_BUTTON_B:
				finish(false)
			JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
				_toggle_shift()
			JOY_BUTTON_BACK:
				pass
			_:
				return
		get_viewport().set_input_as_handled()


func finish(apply: bool) -> void :
	if _closing:
		return
	_closing = true
	Sfx.play("tick", -12.0, 0.0, 1.6 if apply else 0.9)
	for c in _disabled:
		if is_instance_valid(c):
			(c as Control).focus_behavior_recursive = Control.FOCUS_BEHAVIOR_INHERITED
	if is_instance_valid(from) and from.is_inside_tree():
		from.grab_focus()
	var t: = text.strip_edges()
	if apply and on_done.is_valid():
		on_done.call_deferred(t)
	queue_free()
