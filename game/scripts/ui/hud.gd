class_name FightHUD
extends CanvasLayer



signal getup_success

const VIGNETTE_SHADER: = "\r\nshader_type canvas_item;\r\nuniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;\r\nuniform float vignette = 0.0;\r\nuniform float blur = 0.0;\r\nuniform vec4 tint : source_color = vec4(0.45, 0.0, 0.0, 1.0);\r\nvoid fragment() {\r\n\tvec2 uv = SCREEN_UV;\r\n\tfloat lod = blur * 3.5;\r\n\tvec3 col = textureLod(screen_tex, uv, lod).rgb;\r\n\tvec3 ghost = textureLod(screen_tex, uv + vec2(blur * 0.014 * sin(TIME * 2.3), blur * 0.006), lod + 0.5).rgb;\r\n\tcol = mix(col, (col + ghost) * 0.5, clamp(blur, 0.0, 1.0));\r\n\tfloat g = dot(col, vec3(0.299, 0.587, 0.114));\r\n\tcol = mix(col, vec3(g), clamp(blur * 0.5, 0.0, 0.8));\r\n\tfloat d = distance(UV, vec2(0.5));\r\n\tfloat v = smoothstep(0.3, 0.85, d) * vignette;\r\n\tcol = mix(col, col * tint.rgb * 0.6, v);\r\n\tcol *= 1.0 - v * 0.55;\r\n\tCOLOR = vec4(col, 1.0);\r\n}\r\n"






















class StatBar:
	extends Control
	var value: = 1.0
	var cap: = 1.0
	var fill_color: = Color(0.85, 0.15, 0.12)
	var mirrored: = false
	var ghost: = 1.0

	func set_values(v: float, c: float) -> void :
		var nv: = clampf(v, 0.0, 1.0)
		var nc: = clampf(c, 0.0, 1.0)
		if absf(nv - value) > 0.0005 or absf(nc - cap) > 0.0005:
			value = nv
			cap = nc
			queue_redraw()

	func _process(delta: float) -> void :
		if ghost > value:
			ghost = maxf(value, ghost - delta * 0.35)
			queue_redraw()
		elif ghost < value:
			ghost = value

	func _draw() -> void :
		var w: = size.x
		var h: = size.y
		draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.55))
		var cap_w: = w * cap
		var lost_cap: = Rect2(w - (w - cap_w), 0, w - cap_w, h) if not mirrored else Rect2(0, 0, w - cap_w, h)
		draw_rect(lost_cap, Color(0.22, 0.04, 0.04, 0.85))
		var gw: = w * ghost
		var vw: = w * value
		if mirrored:
			draw_rect(Rect2(w - gw, 0, gw, h), Color(1, 1, 1, 0.45))
			draw_rect(Rect2(w - vw, 0, vw, h), fill_color)
		else:
			draw_rect(Rect2(0, 0, gw, h), Color(1, 1, 1, 0.45))
			draw_rect(Rect2(0, 0, vw, h), fill_color)
		draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, 0.25), false, 1.0)


class GetupBar:
	extends Control
	var needle: = 0.5
	var zone_center: = 0.5
	var zone_width: = 0.2

	func _draw() -> void :
		var w: = size.x
		var h: = size.y
		draw_rect(Rect2(0, 0, w, h), Color(0.08, 0.08, 0.1, 0.95))
		var zx: = (zone_center - zone_width * 0.5) * w
		draw_rect(Rect2(zx, 0, zone_width * w, h), Color(0.2, 0.75, 0.3, 0.9))
		var nx: = needle * w
		draw_rect(Rect2(nx - 3, -8, 6, h + 16), Color(1, 0.95, 0.8))
		draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, 0.4), false, 2.0)



