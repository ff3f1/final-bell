class_name FightScene
extends Node3D



enum Phase{INTRO, FIGHT, KNOCKDOWN, ROUND_END, CORNER, ENDED}

const START_RED: = Vector3(-0.75, 0, 0.75)
const START_BLUE: = Vector3(0.75, 0, -0.75)

var config: Dictionary = {}
var red: Fighter
var blue: Fighter
var fighters: Array[Fighter] = []
var player: Fighter
var player_ctrl: PlayerController
var ais: Array[BoxerAI] = []
var camera: FightCamera
var hud: FightHUD
var screens: FightScreens
var judges: Judges
var arena_refs: Dictionary = {}
var blood_fx: BloodFx

var referee_root: Node3D
var referee
var _ref_vel: = Vector3.ZERO

var phase: int = Phase.INTRO
var round_num: = 1
var total_rounds: = 3
var round_seconds: = 120.0
var time_left: = 120.0
var spectator: = false
var cam_mode_saved: = 0

var stats: Array = [{}, {}]
var totals: Array = [{}, {}]
var best_punch: Array = [{}, {}]
var unanswered: = [0, 0]
var cut_warned: = [false, false]
var kd: Dictionary = {}
var clinch_active: = false
var clinch_timer: = 0.0
var separating_t: = 0.0
var result: Dictionary = {}

var hitstop_real: = 0.0
var slowmo_real: = 0.0
var excitement: = 0.3
var flash_boost: = 0.0
var warned_10s: = false
var _board_t: = 0.0
var _last_us: = 0
var _seq: Array = []
var _intro_skip: = false
var _seq_t: = 0.0
var _rng: = RandomNumberGenerator.new()

var training: = ""
var train_stats: = {"thrown": 0, "landed": 0, "power": 0, "best": 0.0, "combo": 0, "best_combo": 0, "last": "", "last_dmg": 0.0, "last_t": -10.0}
var _train_clock: = 0.0
var post_mat: ShaderMaterial
var _impact_pulse: = 0.0


func _ready() -> void :

	process_mode = Node.PROCESS_MODE_PAUSABLE
	_rng.randomize()
	config = Game.fight_config
	if config.is_empty():
		var list: = Roster.fighters()
		config = Game.make_fight_config(list[0], list[1], Game.setting_i("difficulty"), 3, 120)
	spectator = bool(config.get("spectator", false))
	training = str(config.get("training", ""))
	Fighter.tempo_level = Game.test_int("tempo", Game.setting_i("fight_tempo")) if Game.autotest else Game.setting_i("fight_tempo")
	total_rounds = int(config.get("rounds", 3))
	round_seconds = float(config.get("round_seconds", 120))
	time_left = round_seconds

	arena_refs = Arena.build(self, Arena.venue_for(config))
	blood_fx = BloodFx.new()
	add_child(blood_fx)
	judges = Judges.new()
	_spawn_fighters()
	_spawn_referee()

	camera = FightCamera.new()
	add_child(camera)
	camera.current = true
	camera.shake_scale = Game.setting_f("camera_shake")
	cam_mode_saved = Game.setting_i("camera_mode")
	if Game.autotest and Game.test_int("cam", -1) >= 0:
		cam_mode_saved = Game.test_int("cam", 0)
	camera.mode = FightCamera.Mode.ORBIT


	var sl: = CanvasLayer.new()
	sl.layer = 1
	add_child(sl)
	var sr: = ColorRect.new()
	sr.set_anchors_preset(Control.PRESET_FULL_RECT)
	sr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_mat = ShaderMaterial.new()
	post_mat.shader = preload("res://scripts/visual/sharpen.gdshader")
	post_mat.set_shader_parameter("sharpness", 0.55 if Game.setting_b("sharpen") else 0.0)
	sr.material = post_mat
	sl.add_child(sr)

	hud = FightHUD.new()
	add_child(hud)
	hud.setup(red, blue, Game.setting_b("show_health"))
	hud.getup_success.connect(_on_player_getup)
	hud.player_ctrl = player_ctrl

	screens = FightScreens.new()
	add_child(screens)
	screens.fight = self

	_reset_round_stats()
	for i in 2:
		totals[i] = _empty_stats()
	Sfx.start_crowd()
	if training != "":
		_start_training()
		return
	_start_intro()


func _exit_tree() -> void :
	Engine.time_scale = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE




func _spawn_fighters() -> void :
	var use_mixamo: = Game.setting_b("use_mixamo")
	red = Fighter.new()
	red.name = "Red"
	add_child(red)
	red.global_position = Arena.CORNERS["red"]
	red.setup(config["red"], 0, not spectator, use_mixamo)
	blue = _make_blue(config["blue"] if training != "bag" else BAG_DEF, use_mixamo)
	red.opponent = blue
	blue.opponent = red
	fighters = [red, blue]
	red.punch_started.connect(_on_punch_started)
	red.punch_resolved.connect(_on_punch_resolved)
	red.clinch_requested.connect(_on_clinch_requested)
	red.guard_broken.connect(_on_guard_broken)
	if training != "":
		red.training = true
		player = red
		if Game.autotest:
			var ai_t: = BoxerAI.new()
			ai_t.setup(red, blue, 3)
			ais.append(ai_t)
		else:
			player_ctrl = PlayerController.new()
			player_ctrl.setup(red)
		if training == "spar":
			_add_spar_ai()
		return
	var diff: = int(config.get("difficulty", 2))
	if spectator:
		for f in fighters:
			var ai: = BoxerAI.new()
			ai.setup(f, f.opponent, diff)
			ais.append(ai)
		player = null
	else:
		player = red
		if Game.autotest:

			var ai_p: = BoxerAI.new()
			ai_p.setup(red, blue, diff)
			ais.append(ai_p)
		else:
			player_ctrl = PlayerController.new()
			player_ctrl.setup(red)
		var ai2: = BoxerAI.new()
		ai2.setup(blue, red, diff)
		ais.append(ai2)


const BAG_DEF: = {"bag": true, "id": "bag", "name": "Груша", "height": 1.8, "stance": 1}


func _make_blue(def: Dictionary, use_mixamo: bool) -> Fighter:
	var f: = Fighter.new()
	f.name = "Blue"
	add_child(f)
	f.global_position = Arena.CORNERS["blue"]
	f.setup(def, 1, false, use_mixamo)
	f.punch_started.connect(_on_punch_started)
	f.punch_resolved.connect(_on_punch_resolved)
	f.clinch_requested.connect(_on_clinch_requested)
	f.guard_broken.connect(_on_guard_broken)
	if training == "spar":
		f.training = true
	return f


func _add_spar_ai() -> void :
	var ai: = BoxerAI.new()
	ai.setup(blue, red, int(config.get("difficulty", 1)))
	ai.spar = true
	ais.append(ai)


func _spawn_referee() -> void :
	referee_root = Node3D.new()
	referee_root.name = "Referee"
	add_child(referee_root)
	referee_root.global_position = Vector3(0, 0, 2.0)
	if RefereeRig.available_model() and Game.setting_b("use_mixamo"):
		var rr: = RefereeRig.new()
		referee_root.add_child(rr)
		rr.setup_referee()
		referee = rr
	else:
		var pr: = ProceduralRig.new()
		referee_root.add_child(pr)
		pr.setup({"referee": true, "height": 1.78, "stance": 1, "skin": Roster.SKIN_TONES[1], 
			"hair": Color(0.55, 0.55, 0.57), "bald": false}, null)
		referee = pr




func _start_training() -> void :
	phase = Phase.FIGHT
	referee_root.visible = false
	referee_root.global_position = Vector3(2.2, 0, 2.2)
	red.reset_for_round()
	blue.reset_for_round()
	red.global_position = Vector3(-0.35, 0, 0.75)
	blue.global_position = Vector3(0.35, 0, -0.55) if training == "bag" else Vector3(0.6, 0, -0.6)
	red.begin_fight_state()
	blue.begin_fight_state()
	camera.mode = cam_mode_saved
	camera.snap()
	hud.set_top_visible(training == "spar")
	hud.set_clock_visible(false)
	hud.set_fade(1.0)
	hud.fade_to(0.0, 0.6)
	hud.setup_training(training)
	hud.flash_message("ТРЕНИРОВКА" if training == "bag" else "СПАРРИНГ", Game.ACCENT, 110, 0.9)
	Sfx.stop_music(1.5)
	Sfx.set_crowd(0.12)
	excitement = 0.05


