extends Node


signal settings_changed

const SETTINGS_PATH: = "user://settings.cfg"

const DIFFICULTY_NAMES: = ["Новичок", "Любитель", "Профи", "Чемпион", "Легенда"]
const ROUND_OPTIONS: = [1, 3, 4, 6, 8, 10, 12]
const ROUND_SECONDS_OPTIONS: = [60, 90, 120, 180]


const ACCENT: = Color(0.91, 0.7, 0.23)
const ACCENT_RED: = Color(0.78, 0.17, 0.15)
const PANEL_BG: = Color(0.05, 0.05, 0.07, 0.86)
const TEXT: = Color(0.94, 0.93, 0.9)
const TEXT_DIM: = Color(0.64, 0.64, 0.66)

var settings: = {
	"master_volume": 0.8, 
	"sfx_volume": 1.0, 
	"crowd_volume": 0.5, 
	"music_volume": 0.6, 
	"mouse_punch": true, 
	"mouse_sens": 1.0, 
	"fight_tempo": 1, 
	"sharpen": true, "vibration": true, "live_cards": true, 
	"hud_mouse_aim": true, 
	"show_health": true, 
	"camera_shake": 1.0, 
	"fullscreen": false, 
	"camera_mode": 0, 
	"slowmo": true, 
	"hints": true, 
	"use_mixamo": true, 
	"mixamo_gloves": true, 
	"difficulty": 2, 
	"rounds": 3, 
	"round_seconds": 120, 
}

var fight_config: Dictionary = {}
var career: Dictionary = {}
var tournament: Dictionary = {}
var autotest: = false
var test_args: = {}
var test_shot_no: = 0
var main: Node = null
var last_result: Dictionary = {}
var ui_theme: Theme
var title_font: Font
var body_font: Font
var nav: MenuNav
var no_save: = false


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_inputs()
	nav = MenuNav.new()
	nav.name = "MenuNav"
	add_child(nav)
	load_settings()
	_build_theme()
	apply_settings()




