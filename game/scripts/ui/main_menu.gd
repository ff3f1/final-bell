class_name MainMenu
extends CanvasLayer



const VERSION: = "0.9 beta"
const DIV_HINT: = [
	"Скорость рук, бесконечные серии, нокауты — редкость", 
	"Темп и точность, бой на скорости", 
	"Быстрые ноги, техничные размены", 
	"Золотая середина: скорость и уже ощутимый удар", 
	"Самая звёздная весовая: всё решает класс", 
	"Сила и выносливость в равновесии", 
	"Тяжёлые руки — один точный удар меняет бой", 
	"Медленно, тяжело, каждый удар может стать последним", 
]

var root: Control
var current: Control
var career_ui: CareerUI
var _back: Callable = Callable()

var _tabs_cb: Callable = Callable()

var _screen_key: = ""
var _restore: Dictionary = {}
var _want_focus_id: = ""


var _q_div: = 4
var _q_idx: = [0, 1]
var _diff: = 2
var _rounds_idx: = 1
var _secs_idx: = 2
var _spectator: = false
var _venue_idx: = 0
var _q_cards: Array = []
var _preview_t: = -1.0


var _t_div: = 4
var _t_idx: = 0
var _t_rounds: = 1


var _champ_box: Control
var _champ_i: = 0
var _champ_t: = 0.0


func _ready() -> void :
	layer = 5
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = Game.ui_theme
	root.add_to_group("nav_root")
	add_child(root)
	_diff = Game.setting_i("difficulty")
	_rounds_idx = maxi(Game.ROUND_OPTIONS.find(Game.setting_i("rounds")), 0)
	_secs_idx = maxi(Game.ROUND_SECONDS_OPTIONS.find(Game.setting_i("round_seconds")), 0)
	if Game.career.is_empty() or not Game.career.has("v"):
		Career.load_saved()
	career_ui = CareerUI.new(self)
	if Career.has():
		_q_div = Career.my_div()
		_t_div = _q_div


func open(screen: String) -> void :
	match screen:
		"career":
			show_career()
		"quick":
			show_quick()
		"tournament":
			show_tournament()
		"training":
			show_training()
		"controls":
			show_controls()
		"settings":
			show_settings()
		_:
			show_main()


func scene() -> MenuScene:
	return get_parent() as MenuScene



func _screen(dark: float = 0.8, key: String = "") -> Control:
	var info: = {}
	var fo: = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if current and is_instance_valid(current) and fo and current.is_ancestor_of(fo):
		info = {"key": _screen_key, "id": str(fo.get_meta("nav_id", "")), "path": _rel_path(current, fo)}
	if current:
		current.queue_free()
	_champ_box = null
	_tabs_cb = Callable()
	var c: = Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(c)
	current = c
	_screen_key = key
	_restore = info
	UIKit.backdrop(c, dark)
	_apply_focus.call_deferred(c)
	return c


func _unhandled_input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if _back.is_valid():
			Sfx.play("tick", -12.0, 0.0, 1.2)
			_back.call()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu_tab_prev") or event.is_action_pressed("menu_tab_next"):
		if _tabs_cb.is_valid():
			_tabs_cb.call(-1 if event.is_action_pressed("menu_tab_prev") else 1)
			get_viewport().set_input_as_handled()


static func _rel_path(base: Node, n: Node) -> Array:
	var path: Array = []
	while n and n != base:
		path.push_front(n.get_index())
		n = n.get_parent()
	return path if n == base else []


static func _node_at(base: Node, path: Array) -> Node:
	var n: = base
	for i in path:
		if int(i) < 0 or int(i) >= n.get_child_count():
			return null
		n = n.get_child(int(i))
	return n


static func _find_nav_id(n: Node, id: String) -> Control:
	for ch in n.get_children():
		if ch is Control and str((ch as Control).get_meta("nav_id", "")) == id and (ch as Control).is_visible_in_tree():
			return ch
		var r: = _find_nav_id(ch, id)
		if r:
			return r
	return null


static func _can_focus(c: Node) -> bool:
	return c is Control and (c as Control).focus_mode != Control.FOCUS_NONE and (c as Control).is_visible_in_tree()




func _apply_focus(c: Control) -> void :
	if not is_instance_valid(c) or c != current:
		return
	var target: Control = null
	if _want_focus_id != "":
		target = _find_nav_id(c, _want_focus_id)
		_want_focus_id = ""
	if target == null and str(_restore.get("id", "")) != "":
		target = _find_nav_id(c, str(_restore["id"]))
	if target == null and _screen_key != "" and str(_restore.get("key", "")) == _screen_key:
		var n: = _node_at(c, _restore.get("path", []))
		if _can_focus(n):
			target = n
	if target == null:
		var fo: = get_viewport().gui_get_focus_owner()
		if fo and c.is_ancestor_of(fo) and fo.is_visible_in_tree():
			return
		target = MenuNav.first_focusable(c)
	if target:
		target.grab_focus()



func _cycle(prefix: String, cur: int, n: int, d: int, apply: Callable) -> void :
	if n <= 0:
		return
	var fo: = get_viewport().gui_get_focus_owner()
	var ni: = posmod(cur + d, n)
	if fo and str(fo.get_meta("nav_id", "")).begins_with(prefix):
		_want_focus_id = prefix + str(ni)
	Sfx.play("tick", -14.0, 0.0, 1.5)
	apply.call(ni)


const HINTS_NAV: = [["↑↓←→", "Навигация"], ["Enter", "Выбрать"], ["Esc", "Назад"]]
const HINTS_TABS: = [["↑↓←→", "Навигация"], ["Enter", "Выбрать"], ["Q / E", "Вкладки"], ["Esc", "Назад"]]
const HINTS_DIVS: = [["↑↓←→", "Навигация"], ["Enter", "Выбрать"], ["Q / E", "Весовая"], ["Esc", "Назад"]]


func _process(delta: float) -> void :
	if _champ_box and is_instance_valid(_champ_box):
		_champ_t -= delta
		if _champ_t <= 0.0:
			_champ_t = 4.5
			_champ_i = (_champ_i + 1) % Divisions.COUNT
			_fill_champion()
	if _preview_t > 0.0:
		_preview_t -= delta
		if _preview_t <= 0.0:
			_apply_preview()