func _tick_training(dt: float) -> void :
	_train_clock += dt
	excitement = 0.05

	if training == "spar":
		for f in fighters:
			f.cut = minf(f.cut, 40.0)


func _train_punch(p: Dictionary, res: Dictionary) -> void :
	var outcome: String = res["outcome"]
	var name: = Punches.display_name(int(p["type"]), bool(p["body"]), bool(p["power"]))
	var dmg: = float(res.get("damage", 0.0))
	var landed: = outcome == "hit"
	train_stats["last"] = name
	train_stats["last_t"] = _train_clock
	train_stats["last_outcome"] = outcome
	if landed:
		train_stats["landed"] = int(train_stats["landed"]) + 1
		train_stats["last_dmg"] = dmg
		train_stats["best"] = maxf(float(train_stats["best"]), dmg)
		if _train_clock - float(train_stats.get("combo_t", -10.0)) < 1.3:
			train_stats["combo"] = int(train_stats["combo"]) + 1
		else:
			train_stats["combo"] = 1
		train_stats["combo_t"] = _train_clock
		train_stats["best_combo"] = maxi(int(train_stats["best_combo"]), int(train_stats["combo"]))
	else:
		train_stats["last_dmg"] = 0.0



func _switch_training() -> void :
	training = "spar" if training == "bag" else "bag"
	config["training"] = training
	var use_mixamo: = Game.setting_b("use_mixamo")
	_end_clinch()
	for ai in ais.duplicate():
		var a: BoxerAI = ai
		if a.me == blue:
			ais.erase(a)
	var old: = blue
	var def: Dictionary = config["blue"] if training == "spar" else BAG_DEF
	if training == "spar" and bool(def.get("bag", false)):
		def = Roster.fighters()[0]
	blue = _make_blue(def, use_mixamo)
	old.queue_free()
	red.opponent = blue
	blue.opponent = red
	fighters = [red, blue]
	for ai in ais:
		var a2: BoxerAI = ai
		a2.opp = blue
	if training == "spar":
		_add_spar_ai()
	blue.global_position = red.global_position + (Vector3(0.9, 0, -0.9) if red.global_position.length() < 1.5 else - red.global_position.normalized() * 1.3)
	blue.begin_fight_state()
	hud.setup(red, blue, Game.setting_b("show_health"))
	hud.set_top_visible(training == "spar")
	hud.set_clock_visible(false)
	hud.setup_training(training)
	hud.flash_message("ГРУША" if training == "bag" else "СПАРРИНГ", Game.ACCENT, 90, 0.7)


func _on_guard_broken(f: Fighter) -> void :
	Sfx.play("block", 2.0, 0.05, 0.75)
	Sfx.play("punch_heavy", -6.0, 0.05)
	if f == player:
		PlayerController.rumble(0.6, 0.6, 0.25)




static func _empty_stats() -> Dictionary:
	return {
		"thrown": 0, "landed": 0, "power_thrown": 0, "power_landed": 0, "jab_thrown": 0, "jab_landed": 0, 
		"head_landed": 0, "body_landed": 0, "damage": 0.0, "counters": 0, "blocked": 0, "parries": 0, 
		"slips": 0, "kd_scored": 0, "kd_suffered": 0, 
	}


func _reset_round_stats() -> void :
	stats = [_empty_stats(), _empty_stats()]


func _merge_round_stats() -> void :
	for i in 2:
		var t: Dictionary = totals[i]
		var s: Dictionary = stats[i]
		for k in s.keys():
			t[k] = t.get(k, 0) + s[k]
	_reset_round_stats()


func _inc(corner: int, key: String, amount: float = 1.0) -> void :
	var s: Dictionary = stats[corner]
	if s[key] is float:
		s[key] = float(s[key]) + amount
	else:
		s[key] = int(s[key]) + int(amount)




func _sequence(steps: Array) -> void :
	_seq = steps
	_seq_t = 0.0


func _run_seq(real_dt: float) -> void :
	if _seq.is_empty():
		return
	_seq_t += real_dt
	while not _seq.is_empty():
		var step: Array = _seq[0]
		var at: float = step[0]
		if _seq_t < at:
			break
		_seq.pop_front()
		var cb: Callable = step[1]
		cb.call()


func _start_intro() -> void :
	phase = Phase.INTRO
	_place_in_corners()
	Sfx.play_group("walkout", 1.2, 0.85, false)
	camera.mode = FightCamera.Mode.ORBIT
	camera.orbit_angle = 0.4
	camera.snap()
	hud.set_top_visible(false)
	hud.set_fade(1.0)
	hud.fade_to(0.0, 0.8)
	if not Game.autotest or Game.test_flag("intro"):
		hud.set_cinematic(true)
	var vs: = "%s\nпротив\n%s" % [Roster.display_full(red.def), Roster.display_full(blue.def)]
	if Game.autotest and not Game.test_flag("intro"):
		_sequence([
			[0.6, func(): hud.flash_message(vs, Game.TEXT, 64, 2.4)], 
			[3.6, _start_round_sequence], 
		])
		return


	_intro_skip = true
	_sequence([
		[0.2, _intro_establish], 
		[4.2, func(): _present(red, "warmup")], 
		[8.4, func(): _present(blue, "taunt" if blue.rig is MixamoRig and (blue.rig as MixamoRig).available.has("taunt") else "warmup")], 
		[12.6, func(): _intro_faceoff(vs)], 
		[16.4, func():
			hud.set_fade(0.0)
			hud.fade_to(1.0, 0.35)], 
		[16.8, func():
			_place_in_corners()
			for f in fighters:
				if f.rig:
					f.rig.on_reset()
			camera.stop_dolly()
			camera.mode = FightCamera.Mode.ORBIT
			camera.snap()
			hud.fade_to(0.0, 0.5)], 
		[17.2, _end_intro], 
	])



func _intro_establish() -> void :
	var a: = Vector3(6.5, 6.8, 7.5)
	var b: = Vector3(4.6, 2.3, 5.4)
	camera.dolly(a, b, Vector3(0, 0.2, 0), Vector3(0, 1.0, 0), 4.0, 48.0)
	hud.flash_message("%s\nГЛАВНЫЙ БОЙ ВЕЧЕРА" % Arena.venue_name(str(arena_refs.get("venue", "arena"))).to_upper(), Game.ACCENT, 50, 3.2)
	Sfx.cheer(0.5)



func _intro_faceoff(vs: String) -> void :
	var dir: = (blue.global_position - red.global_position)
	dir.y = 0.0
	dir = dir.normalized()
	red.global_position = - dir * 0.5
	blue.global_position = dir * 0.5
	red.rotation.y = atan2( - dir.x, - dir.z)
	blue.rotation.y = atan2(dir.x, dir.z)
	for f in fighters:
		if f.rig:
			f.rig.on_reset()
	var side: = Vector3( - dir.z, 0.0, dir.x)
	_clear_hero_light()
	_faceoff = true
	for f in fighters:
		f.auto_walk = false
		f.velocity = Vector3.ZERO

	referee_root.global_position = side * 1.0
	var h: = maxf(red.height_m, blue.height_m) * 0.9
	camera.dolly( - side * 2.6 + Vector3(0, h + 0.05, 0) + dir * 0.15, - side * 1.75 + Vector3(0, h, 0), 
		Vector3(0, h - 0.05, 0), Vector3(0, h - 0.02, 0), 3.8, 38.0)
	hud.show_plate("ГЛАВНЫЙ БОЙ", Roster.display_full(red.def) + "  vs  " + Roster.display_full(blue.def), 
		Arena.venue_name(str(arena_refs.get("venue", "arena"))) + "  •  %d раунд(ов)" % total_rounds, Game.ACCENT, 3.0)
	Sfx.cheer(0.8)