func _setup_inputs() -> void :
	_add_action("move_forward", [_key(KEY_W), _key(KEY_UP), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)])
	_add_action("move_back", [_key(KEY_S), _key(KEY_DOWN), _joy_axis(JOY_AXIS_LEFT_Y, 1.0)])
	_add_action("move_left", [_key(KEY_A), _key(KEY_LEFT), _joy_axis(JOY_AXIS_LEFT_X, -1.0)])
	_add_action("move_right", [_key(KEY_D), _key(KEY_RIGHT), _joy_axis(JOY_AXIS_LEFT_X, 1.0)])



	_add_action("punch_jab", [_key(KEY_J), _joy_btn(JOY_BUTTON_X)])
	_add_action("punch_cross", [_key(KEY_K), _joy_btn(JOY_BUTTON_Y)])
	_add_action("punch_lead_hook", [_key(KEY_U), _joy_btn(JOY_BUTTON_A)])
	_add_action("punch_rear_hook", [_key(KEY_I), _joy_btn(JOY_BUTTON_B)])
	_add_action("punch_lead_upper", [_key(KEY_N)])
	_add_action("punch_rear_upper", [_key(KEY_M)])

	_add_action("mod_body", [_key(KEY_X), _joy_btn(JOY_BUTTON_LEFT_SHOULDER)])
	_add_action("mod_power", [_key(KEY_SHIFT), _key(KEY_L), _joy_btn(JOY_BUTTON_RIGHT_SHOULDER)])
	_add_action("mod_upper", [])
	_add_action("block", [_key(KEY_SPACE), _mouse(MOUSE_BUTTON_MIDDLE), _joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_add_action("head_move", [_joy_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_add_action("head_move_kb", [_key(KEY_CTRL)])
	_add_action("rs_left", [_joy_axis(JOY_AXIS_RIGHT_X, -1.0)], 0.15)
	_add_action("rs_right", [_joy_axis(JOY_AXIS_RIGHT_X, 1.0)], 0.15)
	_add_action("rs_up", [_joy_axis(JOY_AXIS_RIGHT_Y, -1.0)], 0.15)
	_add_action("rs_down", [_joy_axis(JOY_AXIS_RIGHT_Y, 1.0)], 0.15)

	_add_action("slip_left", [_key(KEY_Q)])
	_add_action("slip_right", [_key(KEY_E)])
	_add_action("duck", [_key(KEY_C), _key(KEY_F)])
	_add_action("lean_back", [_key(KEY_R)])

	_add_action("clinch", [_key(KEY_G), _joy_btn(JOY_BUTTON_DPAD_UP)])
	_add_action("camera_toggle", [_key(KEY_V), _joy_btn(JOY_BUTTON_BACK)])
	_add_action("pause", [_key(KEY_ESCAPE), _joy_btn(JOY_BUTTON_START)])
	_add_action("getup", [_key(KEY_SPACE), _key(KEY_ENTER), _mouse(MOUSE_BUTTON_LEFT), _joy_btn(JOY_BUTTON_A)])
	_add_action("train_target", [_key(KEY_TAB), _joy_btn(JOY_BUTTON_DPAD_DOWN)])
	_add_action("toggle_hints", [_key(KEY_F1)])

	_ensure_event("ui_accept", _joy_btn(JOY_BUTTON_A))
	_ensure_event("ui_cancel", _joy_btn(JOY_BUTTON_B))
	_ensure_event("ui_up", _joy_btn(JOY_BUTTON_DPAD_UP))
	_ensure_event("ui_down", _joy_btn(JOY_BUTTON_DPAD_DOWN))
	_ensure_event("ui_left", _joy_btn(JOY_BUTTON_DPAD_LEFT))
	_ensure_event("ui_right", _joy_btn(JOY_BUTTON_DPAD_RIGHT))

	for a in ["ui_up", "ui_down", "ui_left", "ui_right"]:
		for ev in InputMap.action_get_events(a):
			if ev is InputEventJoypadMotion:
				InputMap.action_erase_event(a, ev)

	_add_action("menu_tab_prev", [_joy_btn(JOY_BUTTON_LEFT_SHOULDER), _key(KEY_Q)])
	_add_action("menu_tab_next", [_joy_btn(JOY_BUTTON_RIGHT_SHOULDER), _key(KEY_E)])


func _ensure_event(action: String, ev: InputEvent) -> void :
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)


func _add_action(action: String, events: Array, deadzone: float = 0.4) -> void :
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action, deadzone)
	for e in events:
		var ev: InputEvent = e
		InputMap.action_add_event(action, ev)


func _key(k: Key) -> InputEventKey:
	var e: = InputEventKey.new()
	e.physical_keycode = k
	return e


func _mouse(b: MouseButton) -> InputEventMouseButton:
	var e: = InputEventMouseButton.new()
	e.button_index = b
	return e


func _joy_btn(b: JoyButton) -> InputEventJoypadButton:
	var e: = InputEventJoypadButton.new()
	e.button_index = b
	e.device = -1
	return e


func _joy_axis(a: JoyAxis, v: float) -> InputEventJoypadMotion:
	var e: = InputEventJoypadMotion.new()
	e.axis = a
	e.axis_value = v
	e.device = -1
	return e




func load_settings() -> void :
	var cfg: = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for k in settings.keys():
		var key: String = k
		if cfg.has_section_key("settings", key):
			settings[key] = cfg.get_value("settings", key)


func save_settings() -> void :
	if no_save:
		return
	var cfg: = ConfigFile.new()
	for k in settings.keys():
		var key: String = k
		cfg.set_value("settings", key, settings[key])
	cfg.save(SETTINGS_PATH)


func apply_settings() -> void :
	var mv: float = settings["master_volume"]
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(mv, 0.0001)))
	var want_full: bool = settings["fullscreen"]
	var mode: = DisplayServer.window_get_mode()
	if want_full and mode != DisplayServer.WINDOW_MODE_FULLSCREEN and mode != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif not want_full and (mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	settings_changed.emit()


func setting_f(key: String) -> float:
	var v: float = settings.get(key, 0.0)
	return v


func setting_b(key: String) -> bool:
	var v: bool = settings.get(key, false)
	return v


func setting_i(key: String) -> int:
	var v: int = settings.get(key, 0)
	return v




func parse_test_args() -> void :
	test_args = {}
	for a in OS.get_cmdline_user_args():
		var s: String = a
		if not s.begins_with("--"):
			continue
		s = s.substr(2)
		var eq: = s.find("=")
		if eq >= 0:
			test_args[s.substr(0, eq)] = s.substr(eq + 1)
		else:
			test_args[s] = "1"
	autotest = test_args.has("autotest")
	if autotest:
		settings["slowmo"] = true
		settings["use_mixamo"] = not test_args.has("nomixamo")


func test_flag(key: String) -> bool:
	return test_args.has(key)


func test_int(key: String, def: int) -> int:
	if test_args.has(key):
		return str(test_args[key]).to_int()
	return def


func test_float(key: String, def: float) -> float:
	if test_args.has(key):
		return str(test_args[key]).to_float()
	return def


func test_str(key: String, def: String) -> String:
	if test_args.has(key):
		return str(test_args[key])
	return def


func tlog(msg: String) -> void :
	if autotest:
		print("[T] ", msg)




func goto_menu(screen: String = "main") -> void :
	if main and main.has_method("show_menu"):
		main.call("show_menu", screen)


func start_fight(config: Dictionary) -> void :
	fight_config = config
	if main and main.has_method("start_fight"):
		main.call("start_fight", config)


func make_fight_config(red: Dictionary, blue: Dictionary, difficulty: int, rounds: int, 
		round_seconds: int, spectator: bool = false, career_fight: bool = false) -> Dictionary:
	return {
		"red": red, "blue": blue, "difficulty": difficulty, "rounds": rounds, 
		"round_seconds": round_seconds, "spectator": spectator, "career": career_fight, 
	}









func _build_theme() -> void :
	var sys: = SystemFont.new()
	sys.font_names = PackedStringArray(["Segoe UI", "Roboto", "Arial", "Sans-Serif"])
	sys.font_weight = 600
	body_font = sys
	var tf: = SystemFont.new()
	tf.font_names = PackedStringArray(["Impact", "Arial Black", "Bebas Neue", "Sans-Serif"])
	tf.font_weight = 800
	title_font = tf

	var t: = Theme.new()
	t.default_font = body_font
	t.default_font_size = 24

	var btn: = StyleBoxFlat.new()
	btn.bg_color = Color(0.09, 0.09, 0.11, 0.92)
	btn.border_color = Color(0.25, 0.25, 0.28)
	btn.set_border_width_all(2)
	btn.set_corner_radius_all(4)
	btn.set_content_margin_all(12)
	btn.content_margin_left = 22
	btn.content_margin_right = 22
	var hover: = btn.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.16, 0.13, 0.08, 0.95)
	hover.border_color = ACCENT
	var pressed: = btn.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.32, 0.22, 0.06, 0.95)
	pressed.border_color = ACCENT
	var focus: = btn.duplicate() as StyleBoxFlat
	focus.bg_color = Color(0.16, 0.13, 0.08, 0.95)
	focus.border_color = ACCENT
	focus.set_border_width_all(3)
	var disabled: = btn.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.07, 0.07, 0.08, 0.7)
	disabled.border_color = Color(0.15, 0.15, 0.16)
	for cls in ["Button", "OptionButton", "CheckBox", "CheckButton"]:
		var c: String = cls
		t.set_stylebox("normal", c, btn)
		t.set_stylebox("hover", c, hover)
		t.set_stylebox("pressed", c, pressed)
		t.set_stylebox("focus", c, focus)
		t.set_stylebox("disabled", c, disabled)
		t.set_color("font_color", c, TEXT)
		t.set_color("font_hover_color", c, ACCENT)
		t.set_color("font_pressed_color", c, Color.WHITE)
		t.set_color("font_focus_color", c, ACCENT)
		t.set_color("font_disabled_color", c, Color(0.4, 0.4, 0.42))
		t.set_font_size("font_size", c, 26)

	var panel: = StyleBoxFlat.new()
	panel.bg_color = PANEL_BG
	panel.border_color = Color(0.22, 0.22, 0.25)
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(6)
	panel.set_content_margin_all(24)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)

	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.9))
	t.set_font_size("font_size", "Label", 24)

	var line: = StyleBoxFlat.new()
	line.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	line.border_color = Color(0.3, 0.3, 0.33)
	line.set_border_width_all(2)
	line.set_corner_radius_all(4)
	line.set_content_margin_all(10)
	t.set_stylebox("normal", "LineEdit", line)
	var line_focus: = line.duplicate() as StyleBoxFlat
	line_focus.border_color = ACCENT
	t.set_stylebox("focus", "LineEdit", line_focus)
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_font_size("font_size", "LineEdit", 26)

	var slider_bg: = StyleBoxFlat.new()
	slider_bg.bg_color = Color(0.2, 0.2, 0.22)
	slider_bg.set_content_margin_all(4)
	slider_bg.set_corner_radius_all(3)
	var slider_fill: = StyleBoxFlat.new()
	slider_fill.bg_color = ACCENT
	slider_fill.set_content_margin_all(4)
	slider_fill.set_corner_radius_all(3)
	t.set_stylebox("slider", "HSlider", slider_bg)
	t.set_stylebox("grabber_area", "HSlider", slider_fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", slider_fill)

	var popup: = StyleBoxFlat.new()
	popup.bg_color = Color(0.07, 0.07, 0.09, 0.98)
	popup.border_color = ACCENT
	popup.set_border_width_all(1)
	popup.set_content_margin_all(8)
	t.set_stylebox("panel", "PopupMenu", popup)
	t.set_font_size("font_size", "PopupMenu", 24)
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", ACCENT)

	var sep: = StyleBoxLine.new()
	sep.color = Color(0.3, 0.3, 0.33)
	sep.thickness = 1
	t.set_stylebox("separator", "HSeparator", sep)
	ui_theme = t




static func make_mat(color: Color, roughness: float = 0.6, metallic: float = 0.0) -> StandardMaterial3D:
	var m: = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m


static func fmt_time(seconds: float) -> String:
	var s: int = maxi(int(ceil(seconds)), 0)
	return "%d:%02d" % [s / 60, s % 60]
