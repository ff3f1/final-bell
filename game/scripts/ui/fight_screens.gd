class_name FightScreens
extends CanvasLayer


var fight: FightScene
var root: Control
var current: Control
var _pts: = {"health": 0, "stamina": 0, "cut": 0}
var _pts_left: = 3
var _pts_labels: = {}
var _pts_left_label: Label
var _mode: = ""


func _ready() -> void :
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Game.ui_theme
	root.add_to_group("nav_root")
	add_child(root)


func _clear() -> void :
	if current:
		current.queue_free()
		current = null
	_mode = ""



func _focus_later(b: Control, delay: float = 0.5) -> void :
	get_tree().create_timer(delay, true, false, true).timeout.connect( func():
		if is_instance_valid(b) and b.is_inside_tree() and b.is_visible_in_tree():
			var fo: = b.get_viewport().gui_get_focus_owner()
			if fo == null or not current or not current.is_ancestor_of(fo):
				b.grab_focus())


func _input(event: InputEvent) -> void :

	if current and event.is_echo() and event.is_action("ui_accept"):
		get_viewport().set_input_as_handled()


func _new_screen(dim: float = 0.55) -> Control:
	_clear()
	var c: = Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(c)
	UIKit.dim_background(c, dim)
	current = c
	return c


func _unhandled_input(event: InputEvent) -> void :
	if not current:
		return
	if _mode == "controls" and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		Sfx.play("tick", -12.0, 0.0, 1.2)
		show_pause()
		get_viewport().set_input_as_handled()
	elif _mode == "pause" and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		resume()
		get_viewport().set_input_as_handled()




func show_pause() -> void :
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var c: = _new_screen(0.6)
	_mode = "pause"
	var center: = UIKit.full_center(c)
	var p: = UIKit.panel()
	center.add_child(p)
	var v: = UIKit.vbox(14)
	p.add_child(v)
	v.add_child(UIKit.title("ПАУЗА", 80))
	var resume_btn: = UIKit.button("Продолжить", resume)
	v.add_child(resume_btn)
	v.add_child(UIKit.button("Управление", _show_controls))
	if fight and fight.player:
		v.add_child(UIKit.button("Сдаться", _forfeit))
	v.add_child(UIKit.button("В главное меню", _quit_to_menu))
	resume_btn.grab_focus()
	UIKit.hint_bar(c, [["↑↓", "Навигация"], ["Enter", "Выбрать"], ["Esc", "Продолжить бой", "B / START"]])


func resume() -> void :
	_clear()
	get_tree().paused = false


func _show_controls() -> void :
	var c: = _new_screen(0.75)
	_mode = "controls"
	var center: = UIKit.full_center(c)
	var p: = UIKit.panel()
	center.add_child(p)
	var v: = UIKit.vbox(14)
	p.add_child(v)
	v.add_child(UIKit.title("УПРАВЛЕНИЕ", 56))

	var sc: = UIKit.nav_scroll(Vector2(1300, 680))
	v.add_child(sc)
	var rt: = RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.text = UIKit.controls_text()
	rt.scroll_active = false
	rt.fit_content = true
	rt.custom_minimum_size = Vector2(1270, 0)
	rt.add_theme_font_size_override("normal_font_size", 22)
	rt.add_theme_font_size_override("bold_font_size", 24)
	sc.add_child(rt)
	var back: = UIKit.button("Назад", show_pause)
	v.add_child(back)
	back.grab_focus()
	UIKit.hint_bar(c, [["↑↓", "Прокрутка"], ["Enter", "Выбрать"], ["Esc", "Назад"]])


func _forfeit() -> void :
	resume()
	if fight:
		fight.forfeit()


func _quit_to_menu() -> void :
	resume()
	if fight:
		fight.exit_to_menu()