func _present(f: Fighter, anim: String) -> void :
	if f.rig:
		f.rig.play_show(anim)
	var to_center: = - f.global_position
	to_center.y = 0.0
	to_center = to_center.normalized()
	var side: = Vector3( - to_center.z, 0.0, to_center.x)

	var h: = f.height_m
	var from: = f.global_position + to_center * 3.0 + side * 1.1 + Vector3(0, h * 0.55, 0)
	var to: = f.global_position + to_center * 2.0 + side * 0.55 + Vector3(0, h * 0.62, 0)
	camera.dolly(from, to, f.global_position + Vector3(0, h * 0.72, 0), f.global_position + Vector3(0, h * 0.8, 0), 4.0, 40.0)
	var d: = f.def
	var nick: = str(d.get("nick", ""))
	var line2: = str(d.get("name", "")).to_upper() + (("  «%s»" % nick) if nick != "" else "")
	var line3: = "%s  •  %s  •  %s" % [UIKit.country_name(str(d.get("country", ""))), str(d.get("record", "")), Roster.style_name(str(d.get("style", "balanced")))]
	hud.show_plate("КРАСНЫЙ УГОЛ" if f == red else "СИНИЙ УГОЛ", line2, line3, UIKit.RED if f == red else UIKit.BLUE, 3.2)
	_hero_light(f)
	Sfx.cheer(0.7)


func _end_intro() -> void :
	_intro_skip = false
	_faceoff = false
	_clear_hero_light()
	hud.set_cinematic(false)
	_start_round_sequence()



var _hero_lights: Array = []
var _faceoff: = false


func _hero_light(f: Fighter) -> void :
	_clear_hero_light()
	var to_center: = - f.global_position
	to_center.y = 0.0
	to_center = to_center.normalized() if to_center.length() > 0.1 else Vector3(0, 0, 1)
	var head: = f.global_position + Vector3(0, f.height_m * 0.85, 0)
	var key: = SpotLight3D.new()
	add_child(key)
	key.look_at_from_position(head + to_center * 1.6 + Vector3(0, 2.2, 0) + Vector3( - to_center.z, 0, to_center.x) * 0.8, head, Vector3.UP)
	key.spot_range = 6.0
	key.spot_angle = 24.0
	key.light_energy = 3.2
	key.light_color = Color(1.0, 0.9, 0.78)
	key.shadow_enabled = true
	key.light_size = 0.15
	key.light_volumetric_fog_energy = 0.4
	var rim: = SpotLight3D.new()
	add_child(rim)
	rim.look_at_from_position(head - to_center * 1.8 + Vector3(0, 1.4, 0), head, Vector3.UP)
	rim.spot_range = 6.0
	rim.spot_angle = 28.0
	rim.light_energy = 4.0
	rim.light_color = Color(0.7, 0.82, 1.0)
	rim.light_specular = 1.2
	rim.light_volumetric_fog_energy = 0.45
	_hero_lights = [key, rim]


func _clear_hero_light() -> void :
	for l in _hero_lights:
		if is_instance_valid(l):
			(l as Node).queue_free()
	_hero_lights = []



func _victory_camera(winner: Fighter) -> void :
	if winner == null or not is_instance_valid(winner):
		return
	var to_center: = - winner.global_position
	to_center.y = 0.0
	if to_center.length() < 0.3:
		to_center = winner.global_transform.basis.z
	to_center = to_center.normalized()
	camera.mode = FightCamera.Mode.FOCUS
	camera.focus_target = winner.global_position + Vector3(0, 1.45, 0)
	camera.focus_from = winner.global_position + (winner.global_transform.basis.z * -1.0 + to_center).normalized() * 2.8 + Vector3(0, 1.7, 0)


func _place_in_corners() -> void :
	red.reset_for_round()
	blue.reset_for_round()
	red.global_position = Arena.CORNERS["red"]
	blue.global_position = Arena.CORNERS["blue"]
	red.rotation.y = atan2( - (blue.global_position.x - red.global_position.x), - (blue.global_position.z - red.global_position.z))
	blue.rotation.y = atan2( - (red.global_position.x - blue.global_position.x), - (red.global_position.z - blue.global_position.z))
	referee_root.global_position = Vector3(0, 0, 0)


func _start_round_sequence() -> void :
	phase = Phase.INTRO
	hud.set_top_visible(true)
	time_left = round_seconds
	warned_10s = false
	unanswered = [0, 0]
	_sequence([
		[0.1, _round_announce], 
		[1.2, _round_camera], 
		[2.0, _begin_fighting], 
	])


func _round_announce() -> void :
	hud.flash_message("РАУНД %d" % round_num, Game.ACCENT, 120, 1.0)
	Sfx.play_bell(1)
	red.walk_to(START_RED)
	blue.walk_to(START_BLUE)
	referee.ref_action = "start"


func _round_camera() -> void :
	camera.mode = cam_mode_saved
	camera.snap()


func _begin_fighting() -> void :
	phase = Phase.FIGHT
	referee.ref_action = ""
	for f in fighters:
		f.begin_fight_state()
	hud.flash_message("БОЙ!", Game.ACCENT_RED, 130, 0.5)
	Sfx.set_crowd(0.45)
	Sfx.stop_music(2.5)




func _process(delta: float) -> void :

	var real_dt: = clampf(delta / maxf(Engine.time_scale, 0.001), 0.0, 0.1)
	_update_time_scale(real_dt)
	var dt: = minf(delta, 0.05)
	_run_seq(real_dt)
	if Game.autotest:
		_autotest_tick(real_dt)

	match phase:
		Phase.FIGHT:
			if player_ctrl:
				player_ctrl.tick(dt)
			for ai in ais:
				ai.tick(dt)
			_update_clinch(dt)
			if training != "":
				_tick_training(dt)
			else:
				time_left -= dt
			if training == "" and time_left <= 10.0 and not warned_10s:
				warned_10s = true
				Sfx.play("tick", 0.0, 0.0, 0.8)
				hud.feed_message("10 секунд!", Game.ACCENT)
			if training == "" and time_left <= 0.0:
				time_left = 0.0
				_end_round()
		Phase.KNOCKDOWN:
			_update_knockdown(dt)

	for f in fighters:
		f.tick(dt)
		if blood_fx and phase != Phase.INTRO:
			blood_fx.tick_fighter(f, dt)
	_separate_fighters(dt)
	_update_ropes(dt)
	if training == "":
		_update_referee(dt)
	var cam_a: Fighter = player if player else red
	camera.update_camera(dt, cam_a, cam_a.opponent)
	hud.update_hud(real_dt, round_num, total_rounds, time_left)
	if training != "":
		hud.update_training(train_stats, training, _train_clock)
	_update_vision()
	_update_crowd(real_dt)
	_update_mouse_capture()
	if post_mat:
		_impact_pulse = maxf(0.0, _impact_pulse - real_dt * 7.0)
		post_mat.set_shader_parameter("impact", _impact_pulse)



func _update_mouse_capture() -> void :
	var want: = phase == Phase.FIGHT and player_ctrl != null and not spectator and not Game.autotest\
	and Game.setting_b("mouse_punch") and not get_tree().paused
	var mm: = Input.MOUSE_MODE_CAPTURED if want else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != mm:
		Input.mouse_mode = mm


func _update_time_scale(real_dt: float) -> void :
	hitstop_real = maxf(0.0, hitstop_real - real_dt)
	slowmo_real = maxf(0.0, slowmo_real - real_dt)
	var ts: = 1.0
	if slowmo_real > 0.0:
		ts = 0.28
	if hitstop_real > 0.0:
		ts = 0.05
	if Game.autotest and Game.test_flag("fast"):
		ts *= 4.0
	Engine.time_scale = ts


