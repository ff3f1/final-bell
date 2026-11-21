extends Node












var current: Node
var fade_layer: CanvasLayer
var fade_rect: ColorRect
var _busy: = false
var _pending_kind: = ""
var _pending_screen: = "main"
var _pending_config: Dictionary = {}
var _test_fights_left: = 0
var _test_index: = 0


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.main = self
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_rect)
	Game.parse_test_args()
	if Game.test_str("tool", "") != "":

		fade_rect.color.a = 0.0
		var tool_node: Node = load(Game.test_str("tool", "")).new()
		add_child(tool_node)
		return
	if Game.test_flag("navtest"):
		Game.no_save = true
		fade_rect.color.a = 0.0
		var nt: Node = load("res://tools/nav_test.gd").new()
		add_child(nt)
		return
	if Game.autotest:
		_test_fights_left = Game.test_int("fights", 1)
		autotest_next()
		return
	if Game.test_flag("test_career") and not Career.has():
		Career.create({"name": "Test Boxer", "nick": "Tester", "division": 3, "style": "swarmer", "guard": "peekaboo"})
		Career.save()
	if Game.test_flag("pad"):

		Game.nav.keyboard_nav = true
		Game.nav.using_pad = true
	show_menu(Game.test_str("menu_screen", "main"))
	var menu_shot: = Game.test_str("menu_shot", "")
	if menu_shot != "":
		get_tree().create_timer(4.0, true, false, true).timeout.connect(_menu_snapshot.bind(menu_shot))


func _menu_snapshot(path: String) -> void :
	await RenderingServer.frame_post_draw
	var img: = get_viewport().get_texture().get_image()
	img.save_png(path)
	print("MENU_SHOT ", path)
	get_tree().quit()


func autotest_next() -> void :
	if _test_fights_left <= 0:
		print("AUTOTEST DONE")
		get_tree().quit(0)
		return
	_test_fights_left -= 1
	_test_index += 1
	var list: = Roster.fighters()
	var rng: = RandomNumberGenerator.new()
	rng.seed = 1000 + _test_index * 77 + Game.test_int("seed", 0) * 100003
	if Game.test_flag("balance"):

		list = Divisions.fighters_of(rng.randi() % Divisions.COUNT)
	var ia: = rng.randi() % list.size()
	var ib: = (ia + 1 + rng.randi() % (list.size() - 1)) % list.size()
	var a: Dictionary = list[ia]
	var b: Dictionary = list[ib]
	var cfg: = Game.make_fight_config(a, b, Game.test_int("diff", 3), Game.test_int("rounds", 3), 
		Game.test_int("secs", 60), not Game.test_flag("asplayer"), false)
	if Game.test_str("training", "") != "":
		cfg["training"] = Game.test_str("training", "bag")
		cfg["spectator"] = false
	print("AUTOTEST FIGHT %d: %s vs %s" % [_test_index, a["name"], b["name"]])
	start_fight(cfg)


func show_menu(screen: String = "main") -> void :
	if Game.autotest:
		autotest_next()
		return
	_pending_kind = "menu"
	_pending_screen = screen
	_transition()


func start_fight(config: Dictionary) -> void :
	_pending_kind = "fight"
	_pending_config = config
	_transition()


func _transition() -> void :
	if _busy:
		return
	_busy = true
	var tw: = create_tween().set_ignore_time_scale(true)
	tw.tween_property(fade_rect, "color:a", 1.0, 0.25)
	tw.tween_callback(_swap)
	tw.tween_interval(0.08)
	tw.tween_property(fade_rect, "color:a", 0.0, 0.45)
	tw.tween_callback(_done)


func _swap() -> void :
	get_tree().paused = false
	Engine.time_scale = 1.0
	if current:
		remove_child(current)
		current.queue_free()
		current = null
	if _pending_kind == "fight":
		Game.fight_config = _pending_config
		var f: = FightScene.new()
		f.name = "Fight"
		current = f
		add_child(f)
	else:
		var m: = MenuScene.new()
		m.name = "Menu"
		current = m
		add_child(m)
		m.open(_pending_screen)


func _done() -> void :
	_busy = false
