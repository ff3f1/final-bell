class_name CareerUI
extends RefCounted



const TABS: = [["overview", "Обзор"], ["fights", "Бои"], ["camp", "Лагерь"], ["ranking", "Рейтинг"], 
	["look", "Внешность"], ["history", "История"], ["news", "Новости"], ["weight", "Весовая"]]
const SKIN_STEPS: = [0.82, 0.9, 1.0, 1.08, 1.16]
const TRIMS: = [Color(0.93, 0.72, 0.25), Color(0.95, 0.95, 0.95), Color(0.06, 0.06, 0.07), Color(0.75, 0.08, 0.08), 
	Color(0.1, 0.25, 0.7), Color(0.1, 0.5, 0.25)]
const BOOTS: = [Color(0.06, 0.06, 0.07), Color(0.95, 0.95, 0.95), Color(0.75, 0.08, 0.08), Color(0.1, 0.22, 0.62), 
	Color(0.85, 0.65, 0.12)]

var menu: MainMenu
var tab: = "overview"
var camp_pick: Array = []
var camp_report: Array = []
var message: = ""
var cr: = {}
var _scroll: ScrollContainer
var _scroll_v: = 0


func _init(m: MainMenu) -> void :
	menu = m


func show() -> void :
	if Career.has():
		show_hub()
	else:
		show_create()


func _scr(dark: float = 0.7, key: String = "") -> Control:
	return menu._screen(dark, key)




func _cr_defaults() -> void :
	if not cr.is_empty():
		return
	var d: = Divisions.DEFAULT
	var hr: Array = Divisions.LIST[d]["h"]
	cr = {"name": "Ivan Volkov", "nick": "Wolf", "country": "Russia", "division": d, 
		"height": snappedf((float(hr[0]) + float(hr[1])) * 0.5, 0.01), "style": "balanced", "stance": 1, 
		"guard": "classic", "face": 0, "trunks": 0, "trim": 0, "gloves": 0, "boots": 0, "skin": 2}


func _cr_def() -> Dictionary:
	var base: = Roster.career_base_stats(str(cr["style"]))
	var d: = int(cr["division"])
	var def: = {
		"id": "career", "model": Divisions.player_model(int(cr["face"]), d), "name": cr["name"], "nick": cr["nick"], 
		"country": cr["country"], "record": "0-0-0", "style": cr["style"], "stance": cr["stance"], "height": cr["height"], 
		"division": d, "guard": cr["guard"], 
		"trunks": Career.TRUNK_PALETTE[int(cr["trunks"])], "trim": TRIMS[int(cr["trim"])], 
		"gloves": Career.TRUNK_PALETTE[int(cr["gloves"])], "boots": BOOTS[int(cr["boots"])], 
	}
	var k: = float(SKIN_STEPS[int(cr["skin"])])
	def["skin_tint"] = Color(k, k * 0.98 + 0.02, k * 0.97 + 0.03)
	def.merge(base, true)
	return def