func _unhandled_input(event: InputEvent) -> void :
	if _intro_skip and phase == Phase.INTRO and (event.is_action_pressed("ui_accept") or event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		_intro_skip = false
		_seq = []
		camera.stop_dolly()
		_place_in_corners()
		_faceoff = false
		_clear_hero_light()
		hud.set_cinematic(false)
		hud.set_fade(0.0)
		camera.mode = FightCamera.Mode.ORBIT
		camera.snap()
		for f in fighters:
			if f.rig:
				f.rig.on_reset()
		_start_round_sequence()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause") and phase != Phase.ENDED and phase != Phase.CORNER:
		screens.show_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_hints"):
		hud.toggle_hints()
		return
	if event.is_action_pressed("camera_toggle"):
		camera.cycle_mode()
		cam_mode_saved = camera.mode
		Game.settings["camera_mode"] = cam_mode_saved
		hud.feed_message("Камера: " + str(FightCamera.CYCLE_NAMES[FightCamera.cycle_index(camera.mode)]), Game.TEXT_DIM)
		return
	if training != "" and event.is_action_pressed("train_target"):
		_switch_training()
		get_viewport().set_input_as_handled()
		return
	if hud.getup_is_active() and event.is_action_pressed("getup"):
		hud.getup_press()
		get_viewport().set_input_as_handled()
		return
	if phase == Phase.FIGHT and player_ctrl:
		player_ctrl.handle_event(event)




func _on_punch_started(f: Fighter, p: Dictionary) -> void :
	var c: = f.corner
	if training != "" and f == player:
		train_stats["thrown"] = int(train_stats["thrown"]) + 1
		if bool(p["power"]):
			train_stats["power"] = int(train_stats["power"]) + 1
	_inc(c, "thrown")
	if bool(p["power"]):
		_inc(c, "power_thrown")
		Sfx.play("whoosh", -9.0, 0.1, 0.8)

		Sfx.play("exhale", -11.0 if f == player else -16.0, 0.08)
	elif _rng.randf() < 0.25:
		Sfx.play("exhale", -18.0 if f == player else -22.0, 0.1, 1.08)
	if int(p["type"]) == Punches.Type.JAB:
		_inc(c, "jab_thrown")


func _on_punch_resolved(attacker: Fighter, defender: Fighter, p: Dictionary, res: Dictionary) -> void :
	var ac: = attacker.corner
	var dc: = defender.corner
	var outcome: String = res["outcome"]
	var pw: bool = p["power"]
	var body: bool = p["body"]
	var t: int = p["type"]
	var dmg: float = float(res.get("damage", 0.0))
	var player_involved: = attacker == player or defender == player or spectator
	if training != "" and attacker == player:
		_train_punch(p, res)
	match outcome:
		"miss":
			Sfx.play("whoosh", -10.0, 0.15)
			if attacker == player and training != "":
				train_stats["combo"] = 0
		"slipped":
			Sfx.play("whoosh", -6.0, 0.1, 1.2)
			_inc(dc, "slips")
			if bool(res.get("perfect", false)) and player_involved:
				hud.feed_message("ИДЕАЛЬНЫЙ УКЛОН" if defender == player or spectator else "Он ушёл от удара", Game.ACCENT)
				if defender == player and Game.setting_b("slowmo"):
					slowmo_real = maxf(slowmo_real, 0.35)
		"parried":
			Sfx.play("parry", -1.0)
			_inc(dc, "parries")
			camera.add_trauma(0.12)
			if player_involved:
				hud.feed_message("ПАРИРОВАНИЕ!", Game.ACCENT)
			if defender == player and Game.setting_b("slowmo"):
				slowmo_real = maxf(slowmo_real, 0.3)
		"blocked":
			Sfx.play("block", -3.0 + (3.0 if pw else 0.0))
			_inc(ac, "blocked")
			if player_involved:
				camera.add_trauma(0.04 + dmg * 0.02)
			if defender == player:
				PlayerController.rumble(0.35, 0.1, 0.08)
				if float(res.get("guard", 1.0)) < 0.3:
					hud.feed_message("Гард слабеет!", Game.ACCENT_RED)
		"hit":
			_on_clean_hit(attacker, defender, p, res, ac, dc, pw, body, t, dmg)
	if outcome == "hit" and bool(res.get("guard_break", false)):
		hud.feed_message("ГАРД ПРОБИТ!" if defender == player else "ПРОБИЛ ЗАЩИТУ!", Game.ACCENT_RED)


func _on_clean_hit(attacker: Fighter, defender: Fighter, _p: Dictionary, res: Dictionary, 
		ac: int, dc: int, pw: bool, body: bool, t: int, dmg: float) -> void :
	if Game.test_flag("hits"):
		Game.tlog("%.1f HIT %s -> %s %s dmg %.1f ctr %s stun %s kd %s | def head %.2f" % [time_left, attacker.display_name, defender.display_name, Punches.display_name(t, body, pw), dmg, str(res.get("counter", false)), str(res.get("stun", false)), str(res.get("kd", false)), defender.head_ratio()])
	_inc(ac, "landed")
	if pw:
		_inc(ac, "power_landed")
	if t == Punches.Type.JAB:
		_inc(ac, "jab_landed")
	_inc(ac, "body_landed" if body else "head_landed")
	_inc(ac, "damage", dmg)
	var counter: bool = res.get("counter", false)
	if counter:
		_inc(ac, "counters")
		if attacker == player or defender == player or spectator:
			hud.feed_message("КОНТРАТАКА!", Game.ACCENT_RED if defender == player else Game.ACCENT)

	if defender.is_bag:
		Sfx.hit("bag", -3.0 + minf(dmg * 0.3, 5.0), 0.06)
	elif body:
		Sfx.hit("punch_body", -2.0 + minf(dmg * 0.25, 4.0))
	elif dmg >= 10.0 or pw:
		Sfx.hit("punch_heavy", minf(dmg * 0.2, 4.0))
	else:
		Sfx.hit("punch_light", -2.0)

	if dmg >= Balance.HITSTOP_MIN_DMG:
		hitstop_real = maxf(hitstop_real, clampf(0.025 + dmg * 0.0045, float(Balance.HITSTOP[0]), float(Balance.HITSTOP[1])))
	var shake: = Balance.SHAKE_BASE + dmg * Balance.SHAKE_PER_DMG
	if defender == player:
		shake *= 1.5

	if pw or counter or dmg >= 8.0:
		_impact_pulse = maxf(_impact_pulse, clampf(0.35 + dmg * 0.04, 0.35, 1.0))
	camera.add_trauma(shake)
	camera.kick(minf(dmg * 0.25, 5.0))

	var push_dir: = defender.global_position - attacker.global_position
	push_dir.y = 0.0
	push_dir = push_dir.normalized()
	if attacker == player:
		camera.nudge(push_dir, 0.25 + dmg * 0.05)
		PlayerController.rumble(0.25 + dmg * 0.02, 0.15 + dmg * 0.03, 0.09)
	elif defender == player:
		camera.nudge(push_dir, 0.4 + dmg * 0.07)
		PlayerController.rumble(0.4, 0.3 + dmg * 0.04, 0.16)
	if not defender.is_bag:
		_spawn_hit_fx(attacker, defender, body, dmg, float(res.get("bleed", 0.0)))
	if training != "":
		return
	excitement = minf(1.0, excitement + dmg * 0.018)
	if dmg >= 12.0:
		flash_boost = minf(1.0, flash_boost + dmg * 0.03)
		Sfx.cheer(0.4 + dmg / 30.0)

	var best: Dictionary = best_punch[ac]
	if dmg > float(best.get("damage", 0.0)):
		best_punch[ac] = {"damage": dmg, "name": Punches.display_name(t, body, pw), "round": round_num}

	if bool(res.get("stun", false)):
		hud.feed_message("ОН ПОПЛЫЛ! ДОБИВАЙ — силовые и апперкоты" if defender != player else "ТЕБЯ ШАТАЕТ! Клинч (G) или уходи назад", Game.ACCENT_RED)
		Sfx.cheer(0.9)
		excitement = 1.0


	if defender.stun_timer > 0.0:
		unanswered[dc] = int(unanswered[dc]) + 1
	else:
		unanswered[dc] = 0
	unanswered[ac] = 0
	if int(unanswered[dc]) >= Balance.REF_STOP_UNANSWERED and defender.head_ratio() < Balance.REF_STOP_HP and not bool(res.get("kd", false)):
		_end_fight(attacker, "TKO (остановка рефери)")
		return

	if defender.cut >= 70.0 and not bool(cut_warned[dc]):
		cut_warned[dc] = true
		hud.feed_message("Врач осматривает рассечение", Game.TEXT)
	if defender.cut >= Balance.CUT_STOP and not bool(res.get("kd", false)):
		_end_fight(attacker, "TKO (рассечение)")
		return

	if bool(res.get("kd", false)):
		_on_knockdown(defender, attacker, bool(res.get("flash", false)), bool(res.get("cold", false)))


static var _mist_tex: GradientTexture2D


static func _mist_texture() -> GradientTexture2D:
	if _mist_tex == null:
		var g: = Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.45, Color(1, 1, 1, 0.45))
		_mist_tex = GradientTexture2D.new()
		_mist_tex.gradient = g
		_mist_tex.fill = GradientTexture2D.FILL_RADIAL
		_mist_tex.fill_from = Vector2(0.5, 0.5)
		_mist_tex.fill_to = Vector2(1.0, 0.5)
		_mist_tex.width = 64
		_mist_tex.height = 64
	return _mist_tex




