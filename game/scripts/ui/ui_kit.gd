class_name UIKit
extends RefCounted


static func label(text: String, font_size: int = 24, color: Color = Game.TEXT, 
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l: = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	return l


static func title(text: String, font_size: int = 72, color: Color = Game.ACCENT) -> Label:
	var l: = label(text, font_size, color, HORIZONTAL_ALIGNMENT_CENTER)
	if Game.title_font:
		l.add_theme_font_override("font", Game.title_font)
	l.add_theme_constant_override("outline_size", 10)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	return l


static func wrap_label(text: String, font_size: int = 22, color: Color = Game.TEXT) -> Label:
	var l: = label(text, font_size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, cb: Callable, min_w: float = 380.0) -> Button:
	var b: = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 56)
	b.pressed.connect( func(): _click(cb))
	return b


static func _click(cb: Callable) -> void :
	Sfx.play("tick", -12.0, 0.0, 1.6)
	cb.call()


static func small_button(text: String, cb: Callable) -> Button:
	var b: = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(56, 48)
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(cb)
	return b


static func vbox(sep: int = 12) -> VBoxContainer:
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep: int = 12) -> HBoxContainer:
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func panel() -> PanelContainer:
	return PanelContainer.new()


static func full_center(parent: Node) -> CenterContainer:
	var c: = CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(c)
	return c


static func dim_background(parent: Node, alpha: float = 0.55) -> ColorRect:
	var r: = ColorRect.new()
	r.color = Color(0, 0, 0, alpha)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(r)
	return r


static func option(items: Array, selected: int, cb: Callable) -> OptionButton:
	var o: = OptionButton.new()
	for i in items.size():
		o.add_item(str(items[i]), i)
	o.selected = clampi(selected, 0, maxi(items.size() - 1, 0))
	o.custom_minimum_size = Vector2(320, 52)
	o.item_selected.connect(cb)
	return o


static func slider(min_v: float, max_v: float, step: float, value: float, cb: Callable) -> HSlider:
	var s: = HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(320, 32)
	s.value_changed.connect(cb)
	s.set_meta("nav_consumes", ["left", "right"])
	var lit: = StyleBoxFlat.new()
	lit.bg_color = Color(0.28, 0.24, 0.14)
	lit.border_color = GOLD
	lit.set_border_width_all(2)
	lit.set_content_margin_all(4)
	lit.set_corner_radius_all(3)
	s.focus_entered.connect( func(): s.add_theme_stylebox_override("slider", lit))
	s.focus_exited.connect( func(): s.remove_theme_stylebox_override("slider"))
	return s


static func check(text: String, value: bool, cb: Callable) -> CheckBox:
	var c: = CheckBox.new()
	c.text = text
	c.button_pressed = value
	c.toggled.connect(cb)
	return c


static func row(label_text: String, control: Control, label_w: float = 360.0) -> HBoxContainer:
	var h: = hbox(18)
	var l: = label(label_text, 24, Game.TEXT_DIM)
	l.custom_minimum_size = Vector2(label_w, 0)
	h.add_child(l)
	h.add_child(control)
	return h


static func stat_bar(value: int, color: Color = Game.ACCENT, width: float = 260.0) -> Control:
	var bg: = ColorRect.new()
	bg.color = Color(1, 1, 1, 0.08)
	bg.custom_minimum_size = Vector2(width, 14)
	var fill: = ColorRect.new()
	fill.color = color
	fill.size = Vector2(width * clampf(float(value) / 100.0, 0.0, 1.0), 14)
	bg.add_child(fill)
	return bg


static func controls_text() -> String:
	var out: = "[b]Мышь — удары[/b]\n"
	for r in Controls.MOUSE:
		out += "[color=#e8b23a]%s[/color] — %s\n" % [r[0], r[1]]
	out += "\n[b]Клавиатура — защита и ноги[/b]\n"
	for r in Controls.KEYBOARD:
		out += "[color=#e8b23a]%s[/color] — %s\n" % [r[0], r[1]]
	out += "\n[b]Геймпад[/b]\n"
	for r in Controls.GAMEPAD:
		out += "[color=#e8b23a]%s[/color] — %s\n" % [r[0], r[1]]
	out += "\n[b]Как побеждать[/b]\n"
	for t in Controls.TIPS:
		out += "• %s\n" % t
	return out