func show_create() -> void :
	_cr_defaults()
	menu._back = menu.show_main
	var c: = _scr(0.55, "create")
	var head: = UIKit.header("НОВЫЙ БОЕЦ", "Создай боксёра: внешность, вес, стиль и стойка")
	MainMenu._place(head, 70, 40)
	c.add_child(head)
	var def: = _cr_def()
	var left: = Control.new()
	MainMenu._place(left, 70, 170)
	c.add_child(left)

	left.add_child(menu.fighter_card(def, UIKit.RED, "ТВОЙ БОЕЦ", false, false))
	var note: = UIKit.wrap_label("Начинаешь проспектом в самом низу рейтинга своей весовой. Бои, лагерь, гонорары и слава — дальше всё зависит от тебя.", 18, Game.TEXT_DIM)
	note.custom_minimum_size = Vector2(700, 0)
	note.position = Vector2(0, 500)
	left.add_child(note)

	var panel: = UIKit.card(0.0, Color(0.03, 0.035, 0.05, 0.88), Color(1, 1, 1, 0.08), 22)
	MainMenu._place(panel, 830, 170)
	panel.custom_minimum_size = Vector2(1020, 730)
	c.add_child(panel)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(980, 690)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	panel.add_child(_scroll)
	var v: = UIKit.vbox(16)
	v.custom_minimum_size = Vector2(950, 0)
	_scroll.add_child(v)


	var ne: = UIKit.name_field(str(cr["name"]), "Имя бойца (латиницей)", 24, func(t: String): _cr_text("name", t))
	v.add_child(UIKit.srow("Имя (латиницей)", ne, 280))
	var ke: = UIKit.name_field(str(cr["nick"]), "Прозвище", 16, func(t: String): _cr_text("nick", t))
	v.add_child(UIKit.srow("Прозвище", ke, 280))
	var countries: Array = Career.NAMES.keys()
	var cnames: Array = []
	for k in countries:
		cnames.append(UIKit.country_name(str(k)))
	v.add_child(UIKit.srow("Страна", UIKit.stepper(cnames, countries.find(cr["country"]), func(i: int):
		cr["country"] = countries[i]), 280))

	var dn: Array = []
	for d in Divisions.COUNT:
		dn.append(Divisions.name_of(d))
	v.add_child(UIKit.srow("Весовая", UIKit.stepper(dn, int(cr["division"]), _cr_set_div, 420), 280))
	var hr: Array = Divisions.LIST[int(cr["division"])]["h"]
	var hs: Array = []
	var h_cm: = int(round(float(hr[0]) * 100.0))
	while h_cm <= int(round(float(hr[1]) * 100.0)):
		hs.append("%d см" % h_cm)
		h_cm += 1
	var cur_h: = clampi(int(round(float(cr["height"]) * 100.0)) - int(round(float(hr[0]) * 100.0)), 0, hs.size() - 1)
	v.add_child(UIKit.srow("Рост", UIKit.stepper(hs, cur_h, func(i: int):
		cr["height"] = (float(hr[0]) * 100.0 + float(i)) / 100.0), 280))

	var sh: = UIKit.hbox(6)
	for sid in Roster.STYLE_ORDER:
		var s: String = sid
		sh.add_child(UIKit.chip(Roster.style_name(s), s == str(cr["style"]), func(): _cr_set("style", s), 18))
	v.add_child(UIKit.srow("Стиль", sh, 280))
	var sd: Dictionary = Roster.STYLES.get(str(cr["style"]), {})
	v.add_child(_indent(UIKit.label(str(sd.get("desc", "")), 17, Game.TEXT_DIM)))
	var st: = UIKit.hbox(6)
	st.add_child(UIKit.chip("Правша", int(cr["stance"]) == 1, func(): _cr_set("stance", 1), 18))
	st.add_child(UIKit.chip("Левша", int(cr["stance"]) == -1, func(): _cr_set("stance", -1), 18))
	v.add_child(UIKit.srow("Стойка", st, 280))
	var gn: Array = []
	for g in Guards.ORDER:
		gn.append(Guards.name_of(str(g)))
	v.add_child(UIKit.srow("Защита", UIKit.stepper(gn, Guards.ORDER.find(cr["guard"]), func(i: int): _cr_set("guard", Guards.ORDER[i]), 420), 280))
	v.add_child(_indent(UIKit.label(str(Guards.get_data(str(cr["guard"]))["desc"]), 17, Game.TEXT_DIM)))

	v.add_child(UIKit.label("ЛИЦО", 19, Game.TEXT_DIM))
	var grid: = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for f in 12:
		grid.add_child(_face_button(f, int(cr["division"]), f == int(cr["face"])))
	v.add_child(grid)
	v.add_child(UIKit.srow("Оттенок кожи", UIKit.stepper(["Светлее", "Чуть светлее", "Как есть", "Чуть темнее", "Темнее"], int(cr["skin"]), func(i: int): _cr_set("skin", i), 360), 280))

	v.add_child(_swatch_row("Трусы", Career.TRUNK_PALETTE, int(cr["trunks"]), "trunks"))
	v.add_child(_swatch_row("Кант и пояс", TRIMS, int(cr["trim"]), "trim"))
	v.add_child(_swatch_row("Перчатки", Career.TRUNK_PALETTE, int(cr["gloves"]), "gloves"))
	v.add_child(_swatch_row("Обувь", BOOTS, int(cr["boots"]), "boots"))
	v.add_child(UIKit.spacer(10))

	var go: = UIKit.sbutton("Начать карьеру", _create, 380, true, 30)
	MainMenu._place(go, 1920 - 70 - 380 - 250, 940)
	c.add_child(go)
	var back: = UIKit.sbutton("Назад", menu.show_main, 220)
	MainMenu._place(back, 1920 - 70 - 220, 945)
	c.add_child(back)
	ne.grab_focus()
	UIKit.hint_bar(c, [["↑↓←→", "Навигация"], ["Enter", "Выбрать"], ["Колесо", "Прокрутка"], ["Esc", "Назад"]])
	if menu.scene():
		menu.scene().show_single(def)
	_restore_scroll()


func _indent(c: Control) -> Control:
	var m: = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 296)
	m.add_child(c)
	return m