func _spawn_hit_fx(attacker: Fighter, defender: Fighter, body: bool, dmg: float, bleed: float = 0.0) -> void :
	var dir: = defender.global_position - attacker.global_position
	dir.y = 0.0
	dir = dir.normalized()
	var origin: Vector3
	if body:
		origin = defender.global_position + Vector3(0, 1.2 * defender.height_m / 1.8, 0) - dir * 0.12
	else:
		origin = defender.head_global() - dir * 0.08
	var wet: = clampf(0.45 + defender.sweat * 0.9, 0.0, 1.0)

	var bl: = bleed
	if not body and dmg > 8.0:
		bl = maxf(bl, clampf((dmg - 8.0) * 0.06, 0.0, 0.5))
	var bloody: = not body and bl > 0.06
	_mist_puff(origin, dir, dmg, Color(0.85, 0.87, 0.9, 0.34 * wet), int(clampf(dmg * 1.4 * wet, 5.0, 22.0)))
	if bloody:
		_mist_puff(origin, dir, dmg, Color(0.42, 0.015, 0.02, 0.55), int(clampf(dmg * bl * 2.0 + 3.0, 3.0, 14.0)))
	if blood_fx:
		blood_fx.spray(origin, dir + Vector3(0, 0.35, 0), dmg * 1.3, 0.0 if body else bl, maxf(defender.sweat, 0.45) * (0.8 if body else 1.2))


