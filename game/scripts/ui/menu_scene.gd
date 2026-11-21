class_name MenuScene
extends Node3D


var camera: FightCamera
var a: Fighter
var b: Fighter
var menu: MainMenu
var refs: Dictionary = {}
var _spar_t: = 1.5
var _lean_t: = 0.0
var _lean_f: Fighter
var _rng: = RandomNumberGenerator.new()


func _ready() -> void :
	_rng.randomize()
	refs = Arena.build(self)
	var list: = Roster.fighters()
	var i1: = _rng.randi() % list.size()
	var i2: = (i1 + 1 + _rng.randi() % (list.size() - 1)) % list.size()
	var use_mixamo: = Game.setting_b("use_mixamo")
	a = Fighter.new()
	add_child(a)
	a.global_position = Vector3(-0.6, 0, 0.45)
	a.setup(list[i1], 0, false, use_mixamo)
	b = Fighter.new()
	add_child(b)
	b.global_position = Vector3(0.6, 0, -0.45)
	b.setup(list[i2], 1, false, use_mixamo)
	a.opponent = b
	b.opponent = a
	a.begin_fight_state()
	b.begin_fight_state()

	camera = FightCamera.new()
	add_child(camera)
	camera.current = true
	camera.mode = FightCamera.Mode.ORBIT
	camera.orbit_speed = 0.1
	camera.orbit_radius = 4.4
	camera.orbit_height = 1.85
	camera.orbit_angle = 2.2

	menu = MainMenu.new()
	add_child(menu)
	Sfx.start_crowd()
	Sfx.set_crowd(0.22)
	Arena.set_board(refs, "FINAL BELL")
	Arena.set_crowd(refs, 0.25, 0.0)


func open(screen: String) -> void :
	menu.open(screen)



var _shown_ids: = ""


func _swap(f: Fighter, def: Dictionary, corner: int, pos: Vector3) -> Fighter:
	if f:
		f.queue_free()
	var nf: = Fighter.new()
	add_child(nf)
	nf.global_position = pos
	nf.setup(def, corner, false, Game.setting_b("use_mixamo"))
	return nf


func show_pair(red: Dictionary, blue: Dictionary) -> void :
	var key: = str(red.get("id", "")) + "|" + str(red.get("model", "")) + "|" + str(blue.get("id", "")) + "|" + str(blue.get("model", ""))
	if key == _shown_ids:
		return
	_shown_ids = key
	a = _swap(a, red, 0, Vector3(-0.6, 0, 0.45))
	b = _swap(b, blue, 1, Vector3(0.6, 0, -0.45))
	a.opponent = b
	b.opponent = a
	a.begin_fight_state()
	b.begin_fight_state()


func show_single(def: Dictionary) -> void :
	var list: = Roster.fighters()
	var other: Dictionary = list[absi(hash(str(def.get("name", "")))) % list.size()]
	var key: = JSON.stringify(def).md5_text()
	if key == _shown_ids:
		return
	_shown_ids = key
	a = _swap(a, def, 0, Vector3(-0.6, 0, 0.45))
	b = _swap(b, other, 1, Vector3(0.6, 0, -0.45))
	a.opponent = b
	b.opponent = a
	a.begin_fight_state()
	b.begin_fight_state()


func show_idle() -> void :
	pass


func _process(delta: float) -> void :
	var dt: = minf(delta, 0.05)
	_spar_t -= dt
	if _spar_t <= 0.0:
		_spar_t = _rng.randf_range(0.7, 2.0)
		var f: Fighter = a if _rng.randf() < 0.5 else b
		if _rng.randf() < 0.75:
			var t: = _rng.randi() % 6
			f.request_punch(t, _rng.randf() < 0.2, _rng.randf() < 0.15)
			if _rng.randf() < 0.5:
				f.queued = {"type": _rng.randi() % 6, "body": false, "power": false}
				f.queued_time = f.clock
		else:
			_lean_f = f
			_lean_t = _rng.randf_range(0.3, 0.6)
			f.lean_input = 1 + _rng.randi() % 4
	if _lean_f:
		_lean_t -= dt
		if _lean_t <= 0.0:
			_lean_f.lean_input = Fighter.Lean.NONE
			_lean_f = null
	a.tick(dt)
	b.tick(dt)

	var d: = b.global_position - a.global_position
	d.y = 0.0
	if d.length() < 1.45 and d.length() > 0.01:
		var n: = d.normalized()
		var push: = (1.45 - d.length()) * 0.5
		a.global_position -= n * push
		b.global_position += n * push
	camera.update_camera(dt, a, b)