class AimWidget:
	extends Control
	var vec: = Vector2.ZERO
	var kind: = "straight"
	var body: = false
	var power: = false
	var flash: = 0.0

	func _draw() -> void :
		var c: = size * 0.5
		var r: = minf(size.x, size.y) * 0.5 - 4.0
		var a: = 0.55 + flash * 0.45
		draw_circle(c, r, Color(0.02, 0.02, 0.03, 0.55 * a))
		draw_arc(c, r, 0.0, TAU, 48, Color(1, 1, 1, 0.25 * a), 2.0, true)
		draw_arc(c, r * 0.32, 0.0, TAU, 32, Color(1, 1, 1, 0.18 * a), 1.5, true)

		var col_on: = Color(0.93, 0.72, 0.25, 0.9 * a) if not power else Color(0.95, 0.3, 0.2, 0.95 * a)
		var col_off: = Color(1, 1, 1, 0.08 * a)
		var sectors: = [["upper", - PI * 0.5, 38.0], ["hook", 0.0, 50.0], ["hook", PI, 50.0], ["bodyst", PI * 0.5, 32.0], ["bodyhook", PI * 0.5 - 0.82, 18.0], ["bodyhook", PI * 0.5 + 0.82, 18.0]]
		var cur: = kind
		if body:
			cur = "bodyst" if kind == "straight" else "bodyhook"
		for sct in sectors:
			var sa: Array = sct
			var mid: float = sa[1]
			var half: = deg_to_rad(float(sa[2]))
			var on: bool = str(sa[0]) == cur
			draw_arc(c, r * 0.72, mid - half, mid + half, 16, col_on if on else col_off, r * 0.42, false)
		if cur == "straight":
			draw_circle(c, r * 0.3, col_on)
		draw_circle(c + vec * r * 0.85, 5.0, Color(1, 1, 1, 0.95 * a))


class GuardBar:
	extends Control
	var value: = 1.0
	var mirrored: = false
	var broken: = false

	func _draw() -> void :
		var w: = size.x
		var h: = size.y
		draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.5))
		var segs: = 10
		var gap: = 3.0
		var sw: = (w - gap * (segs - 1)) / float(segs)
		for i in segs:
			var k: = float(i + 1) / float(segs)
			var on: = value >= k - 0.5 / float(segs)
			var x: = float(i) * (sw + gap)
			if mirrored:
				x = w - x - sw
			var col: = Color(0.55, 0.75, 1.0, 0.95) if value > 0.3 else Color(1.0, 0.45, 0.25, 0.95)
			if broken:
				col = Color(1, 0.2, 0.15, 0.6 + 0.4 * absf(sin(Time.get_ticks_msec() * 0.012)))
			draw_rect(Rect2(x, 0, sw, h), col if on else Color(1, 1, 1, 0.08))


var root: Control
var player_ctrl: PlayerController
var aim: AimWidget
var aim_label: Label
var train_panel: PanelContainer
var train_label: Label
var train_title: Label
var punch_pop: Label
var _pop_last: = ""
var bars: = {}
var name_labels: Array[Label] = []
var round_label: Label
var clock_label: Label
var message_label: Label
var count_label: Label
var feed: VBoxContainer
var hint_panel: PanelContainer
var hint_small: Label
var _hint_t: = 0.0
var _hint_pinned: = false
var vignette_rect: ColorRect
var vignette_mat: ShaderMaterial
var fade_rect: ColorRect
var getup_panel: PanelContainer
var getup_bar: GetupBar
var getup_hits_label: Label
var getup_info: Label

var fighters: Array = []
var show_health: = true
var _msg_tween: Tween
var _getup_active: = false
var _getup_t: = 0.0
var _getup_speed: = 3.2
var _getup_hits: = 0
var _getup_needed: = 3
var _rng: = RandomNumberGenerator.new()


func _ready() -> void :
	layer = 10
	_rng.randomize()
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Game.ui_theme
	add_child(root)

	vignette_rect = ColorRect.new()
	vignette_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh: = Shader.new()
	sh.code = VIGNETTE_SHADER
	vignette_mat = ShaderMaterial.new()
	vignette_mat.shader = sh
	vignette_rect.material = vignette_mat
	vignette_rect.visible = false
	root.add_child(vignette_rect)

	_build_top()
	_build_center()
	_build_getup()
	_build_hints()
	_build_aim()
	_build_training()

	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade_rect)


static func _place(c: Control, preset: Control.LayoutPreset, left: float, top: float, right: float, bottom: float) -> void :
	c.set_anchors_preset(preset)
	c.offset_left = left
	c.offset_top = top
	c.offset_right = right
	c.offset_bottom = bottom