func _face_button(f: int, d: int, sel: bool) -> Control:
	var b: = Button.new()
	b.custom_minimum_size = Vector2(140, 170)
	b.flat = true
	var por: = UIKit.portrait(Divisions.player_model(f, d), Vector2(140, 170))
	por.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for ch in por.get_children():
		(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(por)
	var frame: = Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base_box: = UIKit.sbox(Color(0, 0, 0, 0), 0.0, UIKit.GOLD if sel else Color(1, 1, 1, 0.12), 3 if sel else 1, 0.0)
	var lit_box: = UIKit.sbox(Color(1, 0.85, 0.4, 0.12), 0.0, Color(1, 0.9, 0.55), 4, 0.0)
	frame.add_theme_stylebox_override("panel", base_box)
	b.add_child(frame)
	b.focus_entered.connect( func(): frame.add_theme_stylebox_override("panel", lit_box))
	b.focus_exited.connect( func(): frame.add_theme_stylebox_override("panel", base_box))
	b.pressed.connect( func(): _cr_set("face", f))
	return b


func _swatch_row(title: String, pal: Array, sel: int, key: String) -> Control:
	var h: = UIKit.hbox(8)
	for i in pal.size():
		var idx: = i
		h.add_child(UIKit.swatch(pal[i], i == sel, func(): _swatch_pick(key, idx), 40.0))
	return UIKit.srow(title, h, 280)



func _swatch_pick(key: String, idx: int) -> void :
	if Career.has() and tab == "look":
		var look: Dictionary = Game.career.get("look", Career.default_look())
		match key:
			"trunks":
				look["trunks"] = Career.TRUNK_PALETTE[idx]
			"gloves":
				look["gloves"] = Career.TRUNK_PALETTE[idx]
			"trim":
				look["trim"] = TRIMS[idx]
			"boots":
				look["boots"] = BOOTS[idx]
		Game.career["look"] = look
		Career.save()
		show_hub()
	else:
		_cr_set(key, idx)


func _save_scroll() -> void :
	if _scroll and is_instance_valid(_scroll):
		_scroll_v = _scroll.scroll_vertical


func _restore_scroll() -> void :
	if _scroll and _scroll_v > 0:
		var s: = _scroll
		var v: = _scroll_v
		s.call_deferred("set", "scroll_vertical", v)


func _cr_set(key: String, val: Variant) -> void :
	cr[key] = val
	_save_scroll()
	show_create()


func _cr_text(key: String, t: String) -> void :
	cr[key] = t
	_save_scroll()
	show_create()


func _refresh_create() -> void :
	_save_scroll()
	show_create.call_deferred()


func _cr_set_div(d: int) -> void :
	cr["division"] = d
	var hr: Array = Divisions.LIST[d]["h"]
	cr["height"] = snappedf((float(hr[0]) + float(hr[1])) * 0.5, 0.01)
	_save_scroll()
	show_create()


func _create() -> void :
	var nm: = str(cr["name"]).strip_edges()
	if nm == "":
		nm = "Ivan Volkov"
	var k: = float(SKIN_STEPS[int(cr["skin"])])
	var look: = {"face": int(cr["face"]), "trunks": Career.TRUNK_PALETTE[int(cr["trunks"])], "trim": TRIMS[int(cr["trim"])], 
		"gloves": Career.TRUNK_PALETTE[int(cr["gloves"])], "cuff": Color(0.95, 0.95, 0.95), "boots": BOOTS[int(cr["boots"])], 
		"skin_tint": k, "hair_tint": Color(1, 1, 1)}
	Career.create({"name": nm, "nick": str(cr["nick"]).strip_edges(), "country": cr["country"], "style": cr["style"], 
		"stance": cr["stance"], "height": cr["height"], "division": cr["division"], "guard": cr["guard"], "look": look})
	tab = "overview"
	cr = {}
	_scroll_v = 0
	show_hub()




func show_hub() -> void :
	menu._back = menu.show_main
	var c: = _scr(0.78, "hub:" + tab)
	menu._tabs_cb = _cycle_tab
	var gc: = Game.career
	var me: = Career.player_def()

	var top: = UIKit.hbox(22)
	MainMenu._place(top, 70, 34)
	c.add_child(top)
	top.add_child(UIKit.portrait(str(me["model"]), Vector2(118, 140)))
	var tv: = UIKit.vbox(0)
	top.add_child(tv)
	tv.add_child(UIKit.tlabel(str(gc["name"]).to_upper(), 54, Game.TEXT))
	var line: = UIKit.hbox(14)
	if str(gc.get("nick", "")) != "":
		line.add_child(UIKit.label("«%s»" % gc["nick"], 22, UIKit.GOLD))
	line.add_child(UIKit.label(Divisions.name_of(Career.my_div()).to_upper() + " ВЕС", 20, Game.TEXT))
	line.add_child(UIKit.label("№%d В РЕЙТИНГЕ" % Career.my_rank(), 20, UIKit.GOLD))
	var stat: = PanelContainer.new()
	stat.add_theme_stylebox_override("panel", UIKit.sbox(Color(0.75, 0.15, 0.13, 0.95), UIKit.SKEW, Color(0, 0, 0, 0), 0, 4.0))
	stat.add_child(UIKit.tlabel(Career.status().to_upper(), 18, Color.WHITE))
	line.add_child(stat)
	tv.add_child(line)
	var belts_me: = Career.belts_of("me")
	if not belts_me.is_empty():
		var bl: = UIKit.hbox(10)
		for k in belts_me:
			bl.add_child(_belt_badge(str(k)))
		tv.add_child(bl)

	var right: = UIKit.hbox(34)
	right.position = Vector2(1920 - 70 - 760, 44)
	c.add_child(right)
	right.add_child(_kpi("РЕКОРД", Career.record_str(gc["rec"]), "%d KO" % int(gc["rec"].get("ko", 0))))
	right.add_child(_kpi("ДЕНЬГИ", "$" + _money(int(gc["money"])), "лагерь ур. %d" % int(gc.get("camp_level", 1))))
	var fame: = _kpi("СЛАВА", "%d" % int(float(gc.get("fame", 0.0))), "")
	fame.add_child(UIKit.seg_bar(int(float(gc.get("fame", 0.0))), UIKit.GOLD, 150, 12))
	right.add_child(fame)
	right.add_child(_kpi("ДАТА", Career.date_str().to_upper(), "возраст %d" % int(float(gc.get("age", 21.0)))))

	var tabs: = UIKit.hbox(6)
	MainMenu._place(tabs, 70, 196)
	c.add_child(tabs)
	for t in TABS:
		var id: String = t[0]
		tabs.add_child(UIKit.chip(str(t[1]), id == tab, func(): _set_tab(id), 20, "tab:" + id))
	var area: = Control.new()
	MainMenu._place(area, 70, 262)
	area.custom_minimum_size = Vector2(1780, 640)
	c.add_child(area)
	match tab:
		"fights":
			_tab_fights(area)
		"camp":
			_tab_camp(area)
		"ranking":
			_tab_ranking(area)
		"look":
			_tab_look(area)
		"history":
			_tab_history(area)
		"news":
			_tab_news(area)
		"weight":
			_tab_weight(area)
		_:
			_tab_overview(area, me)
	UIKit.intro(area, 0.0)
	var back: = UIKit.sbutton("В меню", menu.show_main, 220)
	MainMenu._place(back, 70, 960)
	c.add_child(back)
	if message != "":
		var ml: = UIKit.label(message, 20, UIKit.GOLD)
		MainMenu._place(ml, 320, 975)
		c.add_child(ml)
		message = ""
	UIKit.hint_bar(c, MainMenu.HINTS_TABS).offset_left = 900

	var fo: = c.get_viewport().gui_get_focus_owner()
	if fo == null or not c.is_ancestor_of(fo):
		var chip: = MainMenu._find_nav_id(tabs, "tab:" + tab)
		if chip:
			chip.grab_focus()
	if menu.scene():
		menu.scene().show_single(me)


func _set_tab(id: String) -> void :
	tab = id
	show_hub()



func _cycle_tab(d: int) -> void :
	var ids: Array = []
	for t in TABS:
		ids.append(t[0])
	var ni: = posmod(ids.find(tab) + d, ids.size())
	var fo: = menu.get_viewport().gui_get_focus_owner()
	if fo and str(fo.get_meta("nav_id", "")).begins_with("tab:"):
		menu._want_focus_id = "tab:" + str(ids[ni])
	Sfx.play("tick", -14.0, 0.0, 1.5)
	_set_tab(str(ids[ni]))


func _kpi(title: String, value: String, sub: String) -> VBoxContainer:
	var v: = UIKit.vbox(0)
	v.add_child(UIKit.label(title, 15, Game.TEXT_DIM))
	v.add_child(UIKit.tlabel(value, 36, Game.TEXT))
	if sub != "":
		v.add_child(UIKit.label(sub, 15, Game.TEXT_DIM))
	return v


static func _money(n: int) -> String:
	var s: = str(absi(n))
	var out: = ""
	while s.length() > 3:
		out = " " + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


func _belt_badge(k: String) -> Control:
	var b: Dictionary = Career.BELTS[k]
	var p: = PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.sbox(Color(0.08, 0.07, 0.04, 0.95), UIKit.SKEW, b["color"], 2, 4.0))
	p.add_child(UIKit.tlabel("★ " + str(b["short"]), 18, b["color"]))
	return p




