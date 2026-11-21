class_name BoxerAI
extends RefCounted





const DIFF: = Balance.AI_DIFF

const STYLES: = Balance.AI_STYLES

const COUNTER_COMBOS: = ["C", "C LH", "LH C", "RU LH", "C!", "LH!", "Cb LH"]
const TOKENS: = {
	"J": Punches.Type.JAB, "C": Punches.Type.CROSS, "LH": Punches.Type.LEAD_HOOK, 
	"RH": Punches.Type.REAR_HOOK, "LU": Punches.Type.LEAD_UPPER, "RU": Punches.Type.REAR_UPPER, 
}

var me: Fighter
var opp: Fighter
var level: = 2

var spar: = false

const TEMPO_CD: = Balance.AI_TEMPO_CD
const TEMPO_MAX_COMBO: = Balance.AI_TEMPO_MAX_COMBO
var style: Dictionary
var rng: = RandomNumberGenerator.new()

var clock: = 0.0
var think_t: = 0.0
var attack_cd: = 0.8
var combo: Array = []
var pending: Dictionary = {}
var retreat_now: = false
var guard_hold: = 0.0
var strafe_dir: = 1.0
var strafe_timer: = 0.0


var seen: = [0, 0, 0, 0, 0, 0]
var seen_total: = 0
var opp_high_block: = 0.0
var opp_low_block: = 0.0
var observed: = 0.001


func setup(fighter: Fighter, opponent: Fighter, difficulty: int) -> void :
	me = fighter
	opp = opponent
	level = clampi(difficulty, 0, 4)
	var style_id: String = fighter.def.get("style", "balanced")
	style = STYLES.get(style_id, STYLES["balanced"])
	rng.randomize()
	opp.punch_started.connect(_on_opp_punch)


func _d(key: String) -> float:
	var arr: Array = DIFF[key]
	return float(arr[level])


func _s(key: String) -> float:
	return float(style.get(key, 0.5))




func _on_opp_punch(_f: Fighter, p: Dictionary) -> void :
	var t: int = p["type"]
	seen[t] = int(seen[t]) + 1
	seen_total += 1
	if not me.is_active():
		return
	if me.state == Fighter.State.PUNCH and me.punch_phase == Fighter.Phase.WINDUP:
		return
	var reach: float = p["reach"]
	if me.dist_to_opp > reach + 0.12:
		return
	var chance: = _d("react") + _adapt_bonus(t)
	if me.stun_timer > 0.0:
		chance *= 0.5
	if me.stamina < 15.0:
		chance *= 0.7
	if rng.randf() > chance:
		return
	var windup: float = p["windup"]
	var tl: = clampi(Fighter.tempo_level, 0, 2)

	var delay: = _d("delay") * rng.randf_range(0.8, 1.2) * lerpf(1.0, float(Fighter.TEMPO_WINDUP[tl]), 0.85)
	if rng.randf() < _d("perfect"):
		delay = maxf(0.02, windup - 0.09)
	if delay > windup - 0.02:
		return
	var body: bool = p["body"]
	var kind: = _choose_defense(t, body)
	pending = {"at": clock + delay, "kind": kind, "until": clock + windup + 0.22 + rng.randf_range(0.0, 0.2)}
	combo.clear()


func _choose_defense(t: int, body: bool) -> String:
	var wb: = _s("block")
	var ws: = _s("slip")
	var wk: = _s("back")

	if me.guard_ratio() < 0.3:
		wb *= 0.3
		ws *= 1.4
		wk *= 1.4
	if body:
		return "block_low" if rng.randf() < (wb + ws) / (wb + ws + wk) else "back"
	var r: = rng.randf() * (wb + ws + wk)
	if r < wb:
		return "block_high"
	if r < wb + ws:
		if Punches.is_hook(t):
			return "duck"
		return "slip_left" if rng.randf() < 0.5 else "slip_right"
	return "back"