static func _place(c: Control, x: float, y: float, w: float = 0.0, h: float = 0.0) -> void :
	c.position = Vector2(x, y)
	if w > 0.0 or h > 0.0:
		c.custom_minimum_size = Vector2(w, h)




func show_main() -> void :
	Sfx.play_group("menu")
	_back = Callable()
	var c: = _screen(0.86, "main")
	if scene():
		scene().show_idle()
	var logo: = UIKit.vbox(0)
	_place(logo, 84, 56)
	c.add_child(logo)
	var t: = UIKit.tlabel("FINAL BELL", 140, UIKit.GOLD)
	t.add_theme_constant_override("outline_size", 12)
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	logo.add_child(t)
	var tag: = UIKit.hbox(14)
	var red: = ColorRect.new()
	red.color = UIKit.RED
	red.custom_minimum_size = Vector2(70, 6)
	red.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.add_child(red)
	tag.add_child(UIKit.label("СИМУЛЯТОР БОКСА   •   ВОСЕМЬ ВЕСОВЫХ   •   160 БОЙЦОВ", 20, Game.TEXT_DIM))
	logo.add_child(tag)
	UIKit.intro(logo, -40.0)

	var items: = UIKit.vbox(10)
	_place(items, 64, 330)
	c.add_child(items)
	var car_sub: = "Путь от дебюта до пояса чемпиона мира"
	if Career.has():
		car_sub = "Продолжить: %s  •  %s  •  №%d" % [str(Game.career.get("name", "")), Divisions.name_of(Career.my_div()), Career.my_rank()]
	var list: = [
		["Карьера", car_sub, show_career], 
		["Быстрый бой", "Любые бойцы восьми весовых", show_quick], 
		["Турнир", "Восемь бойцов, плей-офф за кубок", show_tournament], 
		["Тренировка", "Груша и спарринг: освой удары, блок и уклоны", show_training], 
		["Управление", "Мышь, клавиатура, геймпад", show_controls], 
		["Настройки", "Темп боя, камера, звук, экран", show_settings], 
		["Выход", "", func(): get_tree().quit()], 
	]
	var first: Control = null
	for i in list.size():
		var it: Array = list[i]
		var b: = UIKit.menu_item(i + 1, str(it[0]), str(it[1]), it[2], 620.0)
		b.set_meta("nav_id", "main:%d" % i)
		items.add_child(b)
		UIKit.intro(b, -70.0, 0.05 + i * 0.045)
		if first == null:
			first = b
	first.grab_focus()


	var showcase: = UIKit.card(0.0, Color(0.03, 0.035, 0.05, 0.95), Color(1, 1, 1, 0.1), 18)
	showcase.position = Vector2(1920 - 700, 330)
	showcase.custom_minimum_size = Vector2(620, 380)
	c.add_child(showcase)
	var sv: = UIKit.vbox(10)
	showcase.add_child(sv)
	var sh: = UIKit.hbox(10)
	var star: = UIKit.tlabel("★", 26, UIKit.GOLD)
	sh.add_child(star)
	sh.add_child(UIKit.tlabel("ЧЕМПИОНЫ МИРА", 26, UIKit.GOLD))
	sv.add_child(sh)
	_champ_box = UIKit.hbox(18)
	sv.add_child(_champ_box)
	_champ_i = randi() % Divisions.COUNT
	_champ_t = 4.5
	_fill_champion()
	UIKit.intro(showcase, 60.0, 0.2)

	UIKit.hint_bar(c, [["↑↓", "Навигация"], ["Enter", "Выбрать"]])
	var ver: = UIKit.label("v" + VERSION, 16, Color(1, 1, 1, 0.3))
	ver.position = Vector2(1920 - 160, 1080 - 44)
	c.add_child(ver)


func _champion_of(d: int) -> Dictionary:
	if Career.has():
		var id: = str(Career.belts_div(d).get("world", ""))
		if id == "me":
			return Career.player_def()
		if id != "":
			return Career.entry(id)
	var list: Array = Divisions.fighters_of(d)
	return list[0] if not list.is_empty() else {}


func _fill_champion() -> void :
	if _champ_box == null:
		return
	for ch in _champ_box.get_children():
		ch.queue_free()
	var f: = _champion_of(_champ_i)
	if f.is_empty():
		return
	_champ_box.add_child(UIKit.portrait(str(f.get("model", f.get("id", ""))), Vector2(230, 290)))
	var v: = UIKit.vbox(4)
	_champ_box.add_child(v)
	v.add_child(UIKit.label(Divisions.name_of(_champ_i).to_upper() + " ВЕС", 18, UIKit.GOLD))
	var parts: = str(f.get("name", "")).split(" ", false, 1)
	v.add_child(UIKit.tlabel(str(parts[0]).to_upper(), 30, Game.TEXT_DIM))
	if parts.size() > 1:
		v.add_child(UIKit.tlabel(str(parts[1]).to_upper(), 46, Game.TEXT))
	if str(f.get("nick", "")) != "":
		v.add_child(UIKit.label("«%s»" % f["nick"], 22, UIKit.GOLD))
	v.add_child(UIKit.spacer(8))
	v.add_child(UIKit.country_tag(str(f.get("country", ""))))
	v.add_child(UIKit.label("Рекорд  " + str(f.get("record", "")), 20, Game.TEXT))
	v.add_child(UIKit.label("Стиль: " + Roster.style_name(str(f.get("style", "balanced"))), 18, Game.TEXT_DIM))
	UIKit.intro(_champ_box, 24.0)