func _tab_overview(area: Control, me: Dictionary) -> void :
	area.add_child(menu.fighter_card(me, UIKit.RED, "ТВОЙ БОЕЦ"))
	var p: = UIKit.card(0.0, Color(0.03, 0.035, 0.05, 0.86), Color(1, 1, 1, 0.08), 24)
	p.position = Vector2(760, 0)
	p.custom_minimum_size = Vector2(1020, 480)
	area.add_child(p)
	var v: = UIKit.vbox(14)
	p.add_child(v)
	v.add_child(UIKit.tlabel("ПОЯСА " + Divisions.name_of(Career.my_div()).to_upper() + " ВЕСА", 30, UIKit.GOLD))
	var belts: = Career.belts_div()
	var rk: = Career.my_rank()
	for k in Career.BELT_ORDER:
		var b: Dictionary = Career.BELTS[k]
		var holder: = str(belts.get(k, ""))
		var h: = UIKit.hbox(16)
		h.add_child(_belt_badge(str(k)))
		var nm: = "ТЫ" if holder == "me" else str(Career.entry(holder).get("name", "вакантен"))
		var l: = UIKit.tlabel(nm.to_upper(), 28, UIKit.GOLD if holder == "me" else Game.TEXT)
		l.custom_minimum_size = Vector2(420, 0)
		h.add_child(l)
		var need: = "твой" if holder == "me" else ("бой за пояс доступен" if rk <= int(b["max_rank"]) else "нужно войти в топ-%d" % int(b["max_rank"]))
		h.add_child(UIKit.label(need, 18, Game.TEXT_DIM))
		v.add_child(h)
	v.add_child(UIKit.spacer(6))
	var gc: = Game.career
	v.add_child(UIKit.label("Износ: %d   •   Лучшая позиция: №%d   •   Боёв: %d" % [int(float(gc.get("wear", 0.0))), int(gc.get("best_rank", 99)), (gc.get("history", []) as Array).size()], 19, Game.TEXT_DIM))
	var offers: = Career.offers()
	if not offers.is_empty():
		var o: Dictionary = offers[0]
		var opp: = Career.entry(str(o["opp"]))
		var t: = "Следующий шаг: %s — %s, %d раундов, $%s" % ["ТИТУЛЬНЫЙ БОЙ" if str(o["title"]) != "" else "бой", str(opp.get("name", "?")), int(o["rounds"]), _money(int(o["purse"]))]
		v.add_child(UIKit.label(t, 20, Game.TEXT))
	var hb: = UIKit.hbox(12)
	v.add_child(hb)
	var go: = UIKit.sbutton("К предложениям", func(): _set_tab("fights"), 320, true)
	hb.add_child(go)
	hb.add_child(UIKit.sbutton("Лагерь", func(): _set_tab("camp"), 220))
	hb.add_child(UIKit.sbutton("Завершить карьеру", _confirm_retire, 330))
	go.grab_focus()