func _mist_puff(origin: Vector3, dir: Vector3, dmg: float, col: Color, amount: int) -> void :
	var p: = CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = maxi(amount, 2)
	p.lifetime = 0.45
	p.explosiveness = 0.95
	p.direction = dir + Vector3(0, 0.25, 0)
	p.spread = 30.0
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.4 + dmg * 0.06
	p.damping_min = 2.0
	p.damping_max = 4.0
	p.gravity = Vector3(0, -1.5, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var curve: = Curve.new()
	curve.add_point(Vector2(0.0, 0.4))
	curve.add_point(Vector2(1.0, 1.6))
	p.scale_amount_curve = curve
	var grad: = Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = grad
	var q: = QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	var m: = StandardMaterial3D.new()
	m.albedo_texture = _mist_texture()
	m.albedo_color = col
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.roughness = 1.0
	m.metallic_specular = 0.0
	m.disable_receive_shadows = true
	q.material = m
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	p.global_position = origin
	p.emitting = true
	get_tree().create_timer(1.2, false).timeout.connect(p.queue_free)




func _on_knockdown(down: Fighter, scorer: Fighter, flash: bool, cold: bool = false) -> void :
	Game.tlog("KNOCKDOWN %s (total %d, flash %s, cold %s) at %.1f" % [down.display_name, down.knockdowns_total + 0, str(flash), str(cold), time_left])
	_end_clinch()
	phase = Phase.KNOCKDOWN

	scorer.regen_boost = 2.6
	if cold and down.rig is MixamoRig:
		var push: = down.global_position - scorer.global_position
		push.y = 0.0
		(down.rig as MixamoRig).start_ragdoll(push.normalized() * 2.2)
	if down == player or scorer == player:
		PlayerController.rumble(0.8, 1.0, 0.45)
	_inc(scorer.corner, "kd_scored")
	_inc(down.corner, "kd_suffered")
	scorer.clear_inputs()
	scorer.state = Fighter.State.INACTIVE
	var na: Vector3 = Arena.CORNERS["neutral_a"]
	var nb: Vector3 = Arena.CORNERS["neutral_b"]
	var corner: = na if na.distance_to(down.global_position) > nb.distance_to(down.global_position) else nb
	scorer.walk_to(corner * 0.92)
	if Game.setting_b("slowmo"):
		slowmo_real = Balance.KD_SLOWMO
	hitstop_real = Balance.KD_HITSTOP
	camera.mode = FightCamera.Mode.FOCUS
	var side: = down.global_transform.basis.x
	camera.focus_from = down.global_position + side * 2.3 + Vector3(0, 1.4, 0) + down.global_transform.basis.z * 0.8
	camera.focus_target = down.global_position + Vector3(0, 0.5, 0) + down.global_transform.basis.z * 0.5
	if cold:

		var fall: = down.global_position - scorer.global_position
		fall.y = 0.0
		fall = fall.normalized() if fall.length() > 0.01 else Vector3(0, 0, 1)
		var perp: = fall.cross(Vector3.UP)
		if (down.global_position + perp * 3.0).length() > (down.global_position - perp * 3.0).length():
			perp = - perp
		camera.focus_from = down.global_position + perp * 3.4 + Vector3(0, 1.9, 0) - fall * 0.4
		camera.focus_target = down.global_position + fall * 0.7 + Vector3(0, 0.6, 0)
		camera.snap()
	camera.add_trauma(0.6)
	var kd_text: = "НОКДАУН!" if not flash else "НОКДАУН С ОДНОГО УДАРА!"
	if cold:
		kd_text = "НОКАУТ!"
	hud.flash_message(kd_text, Game.ACCENT_RED, 120 if not flash else 90, 1.2)
	Sfx.cheer(1.4)
	excitement = 1.0
	flash_boost = 1.0
	get_tree().create_timer(0.55, false).timeout.connect( func(): Sfx.play("thud", 2.0, 0.05))
	kd = {"f": down, "scorer": scorer, "count": 0, "t": 0.0, "next": 1.8, "getup_at": -1, 
		"standing": false, "final": down.knockdowns_round >= 3 or cold, "minigame": false, "cold": cold}
	if bool(kd["final"]):
		if cold:
			referee.ref_action = "wave"
			if Game.setting_b("slowmo"):
				slowmo_real = 1.6
		return
	var player_down: = down == player and not spectator
	if player_down:
		kd["minigame"] = true
	else:
		var g: Dictionary = Balance.AI_GETUP
		var prob: = float(g["base"]) - float(g["per_kd"]) * float(down.knockdowns_total - 1) - (1.0 - down.head_max_ratio()) * float(g["wear"]) + down.chin / 100.0 * float(g["chin"])
		if flash:
			prob += float(g["flash"])
		prob = clampf(prob, 0.05, 0.97)
		if _rng.randf() < prob:
			kd["getup_at"] = clampi(_rng.randi_range(3, 7) + down.knockdowns_total - 1, 3, 9)


func _update_knockdown(dt: float) -> void :
	if kd.is_empty():
		return
	var down: Fighter = kd["f"]
	var scorer: Fighter = kd["scorer"]
	kd["t"] = float(kd["t"]) + dt
	var t: float = kd["t"]
	if camera.mode == FightCamera.Mode.FOCUS and t > 0.5:
		_kd_camera(down, dt)
	if bool(kd["final"]):
		if Game.test_flag("cold") and down.rig:
			Game.tlog("RAG t=%.2f head %s pos %s" % [t, str(down.rig.get_head_global()), str(down.global_position)])
		if t > (2.4 if bool(kd.get("cold", false)) else 1.8):
			_end_fight(scorer, "KO" if bool(kd.get("cold", false)) else "TKO (3 нокдауна)")
		return
	if bool(kd["minigame"]) and t > 1.3 and not hud.getup_is_active() and not bool(kd["standing"]):
		hud.getup_begin(down.knockdowns_total, 1.0 - down.head_max_ratio())
		kd["minigame"] = false
	var next: float = kd["next"]
	if t >= next:
		kd["next"] = next + 1.0
		var c: = int(kd["count"]) + 1
		kd["count"] = c
		var standing: bool = kd["standing"]
		if not standing or c <= 8:
			hud.show_count(c)
			Sfx.play("tick", -2.0, 0.0)
			referee.ref_pulse = referee._t
			referee.ref_action = "count"
		if not standing:
			if int(kd["getup_at"]) == c:
				_begin_standup(down, scorer)
			elif c >= 10:
				hud.getup_end()
				_end_fight(scorer, "KO")
				return
	if bool(kd["standing"]) and int(kd["count"]) >= 8 and down.state == Fighter.State.IDLE:
		_resume_after_kd()



func _kd_camera(down: Fighter, dt: float) -> void :
	var head: Vector3 = down.rig.get_head_global() if down.rig else down.global_position + Vector3(0, 0.4, 0)
	var refp: = referee_root.global_position + Vector3(0, 1.2, 0)
	var tgt: = head.lerp(refp, 0.42)
	tgt.y = clampf(tgt.y, 0.7, 1.3)
	var line: = refp - head
	line.y = 0.0
	if line.length() < 0.1:
		line = Vector3(1, 0, 0)
	var side: = line.normalized().cross(Vector3.UP)
	if (tgt + side * 3.0).length() > (tgt - side * 3.0).length():
		side = - side
	var dist: = clampf(2.6 + line.length() * 0.6, 2.8, 4.2)
	var from: = tgt + side * dist + Vector3(0, 0.9, 0)
	var k: = clampf(dt * 2.5, 0.0, 1.0)
	camera.focus_target = camera.focus_target.lerp(tgt, k)
	camera.focus_from = camera.focus_from.lerp(from, k)


func _on_player_getup() -> void :
	if phase != Phase.KNOCKDOWN or kd.is_empty():
		return
	if int(kd["count"]) >= 10:
		return
	_begin_standup(kd["f"], kd["scorer"])


func _begin_standup(down: Fighter, scorer: Fighter) -> void :
	kd["standing"] = true
	hud.getup_end()
	down.start_getup(2.4 if down.rig is MixamoRig else 1.4)
	Sfx.cheer(0.7)
	hud.feed_message("Поднимается!", Game.TEXT)

	var to_center: = - down.global_position
	to_center.y = 0.0
	if to_center.length() < 0.2:
		to_center = Vector3(0, 0, 1)
	var spot: = down.global_position + to_center.normalized() * 1.7
	spot.x = clampf(spot.x, -2.2, 2.2)
	spot.z = clampf(spot.z, -2.2, 2.2)
	scorer.walk_to(spot)


func _resume_after_kd() -> void :
	if not kd.is_empty():
		var down: Fighter = kd["f"]
		var scorer: Fighter = kd["scorer"]
		scorer.regen_boost = 1.0
		down.wobble_after_getup()
	kd = {}
	phase = Phase.FIGHT
	hud.hide_count()
	referee.ref_action = ""
	camera.mode = cam_mode_saved
	for f in fighters:
		if f.state == Fighter.State.INACTIVE or f.state == Fighter.State.GETUP:
			f.begin_fight_state()
	hud.flash_message("БОКС!", Game.ACCENT, 110, 0.5)




func _on_clinch_requested(f: Fighter) -> void :
	if phase != Phase.FIGHT or clinch_active:
		return
	var other: = f.opponent
	if not other.is_active():
		return
	clinch_active = true
	clinch_timer = _rng.randf_range(2.2, 3.2)
	f.enter_clinch(true)
	other.enter_clinch(false)
	hud.feed_message("КЛИНЧ", Game.TEXT_DIM)


func _update_clinch(dt: float) -> void :
	if not clinch_active:
		return
	clinch_timer -= dt
	var d: = blue.global_position - red.global_position
	d.y = 0.0
	var dist: = d.length()
	if dist > 0.01 and dist > 0.56:
		var pull: = (dist - 0.56) * minf(dt * 6.0, 1.0) * 0.5
		var n: = d / dist
		red.global_position += n * pull
		blue.global_position -= n * pull
	if clinch_timer < 0.6:
		referee.ref_action = "separate"
	if clinch_timer <= 0.0:
		_end_clinch()
		hud.feed_message("Брейк!", Game.TEXT_DIM)


func _end_clinch() -> void :
	if not clinch_active:
		return
	clinch_active = false
	red.exit_clinch()
	blue.exit_clinch()
	separating_t = 0.45
	referee.ref_action = ""


func _separate_fighters(dt: float) -> void :
	separating_t = maxf(0.0, separating_t - dt)
	var d: = blue.global_position - red.global_position
	d.y = 0.0
	var dist: = d.length()
	var min_d: = 0.8
	if clinch_active:
		min_d = 0.58
	if separating_t > 0.0:
		min_d = 1.3
	if red.is_down() or blue.is_down():
		min_d = 1.15
	if dist < min_d:
		var n: = d / dist if dist > 0.0001 else Vector3(1, 0, 0)
		var push: = (min_d - dist) * (0.5 if separating_t <= 0.0 else minf(dt * 5.0, 0.5))
		if red.is_down():
			blue.global_position += n * push * 2.0
		elif blue.is_down():
			red.global_position -= n * push * 2.0
		else:
			red.global_position -= n * push
			blue.global_position += n * push
	for f in fighters:
		var p: = f.global_position
		p.x = clampf(p.x, - Fighter.RING_LIMIT, Fighter.RING_LIMIT)
		p.z = clampf(p.z, - Fighter.RING_LIMIT, Fighter.RING_LIMIT)
		f.global_position = p




func _update_referee(dt: float) -> void :
	var target: = Vector3.ZERO
	var look: = Vector3.ZERO
	var mid: = (red.global_position + blue.global_position) * 0.5
	var d: = blue.global_position - red.global_position
	d.y = 0.0
	var perp: = Vector3(1, 0, 0)
	if d.length() > 0.01:
		perp = d.normalized().cross(Vector3.UP)
	match phase:
		Phase.KNOCKDOWN:
			if not kd.is_empty():
				var down: Fighter = kd["f"]
				var to_c: = - down.global_position
				to_c.y = 0.0
				if to_c.length() < 0.1:
					to_c = Vector3(0, 0, 1)
				target = down.global_position + to_c.normalized() * 1.0
				look = down.global_position
		Phase.FIGHT, Phase.INTRO:
			if _faceoff:
				target = mid + perp * 1.0
			elif clinch_active:
				target = mid - perp * 0.75
			else:
				target = mid - perp * 1.9
			look = mid
		_:
			target = Vector3(0, 0, 0)
			look = mid
	target.x = clampf(target.x, -2.55, 2.55)
	target.z = clampf(target.z, -2.55, 2.55)
	var cur: = referee_root.global_position
	var to: = target - cur
	to.y = 0.0
	var want_v: = Vector3.ZERO
	if to.length() > 0.15:
		want_v = to.normalized() * minf(2.2, to.length() * 2.5)
	_ref_vel = _ref_vel.move_toward(want_v, dt * 8.0)
	referee_root.global_position = cur + _ref_vel * dt
	var ld: = look - referee_root.global_position
	ld.y = 0.0
	if ld.length() > 0.05:
		var yaw: = atan2( - ld.x, - ld.z)
		referee_root.rotation.y = lerp_angle(referee_root.rotation.y, yaw, clampf(dt * 6.0, 0.0, 1.0))
	var fwd: = - referee_root.global_transform.basis.z
	var right: = referee_root.global_transform.basis.x
	referee.ext_move = Vector2(_ref_vel.dot(right), _ref_vel.dot(fwd)) / 2.0
	referee.update_rig(dt)




func _update_vision() -> void :
	if player == null:
		hud.set_vision(0.0, 0.0)
		return
	var hurt: = 1.0 - player.head_ratio()
	var v: = clampf((hurt - 0.45) * 1.6, 0.0, 0.75)
	var b: = 0.0
	if player.stun_timer > 0.0:
		v = maxf(v, 0.55)
		b = 0.55
	if player.is_down() or (phase == Phase.KNOCKDOWN and not kd.is_empty() and kd["f"] == player):
		v = 0.9
		b = 1.0
	hud.set_vision(v, b)


func _update_crowd(real_dt: float) -> void :
	var base: = 0.25 + 0.25 * float(round_num) / float(maxi(total_rounds, 1))
	excitement = move_toward(excitement, base, real_dt * 0.12)
	flash_boost = move_toward(flash_boost, 0.0, real_dt * 0.5)
	Arena.set_crowd(arena_refs, excitement, flash_boost)
	Sfx.set_crowd(0.25 + excitement * 0.65)
	_board_t -= real_dt
	if _board_t <= 0.0:
		_board_t = 0.25
		Arena.set_board(arena_refs, "R%d   %s" % [round_num, Game.fmt_time(time_left)])




func _end_round() -> void :
	phase = Phase.ROUND_END
	_end_clinch()
	Sfx.play_bell(3)
	Sfx.cheer(0.6)
	hud.flash_message("КОНЕЦ РАУНДА %d" % round_num, Game.TEXT, 90, 1.4)
	var cards: = judges.score_round(stats[0], stats[1])
	var s0: Dictionary = stats[0]
	var s1: Dictionary = stats[1]
	Game.tlog("ROUND %d END cards %s | red %d/%d blue %d/%d | hp red %.2f blue %.2f | sta red %.0f blue %.0f" % [round_num, str(cards), int(s0["landed"]), int(s0["thrown"]), int(s1["landed"]), int(s1["thrown"]), red.head_ratio(), blue.head_ratio(), red.stamina, blue.stamina])
	last_round_stats = [stats[0].duplicate(), stats[1].duplicate()]
	_merge_round_stats()
	for f in fighters:
		f.reset_for_round()
	red.walk_to(Arena.CORNERS["red"])
	blue.walk_to(Arena.CORNERS["blue"])
	_sequence([[2.4, _after_round]])


var last_round_stats: Array = [{}, {}]


func _after_round() -> void :
	if round_num >= total_rounds:
		_decision()
		return
	phase = Phase.CORNER
	hud.fade_to(0.6, 0.4)
	if spectator:
		_ai_corner(red)
		_ai_corner(blue)
		_sequence([[1.2, _next_round]])
		return
	screens.show_corner(_corner_data())


func corner_done(pts_health: int, pts_stamina: int, pts_cut: int) -> void :

	for f in fighters:
		if f != player and not f.is_bag:
			_ai_corner(f)
	if player:
		player.corner_recover(pts_health, pts_stamina, pts_cut)
	_next_round()


func _ai_corner(f: Fighter) -> void :
	var h: = 0
	var s: = 0
	var c: = 0
	for i in 3:
		if f.cut > 45.0 and c < 2:
			c += 1
		elif f.head_max_ratio() < f.stamina_max_ratio():
			h += 1
		else:
			s += 1
	f.corner_recover(h, s, c)


func _next_round() -> void :
	round_num += 1
	hud.fade_to(1.0, 0.25)
	_sequence([[0.3, _next_round_setup]])


func _next_round_setup() -> void :
	_place_in_corners()
	camera.mode = FightCamera.Mode.ORBIT
	camera.orbit_angle = _rng.randf() * TAU
	camera.snap()
	hud.fade_to(0.0, 0.5)
	_start_round_sequence()


func _decision() -> void :
	var dec: = judges.decision()
	var w: = int(dec["winner"])
	var winner: Fighter = null
	if w == 0:
		winner = red
	elif w == 1:
		winner = blue
	_end_fight(winner, str(dec["method"]), true)


func forfeit() -> void :
	if player and phase != Phase.ENDED:
		_end_fight(player.opponent, "Отказ от продолжения")


func _end_fight(winner: Fighter, method: String, decision: bool = false) -> void :
	if phase == Phase.ENDED:
		return
	phase = Phase.ENDED
	_seq = []
	_end_clinch()
	hud.hide_count()
	hud.getup_end()
	if not decision:
		_merge_round_stats()
	var loser: Fighter = null
	if winner:
		loser = winner.opponent
		if loser.is_down():
			loser.set_ko()
		else:
			loser.state = Fighter.State.INACTIVE
			loser.clear_inputs()
			if loser.rig:
				loser.rig.on_defeat()
		winner.set_victory()
	else:
		for f in fighters:
			f.state = Fighter.State.INACTIVE
			f.clear_inputs()
	Sfx.play_bell(4)
	Sfx.cheer(1.5)
	var lost: = winner != null and player != null and not spectator and winner != player
	get_tree().create_timer(2.2, false).timeout.connect( func(): Sfx.play_group("defeat" if lost else "victory", 1.5, 0.9, false))
	excitement = 1.0
	flash_boost = 0.8
	referee.ref_action = "wave" if not decision else ""
	var headline: = method
	if method == "KO":
		headline = "НОКАУТ!"
	elif method.begins_with("TKO"):
		headline = "ТЕХНИЧЕСКИЙ НОКАУТ"
	elif decision:
		headline = "РЕШЕНИЕ СУДЕЙ"
	hud.flash_message(headline, Game.ACCENT_RED if not decision else Game.ACCENT, 110, 2.2)
	if Game.setting_b("slowmo") and not decision:
		slowmo_real = 1.2
	camera.mode = FightCamera.Mode.ORBIT
	camera.orbit_radius = 4.2
	camera.orbit_height = 2.0

	var elapsed: = round_seconds - time_left
	result = {
		"winner": winner.corner if winner else -1, 
		"method": method, 
		"decision": decision, 
		"round": round_num, 
		"time": Game.fmt_time(elapsed), 
		"red": red.def, "blue": blue.def, 
		"totals": totals, 
		"cards": judges.cards, 
		"judge_totals": judges.totals(), 
		"best": best_punch, 
		"spectator": spectator, 
		"career": bool(config.get("career", false)), 
		"player_corner": 0 if player else -1, 
	}
	if bool(config.get("career", false)) and player and Career.has():
		result["career_summary"] = Career.apply_result({
			"won": winner == player, "draw": winner == null, 
			"method": method if not decision else "Решение", "round": round_num, 
		})
	if config.has("tournament") and player:
		result["tournament_summary"] = Tournament.apply_result(winner == player, method, round_num)
	Game.last_result = result
	if winner and not Game.autotest:
		var w: = winner
		_sequence([[1.9, func(): _victory_camera(w)], [5.2, _show_results]])
	else:
		_sequence([[4.2, _show_results]])


func _show_results() -> void :
	screens.show_results(result)
	if Game.autotest:
		_autotest_report()
		get_tree().create_timer(1.5, true, false, true).timeout.connect(_autotest_finish)




var _t_phase_prev: = -1
var _t_phase_time: = 0.0
var _t_shot_t: = 1.0
var _t_getup_t: = 0.0
var _t_forced_kd: = false


func _autotest_tick(real_dt: float) -> void :
	if phase != _t_phase_prev:
		_t_phase_prev = phase
		_t_phase_time = 0.0
	_t_phase_time += real_dt
	if phase != Phase.FIGHT and phase != Phase.ENDED and _t_phase_time > 40.0:
		print("[T] STUCK in phase %d" % phase)
		get_tree().quit(2)
	if Game.test_flag("bloody") and phase == Phase.FIGHT:
		for f in fighters:
			f.cut = maxf(f.cut, 72.0)
			f.nose_blood = maxf(f.nose_blood, 0.7)
			f.sweat = maxf(f.sweat, 0.7)
			f.head_max = minf(f.head_max, f.head_cap * 0.55)
	if Game.test_flag("ropes") and not _t_ropes_placed and phase == Phase.FIGHT and _t_phase_time > 2.0:

		_t_ropes_placed = true
		blue.global_position = Vector3(Arena.ROPE_HALF - 0.2, 0, 0.4)
		red.global_position = Vector3(Arena.ROPE_HALF - 1.1, 0, 0.4)
	if Game.test_flag("forceclinch") and phase == Phase.FIGHT and not clinch_active and _t_phase_time > 3.0 and fmod(_t_phase_time, 7.0) < real_dt * 1.5:

		var dd: = (blue.global_position - red.global_position)
		dd.y = 0.0
		var mid: = (blue.global_position + red.global_position) * 0.5
		dd = dd.normalized() if dd.length() > 0.01 else Vector3(1, 0, 0)
		red.global_position = mid - dd * 0.35
		blue.global_position = mid + dd * 0.35
		red.clinch_cooldown = 0.0
		_on_clinch_requested(red)
		clinch_timer = 3.5
	if Game.test_flag("forcekd") and not _t_forced_kd and phase == Phase.FIGHT and _t_phase_time > 4.0:
		_t_forced_kd = true
		blue.go_down(false)
		_on_knockdown(blue, red, false, Game.test_flag("cold"))
	if training != "" and _t_phase_time > float(Game.test_int("secs", 30)):
		print("[T] TRAINING %s thrown %d landed %d best %.1f combo %d | red sta %.0f guard %.2f" % [training, int(train_stats["thrown"]), int(train_stats["landed"]), float(train_stats["best"]), int(train_stats["best_combo"]), red.stamina, red.guard_ratio()])
		if Game.test_flag("switch") and training == "bag":
			_switch_training()
			_t_phase_time = 0.0
			_t_phase_prev = phase
		else:
			print("AUTOTEST DONE")
			get_tree().quit(0)
			return
	if phase == Phase.CORNER and _t_phase_time > 0.8 and screens.current != null:
		screens._corner_continue()
	if phase == Phase.KNOCKDOWN and hud.getup_is_active():
		_t_getup_t += real_dt
		if _t_getup_t > 3.0:
			_t_getup_t = 0.0
			hud.getup_end()
			if randf() < 0.7:
				_on_player_getup()
	var shots: = Game.test_str("shots", "")
	if shots != "" and DisplayServer.get_name() != "headless":
		_t_shot_t -= real_dt
		if _t_shot_t <= 0.0:
			_t_shot_t = Game.test_float("shot_every", 3.0)
			save_shot(shots)


func save_shot(dir: String) -> void :
	Game.test_shot_no += 1
	var img: = get_viewport().get_texture().get_image()
	var path: = "%s/shot_%04d.png" % [dir, Game.test_shot_no]
	img.save_png(path)


func _autotest_report() -> void :
	var a: Dictionary = totals[0]
	var b: Dictionary = totals[1]
	print("[T] RESULT winner=%d method=%s round=%d time=%s" % [int(result["winner"]), str(result["method"]), int(result["round"]), str(result["time"])])
	print("[T]   red  thrown %d landed %d power %d/%d body %d counters %d kd %d parries %d slips %d" % [int(a["thrown"]), int(a["landed"]), int(a["power_landed"]), int(a["power_thrown"]), int(a["body_landed"]), int(a["counters"]), int(a["kd_scored"]), int(a["parries"]), int(a["slips"])])
	print("[T]   blue thrown %d landed %d power %d/%d body %d counters %d kd %d parries %d slips %d" % [int(b["thrown"]), int(b["landed"]), int(b["power_landed"]), int(b["power_thrown"]), int(b["body_landed"]), int(b["counters"]), int(b["kd_scored"]), int(b["parries"]), int(b["slips"])])
	print("[T]   judges ", judges.totals())
	print("[T]   end hp red head %.2f body %.2f sta %.0f | blue head %.2f body %.2f sta %.0f" % [red.head_ratio(), red.body_ratio(), red.stamina, blue.head_ratio(), blue.body_ratio(), blue.stamina])
	if Game.test_flag("balance"):
		var row: = {"div": Weight.of(red.def), "rounds": total_rounds, "secs": round_seconds, "winner": int(result["winner"]), 
			"method": str(result["method"]), "decision": bool(result["decision"]), "round": int(result["round"]), "time": str(result["time"]), 
			"red": {"style": str(red.def.get("style", "")), "ovr": Roster.overall(red.def), "kd": int(a["kd_scored"]), "landed": int(a["landed"]), "thrown": int(a["thrown"]), "power": int(a["power_landed"])}, 
			"blue": {"style": str(blue.def.get("style", "")), "ovr": Roster.overall(blue.def), "kd": int(b["kd_scored"]), "landed": int(b["landed"]), "thrown": int(b["thrown"]), "power": int(b["power_landed"])}}
		print("[BAL] ", JSON.stringify(row))


func _autotest_finish() -> void :
	if Game.main:
		Game.main.call("autotest_next")


func rematch() -> void :
	Game.start_fight(config)


func exit_to_menu() -> void :
	Sfx.stop_crowd()
	if training != "":
		Game.goto_menu("training")
	elif bool(config.get("career", false)):
		Game.goto_menu("career")
	elif config.has("tournament"):
		Game.goto_menu("tournament")
	elif not bool(config.get("spectator", false)) or true:
		Game.goto_menu("quick")




func _corner_data() -> Dictionary:
	var me: Dictionary = last_round_stats[0]
	var op: Dictionary = last_round_stats[1]
	var cards: Array = []
	for j in 3:
		var c: Array = judges.cards[j]
		if c.size() > 0:
			cards.append(c[c.size() - 1])
	return {
		"round": round_num, 
		"me": me, "opp": op, 
		"advice": _corner_advice(me, op), 
		"head": player.head_max_ratio() if player else 1.0, 
		"stamina": player.stamina_max_ratio() if player else 1.0, 
		"cut": player.cut if player else 0.0, 
		"last_cards": cards, 
	}


func _corner_advice(me: Dictionary, op: Dictionary) -> Array:
	var tips: Array = []
	var thrown: = maxi(int(me["thrown"]), 1)
	var acc: = float(me["landed"]) / float(thrown)
	var opp_head: = int(op["head_landed"])
	if player and player.head_max_ratio() < 0.55:
		tips.append("Руки выше! Голова уже не держит — больше защиты, меньше размена.")
	if player and player.cut > 60.0:
		tips.append("Рассечение плохое. Ещё пара точных — и врач остановит бой.")
	if int(op["counters"]) >= 3:
		tips.append("Он ловит тебя на встречных. После удара уходи с линии (Q/E) или сразу закрывайся.")
	if thrown >= 8 and acc < 0.28:
		tips.append("Много мажешь. Подойди ближе и бей короткими сериями по 2–3 удара.")
	if int(me["blocked"]) >= 8 and int(me["body_landed"]) < 3:
		tips.append("Он закрывает голову. Иди в корпус: клик с мышью вниз (или LB + удар) — и его дыхалка кончится.")
	if blue and blue.stamina_max_ratio() < 0.75:
		tips.append("Он подсел на корпус и устал. Дави его!")
	if opp_head >= 12:
		tips.append("Слишком много пропускаешь в голову. Ныряй под хуки (C или Ctrl+W) и уклоняйся от прямых (Q/E или Ctrl+A/D).")
	if player and player.stamina_max_ratio() < 0.7:
		tips.append("Ты выдыхаешься. Меньше силовых, работай джебом и восстанавливайся в клинче (G).")
	if player and int(op["blocked"]) >= 10:
		tips.append("Ты долго стоишь в блоке — гард тает. Отвечай после его серии и работай корпусом.")
	if int(me["parries"]) + int(me["slips"]) >= 4:
		tips.append("Защита работает! После уклона или парирования сразу отвечай — это окно для контры.")
	if tips.is_empty():
		tips.append("Работай джебом, держи дистанцию и не стой на месте.")
	if tips.size() > 3:
		tips.resize(3)
	return tips




var _rope_prev: = 0.0
var _rope_cd: = 0.0
var _t_ropes_placed: = false


func _update_ropes(dt: float) -> void :
	var rs: RingRopes = arena_refs.get("rope_sim")
	if rs == null:
		return
	var pts: Array = []
	for f in fighters:
		if f.rig == null or f.is_bag:
			continue
		var fp: = f.global_position
		if maxf(absf(fp.x), absf(fp.z)) < Arena.ROPE_HALF - 0.75 and not (f.rig is MixamoRig and (f.rig as MixamoRig).is_ragdoll()):
			continue
		pts.append_array(f.rig.rope_points())
	rs.tick(dt, pts)
	var d: = rs.max_deflection()
	_rope_cd = maxf(0.0, _rope_cd - dt)

	if d - _rope_prev > 0.09 and d > 0.16 and _rope_cd <= 0.0:
		Sfx.play("rope", -15.0 + minf(d * 14.0, 6.0), 0.08)
		_rope_cd = 0.9
	_rope_prev = lerpf(_rope_prev, d, clampf(dt * 6.0, 0.0, 1.0))