func _adapt_bonus(t: int) -> float:
	if seen_total < 10:
		return 0.0
	var ratio: = float(seen[t]) / float(seen_total)
	return clampf((ratio - 1.0 / 6.0) * 0.6, 0.0, 0.18) * _d("adapt")




func tick(delta: float) -> void :
	clock += delta
	if opp:
		observed += delta
		if opp.blocking:
			if opp.block_low:
				opp_low_block += delta
			else:
				opp_high_block += delta
	if me == null or opp == null or not me.is_active() or not opp.can_be_hit():
		if me:
			me.clear_inputs()
		combo.clear()
		pending = {}
		return

	guard_hold = maxf(0.0, guard_hold - delta)
	attack_cd -= delta
	retreat_now = false
	var defending: = false
	if not pending.is_empty():
		var at: float = pending["at"]
		var until: float = pending["until"]
		if clock >= at:
			if clock <= until:
				_apply_defense(str(pending["kind"]))
				defending = true
			else:
				pending = {}
	if not defending:
		me.lean_input = Fighter.Lean.NONE
		me.want_block = guard_hold > 0.0 and combo.is_empty()
		me.want_block_low = false

	think_t -= delta
	if think_t <= 0.0:
		think_t = _d("think") * rng.randf_range(0.8, 1.2)
		_think()

	if not combo.is_empty() and not defending:
		if me.blocking or me.want_block:
			me.want_block = false
		elif me.state == Fighter.State.IDLE or (me.state == Fighter.State.PUNCH and me.punch_phase == Fighter.Phase.RECOVERY and me.queued.is_empty()):
			var p: Dictionary = combo.pop_front()
			me.request_punch(int(p["type"]), bool(p["body"]), bool(p["power"]))

	_move(delta)


func _apply_defense(kind: String) -> void :
	me.want_block = false
	me.want_block_low = false
	me.lean_input = Fighter.Lean.NONE
	match kind:
		"block_high":
			me.want_block = true
		"block_low":
			me.want_block = true
			me.want_block_low = true
		"slip_left":
			me.lean_input = Fighter.Lean.LEFT
		"slip_right":
			me.lean_input = Fighter.Lean.RIGHT
		"duck":
			me.lean_input = Fighter.Lean.DUCK
		"back":
			me.lean_input = Fighter.Lean.BACK
			retreat_now = true