func _label(text: String, font_size: int, color: Color = Game.TEXT, outline: int = 6) -> Label:
	var l: = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_top() -> void :
	for corner in 2:
		var box: = VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if corner == 0:
			_place(box, Control.PRESET_TOP_LEFT, 40, 28, 640, 148)
		else:
			_place(box, Control.PRESET_TOP_RIGHT, -640, 28, -40, 148)
		root.add_child(box)
		var nl: = _label("", 30, Game.TEXT, 8)
		if Game.title_font:
			nl.add_theme_font_override("font", Game.title_font)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if corner == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		box.add_child(nl)
		name_labels.append(nl)
		var head: = StatBar.new()
		head.custom_minimum_size = Vector2(600, 22)
		head.fill_color = Color(0.86, 0.16, 0.13)
		head.mirrored = corner == 1
		box.add_child(head)
		var body: = StatBar.new()
		body.custom_minimum_size = Vector2(600, 9)
		body.fill_color = Color(0.95, 0.55, 0.12)
		body.mirrored = corner == 1
		box.add_child(body)
		var stam: = StatBar.new()
		stam.custom_minimum_size = Vector2(600, 14)
		stam.fill_color = Color(0.25, 0.75, 0.35)
		stam.mirrored = corner == 1
		box.add_child(stam)
		for bar in [head, body, stam]:
			var sbar: StatBar = bar
			sbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var grow: = HBoxContainer.new()
		grow.add_theme_constant_override("separation", 8)
		grow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grow.alignment = BoxContainer.ALIGNMENT_BEGIN if corner == 0 else BoxContainer.ALIGNMENT_END
		box.add_child(grow)
		var gl: = _label("ЗАЩИТА", 13, Color(0.7, 0.8, 1.0, 0.8), 3)
		var guard: = GuardBar.new()
		guard.custom_minimum_size = Vector2(240, 8)
		guard.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		guard.mirrored = corner == 1
		guard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if corner == 0:
			grow.add_child(gl)
			grow.add_child(guard)
		else:
			grow.add_child(guard)
			grow.add_child(gl)
		bars["%d_head" % corner] = head
		bars["%d_body" % corner] = body
		bars["%d_stam" % corner] = stam
		bars["%d_guard" % corner] = guard


func _build_center() -> void :
	var top: = VBoxContainer.new()
	_place(top, Control.PRESET_CENTER_TOP, -200, 18, 200, 138)
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 0)
	root.add_child(top)
	round_label = _label("РАУНД 1", 24, Game.ACCENT)
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(round_label)
	clock_label = _label("3:00", 58, Game.TEXT, 10)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if Game.title_font:
		clock_label.add_theme_font_override("font", Game.title_font)
	top.add_child(clock_label)

	feed = VBoxContainer.new()
	_place(feed, Control.PRESET_CENTER_TOP, -400, 170, 400, 470)
	feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feed.add_theme_constant_override("separation", 2)
	root.add_child(feed)

	message_label = _label("", 110, Game.TEXT, 14)
	_place(message_label, Control.PRESET_CENTER, -900, -230, 900, -30)
	message_label.pivot_offset = Vector2(900, 100)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if Game.title_font:
		message_label.add_theme_font_override("font", Game.title_font)
	message_label.modulate.a = 0.0
	root.add_child(message_label)

	count_label = _label("", 260, Color(1, 1, 1), 18)
	_place(count_label, Control.PRESET_CENTER, -300, -330, 300, -30)
	count_label.pivot_offset = Vector2(300, 150)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if Game.title_font:
		count_label.add_theme_font_override("font", Game.title_font)
	count_label.visible = false
	root.add_child(count_label)