func show_quick() -> void :
	Sfx.play_group("menu")
	_back = show_main
	var c: = _screen(0.55, "quick")
	_tabs_cb = func(d: int): _cycle("div:", _q_div, Divisions.COUNT, d, _set_q_div)
	var head: = UIKit.header("БЫСТРЫЙ БОЙ", "Весовая категория, бойцы, правила")
	_place(head, 70, 40)
	c.add_child(head)

	var chips: = UIKit.hbox(6)
	_place(chips, 70, 160)
	c.add_child(chips)
	for d in Divisions.COUNT:
		chips.add_child(UIKit.chip(Divisions.name_of(d), d == _q_div, func(): _set_q_div(d), 19, "div:%d" % d))
	var info: = UIKit.hbox(14)
	_place(info, 76, 214)
	c.add_child(info)
	var e: Dictionary = Divisions.LIST[_q_div]
	var lim: = ("свыше %d фунтов (%.1f кг)" % [int(e["lb"]), float(e["kg"])]) if _q_div == Divisions.COUNT - 1 else ("до %d фунтов (%.1f кг)" % [int(e["lb"]), float(e["kg"])])
	info.add_child(UIKit.tlabel(lim.to_upper(), 22, UIKit.GOLD))
	info.add_child(UIKit.label("—  " + str(DIV_HINT[_q_div]), 19, Game.TEXT_DIM))

	_q_cards = []
	for side in 2:
		var holder: = Control.new()
		_place(holder, 70 if side == 0 else 1920 - 70 - 720, 262)
		holder.custom_minimum_size = Vector2(720, 560)
		c.add_child(holder)
		_q_cards.append(holder)
		_fill_q_card(side)
		UIKit.intro(holder, -60.0 if side == 0 else 60.0, 0.05)
	var vs: = UIKit.tlabel("VS", 110, Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_CENTER)
	vs.add_theme_constant_override("outline_size", 14)
	vs.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_place(vs, 960 - 90, 262, 180, 0)
	c.add_child(vs)


	var opts: = UIKit.vbox(12)
	_place(opts, 960 - 160, 410)
	c.add_child(opts)
	opts.add_theme_constant_override("separation", 8)
	opts.add_child(_opt_block("Сложность ИИ", UIKit.stepper(Game.DIFFICULTY_NAMES, _diff, func(i: int): _diff = i, 320)))
	var rn: Array = []
	for r in Game.ROUND_OPTIONS:
		rn.append("%d" % int(r))
	opts.add_child(_opt_block("Раундов", UIKit.stepper(rn, _rounds_idx, func(i: int): _rounds_idx = i, 320)))
	var sn: Array = []
	for s2 in Game.ROUND_SECONDS_OPTIONS:
		sn.append(Game.fmt_time(float(s2)))
	opts.add_child(_opt_block("Длина раунда", UIKit.stepper(sn, _secs_idx, func(i: int): _secs_idx = i, 320)))
	opts.add_child(_opt_block("Режим", UIKit.stepper(["Играю сам", "ИИ против ИИ"], 1 if _spectator else 0, func(i: int): _spectator = i == 1, 320)))
	var vn: Array = []
	for vid in Arena.VENUE_ORDER:
		vn.append(Arena.venue_name(str(vid)))
	opts.add_child(_opt_block("Арена", UIKit.stepper(vn, _venue_idx, func(i: int): _venue_idx = i, 320)))
	var go: = UIKit.sbutton("В бой!", _start_quick, 320, true, 34)
	go.custom_minimum_size = Vector2(320, 78)
	_place(go, 960 - 160, 868)
	c.add_child(go)
	var back: = UIKit.sbutton("Назад", show_main, 220)
	_place(back, 1920 - 70 - 220, 910)
	c.add_child(back)
	go.grab_focus()
	UIKit.hint_bar(c, HINTS_DIVS)
	_schedule_preview()


func _opt_block(title: String, ctl: Control) -> Control:
	var v: = UIKit.vbox(6)
	v.add_child(UIKit.label(title.to_upper(), 16, Game.TEXT_DIM))
	v.add_child(ctl)
	return v


func _set_q_div(d: int) -> void :
	_q_div = d
	_q_idx = [0, 1]
	show_quick()


func _q_list() -> Array:
	return Divisions.fighters_of(_q_div)


func _q_cycle(side: int, step: int) -> void :
	var n: = _q_list().size()
	_q_idx[side] = posmod(int(_q_idx[side]) + step, n)
	if int(_q_idx[0]) == int(_q_idx[1]):
		_q_idx[side] = posmod(int(_q_idx[side]) + step, n)
	_fill_q_card(side)
	_schedule_preview()


func _q_random(side: int) -> void :
	var n: = _q_list().size()
	var v: = randi() % n
	if v == int(_q_idx[1 - side]):
		v = (v + 1) % n
	_q_idx[side] = v
	_fill_q_card(side)
	_schedule_preview()


func _fill_q_card(side: int) -> void :
	if side >= _q_cards.size():
		return
	var holder: Control = _q_cards[side]
	for ch in holder.get_children():
		ch.queue_free()
	var list: = _q_list()
	var def: Dictionary = list[int(_q_idx[side])]
	var col: = UIKit.RED if side == 0 else UIKit.BLUE
	var card: = fighter_card(def, col, "КРАСНЫЙ УГОЛ" if side == 0 else "СИНИЙ УГОЛ", side == 1)
	holder.add_child(card)
	var nav: = UIKit.hbox(10)
	nav.position = Vector2(0, 498)
	holder.add_child(nav)
	var s: = side
	nav.add_child(UIKit.sbutton("◀", func(): _q_cycle(s, -1), 90))
	nav.add_child(UIKit.sbutton("Случайный", func(): _q_random(s), 240))
	nav.add_child(UIKit.sbutton("▶", func(): _q_cycle(s, 1), 90))
	var cnt: = UIKit.label("№%d ИЗ %d В ВЕСЕ" % [int(_q_idx[side]) + 1, list.size()], 18, Game.TEXT_DIM)
	cnt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nav.add_child(cnt)