func show_corner(data: Dictionary) -> void :
	var c: = _new_screen(0.45)
	_mode = "corner"
	var center: = UIKit.full_center(c)
	var p: = UIKit.panel()
	center.add_child(p)
	var v: = UIKit.vbox(16)
	p.add_child(v)
	v.add_child(UIKit.title("УГОЛ  •  ПОСЛЕ РАУНДА %d" % int(data["round"]), 52))

	var cols: = UIKit.hbox(40)
	v.add_child(cols)


	var left: = UIKit.vbox(8)
	left.custom_minimum_size = Vector2(520, 0)
	cols.add_child(left)
	left.add_child(UIKit.label("Раунд в цифрах", 28, Game.ACCENT))
	var me: Dictionary = data["me"]
	var op: Dictionary = data["opp"]
	left.add_child(_stat_line("", "Ты", "Он", true))
	left.add_child(_stat_line("Выброшено", str(me["thrown"]), str(op["thrown"])))
	left.add_child(_stat_line("Попало", str(me["landed"]), str(op["landed"])))
	left.add_child(_stat_line("Силовых попало", str(me["power_landed"]), str(op["power_landed"])))
	left.add_child(_stat_line("В корпус", str(me["body_landed"]), str(op["body_landed"])))
	left.add_child(_stat_line("Контратаки", str(me["counters"]), str(op["counters"])))
	left.add_child(_stat_line("Нокдауны", str(me["kd_scored"]), str(op["kd_scored"])))
	var cards: Array = data["last_cards"]
	if cards.size() > 0:
		var parts: Array = []
		for card in cards:
			var pair: Array = card
			parts.append("%d-%d" % [int(pair[0]), int(pair[1])])
		left.add_child(UIKit.label("Судьи за раунд:  " + "   ".join(PackedStringArray(parts)), 24, Game.TEXT_DIM))


	var right: = UIKit.vbox(10)
	right.custom_minimum_size = Vector2(620, 0)
	cols.add_child(right)
	right.add_child(UIKit.label("Тренер говорит:", 28, Game.ACCENT))
	for tip in data["advice"]:
		right.add_child(UIKit.wrap_label("— " + str(tip), 23))
	right.add_child(HSeparator.new())
	right.add_child(UIKit.label("Работа секунданта (3 очка)", 26, Game.ACCENT))
	_pts = {"health": 0, "stamina": 0, "cut": 0}
	_pts_left = 3
	_pts_labels = {}
	right.add_child(_pts_row("health", "Привести в чувство (здоровье)", float(data["head"])))
	right.add_child(_pts_row("stamina", "Отдышаться (выносливость)", float(data["stamina"])))
	right.add_child(_pts_row("cut", "Заняться рассечением", 1.0 - float(data["cut"]) / 100.0))
	_pts_left_label = UIKit.label("", 22, Game.TEXT_DIM)
	right.add_child(_pts_left_label)
	_refresh_pts()

	var go: = UIKit.button("В бой", _corner_continue, 420)
	var hb: = UIKit.hbox()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(go)
	v.add_child(hb)
	_focus_later(go)


func _stat_line(name_text: String, a: String, b: String, header: bool = false) -> HBoxContainer:
	var h: = UIKit.hbox(10)
	var col: = Game.ACCENT if header else Game.TEXT
	var l: = UIKit.label(name_text, 23, Game.TEXT_DIM)
	l.custom_minimum_size = Vector2(260, 0)
	h.add_child(l)
	var la: = UIKit.label(a, 23, col, HORIZONTAL_ALIGNMENT_CENTER)
	la.custom_minimum_size = Vector2(110, 0)
	h.add_child(la)
	var lb: = UIKit.label(b, 23, col, HORIZONTAL_ALIGNMENT_CENTER)
	lb.custom_minimum_size = Vector2(110, 0)
	h.add_child(lb)
	return h