func _think() -> void :
	var dist: = me.dist_to_opp
	var hurt: = me.head_ratio() < 0.28 or me.stun_timer > 0.0
	var opp_hurt: = opp.stun_timer > 0.0 or opp.head_ratio() < 0.3
	var tired: = me.stamina < 25.0


	if me.stun_timer > 0.0:
		if dist < Fighter.CLINCH_RANGE and me.clinch_cooldown <= 0.0 and rng.randf() < 0.3:
			me.request_clinch()
			return
		guard_hold = rng.randf_range(0.3, 0.8)
		retreat_now = rng.randf() < 0.6
		combo.clear()
		if rng.randf() < 0.88:
			return

	if hurt and dist < Fighter.CLINCH_RANGE and me.clinch_cooldown <= 0.0 and rng.randf() < _s("clinch") * 1.5:
		me.request_clinch()
		return
	if hurt and combo.is_empty() and rng.randf() < 0.35:
		guard_hold = rng.randf_range(0.4, 1.0)


	if me.counter_window > 0.15 and combo.is_empty() and rng.randf() < 0.55 * _s("counter") * _d("counter"):
		combo = _parse_combo(COUNTER_COMBOS[rng.randi() % COUNTER_COMBOS.size()])
		guard_hold = 0.0
		return

	if not combo.is_empty() or attack_cd > 0.0:
		return
	var reach_jab: = 1.34 + me.reach_bonus + _d("range_err") * rng.randf()
	if dist > reach_jab:
		return
	var p_attack: = 0.28 * _s("aggr") * _d("aggr")
	if opp_hurt:
		p_attack *= 2.0
	if tired:
		p_attack *= 0.4
	if opp.state == Fighter.State.PUNCH and opp.punch_phase == Fighter.Phase.RECOVERY:
		p_attack *= 1.8
	if rng.randf() >= p_attack:
		return
	var list: Array = style["combos"]
	var parsed: = _parse_combo(str(list[rng.randi() % list.size()]))

	if opp_high_block / observed > 0.25 and rng.randf() < 0.5 and parsed.size() > 0:
		var idx: = rng.randi() % parsed.size()
		var pd: Dictionary = parsed[idx]
		pd["body"] = true
	if (opp_hurt and rng.randf() < 0.6) or rng.randf() < _s("power") * 0.4 or (opp.blocking and opp.guard_ratio() < 0.4 and rng.randf() < 0.5):
		var last: Dictionary = parsed[parsed.size() - 1]
		last["power"] = true
	var tl: = clampi(Fighter.tempo_level, 0, 2)
	var max_len: int = (TEMPO_MAX_COMBO[tl] as Array)[level]
	if parsed.size() > max_len:
		parsed.resize(max_len)
	if tired or spar:
		for item in parsed:
			var d: Dictionary = item
			d["power"] = false
	combo = parsed
	guard_hold = 0.0
	attack_cd = rng.randf_range(1.0, 2.6) / maxf(_s("aggr") * _d("aggr"), 0.2) * float(TEMPO_CD[tl])
	if tired:
		attack_cd *= 1.8
	if spar:
		attack_cd *= 1.6


func _move(delta: float) -> void :
	var ideal: = _s("dist")
	var hurt: = me.head_ratio() < 0.28 or me.stun_timer > 0.0
	if hurt or me.stamina < 25.0:
		ideal += 0.35
	if opp.stun_timer > 0.0:
		ideal = 0.95
	if not combo.is_empty():
		ideal = minf(ideal, _combo_reach() - 0.12)
	var err: = me.dist_to_opp - ideal
	var fwd: = clampf(err * 2.5, -1.0, 1.0)
	if absf(err) < 0.06:
		fwd = 0.0
	if retreat_now:
		fwd = -1.0

	strafe_timer -= delta
	if strafe_timer <= 0.0:
		strafe_timer = rng.randf_range(0.8, 2.5)
		var r: = rng.randf()
		strafe_dir = -1.0 if r < 0.4 else (1.0 if r < 0.8 else 0.0)
	var strafe: = strafe_dir * _s("circle")


	var to_opp: = opp.global_position - me.global_position
	to_opp.y = 0.0
	if to_opp.length() > 0.01:
		var right: = to_opp.normalized().cross(Vector3.UP)
		var center_dir: = - me.global_position
		center_dir.y = 0.0
		var near_rope: = absf(me.global_position.x) > 1.9 or absf(me.global_position.z) > 1.9
		if near_rope:
			strafe = signf(center_dir.dot(right))
			if strafe == 0.0:
				strafe = 1.0
			if fwd < 0.0:
				fwd *= 0.3

		var sid: String = me.def.get("style", "")
		if opp.on_ropes and (sid == "swarmer" or sid == "slugger"):
			strafe *= 0.2
	me.move_input = Vector2(strafe, fwd)


func _combo_reach() -> float:
	var r: = 2.0
	for item in combo:
		var d: Dictionary = item
		var data: = Punches.get_data(int(d["type"]))
		r = minf(r, float(data["reach"]) + me.reach_bonus)
	return r


func _parse_combo(s: String) -> Array:
	var out: Array = []
	for tok in s.split(" ", false):
		var token: String = tok
		var body: = token.contains("b")
		var pw: = token.contains("!")
		var base: = token.replace("b", "").replace("!", "")
		if TOKENS.has(base):
			out.append({"type": int(TOKENS[base]), "body": body, "power": pw})
	return out