func fighter_card(def: Dictionary, col: Color, corner: String, mirror: bool = false, live: bool = true) -> Control:
	var p: = UIKit.card(0.0, Color(0.025, 0.03, 0.045, 1.0), Color(col.r, col.g, col.b, 0.5), 0)
	p.custom_minimum_size = Vector2(720, 480)
	var h: = UIKit.hbox(0)
	p.add_child(h)
	var pv: = UIKit.vbox(0)
	var stripe: = ColorRect.new()
	stripe.color = col
	stripe.custom_minimum_size = Vector2(250, 8)
	pv.add_child(stripe)
	pv.add_child(FighterPreview.make(def, Vector2(250, 472), mirror) if live else UIKit.portrait(str(def.get("model", def.get("id", ""))), Vector2(250, 472), mirror))
	var info: = MarginContainer.new()
	for k in ["margin_left", "margin_right"]:
		info.add_theme_constant_override(k, 24)
	info.add_theme_constant_override("margin_top", 18)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v: = UIKit.vbox(4)
	info.add_child(v)
	if mirror:
		h.add_child(info)
		h.add_child(pv)
	else:
		h.add_child(pv)
		h.add_child(info)
	v.add_child(UIKit.label(corner, 16, col.lightened(0.2)))
	var parts: = str(def.get("name", "")).split(" ", false, 1)
	v.add_child(UIKit.tlabel(str(parts[0]).to_upper(), 26, Game.TEXT_DIM))
	v.add_child(UIKit.tlabel((str(parts[1]) if parts.size() > 1 else "").to_upper(), 46, Game.TEXT))
	var nick: = str(def.get("nick", ""))
	v.add_child(UIKit.label(("«%s»" % nick) if nick != "" else " ", 22, UIKit.GOLD))
	var row: = UIKit.hbox(18)
	row.add_child(UIKit.country_tag(str(def.get("country", ""))))
	row.add_child(UIKit.label(str(def.get("record", "")), 20, Game.TEXT))
	v.add_child(row)
	var ovr_row: = UIKit.hbox(14)
	var ov: = UIKit.tlabel(str(Roster.overall(def)), 66, UIKit.GOLD)
	ovr_row.add_child(ov)
	var ovl: = UIKit.vbox(0)
	ovl.alignment = BoxContainer.ALIGNMENT_CENTER
	ovl.add_child(UIKit.label("ОБЩИЙ", 15, Game.TEXT_DIM))
	ovl.add_child(UIKit.label(Roster.style_name(str(def.get("style", "balanced"))).to_upper(), 19, Game.TEXT))
	ovl.add_child(UIKit.label("%s  •  %s  •  %d см" % [Guards.name_of(Guards.for_def(def)), "Правша" if int(def.get("stance", 1)) == 1 else "Левша", int(float(def.get("height", 1.8)) * 100.0)], 16, Game.TEXT_DIM))
	ovr_row.add_child(ovl)
	v.add_child(ovr_row)
	v.add_child(UIKit.spacer(4))
	var names: = {"power": "Сила", "speed": "Скорость", "stamina": "Выносливость", "chin": "Подбородок", "defense": "Защита"}
	for k in ["power", "speed", "stamina", "chin", "defense"]:
		v.add_child(UIKit.stat_row(str(names[k]), int(def.get(k, 60)), col.lerp(UIKit.GOLD, 0.45), 200.0, 150.0))
	return p


func _schedule_preview() -> void :
	_preview_t = 0.35


func _apply_preview() -> void :
	if not scene() or current == null:
		return
	var list: = _q_list()
	if list.is_empty():
		return
	scene().show_pair(list[int(_q_idx[0])], list[int(_q_idx[1])])


func _start_quick() -> void :
	var list: = _q_list()
	var red: Dictionary = list[int(_q_idx[0])]
	var blue: Dictionary = list[int(_q_idx[1])]
	var rounds: int = Game.ROUND_OPTIONS[_rounds_idx]
	var secs: int = Game.ROUND_SECONDS_OPTIONS[_secs_idx]
	Game.settings["difficulty"] = _diff
	Game.settings["rounds"] = rounds
	Game.settings["round_seconds"] = secs
	Game.save_settings()
	var cfg: = Game.make_fight_config(red, blue, _diff, rounds, secs, _spectator, false)
	cfg["title"] = Divisions.name_of(_q_div) + " вес"
	cfg["venue"] = Arena.VENUE_ORDER[_venue_idx]
	Game.start_fight(cfg)




func show_career() -> void :
	Sfx.play_group("career")
	career_ui.show()




func show_tournament() -> void :
	Sfx.play_group("menu")
	_back = show_main
	if Tournament.active():
		_show_bracket()
		return
	var c: = _screen(0.6, "tournament")
	_tabs_cb = func(d: int): _cycle("div:", _t_div, Divisions.COUNT, d, _t_set_div)
	var head: = UIKit.header("ТУРНИР", "Восемь бойцов одной весовой • четвертьфинал, полуфинал, финал")
	_place(head, 70, 40)
	c.add_child(head)
	var chips: = UIKit.hbox(6)
	_place(chips, 70, 160)
	c.add_child(chips)
	for d in Divisions.COUNT:
		chips.add_child(UIKit.chip(Divisions.name_of(d), d == _t_div, func(): _t_set_div(d), 19, "div:%d" % d))
	var list: = Divisions.fighters_of(_t_div)
	var def: Dictionary = list[_t_idx % list.size()]
	var holder: = Control.new()
	_place(holder, 70, 240)
	c.add_child(holder)
	holder.add_child(fighter_card(def, UIKit.RED, "ТВОЙ БОЕЦ"))
	var nav: = UIKit.hbox(10)
	nav.position = Vector2(0, 498)
	holder.add_child(nav)
	nav.add_child(UIKit.sbutton("◀", func(): _t_cycle(-1), 90))
	nav.add_child(UIKit.sbutton("▶", func(): _t_cycle(1), 90))
	var rules: = UIKit.card(0.0, Color(0.03, 0.035, 0.05, 0.82), Color(1, 1, 1, 0.08), 26)
	_place(rules, 860, 240)
	rules.custom_minimum_size = Vector2(980, 480)
	c.add_child(rules)
	var rv: = UIKit.vbox(16)
	rules.add_child(rv)
	rv.add_child(UIKit.tlabel("ПРАВИЛА", 34, UIKit.GOLD))
	rv.add_child(UIKit.wrap_label("• Сетка из восьми бойцов весовой, жеребьёвка случайная.\n• Свои бои проводишь сам, остальные пары решаются по силе бойцов.\n• Проиграл — вылетел. Финал на два раунда длиннее.\n• Победа в финале — кубок турнира.", 22, Game.TEXT))
	var rounds_opts: = [3, 4, 6]
	var rn: Array = []
	for r in rounds_opts:
		rn.append("%d раунда" % r if r < 5 else "%d раундов" % r)
	rv.add_child(UIKit.srow("Раунды", UIKit.stepper(rn, _t_rounds, func(i: int): _t_rounds = i, 300), 260))
	rv.add_child(UIKit.srow("Сложность", UIKit.stepper(Game.DIFFICULTY_NAMES, _diff, func(i: int): _diff = i, 300), 260))
	var sn: Array = []
	for s2 in Game.ROUND_SECONDS_OPTIONS:
		sn.append(Game.fmt_time(float(s2)))
	rv.add_child(UIKit.srow("Длина раунда", UIKit.stepper(sn, _secs_idx, func(i: int): _secs_idx = i, 300), 260))
	var go: = UIKit.sbutton("Начать турнир", func(): _t_start(def), 360, true, 30)
	_place(go, 1920 - 70 - 360 - 250, 900)
	c.add_child(go)
	var back: = UIKit.sbutton("Назад", show_main, 220)
	_place(back, 1920 - 70 - 220, 905)
	c.add_child(back)
	go.grab_focus()
	UIKit.hint_bar(c, HINTS_DIVS)
	if scene():
		scene().show_pair(def, list[(_t_idx + 1) % list.size()])