func _tab_fights(area: Control) -> void :
	var offers: = Career.offers()
	if offers.is_empty():
		area.add_child(UIKit.label("Предложений пока нет — проведи лагерь, промоутеры позвонят.", 22, Game.TEXT_DIM))
		return
	var h: = UIKit.hbox(18)
	area.add_child(h)
	var first: Button = null
	for i in offers.size():
		var o: Dictionary = offers[i]
		var opp: = Career.opponent_def(str(o["opp"]))
		var p: = UIKit.card(0.0, Color(0.03, 0.035, 0.05, 0.9), UIKit.GOLD if str(o["title"]) != "" else Color(1, 1, 1, 0.1), 16)
		p.custom_minimum_size = Vector2(425, 620)
		h.add_child(p)
		var v: = UIKit.vbox(6)
		p.add_child(v)
		if str(o["title"]) != "":
			var b: Dictionary = Career.BELTS[str(o["title"])]
			var tag: = ("ЗАЩИТА: " if bool(o.get("defense", false)) else "БОЙ ЗА ") + str(b["name"]).to_upper()
			v.add_child(UIKit.tlabel(tag, 20, b["color"]))
		else:
			var kind: = ["СЛАБЕЕ ТЕБЯ", "РАВНЫЙ БОЙ", "ШАНС ПОДНЯТЬСЯ"]
			var orank: = int(o.get("opp_rank", 20))
			var k2: = 1
			if orank > Career.my_rank() + 1:
				k2 = 0
			elif orank < Career.my_rank() - 1:
				k2 = 2
			v.add_child(UIKit.tlabel(str(kind[k2]), 20, Game.TEXT_DIM))
		var hp: = UIKit.hbox(12)
		hp.add_child(UIKit.portrait(str(opp.get("model", "")), Vector2(170, 210)))
		var iv: = UIKit.vbox(2)
		hp.add_child(iv)
		iv.add_child(UIKit.tlabel("№%d" % int(o.get("opp_rank", 0)), 40, UIKit.GOLD))
		iv.add_child(UIKit.tlabel(str(Roster.overall(opp)), 34, Game.TEXT))
		iv.add_child(UIKit.label("ОБЩИЙ", 14, Game.TEXT_DIM))
		iv.add_child(UIKit.label(str(opp.get("record", "")), 18, Game.TEXT))
		v.add_child(hp)
		v.add_child(UIKit.tlabel(str(opp.get("name", "?")).to_upper(), 30, Game.TEXT))
		if str(opp.get("nick", "")) != "":
			v.add_child(UIKit.label("«%s»" % opp["nick"], 18, UIKit.GOLD))
		v.add_child(UIKit.country_tag(str(opp.get("country", ""))))
		v.add_child(UIKit.label("%s  •  %s" % [Roster.style_name(str(opp.get("style", ""))), Guards.name_of(Guards.for_def(opp))], 17, Game.TEXT_DIM))
		v.add_child(UIKit.spacer(6))
		v.add_child(UIKit.label("Раундов: %d" % int(o["rounds"]), 19, Game.TEXT))
		v.add_child(UIKit.label("Гонорар: $" + _money(int(o["purse"])), 22, UIKit.GOLD))
		v.add_child(UIKit.label("Сложность ИИ: " + str(Game.DIFFICULTY_NAMES[Career.difficulty_vs(opp)]), 17, Game.TEXT_DIM))
		v.add_child(UIKit.spacer(8))
		var idx: = i
		var b2: = UIKit.sbutton("Принять бой", func(): Career.start_offer(idx), 380, true, 26)
		v.add_child(b2)
		if first == null:
			first = b2
	if first:
		first.grab_focus()