func _build_getup() -> void :
	getup_panel = PanelContainer.new()
	_place(getup_panel, Control.PRESET_CENTER_BOTTOM, -420, -320, 420, -80)
	getup_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(getup_panel)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	getup_panel.add_child(v)
	var title: = _label("ВСТАВАЙ!", 44, Game.ACCENT_RED, 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if Game.title_font:
		title.add_theme_font_override("font", Game.title_font)
	v.add_child(title)
	getup_bar = GetupBar.new()
	getup_bar.custom_minimum_size = Vector2(780, 40)
	getup_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(getup_bar)
	getup_hits_label = _label("○ ○ ○", 34, Game.TEXT)
	getup_hits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(getup_hits_label)
	getup_info = _label("Жми ПРОБЕЛ / A, когда стрелка в зелёной зоне", 22, Game.TEXT_DIM, 4)
	getup_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(getup_info)
	getup_panel.visible = false


func _build_hints() -> void :
	hint_panel = PanelContainer.new()
	_place(hint_panel, Control.PRESET_BOTTOM_LEFT, 24, -150, 760, -24)
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_panel.self_modulate = Color(1, 1, 1, 0.75)
	root.add_child(hint_panel)
	var l: = _label("", 16, Game.TEXT_DIM, 0)
	l.text = Controls.hud_text(Game.setting_b("mouse_punch"))
	hint_panel.add_child(l)
	hint_panel.visible = Game.setting_b("hints")
	hint_small = _label("F1 — управление", 15, Game.TEXT_DIM, 0)
	_place(hint_small, Control.PRESET_BOTTOM_LEFT, 24, -48, 300, -20)
	hint_small.modulate = Color(1, 1, 1, 0.55)
	root.add_child(hint_small)
	hint_small.visible = not hint_panel.visible


func _build_aim() -> void :
	aim = AimWidget.new()
	_place(aim, Control.PRESET_CENTER_BOTTOM, -55, -150, 55, -40)
	aim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(aim)
	aim_label = _label("", 17, Game.TEXT_DIM, 4)
	aim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(aim_label, Control.PRESET_CENTER_BOTTOM, -260, -36, 260, -10)
	root.add_child(aim_label)
	var on: = Game.setting_b("mouse_punch") and Game.setting_b("hud_mouse_aim")
	aim.visible = on
	aim_label.visible = on


func _build_training() -> void :
	train_panel = PanelContainer.new()
	_place(train_panel, Control.PRESET_TOP_LEFT, 40, 40, 560, 290)
	train_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	train_panel.self_modulate = Color(1, 1, 1, 0.85)
	root.add_child(train_panel)
	var v: = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	train_panel.add_child(v)
	train_title = _label("ТРЕНИРОВКА", 30, Game.ACCENT, 6)
	if Game.title_font:
		train_title.add_theme_font_override("font", Game.title_font)
	v.add_child(train_title)
	train_label = _label("", 19, Game.TEXT, 3)
	v.add_child(train_label)
	train_panel.visible = false
	punch_pop = _label("", 44, Game.TEXT, 8)
	if Game.title_font:
		punch_pop.add_theme_font_override("font", Game.title_font)
	punch_pop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(punch_pop, Control.PRESET_CENTER_BOTTOM, -500, -260, 500, -190)
	punch_pop.modulate.a = 0.0
	root.add_child(punch_pop)


func setup_training(mode: String) -> void :
	train_panel.visible = true
	train_title.text = "ТРЕНИРОВКА • ГРУША" if mode == "bag" else "ТРЕНИРОВКА • СПАРРИНГ"
	if mode == "spar":
		_place(train_panel, Control.PRESET_BOTTOM_RIGHT, -560, -300, -40, -150)
	else:
		_place(train_panel, Control.PRESET_TOP_LEFT, 40, 40, 560, 290)

	hint_panel.visible = true
	_hint_pinned = true
	aim.visible = Game.setting_b("mouse_punch")
	aim_label.visible = aim.visible


func update_training(st: Dictionary, mode: String, clock: float) -> void :
	var thrown: = int(st["thrown"])
	var landed: = int(st["landed"])
	var acc: = (100.0 * float(landed) / float(thrown)) if thrown > 0 else 0.0
	var lines: = "Ударов: %d    Попало: %d  (%d%%)\n" % [thrown, landed, int(acc)]
	lines += "Серия: %d    Лучшая серия: %d\n" % [int(st["combo"]), int(st["best_combo"])]
	lines += "Самый сильный: %.0f    Силовых: %d\n" % [float(st["best"]), int(st["power"])]
	if fighters.size() > 0:
		var me: Fighter = fighters[0]
		lines += "Выносливость: %d%%    Защита: %d%%\n" % [int(me.stamina_ratio() * 100.0), int(me.guard_ratio() * 100.0)]
	lines += "Tab — %s    Esc — пауза / выход" % ("спарринг-партнёр" if mode == "bag" else "груша")
	train_label.text = lines
	var last: = str(st.get("last", ""))
	var key: = last + str(st.get("last_t", 0.0))
	if last != "" and clock - float(st.get("last_t", -10.0)) < 0.3 and key != _pop_last:
		_pop_last = key
		var outc: = str(st.get("last_outcome", ""))
		var txt: = last.to_upper()
		var col: = Game.TEXT
		match outc:
			"hit":
				txt += "   %.0f" % float(st.get("last_dmg", 0.0))
				col = Game.ACCENT
			"blocked":
				txt += "   В БЛОК"
				col = Color(0.6, 0.75, 1.0)
			"slipped":
				txt += "   УШЁЛ"
				col = Game.TEXT_DIM
			"parried":
				txt += "   ПАРИРОВАН"
				col = Game.ACCENT_RED
			_:
				txt += "   МИМО"
				col = Game.TEXT_DIM
		punch_pop.text = txt
		punch_pop.add_theme_color_override("font_color", col)
		punch_pop.modulate.a = 1.0
		punch_pop.pivot_offset = Vector2(500, 35)
		punch_pop.scale = Vector2(1.15, 1.15)
		var tw: = punch_pop.create_tween().set_ignore_time_scale(true)
		tw.tween_property(punch_pop, "scale", Vector2.ONE, 0.12)
		tw.tween_interval(0.7)
		tw.tween_property(punch_pop, "modulate:a", 0.0, 0.35)


func _update_aim(delta: float) -> void :
	if aim == null or not aim.visible or player_ctrl == null:
		return
	var pv: = player_ctrl.flick_preview()
	aim.vec = aim.vec.lerp(pv["vec"], clampf(delta * 18.0, 0.0, 1.0))
	aim.kind = str(pv["kind"])
	aim.body = bool(pv["body"])
	aim.power = bool(pv["power"])
	aim.flash = maxf(0.0, aim.flash - delta * 2.0)
	if player_ctrl.last_thrown(0.05) != "":
		aim.flash = 1.0
	aim.queue_redraw()
	var lead_n: String = Punches.SHORT_RU[PlayerController.punch_for(aim.kind, true)]
	var rear_n: String = Punches.SHORT_RU[PlayerController.punch_for(aim.kind, false)]
	var suffix: = " В КОРПУС" if aim.body else ""
	var pw: = "СИЛОВОЙ " if aim.power else ""
	aim_label.text = "ЛКМ: %s%s%s     ПКМ: %s%s%s" % [pw, lead_n, suffix, pw, rear_n, suffix]


func _update_hints(delta: float) -> void :
	_hint_t += delta
	if hint_panel.visible and not _hint_pinned and _hint_t > 15.0:
		var a: = clampf(1.0 - (_hint_t - 15.0), 0.0, 1.0)
		hint_panel.modulate.a = a
		if a <= 0.0:
			hint_panel.visible = false
			hint_panel.modulate.a = 1.0
	hint_small.visible = not hint_panel.visible




func setup(red: Fighter, blue: Fighter, health_visible: bool) -> void :
	fighters = [red, blue]
	show_health = health_visible
	for i in 2:
		var f: Fighter = fighters[i]
		var tag: = "  (ВЫ)" if f.is_player else ""
		if i == 0:
			name_labels[i].text = Roster.display_full(f.def) + tag
		else:
			name_labels[i].text = tag.strip_edges() + ("  " if tag != "" else "") + Roster.display_full(f.def)
		var hb: StatBar = bars["%d_head" % i]
		var bb: StatBar = bars["%d_body" % i]
		hb.visible = show_health and not f.is_bag
		bb.visible = show_health and not f.is_bag
		(bars["%d_stam" % i] as Control).visible = not f.is_bag
		name_labels[i].visible = not f.is_bag


func update_hud(_delta: float, round_num: int, total_rounds: int, time_left: float) -> void :
	round_label.text = "РАУНД %d / %d" % [round_num, total_rounds]
	clock_label.text = Game.fmt_time(time_left)
	clock_label.add_theme_color_override("font_color", Game.ACCENT_RED if time_left <= 10.0 else Game.TEXT)
	for i in fighters.size():
		var f: Fighter = fighters[i]
		var hb: StatBar = bars["%d_head" % i]
		var bb: StatBar = bars["%d_body" % i]
		var sb: StatBar = bars["%d_stam" % i]
		hb.set_values(f.head_ratio(), f.head_max_ratio())
		bb.set_values(f.body_ratio(), 1.0)
		sb.set_values(f.stamina_ratio(), f.stamina_max_ratio())
		sb.fill_color = Color(0.25, 0.75, 0.35) if f.stamina > 30.0 else Color(0.9, 0.7, 0.15)
		var gb: GuardBar = bars["%d_guard" % i]
		var gv: = f.guard_ratio()
		var broken: = f.is_guard_broken()
		if absf(gb.value - gv) > 0.004 or broken or gb.broken != broken:
			gb.value = gv
			gb.broken = broken
			gb.queue_redraw()
		(gb.get_parent() as Control).visible = not f.is_bag
	if _getup_active:
		_update_getup(_delta)
	_update_hints(_delta)
	_update_aim(_delta)


func flash_message(text: String, color: Color = Game.TEXT, font_size: int = 110, duration: float = 1.1) -> void :
	message_label.text = text
	message_label.add_theme_font_size_override("font_size", font_size)
	message_label.add_theme_color_override("font_color", color)
	if _msg_tween and _msg_tween.is_valid():
		_msg_tween.kill()
	message_label.modulate.a = 1.0
	message_label.scale = Vector2(1.35, 1.35)
	_msg_tween = create_tween().set_ignore_time_scale(true)
	_msg_tween.tween_property(message_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_msg_tween.tween_interval(duration)
	_msg_tween.tween_property(message_label, "modulate:a", 0.0, 0.35)


func feed_message(text: String, color: Color = Game.TEXT) -> void :
	var l: = _label(text, 30, color, 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feed.add_child(l)
	if feed.get_child_count() > 4:
		feed.get_child(0).queue_free()
	var tw: = l.create_tween().set_ignore_time_scale(true)
	tw.tween_interval(1.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)


func show_count(n: int) -> void :
	count_label.visible = true
	count_label.text = str(n)
	count_label.scale = Vector2(1.6, 1.6)
	count_label.modulate = Color(1, 1, 1, 1) if n < 8 else Color(1, 0.35, 0.3, 1)
	var tw: = count_label.create_tween().set_ignore_time_scale(true)
	tw.tween_property(count_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_count() -> void :
	count_label.visible = false


func set_vision(vignette: float, blur: float) -> void :
	var on: = vignette > 0.01 or blur > 0.01
	vignette_rect.visible = on
	if on:
		vignette_mat.set_shader_parameter("vignette", clampf(vignette, 0.0, 1.0))
		vignette_mat.set_shader_parameter("blur", clampf(blur, 0.0, 1.0))


func set_fade(alpha: float) -> void :
	fade_rect.color = Color(0, 0, 0, alpha)


func fade_to(alpha: float, duration: float) -> Tween:
	var tw: = create_tween().set_ignore_time_scale(true)
	tw.tween_property(fade_rect, "color:a", alpha, duration)
	return tw


func toggle_hints() -> void :
	hint_panel.visible = not hint_panel.visible
	hint_panel.modulate.a = 1.0
	_hint_pinned = hint_panel.visible
	hint_small.visible = not hint_panel.visible


func set_clock_visible(v: bool) -> void :
	var top: = round_label.get_parent() as Control
	if top:
		top.visible = v




var _plate: Control
var _plate_tw: Tween


func show_plate(tag: String, title: String, sub: String, color: Color, duration: float = 3.4) -> void :
	if _plate and is_instance_valid(_plate):
		_plate.queue_free()
	_plate = Control.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_plate, Control.PRESET_BOTTOM_LEFT, 120, -300, 1300, -120)
	root.add_child(_plate)
	var bg: = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.03, 0.82)
	bg.position = Vector2(0, 46)
	bg.size = Vector2(1080, 130)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_child(bg)
	var bar: = ColorRect.new()
	bar.color = color
	bar.position = Vector2(0, 46)
	bar.size = Vector2(12, 130)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_child(bar)
	var tagbg: = ColorRect.new()
	tagbg.color = color
	tagbg.position = Vector2(0, 0)
	tagbg.size = Vector2(330, 46)
	tagbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_child(tagbg)
	var lt: = _label(tag, 28, Color(1, 1, 1), 0)
	lt.position = Vector2(18, 4)
	_plate.add_child(lt)
	var l1: = _label(title, 58, Color(1, 1, 1), 4)
	l1.position = Vector2(34, 52)
	_plate.add_child(l1)
	var l2: = _label(sub, 30, Color(0.82, 0.84, 0.9), 2)
	l2.position = Vector2(36, 126)
	_plate.add_child(l2)
	if Game.title_font:
		for l in [lt, l1]:
			(l as Label).add_theme_font_override("font", Game.title_font)
	_plate.modulate.a = 0.0
	_plate.position.x -= 60.0
	if _plate_tw and _plate_tw.is_valid():
		_plate_tw.kill()
	_plate_tw = create_tween().set_ignore_time_scale(true)
	_plate_tw.set_parallel(true)
	_plate_tw.tween_property(_plate, "modulate:a", 1.0, 0.3)
	_plate_tw.tween_property(_plate, "position:x", _plate.position.x + 60.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_plate_tw.set_parallel(false)
	_plate_tw.tween_interval(duration)
	_plate_tw.tween_property(_plate, "modulate:a", 0.0, 0.35)



func set_cinematic(on: bool) -> void :
	if hint_panel:
		hint_panel.visible = not on
	if hint_small:
		hint_small.visible = not on
	if aim:
		aim.visible = not on and Game.setting_b("mouse_punch")


func set_top_visible(v: bool) -> void :
	for nl in name_labels:
		var box: = nl.get_parent() as Control
		if box:
			box.visible = v
	var top: = round_label.get_parent() as Control
	if top:
		top.visible = v




func getup_begin(knockdowns: int, damage_ratio: float) -> void :
	_getup_active = true
	_getup_t = _rng.randf() * TAU
	_getup_hits = 0
	_getup_needed = 3
	_getup_speed = 3.0 + 0.7 * float(knockdowns - 1) + damage_ratio * 1.2
	getup_bar.zone_width = clampf(0.26 - 0.05 * float(knockdowns - 1) - damage_ratio * 0.08, 0.08, 0.26)
	_new_zone()
	getup_panel.visible = true
	_update_hits()


func getup_end() -> void :
	_getup_active = false
	getup_panel.visible = false


func getup_is_active() -> bool:
	return _getup_active


func getup_press() -> void :
	if not _getup_active:
		return
	var d: = absf(getup_bar.needle - getup_bar.zone_center)
	if d <= getup_bar.zone_width * 0.5:
		_getup_hits += 1
		Sfx.play("tick", -4.0, 0.0, 1.4)
		if _getup_hits >= _getup_needed:
			_getup_active = false
			getup_panel.visible = false
			getup_success.emit()
			return
		_new_zone()
	else:
		_getup_speed += 0.35
		getup_info.text = "Мимо! Соберись..."
		Sfx.play("block", -6.0)
	_update_hits()


func _new_zone() -> void :
	var w: = getup_bar.zone_width
	getup_bar.zone_center = _rng.randf_range(w * 0.5 + 0.03, 1.0 - w * 0.5 - 0.03)
	getup_info.text = "Жми ПРОБЕЛ / A, когда стрелка в зелёной зоне"


func _update_hits() -> void :
	var s: = ""
	for i in _getup_needed:
		s += ("● " if i < _getup_hits else "○ ")
	getup_hits_label.text = s.strip_edges()


func _update_getup(delta: float) -> void :
	_getup_t += delta * _getup_speed
	getup_bar.needle = 0.5 + 0.5 * sin(_getup_t)
	getup_bar.queue_redraw()