func _toggle_spectator() -> void :
	_spectator = not _spectator
	show_quick()


func _t_set_div(d: int) -> void :
	_t_div = d
	_t_idx = 0
	show_tournament()


func _t_cycle(step: int) -> void :
	var n: = Divisions.fighters_of(_t_div).size()
	_t_idx = posmod(_t_idx + step, n)
	show_tournament()


func _t_start(def: Dictionary) -> void :
	var rounds_opts: = [3, 4, 6]
	Tournament.create(_t_div, def, int(rounds_opts[_t_rounds]), _diff, int(Game.ROUND_SECONDS_OPTIONS[_secs_idx]))
	show_tournament()


func _t_new() -> void :
	Tournament.clear()
	show_tournament()


func _t_leave() -> void :
	Tournament.clear()
	show_main()


func _show_bracket() -> void :
	var c: = _screen(0.72, "bracket")
	var t: = Game.tournament
	var head: = UIKit.header("ТУРНИР • " + Divisions.name_of(int(t["div"])).to_upper(), "Сетка плей-офф")
	_place(head, 70, 40)
	c.add_child(head)
	var stages: Array = t["stages"]
	var me: = Tournament.me_idx()
	var col_x: = [70, 620, 1170]
	var titles: = Tournament.STAGES
	for si in 3:
		var lab: = UIKit.tlabel(str(titles[si]), 26, UIKit.GOLD if si == int(t["stage"]) and int(t["champion"]) < 0 else Game.TEXT_DIM)
		_place(lab, col_x[si], 170)
		c.add_child(lab)
		if si >= stages.size():
			continue
		var st: Array = stages[si]
		var gap: = 820.0 / float(st.size())
		for mi in st.size():
			var m: Dictionary = st[mi]
			var box: = _match_box(m, me)
			_place(box, col_x[si], 215 + gap * mi + (gap - 150.0) * 0.5)
			c.add_child(box)
			UIKit.intro(box, -30.0, 0.05 * float(mi + si * 4))

	var champ: = int(t["champion"])
	var cb: = UIKit.card(UIKit.SKEW * 0.5, Color(0.12, 0.09, 0.03, 0.9), UIKit.GOLD, 20)
	_place(cb, 1720 - 120, 520)
	cb.custom_minimum_size = Vector2(300, 0)
	c.add_child(cb)
	var cv: = UIKit.vbox(6)
	cb.add_child(cv)
	cv.add_child(UIKit.tlabel("КУБОК", 26, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	if champ >= 0:
		var cd: = Tournament.entrant(champ)
		cv.add_child(UIKit.portrait(str(cd.get("model", "")), Vector2(260, 300)))
		cv.add_child(UIKit.tlabel(str(cd["name"]).to_upper(), 28, Game.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
		if champ == me:
			cv.add_child(UIKit.label("ТЫ — ПОБЕДИТЕЛЬ ТУРНИРА!", 20, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	else:
		cv.add_child(UIKit.label("разыгрывается…", 20, Game.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	var btns: = UIKit.hbox(16)
	_place(btns, 70, 960)
	c.add_child(btns)
	var first: Button = null
	if not Tournament.my_match().is_empty():
		first = UIKit.sbutton("На бой: " + str(Tournament.STAGES[int(t["stage"])]).to_lower(), Tournament.start_fight, 460, true, 28)
		btns.add_child(first)
	elif champ >= 0:
		first = UIKit.sbutton("Новый турнир", _t_new, 340, true)
		btns.add_child(first)
	var leave: = UIKit.sbutton("Покинуть турнир" if champ < 0 else "В меню", _t_leave, 330)
	btns.add_child(leave)
	btns.add_child(UIKit.sbutton("Назад", show_main, 220))
	if first:
		first.grab_focus()
	else:
		leave.grab_focus()
	UIKit.hint_bar(c, HINTS_NAV)
	var my: = Tournament.my_match()
	if scene() and not my.is_empty():
		scene().show_pair(Tournament.entrant(int(my["a"])), Tournament.entrant(int(my["b"])))


func _match_box(m: Dictionary, me: int) -> Control:
	var mine: = int(m["a"]) == me or int(m["b"]) == me
	var p: = UIKit.card(UIKit.SKEW * 0.4, Color(0.03, 0.035, 0.05, 0.88), UIKit.GOLD if mine and int(m["w"]) < 0 else Color(1, 1, 1, 0.08), 12)
	p.custom_minimum_size = Vector2(500, 150)
	var v: = UIKit.vbox(4)
	p.add_child(v)
	for k in ["a", "b"]:
		var idx: = int(m[k])
		var d: = Tournament.entrant(idx)
		var h: = UIKit.hbox(12)
		var won: = int(m["w"]) == idx
		var lost: = int(m["w"]) >= 0 and not won
		h.add_child(UIKit.portrait(str(d.get("model", "")), Vector2(48, 56)))
		var nm: = UIKit.tlabel(str(d["name"]).to_upper(), 24, UIKit.GOLD if won else (Color(1, 1, 1, 0.35) if lost else Game.TEXT))
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(nm)
		var tag: = "ТЫ" if idx == me else str(Roster.overall(d))
		var tl: = UIKit.tlabel(tag, 22, UIKit.RED if idx == me else Game.TEXT_DIM)
		tl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(tl)
		v.add_child(h)
	if str(m.get("method", "")) != "":
		v.add_child(UIKit.label(str(m["method"]), 15, Game.TEXT_DIM))
	return p




var _set_tab: = 0


func show_settings() -> void :
	_back = _settings_done
	var c: = _screen(0.82, "settings:%d" % _set_tab)
	_tabs_cb = func(d: int): _cycle("tab:", _set_tab, 4, d, _set_tab_to)
	var head: = UIKit.header("НАСТРОЙКИ", "Звук • бой • мышь и камера • экран")
	_place(head, 70, 40)
	c.add_child(head)
	var tabs: = UIKit.hbox(6)
	_place(tabs, 70, 160)
	c.add_child(tabs)
	var tnames: = ["Звук", "Бой", "Мышь и камера", "Экран"]
	for i in tnames.size():
		tabs.add_child(UIKit.chip(str(tnames[i]), i == _set_tab, func(): _set_tab_to(i), 22, "tab:%d" % i))
	var panel: = UIKit.card(0.0, Color(0.03, 0.035, 0.05, 0.86), Color(1, 1, 1, 0.08), 30)
	_place(panel, 70, 230)
	panel.custom_minimum_size = Vector2(1100, 0)
	c.add_child(panel)
	var v: = UIKit.vbox(18)
	panel.add_child(v)
	match _set_tab:
		0:
			v.add_child(_slider_row("Общая громкость", "master_volume", 0.0, 1.0, 0.05))
			v.add_child(_slider_row("Удары и эффекты", "sfx_volume", 0.0, 1.0, 0.05))
			v.add_child(_slider_row("Толпа", "crowd_volume", 0.0, 1.0, 0.05))
			v.add_child(_slider_row("Музыка", "music_volume", 0.0, 1.0, 0.05))
		1:
			v.add_child(UIKit.srow("Темп боя", UIKit.stepper(["Медленный", "Обычный", "Быстрый"], Game.setting_i("fight_tempo"), func(i: int): _set_opt("fight_tempo", i), 320), 420))
			var th: = UIKit.label("Медленный — больше времени прочитать удар и ответить. Быстрый — как раньше.", 16, Color(1, 1, 1, 0.35))
			var thm: = MarginContainer.new()
			thm.add_theme_constant_override("margin_left", 436)
			thm.add_child(th)
			v.add_child(thm)
			v.add_child(UIKit.srow("Сложность по умолчанию", UIKit.stepper(Game.DIFFICULTY_NAMES, Game.setting_i("difficulty"), func(i: int): _set_opt("difficulty", i), 320), 420))
			v.add_child(_toggle_row("Полоски здоровья", "show_health", "Выключи — и читай состояние соперника по нему самому"))
			v.add_child(_toggle_row("Замедление на нокдаунах и уклонах", "slowmo", ""))
			v.add_child(_toggle_row("Подсказки управления в бою", "hints", "F1 — показать или скрыть в любой момент"))
			v.add_child(_toggle_row("Вибрация геймпада", "vibration", "Отдача от попаданий и пропущенных ударов"))
		2:
			v.add_child(_toggle_row("Удары мышью", "mouse_punch", "ЛКМ / ПКМ — руки, движение мыши в момент клика — тип удара"))
			v.add_child(_toggle_row("Прицел мыши на экране", "hud_mouse_aim", "Круг внизу показывает, какой удар выйдет"))
			v.add_child(_slider_row("Чувствительность мыши", "mouse_sens", 0.3, 2.5, 0.05))
			v.add_child(_slider_row("Тряска камеры", "camera_shake", 0.0, 1.5, 0.1))
			v.add_child(UIKit.srow("Камера по умолчанию", UIKit.stepper(FightCamera.CYCLE_NAMES, FightCamera.cycle_index(Game.setting_i("camera_mode")), func(i: int): _set_opt("camera_mode", FightCamera.CYCLE[i]), 320), 420))
		3:
			v.add_child(_toggle_row("Полный экран", "fullscreen", ""))
			v.add_child(_toggle_row("Повышенная резкость", "sharpen", "Чёткая картинка без «мыла» (резкость поверх сцены)"))
			v.add_child(_toggle_row("Живые модели в карточках", "live_cards", "Бойцы в меню выбора двигаются; выключи на слабом ПК"))
	var back: = UIKit.sbutton("Готово", _settings_done, 260, true)
	_place(back, 70, 940)
	c.add_child(back)

	var first: = MenuNav.first_focusable(panel)
	if first:
		first.grab_focus()
	else:
		back.grab_focus()
	UIKit.hint_bar(c, HINTS_TABS)


func _slider_row(title: String, key: String, lo: float, hi: float, step: float) -> Control:
	var h: = UIKit.hbox(16)
	var s: = UIKit.slider(lo, hi, step, Game.setting_f(key), func(x: float): _set_opt(key, x))
	s.custom_minimum_size = Vector2(420, 32)
	var val: = UIKit.tlabel("%d%%" % int(round(Game.setting_f(key) / hi * 100.0)), 22, UIKit.GOLD)
	val.custom_minimum_size = Vector2(80, 0)
	s.value_changed.connect( func(x: float): val.text = "%d%%" % int(round(x / hi * 100.0)))
	h.add_child(s)
	h.add_child(val)
	return UIKit.srow(title, h, 420)


func _toggle_row(title: String, key: String, hint: String) -> Control:
	var v: = UIKit.vbox(2)
	var on: = Game.setting_b(key)
	var h: = UIKit.hbox(16)
	var l: = UIKit.label(title.to_upper(), 19, Game.TEXT_DIM)
	l.custom_minimum_size = Vector2(420, 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	h.add_child(UIKit.chip("Вкл", on, func(): _toggle(key, true), 20))
	h.add_child(UIKit.chip("Выкл", not on, func(): _toggle(key, false), 20))
	v.add_child(h)
	if hint != "":
		var hl: = UIKit.label(hint, 16, Color(1, 1, 1, 0.35))
		var m: = MarginContainer.new()
		m.add_theme_constant_override("margin_left", 436)
		m.add_child(hl)
		v.add_child(m)
	return v


func _set_tab_to(i: int) -> void :
	_set_tab = i
	show_settings()


func _toggle(key: String, v: bool) -> void :
	_set_opt(key, v)
	show_settings()


func _settings_done() -> void :
	Game.save_settings()
	show_main()


func _set_opt(key: String, value: Variant) -> void :
	Game.settings[key] = value
	Game.apply_settings()





class MouseCompass:
	extends Control

	func _draw() -> void :
		var c: = size * 0.5
		var r: = minf(size.x, size.y) * 0.5 - 70.0
		var gold: = Color(0.93, 0.72, 0.25)
		draw_circle(c, r, Color(0.02, 0.025, 0.035, 0.85))
		draw_arc(c, r, 0.0, TAU, 64, Color(1, 1, 1, 0.25), 2.0, true)
		draw_arc(c, r * 0.3, 0.0, TAU, 48, gold, 3.0, true)
		var sec: = [[ - PI * 0.5, 38.0, Color(0.93, 0.72, 0.25, 0.55)], [0.0, 50.0, Color(0.85, 0.3, 0.2, 0.5)], 
			[PI, 50.0, Color(0.85, 0.3, 0.2, 0.5)], [PI * 0.5, 32.0, Color(0.3, 0.55, 0.95, 0.55)], 
			[PI * 0.5 - 0.82, 18.0, Color(0.55, 0.4, 0.9, 0.5)], [PI * 0.5 + 0.82, 18.0, Color(0.55, 0.4, 0.9, 0.5)]]
		for sc in sec:
			var a: Array = sc
			var half: = deg_to_rad(float(a[1]))
			draw_arc(c, r * 0.68, float(a[0]) - half, float(a[0]) + half, 24, a[2], r * 0.5, false)
		var f: Font = Game.title_font if Game.title_font else ThemeDB.fallback_font
		var bf: Font = Game.body_font if Game.body_font else ThemeDB.fallback_font
		_txt(f, c + Vector2(0, - r - 34), "ВВЕРХ — АППЕРКОТ", 30, gold)
		_txt(f, c + Vector2(r + 14, 0), "ХУК", 30, Color(1, 0.6, 0.5), HORIZONTAL_ALIGNMENT_LEFT)
		_txt(bf, c + Vector2(r + 14, 24), "вбок", 18, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_LEFT)
		_txt(f, c + Vector2( - r - 14, 0), "ХУК", 30, Color(1, 0.6, 0.5), HORIZONTAL_ALIGNMENT_RIGHT)
		_txt(bf, c + Vector2( - r - 14, 24), "вбок", 18, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_RIGHT)
		_txt(f, c + Vector2(0, r + 52), "ВНИЗ — В КОРПУС", 30, Color(0.6, 0.75, 1.0))
		_txt(f, c + Vector2(0, 10), "НА МЕСТЕ", 22, Color(1, 1, 1))
		_txt(bf, c + Vector2(0, 34), "прямой", 18, Color(1, 1, 1, 0.7))
		_txt(bf, c + Vector2(0, r + 84), "вниз-вбок — хук в корпус", 18, Color(1, 1, 1, 0.55))

	func _txt(f: Font, p: Vector2, t: String, sz: int, col: Color, al: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> void :
		var w: = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		var x: = p.x - w * 0.5
		if al == HORIZONTAL_ALIGNMENT_LEFT:
			x = p.x
		elif al == HORIZONTAL_ALIGNMENT_RIGHT:
			x = p.x - w
		draw_string_outline(f, Vector2(x, p.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 6, Color(0, 0, 0, 0.85))
		draw_string(f, Vector2(x, p.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


var _ctrl_tab: = 0


func show_controls() -> void :
	_back = show_main
	var c: = _screen(0.88, "controls:%d" % _ctrl_tab)
	_tabs_cb = func(d: int): _cycle("tab:", _ctrl_tab, 3, d, _set_ctrl_tab)
	var head: = UIKit.header("УПРАВЛЕНИЕ", "Все удары — мышью или геймпадом. Попробуй сразу на груше: меню → Тренировка")
	_place(head, 70, 40)
	c.add_child(head)
	var tabs: = UIKit.hbox(6)
	_place(tabs, 70, 160)
	c.add_child(tabs)
	var tn: = ["Мышь и клавиатура", "Геймпад", "Как побеждать"]
	for i in tn.size():
		tabs.add_child(UIKit.chip(str(tn[i]), i == _ctrl_tab, func(): _set_ctrl_tab(i), 22, "tab:%d" % i))
	match _ctrl_tab:
		0:
			var mouse_col: = _ctrl_col("МЫШЬ — УДАРЫ", Controls.MOUSE, 640.0)
			_place(mouse_col, 70, 236)
			c.add_child(mouse_col)
			var comp: = MouseCompass.new()
			_place(comp, 730, 236, 560, 600)
			comp.size = Vector2(560, 600)
			comp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c.add_child(comp)
			var kb: = _ctrl_col("КЛАВИАТУРА — ЗАЩИТА И НОГИ", Controls.KEYBOARD, 560.0)
			_place(kb, 1300, 236)
			c.add_child(kb)
		1:
			var gp: = _ctrl_col("ГЕЙМПАД — КАК В FIGHT NIGHT", Controls.GAMEPAD, 900.0)
			_place(gp, 70, 236)
			c.add_child(gp)
		2:
			var tips: = UIKit.card(0.0, Color(0.03, 0.035, 0.05, 0.86), Color(1, 1, 1, 0.08), 26)
			_place(tips, 70, 236)
			tips.custom_minimum_size = Vector2(1300, 0)
			c.add_child(tips)
			var tv: = UIKit.vbox(16)
			tips.add_child(tv)
			for t in Controls.TIPS:
				var tl: = UIKit.wrap_label("•  " + str(t), 22, Game.TEXT)
				tl.custom_minimum_size = Vector2(1240, 0)
				tv.add_child(tl)
	var back: = UIKit.sbutton("Назад", show_main, 220)
	_place(back, 70, 960)
	c.add_child(back)
	var train: = UIKit.sbutton("На тренировку", show_training, 320, true)
	_place(train, 320, 960)
	c.add_child(train)
	train.grab_focus()
	var hb: = UIKit.hint_bar(c, HINTS_TABS)
	hb.offset_left = 700


func _ctrl_col(title: String, rows: Array, width: float = 578.0) -> Control:
	var p: = UIKit.card(0.0, Color(0.03, 0.035, 0.05, 0.86), Color(1, 1, 1, 0.08), 22)
	p.custom_minimum_size = Vector2(width, 0)
	var v: = UIKit.vbox(10)
	p.add_child(v)
	v.add_child(UIKit.tlabel(title, 28, UIKit.GOLD))
	for r in rows:
		var h: = UIKit.hbox(12)
		var kc: = UIKit.key_cap(str(r[0]))
		kc.custom_minimum_size = Vector2(230, 0)
		h.add_child(kc)
		var l: = UIKit.wrap_label(str(r[1]), 19, Game.TEXT)
		l.custom_minimum_size = Vector2(width - 300.0, 0)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(l)
		v.add_child(h)
	return p




var _tr_mode: = "bag"
var _tr_mine: = true


func show_training() -> void :
	Sfx.play_group("menu")
	_back = show_main
	var c: = _screen(0.6, "training")
	_tabs_cb = _tr_cycle_chip
	var head: = UIKit.header("ТРЕНИРОВКА", "Груша — отработать удары. Спарринг — защита и контратаки, без нокаутов")
	_place(head, 70, 40)
	c.add_child(head)
	var chips: = UIKit.hbox(6)
	_place(chips, 70, 160)
	c.add_child(chips)
	var use_career: = Career.has() and _tr_mine
	if Career.has():
		chips.add_child(UIKit.chip("Мой боец", use_career, func(): _tr_set_mine(true), 19, "div:-1"))
	for d in Divisions.COUNT:
		chips.add_child(UIKit.chip(Divisions.name_of(d), ( not use_career) and d == _q_div, func(): _tr_set_div(d), 19, "div:%d" % d))
	var me_def: = _training_fighter()
	var holder: = Control.new()
	_place(holder, 70, 240)
	c.add_child(holder)
	holder.add_child(fighter_card(me_def, UIKit.RED, "ТВОЙ БОЕЦ"))
	if not use_career:
		var nav: = UIKit.hbox(10)
		nav.position = Vector2(0, 498)
		holder.add_child(nav)
		nav.add_child(UIKit.sbutton("◀", func(): _tr_cycle(-1), 90))
		nav.add_child(UIKit.sbutton("▶", func(): _tr_cycle(1), 90))

	var modes: = UIKit.vbox(16)
	_place(modes, 860, 240)
	c.add_child(modes)
	modes.add_child(_mode_card("bag", "ГРУША", "Тяжёлый мешок на цепях. Никто не бьёт в ответ — отрабатывай удары мышью, серии, силовые. Видно, какой удар вышел и с какой силой."))
	modes.add_child(_mode_card("spar", "СПАРРИНГ", "Партнёр бьёт и защищается, но нокаутов нет: здоровье само восстанавливается. Учись блоку, уклонам корпусом и контратакам."))
	if _tr_mode == "spar":
		modes.add_child(UIKit.srow("Партнёр", UIKit.stepper(Game.DIFFICULTY_NAMES, _diff, func(i: int): _diff = i, 300), 200))
	modes.add_child(UIKit.label("В тренировке: Tab — переключить грушу и партнёра,  Esc — пауза и выход.", 18, Game.TEXT_DIM))
	var go: = UIKit.sbutton("Начать", func(): _start_training(me_def), 300, true, 34)
	go.custom_minimum_size = Vector2(300, 78)
	_place(go, 1920 - 70 - 300 - 250, 900)
	c.add_child(go)
	var back: = UIKit.sbutton("Назад", show_main, 220)
	_place(back, 1920 - 70 - 220, 910)
	c.add_child(back)
	go.grab_focus()
	UIKit.hint_bar(c, HINTS_DIVS)
	if scene():
		scene().show_single(me_def)


func _mode_card(mode: String, title: String, desc: String) -> Control:
	var sel: = _tr_mode == mode
	var b: = Button.new()
	b.custom_minimum_size = Vector2(980, 150)
	UIKit._btn_styles(b, Color(0.12, 0.09, 0.03, 0.92) if sel else Color(0.03, 0.035, 0.05, 0.86), 
		Color(0.16, 0.12, 0.05, 0.96), 0.0, 22.0, UIKit.GOLD if sel else Color(1, 1, 1, 0.08))
	var v: = UIKit.vbox(6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 28
	v.offset_top = 18
	v.offset_right = -28
	var t: = UIKit.tlabel(title, 38, UIKit.GOLD if sel else Game.TEXT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(t)
	var d: = UIKit.wrap_label(desc, 19, Game.TEXT_DIM)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(d)
	b.add_child(v)
	b.pressed.connect( func(): _tr_set_mode(mode))
	return b



func _tr_cycle_chip(d: int) -> void :
	var opts: Array = []
	if Career.has():
		opts.append(-1)
	for i in Divisions.COUNT:
		opts.append(i)
	var cur: = -1 if (Career.has() and _tr_mine) else _q_div
	var ni: = posmod(opts.find(cur) + d, opts.size())
	var fo: = get_viewport().gui_get_focus_owner()
	if fo and str(fo.get_meta("nav_id", "")).begins_with("div:"):
		_want_focus_id = "div:%d" % int(opts[ni])
	Sfx.play("tick", -14.0, 0.0, 1.5)
	if int(opts[ni]) < 0:
		_tr_set_mine(true)
	else:
		_tr_set_div(int(opts[ni]))


func _set_ctrl_tab(i: int) -> void :
	_ctrl_tab = i
	show_controls()


func _tr_set_mine(v: bool) -> void :
	_tr_mine = v
	show_training()


func _tr_set_div(d: int) -> void :
	_tr_mine = false
	_q_div = d
	_q_idx = [0, 1]
	show_training()


func _tr_cycle(step: int) -> void :
	var n: = _q_list().size()
	_q_idx[0] = posmod(int(_q_idx[0]) + step, n)
	show_training()


func _tr_set_mode(m: String) -> void :
	_tr_mode = m
	show_training()


func _training_fighter() -> Dictionary:
	if Career.has() and _tr_mine:
		return Career.player_def()
	var list: = _q_list()
	return list[int(_q_idx[0]) % list.size()]


func _start_training(me_def: Dictionary) -> void :
	var d: = Weight.of(me_def)
	var list: Array = Divisions.fighters_of(d)
	var partner: Dictionary = list[(absi(hash(str(me_def.get("name", "")))) + 3) % list.size()]
	if str(partner.get("name", "")) == str(me_def.get("name", "")):
		partner = list[(list.find(partner) + 1) % list.size()]
	var cfg: = Game.make_fight_config(me_def, partner, _diff, 1, 9999, false, false)
	cfg["training"] = _tr_mode
	cfg["title"] = "Тренировка"
	Game.start_fight(cfg)