func _tab_camp(area: Control) -> void :
	var gc: = Game.career
	var done: = bool(gc.get("camp_done", false))
	var grid: = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	area.add_child(grid)
	for id in Career.CAMP_ORDER:
		var a: Dictionary = Career.CAMP[id]
		var sel: = camp_pick.has(id)
		var b: = Button.new()
		b.custom_minimum_size = Vector2(430, 160)
		b.disabled = done
		var col: = Color(0.12, 0.09, 0.04, 0.95) if sel else Color(0.03, 0.035, 0.05, 0.9)
		UIKit._btn_styles(b, col, Color(0.16, 0.12, 0.05, 0.96), 0.0, 14.0, UIKit.GOLD if sel else Color(1, 1, 1, 0.08))
		var v: = UIKit.vbox(4)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 18
		v.offset_top = 14
		v.add_child(UIKit.tlabel(str(a["name"]).to_upper(), 26, UIKit.GOLD if sel else Game.TEXT))
		v.add_child(UIKit.label(str(a["desc"]), 17, Game.TEXT_DIM))
		var extra: = ""
		if str(a["stat"]) != "":
			extra = "%s +%.1f" % [Career.stat_label(str(a["stat"])), Career.camp_gain(str(a["stat"]))]
		if int(a["cost"]) > 0:
			extra += ("   " if extra != "" else "") + "$" + _money(int(a["cost"]))
		v.add_child(UIKit.label(extra, 18, Game.TEXT))
		for ch in v.get_children():
			(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		var cid: String = id
		b.pressed.connect( func(): _camp_toggle(cid))
		grid.add_child(b)
	var bottom: = UIKit.vbox(8)
	bottom.position = Vector2(0, 360)
	area.add_child(bottom)
	if done:
		bottom.add_child(UIKit.tlabel("ЛАГЕРЬ ПРОВЕДЁН — ЖДЁТ БОЙ", 28, UIKit.GOLD))
	else:
		bottom.add_child(UIKit.label("Выбери до %d занятий (выбрано %d). Лагерь — один раз перед каждым боем." % [Career.CAMP_SLOTS, camp_pick.size()], 20, Game.TEXT_DIM))
	for ln in camp_report:
		bottom.add_child(UIKit.label("• " + str(ln), 20, Game.TEXT))
	var hb: = UIKit.hbox(12)
	bottom.add_child(hb)
	var run: = UIKit.sbutton("Провести лагерь", _run_camp, 340, true)
	run.disabled = done or camp_pick.is_empty()
	hb.add_child(run)
	var up: = Career.upgrade_camp_cost()
	if up > 0:
		var ub: = UIKit.sbutton("Улучшить зал — $" + _money(up), _upgrade_camp, 420)
		ub.disabled = int(gc["money"]) < up
		hb.add_child(ub)
	if not done:
		run.grab_focus()


func _camp_toggle(id: String) -> void :
	if camp_pick.has(id):
		camp_pick.erase(id)
	elif camp_pick.size() < Career.CAMP_SLOTS:
		camp_pick.append(id)
	show_hub()


func _run_camp() -> void :
	camp_report = Career.run_camp(camp_pick)
	Game.career["camp_done"] = true
	Career.save()
	camp_pick = []
	show_hub()


func _upgrade_camp() -> void :
	if Career.upgrade_camp():
		message = "Зал улучшен: занятия дают больше."
	show_hub()


func _tab_ranking(area: Control) -> void :
	var sc: = UIKit.nav_scroll(Vector2(1300, 640))
	area.add_child(sc)
	var my_row: Control = null
	var v: = UIKit.vbox(4)
	v.custom_minimum_size = Vector2(1270, 0)
	sc.add_child(v)
	var ranked: = Career.ranking()
	for i in ranked.size():
		var e: Dictionary = ranked[i]
		var id: = str(e["id"])
		var mine: = id == "me"
		var p: = PanelContainer.new()
		p.add_theme_stylebox_override("panel", UIKit.sbox(Color(0.14, 0.1, 0.03, 0.95) if mine else (Color(0.05, 0.055, 0.075, 0.9) if i % 2 == 0 else Color(0.035, 0.04, 0.055, 0.9)), 0.0, UIKit.GOLD if mine else Color(0, 0, 0, 0), 1 if mine else 0, 6.0))
		var h: = UIKit.hbox(16)
		p.add_child(h)
		var rl: = UIKit.tlabel("%d" % (i + 1), 28, UIKit.GOLD if i < 4 else Game.TEXT)
		rl.custom_minimum_size = Vector2(50, 0)
		h.add_child(rl)
		var model: = str(Career.player_def()["model"]) if mine else str(e.get("model", ""))
		h.add_child(UIKit.portrait(model, Vector2(44, 52)))
		var nm: = UIKit.tlabel(("ТЫ — " if mine else "") + str(e.get("name", "")).to_upper(), 26, UIKit.GOLD if mine else Game.TEXT)
		nm.custom_minimum_size = Vector2(470, 0)
		h.add_child(nm)
		var ct: = UIKit.country_tag(str(e.get("country", Game.career.get("country", ""))))
		ct.custom_minimum_size = Vector2(190, 0)
		h.add_child(ct)
		var rec: = UIKit.label(Career.record_str(e.get("rec", {})), 20, Game.TEXT)
		rec.custom_minimum_size = Vector2(110, 0)
		h.add_child(rec)
		var ovr: = Career.overall_me() if mine else Roster.overall(e)
		var ol: = UIKit.tlabel(str(ovr), 26, Game.TEXT_DIM)
		ol.custom_minimum_size = Vector2(60, 0)
		h.add_child(ol)
		for k in Career.belts_of(id):
			h.add_child(_belt_badge(str(k)))
		v.add_child(p)
		if mine:
			my_row = p

	if my_row:
		var row: = my_row
		menu.get_tree().create_timer(0.05, true, false, true).timeout.connect( func():
			if is_instance_valid(sc) and is_instance_valid(row):
				sc.scroll_vertical = maxi(int(row.position.y - sc.size.y * 0.4), 0))


func _tab_look(area: Control) -> void :
	var p: = UIKit.card(0.0, Color(0.03, 0.035, 0.05, 0.88), Color(1, 1, 1, 0.08), 24)
	p.custom_minimum_size = Vector2(1100, 0)
	area.add_child(p)
	var v: = UIKit.vbox(18)
	p.add_child(v)
	var look: Dictionary = Game.career.get("look", Career.default_look())
	v.add_child(_swatch_row("Трусы", Career.TRUNK_PALETTE, _find_col(Career.TRUNK_PALETTE, look.get("trunks", Color.RED)), "trunks"))
	v.add_child(_swatch_row("Кант и пояс", TRIMS, _find_col(TRIMS, look.get("trim", UIKit.GOLD)), "trim"))
	v.add_child(_swatch_row("Перчатки", Career.TRUNK_PALETTE, _find_col(Career.TRUNK_PALETTE, look.get("gloves", Color.RED)), "gloves"))
	v.add_child(_swatch_row("Обувь", BOOTS, _find_col(BOOTS, look.get("boots", Color.BLACK)), "boots"))
	var gn: Array = []
	for g in Guards.ORDER:
		gn.append(Guards.name_of(str(g)))
	v.add_child(UIKit.srow("Защита", UIKit.stepper(gn, Guards.ORDER.find(str(Game.career.get("guard", "classic"))), func(i: int):
		Game.career["guard"] = Guards.ORDER[i]
		Career.save(), 420), 280))
	v.add_child(UIKit.label("Цвета и защита меняются в любой момент. Лицо и рост — навсегда.", 17, Game.TEXT_DIM))


static func _find_col(pal: Array, c: Variant) -> int:
	if not (c is Color):
		return 0
	var best: = 0
	var bd: = 9.0
	for i in pal.size():
		var p: Color = pal[i]
		var d: = absf(p.r - c.r) + absf(p.g - c.g) + absf(p.b - c.b)
		if d < bd:
			bd = d
			best = i
	return best


func _tab_history(area: Control) -> void :
	var hist: Array = Game.career.get("history", [])
	if hist.is_empty():
		area.add_child(UIKit.label("Пока ни одного боя. Всё впереди.", 22, Game.TEXT_DIM))
		return
	var sc: = UIKit.nav_scroll(Vector2(1400, 640))
	area.add_child(sc)
	var v: = UIKit.vbox(4)
	sc.add_child(v)
	for i in range(hist.size() - 1, -1, -1):
		var e: Dictionary = hist[i]
		var res: = str(e.get("res", "?"))
		var p: = PanelContainer.new()
		p.add_theme_stylebox_override("panel", UIKit.sbox(Color(0.04, 0.045, 0.06, 0.9), 0.0, Color(0, 0, 0, 0), 0, 6.0))
		var h: = UIKit.hbox(18)
		p.add_child(h)
		var badge: = PanelContainer.new()
		var bc: = Color(0.15, 0.55, 0.25) if res == "W" else (Color(0.7, 0.15, 0.13) if res == "L" else Color(0.4, 0.4, 0.45))
		badge.add_theme_stylebox_override("panel", UIKit.sbox(bc, UIKit.SKEW, Color(0, 0, 0, 0), 0, 4.0))
		badge.add_child(UIKit.tlabel({"W": "ПОБЕДА", "L": "ПОРАЖЕНИЕ", "D": "НИЧЬЯ"}.get(res, res), 18, Color.WHITE))
		badge.custom_minimum_size = Vector2(170, 0)
		h.add_child(badge)
		var nm: = UIKit.tlabel(str(e.get("name", "?")).to_upper(), 24, Game.TEXT)
		nm.custom_minimum_size = Vector2(420, 0)
		h.add_child(nm)
		h.add_child(UIKit.label("%s  •  %d р." % [str(e.get("method", "")), int(e.get("round", 0))], 19, Game.TEXT_DIM))
		h.add_child(UIKit.label("$" + _money(int(e.get("purse", 0))), 19, UIKit.GOLD))
		if str(e.get("title", "")) != "":
			h.add_child(_belt_badge(str(e["title"])))
		v.add_child(p)


func _tab_news(area: Control) -> void :
	var news: Array = Game.career.get("news", [])
	var v: = UIKit.vbox(8)
	area.add_child(v)
	if news.is_empty():
		v.add_child(UIKit.label("Тишина в боксёрском мире.", 22, Game.TEXT_DIM))
	for n in news:
		var h: = UIKit.hbox(16)
		var bar: = ColorRect.new()
		bar.color = UIKit.GOLD
		bar.custom_minimum_size = Vector2(5, 30)
		h.add_child(bar)
		h.add_child(UIKit.label(str((n as Dictionary).get("t", "")), 21, Game.TEXT))
		v.add_child(h)


func _tab_weight(area: Control) -> void :
	var d: = Career.my_div()
	var p: = UIKit.card(0.0, Color(0.03, 0.035, 0.05, 0.88), Color(1, 1, 1, 0.08), 26)
	p.custom_minimum_size = Vector2(1500, 0)
	area.add_child(p)
	var v: = UIKit.vbox(16)
	p.add_child(v)
	v.add_child(UIKit.tlabel("СЕЙЧАС: " + Divisions.label(d).to_upper(), 30, UIKit.GOLD))
	v.add_child(UIKit.wrap_label("Переход в соседнюю весовую — серьёзное решение. Пояса текущего веса освобождаются, рейтинг частично сохраняется, слава остаётся. Тело меняется: набор массы даёт силу и подбородок, но отнимает скорость; сгонка ускоряет, но бьёт по выносливости.", 20, Game.TEXT))
	var h: = UIKit.hbox(20)
	v.add_child(h)
	if Career.can_change_division(1):
		h.add_child(UIKit.sbutton("Подняться: " + Divisions.name_of(d + 1), func(): _change_div(1), 520, true, 24))
	if Career.can_change_division(-1):
		h.add_child(UIKit.sbutton("Спуститься: " + Divisions.name_of(d - 1), func(): _change_div(-1), 520, false, 24))
	v.add_child(UIKit.label("Вверх: сила +3, подбородок +2, скорость −3.   Вниз: скорость +3, сила −3, выносливость −2.", 18, Game.TEXT_DIM))
	var hist: Array = Game.career.get("div_history", [])
	if hist.size() > 1:
		var names: Array = []
		for x in hist:
			names.append(Divisions.name_of(int(x)))
		v.add_child(UIKit.label("Путь по весам: " + " → ".join(PackedStringArray(names)), 18, Game.TEXT_DIM))


func _change_div(dir: int) -> void :
	var r: = Career.change_division(dir)
	if not r.is_empty():
		message = "Теперь ты в весе «%s». Удачи на новом месте!" % Divisions.name_of(int(r["to"]))
		tab = "overview"
	show_hub()


func _confirm_retire() -> void :
	var c: = _scr(0.85, "retire")
	menu._back = show_hub
	var p: = UIKit.card(0.0, Color(0.03, 0.035, 0.05, 0.94), UIKit.GOLD, 30)
	MainMenu._place(p, 560, 360)
	p.custom_minimum_size = Vector2(800, 0)
	c.add_child(p)
	var v: = UIKit.vbox(16)
	p.add_child(v)
	v.add_child(UIKit.tlabel("ПОВЕСИТЬ ПЕРЧАТКИ НА ГВОЗДЬ?", 38, Game.TEXT))
	v.add_child(UIKit.label("Карьера завершится, итог попадёт в зал славы. Вернуться будет нельзя.", 20, Game.TEXT_DIM))
	var h: = UIKit.hbox(14)
	v.add_child(h)
	var no: = UIKit.sbutton("Ещё повоюю", show_hub, 320, true)
	h.add_child(no)
	h.add_child(UIKit.sbutton("Завершить", _retire, 260))
	no.grab_focus()


func _retire() -> void :
	var r: = Career.retire()
	var c: = _scr(0.85, "retired")
	menu._back = menu.show_main
	var p: = UIKit.card(0.0, Color(0.03, 0.035, 0.05, 0.94), UIKit.GOLD, 30)
	MainMenu._place(p, 560, 300)
	p.custom_minimum_size = Vector2(800, 0)
	c.add_child(p)
	var v: = UIKit.vbox(14)
	p.add_child(v)
	v.add_child(UIKit.tlabel("КАРЬЕРА ЗАВЕРШЕНА", 44, UIKit.GOLD))
	v.add_child(UIKit.tlabel("РЕКОРД " + Career.record_str(Game.career["rec"]), 34, Game.TEXT))
	v.add_child(UIKit.label("Очки наследия: %d" % int(r["score"]), 24, Game.TEXT))
	v.add_child(UIKit.tlabel("ЗАЛ СЛАВЫ" if bool(r["hof"]) else "До зала славы не хватило совсем чуть-чуть", 28, UIKit.GOLD if bool(r["hof"]) else Game.TEXT_DIM))
	var b: = UIKit.sbutton("В меню", menu.show_main, 260, true)
	v.add_child(b)
	b.grab_focus()