const BG: = Color(0.035, 0.04, 0.055, 0.94)
const BG2: = Color(0.07, 0.075, 0.095, 0.95)
const LINE: = Color(1, 1, 1, 0.08)
const RED: = Color(0.85, 0.18, 0.16)
const BLUE: = Color(0.2, 0.45, 0.95)
const GOLD: = Color(0.93, 0.72, 0.25)
const SKEW: = 0.22


static func sbox(bg: Color, skew: float = 0.0, border: Color = Color(0, 0, 0, 0), bw: int = 0, 
		margin: float = 12.0, radius: int = 0) -> StyleBoxFlat:
	var s: = StyleBoxFlat.new()
	s.bg_color = bg
	s.skew = Vector2(skew, 0)
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_content_margin_all(margin)
	s.content_margin_left = margin + 10.0 * absf(skew) * 4.0
	s.content_margin_right = margin + 10.0 * absf(skew) * 4.0
	s.set_corner_radius_all(radius)
	s.anti_aliasing = true
	return s


static func tlabel(text: String, size: int = 40, color: Color = Game.TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l: = label(text, size, color, align)
	if Game.title_font:
		l.add_theme_font_override("font", Game.title_font)
	return l


static func card(skew: float = 0.0, bg: Color = BG, border: Color = LINE, margin: float = 22.0) -> PanelContainer:
	var p: = PanelContainer.new()
	p.add_theme_stylebox_override("panel", sbox(bg, skew, border, 1, margin))
	return p



static func header(text: String, sub: String = "", size: int = 64) -> Control:
	var v: = vbox(0)
	var h: = hbox(16)
	var bar: = ColorRect.new()
	bar.color = GOLD
	bar.custom_minimum_size = Vector2(10, size * 0.9)
	h.add_child(bar)
	var t: = tlabel(text, size, Game.TEXT)
	h.add_child(t)
	v.add_child(h)
	if sub != "":
		var s: = label(sub.to_upper(), 20, Game.TEXT_DIM)
		s.add_theme_constant_override("outline_size", 0)
		var m: = MarginContainer.new()
		m.add_theme_constant_override("margin_left", 26)
		m.add_child(s)
		v.add_child(m)
	return v


static func _btn_styles(b: Button, normal: Color, hover: Color, skew: float, margin: float, border: Color = Color(0, 0, 0, 0)) -> void :
	var n: = sbox(normal, skew, border, 1 if border.a > 0.0 else 0, margin)
	var h: = sbox(hover, skew, GOLD, 2, margin)
	var p: = sbox(hover.lightened(0.15), skew, GOLD, 2, margin)
	var d: = sbox(Color(normal.r, normal.g, normal.b, normal.a * 0.5), skew, Color(0, 0, 0, 0), 0, margin)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_stylebox_override("focus", h)
	b.add_theme_stylebox_override("disabled", d)



static func menu_item(index: int, text: String, sub: String, cb: Callable, width: float = 560.0) -> Button:
	var b: = Button.new()
	b.custom_minimum_size = Vector2(width, 78)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.text = ""
	_btn_styles(b, Color(0.03, 0.035, 0.05, 0.55), Color(0.12, 0.09, 0.04, 0.92), SKEW, 10.0)
	var h: = hbox(18)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 30
	var num: = tlabel("%02d" % index, 30, GOLD)
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_child(num)
	var v: = vbox(-6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var t: = tlabel(text.to_upper(), 40, Game.TEXT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)
	if sub != "":
		var s: = label(sub, 17, Game.TEXT_DIM)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(s)
	h.add_child(v)
	b.add_child(h)
	var hover_in: = func():
		var tw: = b.create_tween()
		tw.tween_property(h, "offset_left", 52.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.add_theme_color_override("font_color", GOLD)
		Sfx.play("tick", -20.0, 0.0, 2.2)
	var hover_out: = func():
		var tw: = b.create_tween()
		tw.tween_property(h, "offset_left", 30.0, 0.15)
		t.add_theme_color_override("font_color", Game.TEXT)
	b.focus_entered.connect(hover_in)
	b.focus_exited.connect(hover_out)
	b.set_meta("nav_no_ring", true)
	b.pressed.connect( func(): _click(cb))
	return b



static func sbutton(text: String, cb: Callable, width: float = 260.0, accent: bool = false, size: int = 26) -> Button:
	var b: = Button.new()
	b.text = text.to_upper()
	b.custom_minimum_size = Vector2(width, 58)
	if Game.title_font:
		b.add_theme_font_override("font", Game.title_font)
	b.add_theme_font_size_override("font_size", size)
	if accent:
		_btn_styles(b, Color(0.72, 0.52, 0.12, 0.95), Color(0.95, 0.72, 0.22, 1.0), SKEW, 12.0)
		b.add_theme_color_override("font_color", Color(0.06, 0.05, 0.03))
		b.add_theme_color_override("font_hover_color", Color(0.02, 0.02, 0.02))
		b.add_theme_color_override("font_focus_color", Color(0.02, 0.02, 0.02))
		b.add_theme_color_override("font_pressed_color", Color(0, 0, 0))
	else:
		_btn_styles(b, Color(0.08, 0.085, 0.11, 0.92), Color(0.16, 0.12, 0.05, 0.96), SKEW, 12.0, Color(1, 1, 1, 0.1))
	b.pressed.connect( func(): _click(cb))
	return b



static func chip(text: String, selected: bool, cb: Callable, size: int = 20, nav_id: String = "") -> Button:
	var b: = Button.new()
	b.text = text.to_upper()
	if nav_id != "":
		b.set_meta("nav_id", nav_id)
	b.toggle_mode = false
	b.custom_minimum_size = Vector2(0, 44)
	if Game.title_font:
		b.add_theme_font_override("font", Game.title_font)
	b.add_theme_font_size_override("font_size", size)
	if selected:
		_btn_styles(b, Color(0.85, 0.63, 0.18, 0.98), Color(0.95, 0.75, 0.3, 1.0), SKEW, 8.0)
		for k in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			b.add_theme_color_override(k, Color(0.05, 0.04, 0.02))
	else:
		_btn_styles(b, Color(0.07, 0.075, 0.1, 0.88), Color(0.16, 0.12, 0.05, 0.96), SKEW, 8.0, Color(1, 1, 1, 0.08))
		b.add_theme_color_override("font_color", Game.TEXT_DIM)
	b.pressed.connect( func(): _click(cb))
	return b



static func seg_bar(value: int, color: Color = GOLD, width: float = 240.0, segs: int = 20) -> Control:
	var c: = SegBar.new()
	c.value = value
	c.color = color
	c.segs = segs
	c.custom_minimum_size = Vector2(width, 16)
	return c



static func stat_row(name: String, value: int, color: Color = GOLD, width: float = 230.0, label_w: float = 170.0) -> HBoxContainer:
	var h: = hbox(12)
	var l: = label(name.to_upper(), 17, Game.TEXT_DIM)
	l.custom_minimum_size = Vector2(label_w, 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	var bar: = seg_bar(value, color, width)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(bar)
	var n: = tlabel(str(value), 24, Game.TEXT)
	n.custom_minimum_size = Vector2(40, 0)
	h.add_child(n)
	return h



static var _portrait_cache: = {}


static func portrait_tex(model: String) -> Texture2D:
	if _portrait_cache.has(model):
		return _portrait_cache[model]
	var p: = "res://assets/portraits/%s.png" % model
	var t: Texture2D = null
	if ResourceLoader.exists(p):
		t = load(p)
	_portrait_cache[model] = t
	return t


static func portrait(model: String, sz: Vector2 = Vector2(220, 270), flip: bool = false) -> Control:
	var holder: = Control.new()
	holder.custom_minimum_size = sz
	holder.clip_contents = true
	var bg: = ColorRect.new()
	bg.color = Color(0.1, 0.11, 0.14, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(bg)
	var glow: = TextureRect.new()
	var gt: = GradientTexture2D.new()
	var gr: = Gradient.new()
	gr.set_color(0, Color(0.95, 0.72, 0.25, 0.32))
	gr.set_color(1, Color(0.95, 0.72, 0.25, 0.0))
	gt.gradient = gr
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.35)
	gt.fill_to = Vector2(1.0, 0.9)
	glow.texture = gt
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	holder.add_child(glow)
	var t: = portrait_tex(model)
	if t:
		var tr: = TextureRect.new()
		tr.texture = t
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.flip_h = flip
		holder.add_child(tr)
	else:
		var sil: = tlabel("?", int(sz.y * 0.5), Color(1, 1, 1, 0.12), HORIZONTAL_ALIGNMENT_CENTER)
		sil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sil.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		holder.add_child(sil)
	var shade: = TextureRect.new()
	var st: = GradientTexture2D.new()
	var sg: = Gradient.new()
	sg.set_color(0, Color(0, 0, 0, 0))
	sg.set_color(1, Color(0, 0, 0, 0.7))
	st.gradient = sg
	st.fill_from = Vector2(0.5, 0.55)
	st.fill_to = Vector2(0.5, 1.0)
	shade.texture = st
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	holder.add_child(shade)
	return holder



const COUNTRY: = {
	"USA": ["США", Color(0.2, 0.3, 0.7)], "Mexico": ["МЕКСИКА", Color(0.1, 0.5, 0.25)], "England": ["АНГЛИЯ", Color(0.75, 0.1, 0.15)], 
	"Russia": ["РОССИЯ", Color(0.15, 0.3, 0.75)], "Kazakhstan": ["КАЗАХСТАН", Color(0.1, 0.6, 0.75)], "Cuba": ["КУБА", Color(0.2, 0.3, 0.75)], 
	"Philippines": ["ФИЛИППИНЫ", Color(0.15, 0.25, 0.7)], "Japan": ["ЯПОНИЯ", Color(0.8, 0.1, 0.15)], "Nigeria": ["НИГЕРИЯ", Color(0.1, 0.55, 0.25)], 
	"Ghana": ["ГАНА", Color(0.85, 0.65, 0.1)], "Brazil": ["БРАЗИЛИЯ", Color(0.1, 0.6, 0.25)], "Germany": ["ГЕРМАНИЯ", Color(0.2, 0.2, 0.2)], 
	"Poland": ["ПОЛЬША", Color(0.85, 0.15, 0.2)], "Ukraine": ["УКРАИНА", Color(0.15, 0.4, 0.8)], "Ireland": ["ИРЛАНДИЯ", Color(0.1, 0.55, 0.3)], 
	"France": ["ФРАНЦИЯ", Color(0.15, 0.25, 0.7)], "Italy": ["ИТАЛИЯ", Color(0.1, 0.5, 0.25)], "Wales": ["УЭЛЬС", Color(0.75, 0.1, 0.15)], 
	"Australia": ["АВСТРАЛИЯ", Color(0.15, 0.25, 0.6)], 
}


static func country_name(c: String) -> String:
	return str(COUNTRY.get(c, [c.to_upper(), Color.GRAY])[0])


static func country_tag(c: String) -> Control:
	var h: = hbox(8)
	var sw: = ColorRect.new()
	sw.color = COUNTRY.get(c, [c, Color(0.4, 0.4, 0.45)])[1]
	sw.custom_minimum_size = Vector2(6, 22)
	h.add_child(sw)
	h.add_child(label(country_name(c), 18, Game.TEXT_DIM))
	return h



const PAD_COLORS: = {"A": Color(0.2, 0.62, 0.25), "B": Color(0.78, 0.2, 0.17), "X": Color(0.18, 0.4, 0.85), 
	"Y": Color(0.85, 0.66, 0.12)}


static func key_cap(text: String) -> PanelContainer:
	var p: = PanelContainer.new()
	var l: = tlabel(text, 20, Game.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	p.add_child(l)
	_key_style(p, l, text)
	return p


static func _key_style(p: PanelContainer, l: Label, text: String) -> void :
	l.text = text
	if PAD_COLORS.has(text):
		p.add_theme_stylebox_override("panel", sbox(PAD_COLORS[text], 0.0, Color(1, 1, 1, 0.35), 1, 6.0, 14))
		l.add_theme_color_override("font_color", Color.WHITE)
	else:
		p.add_theme_stylebox_override("panel", sbox(Color(0.13, 0.135, 0.16, 1), 0.0, Color(1, 1, 1, 0.22), 1, 6.0, 5))
		l.add_theme_color_override("font_color", Game.TEXT)



static func intro(c: Control, dx: float = -50.0, delay: float = 0.0) -> void :
	c.modulate.a = 0.0
	var tw: = c.create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.set_parallel(true)
	tw.tween_property(c, "modulate:a", 1.0, 0.28)
	if absf(dx) > 0.0:
		var x0: = c.position.x
		c.position.x = x0 + dx
		tw.tween_property(c, "position:x", x0, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)



static func backdrop(parent: Control, strength: float = 0.75) -> void :
	var v: = TextureRect.new()
	var gt: = GradientTexture2D.new()
	var g: = Gradient.new()
	g.set_color(0, Color(0.01, 0.012, 0.02, strength))
	g.set_color(1, Color(0.01, 0.012, 0.02, strength * 0.15))
	gt.gradient = g
	gt.fill_from = Vector2(0.0, 0.5)
	gt.fill_to = Vector2(0.85, 0.5)
	v.texture = gt
	v.stretch_mode = TextureRect.STRETCH_SCALE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(v)
	var bot: = TextureRect.new()
	var bt: = GradientTexture2D.new()
	var bg: = Gradient.new()
	bg.set_color(0, Color(0, 0, 0, 0))
	bg.set_color(1, Color(0, 0, 0, 0.65))
	bt.gradient = bg
	bt.fill_from = Vector2(0.5, 0.6)
	bt.fill_to = Vector2(0.5, 1.0)
	bot.texture = bt
	bot.stretch_mode = TextureRect.STRETCH_SCALE
	bot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bot)



const PAD_HINT: = {"Enter": "A", "Esc": "B", "↑↓": "◆ / СТИК", "↑↓←→": "◆ / СТИК", "←→": "◀ ▶", "Q / E": "LB / RB", 
	"Backspace": "X", "Пробел": "Y", "Tab": "LB / RB", "Пр. стик": "ПРАВЫЙ СТИК", "Колесо": "ПРАВЫЙ СТИК"}



static func hint_bar(parent: Control, items: Array) -> Control:
	var h: = HintBar.new()
	h.add_theme_constant_override("separation", 26)
	h.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	h.offset_left = 70
	h.offset_top = -56
	h.offset_bottom = -20
	h.offset_right = 1800
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for it in items:
		var pair: = hbox(8)
		var kb: = str(it[0])
		var pad: = str(it[2]) if (it as Array).size() > 2 else str(PAD_HINT.get(kb, kb))
		var cap: = key_cap(kb)
		pair.add_child(cap)
		var l: = label(str(it[1]), 18, Game.TEXT_DIM)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pair.add_child(l)
		h.add_child(pair)
		h.caps.append([cap, cap.get_child(0), kb, pad])
	parent.add_child(h)
	h.refresh(Game.nav != null and Game.nav.using_pad)
	return h



class HintBar:
	extends HBoxContainer

	var caps: Array = []

	func _ready() -> void :
		if Game.nav:
			Game.nav.device_changed.connect(refresh)

	func refresh(pad: bool) -> void :
		for c in caps:
			UIKit._key_style(c[0], c[1], str(c[3]) if pad else str(c[2]))


static func spacer(h: float, w: float = 0.0) -> Control:
	var s: = Control.new()
	s.custom_minimum_size = Vector2(w, h)
	return s



static func swatch(c: Color, selected: bool, cb: Callable, sz: float = 40.0) -> Button:
	var b: = Button.new()
	b.custom_minimum_size = Vector2(sz, sz)
	var n: = sbox(c, 0.0, Color(1, 1, 1, 0.9) if selected else Color(0, 0, 0, 0.6), 3 if selected else 1, 0.0, 4)
	var h: = sbox(c.lightened(0.1), 0.0, GOLD, 3, 0.0, 4)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", h)
	b.pressed.connect( func(): _click(cb))
	return b




static func stepper(values: Array, idx: int, cb: Callable, width: float = 300.0) -> Stepper:
	var h: = Stepper.new()
	h.add_theme_constant_override("separation", 6)
	h.values = values
	h.cur = clampi(idx, 0, maxi(values.size() - 1, 0))
	h.cb = cb
	var lab: = tlabel(str(values[h.cur]) if not values.is_empty() else "", 24, Game.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	lab.custom_minimum_size = Vector2(width - 120, 0)
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.mouse_filter = Control.MOUSE_FILTER_PASS
	lab.set_meta("nav_owner", h)
	var left: = Button.new()
	left.text = "◀"
	left.custom_minimum_size = Vector2(52, 48)
	var right: = Button.new()
	right.text = "▶"
	right.custom_minimum_size = Vector2(52, 48)
	for b2 in [left, right]:
		_btn_styles(b2, Color(0.08, 0.085, 0.11, 0.92), Color(0.16, 0.12, 0.05, 0.96), 0.0, 6.0, Color(1, 1, 1, 0.1))
		b2.focus_mode = Control.FOCUS_NONE
		b2.set_meta("nav_owner", h)
	left.pressed.connect( func(): h.step(-1))
	right.pressed.connect( func(): h.step(1))
	h.lab = lab
	h.left = left
	h.right = right
	h.add_child(left)
	h.add_child(lab)
	h.add_child(right)
	return h


class Stepper:
	extends HBoxContainer

	var values: Array = []
	var cur: = 0
	var cb: Callable
	var lab: Label
	var left: Button
	var right: Button

	func _init() -> void :
		focus_mode = Control.FOCUS_ALL
		mouse_filter = Control.MOUSE_FILTER_PASS
		set_meta("nav_item", true)
		set_meta("nav_consumes", ["left", "right"])
		focus_entered.connect(_lit)
		focus_exited.connect(_lit)

	func step(d: int) -> void :
		if values.is_empty():
			return
		cur = posmod(cur + d, values.size())
		lab.text = str(values[cur])
		Sfx.play("tick", -14.0, 0.0, 1.8)
		var b: = left if d < 0 else right
		if b:
			b.modulate = Color(1.6, 1.3, 0.7)
			b.create_tween().tween_property(b, "modulate", Color.WHITE, 0.2)
		if cb.is_valid():
			cb.call(cur)

	func _gui_input(e: InputEvent) -> void :
		if e.is_action_pressed("ui_left", true):
			step(-1)
			accept_event()
		elif e.is_action_pressed("ui_right", true):
			step(1)
			accept_event()
		elif e.is_action_pressed("ui_accept"):
			step(1)
			accept_event()

	func _lit() -> void :
		if lab:
			lab.add_theme_color_override("font_color", UIKit.GOLD if has_focus() else Game.TEXT)
		queue_redraw()

	func _draw() -> void :
		if has_focus():
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.16, 0.12, 0.05, 0.75), true)
			draw_rect(Rect2(Vector2.ZERO, size), UIKit.GOLD, false, 2.0)




static func nav_scroll(sz: Vector2) -> NavScroll:
	var sc: = NavScroll.new()
	sc.custom_minimum_size = sz
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return sc


class NavScroll:
	extends ScrollContainer

	var step_px: = 110

	func _init() -> void :
		focus_mode = Control.FOCUS_ALL
		follow_focus = true
		set_meta("nav_item", true)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)

	func _limit() -> int:
		var vb: = get_v_scroll_bar()
		return int(maxf(vb.max_value - vb.page, 0.0))

	func _gui_input(e: InputEvent) -> void :
		if e.is_action_pressed("ui_down", true) and scroll_vertical < _limit() - 1:
			scroll_vertical = mini(scroll_vertical + step_px, _limit())
			accept_event()
		elif e.is_action_pressed("ui_up", true) and scroll_vertical > 0:
			scroll_vertical = maxi(scroll_vertical - step_px, 0)
			accept_event()
		elif e.is_action_pressed("ui_page_down", true):
			scroll_vertical = mini(scroll_vertical + int(size.y * 0.9), _limit())
			accept_event()
		elif e.is_action_pressed("ui_page_up", true):
			scroll_vertical = maxi(scroll_vertical - int(size.y * 0.9), 0)
			accept_event()

	func _draw() -> void :
		if has_focus():
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.93, 0.72, 0.25, 0.5), false, 2.0)




static func name_field(text: String, title: String, max_len: int, cb: Callable, width: float = 420.0) -> Button:
	var b: = Button.new()
	b.custom_minimum_size = Vector2(width, 50)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.text = (text if text != "" else "—") + "   ✎"
	b.clip_text = true
	var n: = sbox(Color(0.08, 0.08, 0.1, 0.95), 0.0, Color(0.3, 0.3, 0.33), 2, 10.0, 4)
	var f: = sbox(Color(0.14, 0.12, 0.08, 0.95), 0.0, GOLD, 2, 10.0, 4)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", f)
	b.add_theme_stylebox_override("pressed", f)
	b.add_theme_stylebox_override("focus", f)
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect( func():
		Sfx.play("tick", -12.0, 0.0, 1.6)
		ScreenKeyboard.open(b, title, text, max_len, cb))
	return b



static func srow(text: String, control: Control, label_w: float = 300.0) -> HBoxContainer:
	var h: = hbox(16)
	var l: = label(text.to_upper(), 19, Game.TEXT_DIM)
	l.custom_minimum_size = Vector2(label_w, 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	h.add_child(control)
	return h