func _pts_row(key: String, text: String, ratio: float) -> HBoxContainer:
	var h: = UIKit.hbox(10)
	var l: = UIKit.label(text, 22)
	l.custom_minimum_size = Vector2(360, 0)
	h.add_child(l)
	h.add_child(UIKit.stat_bar(int(ratio * 100.0), Color(0.86, 0.2, 0.15) if key != "stamina" else Color(0.3, 0.75, 0.35), 90.0))
	h.add_child(UIKit.small_button("−", func(): _change_pts(key, -1)))
	var val: = UIKit.label("0", 26, Game.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	val.custom_minimum_size = Vector2(36, 0)
	h.add_child(val)
	_pts_labels[key] = val
	h.add_child(UIKit.small_button("+", func(): _change_pts(key, 1)))
	return h


func _change_pts(key: String, d: int) -> void :
	var cur: int = _pts[key]
	if d > 0 and _pts_left <= 0:
		return
	if d < 0 and cur <= 0:
		return
	_pts[key] = cur + d
	_pts_left -= d
	_refresh_pts()


func _refresh_pts() -> void :
	for k in _pts_labels.keys():
		var l: Label = _pts_labels[k]
		l.text = str(_pts[k])
	if _pts_left_label:
		_pts_left_label.text = "Осталось очков: %d   (нераспределённые уйдут в здоровье)" % _pts_left


func _corner_continue() -> void :
	var h: int = int(_pts["health"]) + _pts_left
	var s: int = _pts["stamina"]
	var cut: int = _pts["cut"]
	_clear()
	if fight:
		fight.corner_done(h, s, cut)




func show_results(r: Dictionary) -> void :
	var c: = _new_screen(0.72)
	_mode = "results"
	var red: Dictionary = r["red"]
	var blue: Dictionary = r["blue"]
	var winner: = int(r["winner"])
	var head: = "НИЧЬЯ"
	var head_col: = Game.TEXT
	if winner >= 0:
		var wdef: Dictionary = red if winner == 0 else blue
		head = "ПОБЕДИТЕЛЬ: " + str(wdef.get("name", "")).to_upper()
		head_col = UIKit.GOLD
		if not bool(r["spectator"]):
			if winner == int(r["player_corner"]):
				head = "ПОБЕДА!"
			else:
				head = "ПОРАЖЕНИЕ"
				head_col = Game.ACCENT_RED
	var top: = UIKit.vbox(2)
	top.position = Vector2(0, 40)
	top.size = Vector2(1920, 0)
	top.custom_minimum_size = Vector2(1920, 0)
	c.add_child(top)
	var ht: = UIKit.tlabel(head, 96, head_col, HORIZONTAL_ALIGNMENT_CENTER)
	ht.add_theme_constant_override("outline_size", 12)
	ht.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	top.add_child(ht)
	var method_line: = "%s  •  РАУНД %d, %s" % [str(r["method"]).to_upper(), int(r["round"]), str(r["time"])]
	if bool(r["decision"]):
		method_line = str(r["method"]).to_upper()
	top.add_child(UIKit.label(method_line, 26, Game.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	UIKit.intro(top, 0.0)


	var panel: = UIKit.card(0.0, Color(0.03, 0.035, 0.05, 0.94), Color(1, 1, 1, 0.08), 24)
	panel.position = Vector2(70, 200)
	panel.custom_minimum_size = Vector2(1060, 0)
	c.add_child(panel)
	var pv: = UIKit.vbox(10)
	panel.add_child(pv)
	var names: = UIKit.hbox(12)
	pv.add_child(names)
	names.add_child(UIKit.portrait(str(red.get("model", "")), Vector2(70, 84)))
	var rn: = UIKit.tlabel(_short(red).to_upper(), 34, UIKit.RED.lightened(0.25))
	rn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	names.add_child(rn)
	var bn: = UIKit.tlabel(_short(blue).to_upper(), 34, UIKit.BLUE.lightened(0.3), HORIZONTAL_ALIGNMENT_RIGHT)
	bn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	names.add_child(bn)
	names.add_child(UIKit.portrait(str(blue.get("model", "")), Vector2(70, 84), true))
	var totals: Array = r["totals"]
	var a: Dictionary = totals[0]
	var b: Dictionary = totals[1]
	var rows: = [
		["ВЫБРОШЕНО", float(a["thrown"]), float(b["thrown"]), str(a["thrown"]), str(b["thrown"])], 
		["ПОПАЛО", float(a["landed"]), float(b["landed"]), str(a["landed"]), str(b["landed"])], 
		["ТОЧНОСТЬ", _acc(a), _acc(b), _pct(a), _pct(b)], 
		["СИЛОВЫЕ", float(a["power_landed"]), float(b["power_landed"]), "%d/%d" % [int(a["power_landed"]), int(a["power_thrown"])], "%d/%d" % [int(b["power_landed"]), int(b["power_thrown"])]], 
		["ДЖЕБЫ", float(a["jab_landed"]), float(b["jab_landed"]), "%d/%d" % [int(a["jab_landed"]), int(a["jab_thrown"])], "%d/%d" % [int(b["jab_landed"]), int(b["jab_thrown"])]], 
		["В КОРПУС", float(a["body_landed"]), float(b["body_landed"]), str(a["body_landed"]), str(b["body_landed"])], 
		["КОНТРАТАКИ", float(a["counters"]), float(b["counters"]), str(a["counters"]), str(b["counters"])], 
		["ПАРИРОВАНИЯ", float(a["parries"]), float(b["parries"]), str(a["parries"]), str(b["parries"])], 
		["НОКДАУНЫ", float(a["kd_scored"]), float(b["kd_scored"]), str(a["kd_scored"]), str(b["kd_scored"])], 
	]
	for row in rows:
		pv.add_child(_dual_bar(str(row[0]), float(row[1]), float(row[2]), str(row[3]), str(row[4])))
	UIKit.intro(panel, -50.0, 0.05)


	var side: = UIKit.vbox(14)
	side.position = Vector2(1170, 200)
	c.add_child(side)
	var jc: = UIKit.card(0.0, Color(0.03, 0.035, 0.05, 0.94), Color(1, 1, 1, 0.08), 20)
	jc.custom_minimum_size = Vector2(680, 0)
	side.add_child(jc)
	var jv: = UIKit.vbox(6)
	jc.add_child(jv)
	jv.add_child(UIKit.tlabel("ЗАПИСКИ СУДЕЙ", 26, UIKit.GOLD))
	var jt: Array = r["judge_totals"]
	var cards: Array = r["cards"]
	var any_scored: = false
	for j in jt.size():
		var pair: Array = jt[j]
		var card: Array = cards[j]
		if card.size() == 0:
			continue
		any_scored = true
		var jd: Dictionary = Judges.JUDGES[j]
		var jh: = UIKit.hbox(12)
		var jn: = UIKit.label(str(jd["name"]), 20, Game.TEXT_DIM)
		jn.custom_minimum_size = Vector2(230, 0)
		jh.add_child(jn)
		var sc: = UIKit.tlabel("%d — %d" % [int(pair[0]), int(pair[1])], 26, Game.TEXT)
		sc.custom_minimum_size = Vector2(120, 0)
		jh.add_child(sc)
		var rl: Array = []
		for rr in card:
			var rp: Array = rr
			rl.append("%d-%d" % [int(rp[0]), int(rp[1])])
		jh.add_child(UIKit.label("  ".join(PackedStringArray(rl)), 16, Game.TEXT_DIM))
		jv.add_child(jh)
	if not any_scored:
		jv.add_child(UIKit.label("Бой закончился до первого гонга.", 20, Game.TEXT_DIM))
	var best: Array = r["best"]
	for i in 2:
		var bp: Dictionary = best[i]
		if bp.has("name"):
			jv.add_child(UIKit.label("Лучший удар — %s: %s (%d р.)" % [_short(red if i == 0 else blue), str(bp["name"]).to_lower(), int(bp["round"])], 18, Game.TEXT))
	if r.has("career_summary") and not (r["career_summary"] as Dictionary).is_empty():
		side.add_child(_career_panel(r["career_summary"]))
	if r.has("tournament_summary") and not (r["tournament_summary"] as Dictionary).is_empty():
		side.add_child(_tournament_panel(r["tournament_summary"]))
	UIKit.intro(side, 50.0, 0.1)


	var buttons: = UIKit.hbox(20)
	buttons.position = Vector2(70, 960)
	c.add_child(buttons)
	var first: Button
	if bool(r["career"]):
		first = UIKit.sbutton("Продолжить карьеру", _to_menu, 420, true, 28)
		buttons.add_child(first)
	elif r.has("tournament_summary"):
		first = UIKit.sbutton("К сетке турнира", _to_menu, 400, true, 28)
		buttons.add_child(first)
	else:
		first = UIKit.sbutton("Реванш", _rematch, 300, true, 28)
		buttons.add_child(first)
		buttons.add_child(UIKit.sbutton("В меню", _to_menu, 280))
	var hb: = UIKit.hint_bar(c, [["↑↓←→", "Навигация"], ["Enter", "Выбрать"]])
	hb.offset_left = 900
	_focus_later(first, 0.8)


func _acc(d: Dictionary) -> float:
	var t: = int(d["thrown"])
	return 0.0 if t == 0 else float(d["landed"]) / float(t) * 100.0



func _dual_bar(title: String, va: float, vb: float, ta: String, tb: String) -> Control:
	var h: = UIKit.hbox(10)
	var la: = UIKit.tlabel(ta, 24, Game.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	la.custom_minimum_size = Vector2(110, 0)
	h.add_child(la)
	var mx: = maxf(maxf(va, vb), 0.001)
	h.add_child(_bar(va / mx, UIKit.RED, true))
	var t: = UIKit.label(title, 16, Game.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	t.custom_minimum_size = Vector2(170, 0)
	t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(t)
	h.add_child(_bar(vb / mx, UIKit.BLUE, false))
	var lb: = UIKit.tlabel(tb, 24, Game.TEXT)
	lb.custom_minimum_size = Vector2(110, 0)
	h.add_child(lb)
	return h


func _bar(k: float, col: Color, right_align: bool) -> Control:
	var bg: = ColorRect.new()
	bg.color = Color(1, 1, 1, 0.06)
	bg.custom_minimum_size = Vector2(300, 14)
	bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fill: = ColorRect.new()
	fill.color = col
	var w: = 300.0 * clampf(k, 0.0, 1.0)
	fill.size = Vector2(w, 14)
	fill.position = Vector2(300.0 - w if right_align else 0.0, 0)
	bg.add_child(fill)
	return bg


func _career_panel(s: Dictionary) -> Control:
	var p: = UIKit.card(0.0, Color(0.1, 0.075, 0.03, 0.95), UIKit.GOLD, 20)
	p.custom_minimum_size = Vector2(680, 0)
	var v: = UIKit.vbox(6)
	p.add_child(v)
	v.add_child(UIKit.tlabel("КАРЬЕРА", 26, UIKit.GOLD))
	var h: = UIKit.hbox(40)
	v.add_child(h)
	h.add_child(_kv("ГОНОРАР", "$" + CareerUI._money(int(s.get("money", 0))), Game.TEXT))
	h.add_child(_kv("СЛАВА", "%+d" % int(round(float(s.get("fame", 0.0)))), Game.TEXT))
	var rb: = int(s.get("rank_before", 0))
	var ra: = int(s.get("rank_after", rb))
	var arrow: = "  ▲" if ra < rb else ("  ▼" if ra > rb else "")
	var rc: = Color(0.4, 0.9, 0.45) if ra < rb else (Game.ACCENT_RED if ra > rb else Game.TEXT)
	h.add_child(_kv("РЕЙТИНГ", "№%d → №%d%s" % [rb, ra, arrow], rc))
	if str(s.get("belt", "")) != "":
		v.add_child(UIKit.tlabel("★ " + str(s["belt"]).to_upper(), 24, UIKit.GOLD))
	return p


func _tournament_panel(s: Dictionary) -> Control:
	var p: = UIKit.card(0.0, Color(0.06, 0.05, 0.1, 0.95), Color(0.6, 0.45, 0.95), 20)
	p.custom_minimum_size = Vector2(680, 0)
	var v: = UIKit.vbox(6)
	p.add_child(v)
	v.add_child(UIKit.tlabel("ТУРНИР", 26, Color(0.75, 0.62, 1.0)))
	var t: = ""
	if bool(s.get("champion", false)):
		t = "ТЫ — ПОБЕДИТЕЛЬ ТУРНИРА! КУБОК ТВОЙ"
	elif bool(s.get("out", false)):
		t = "Турнир окончен: выбыл. Сетка досчитана до финала"
	else:
		t = "Проходишь дальше. Следующая стадия: " + str(s.get("stage", "")).to_lower()
	v.add_child(UIKit.wrap_label(t, 22, Game.TEXT))
	return p


func _kv(k: String, val: String, col: Color) -> Control:
	var v: = UIKit.vbox(0)
	v.add_child(UIKit.label(k, 15, Game.TEXT_DIM))
	v.add_child(UIKit.tlabel(val, 32, col))
	return v


static func _short(def: Dictionary) -> String:
	var nick: String = str(def.get("nick", ""))
	if nick != "":
		return nick
	var full: String = str(def.get("name", "?"))
	var parts: = full.split(" ", false)
	return parts[parts.size() - 1] if parts.size() > 0 else full


func _pct(d: Dictionary) -> String:
	var t: = int(d["thrown"])
	if t == 0:
		return "—"
	return "%d%%" % int(round(100.0 * float(d["landed"]) / float(t)))


func _rematch() -> void :
	_clear()
	if fight:
		fight.rematch()


func _to_menu() -> void :
	_clear()
	if fight:
		fight.exit_to_menu()
