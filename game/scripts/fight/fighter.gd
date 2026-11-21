class_name Fighter
extends Node3D





signal punch_started(fighter: Fighter, punch: Dictionary)
signal punch_resolved(attacker: Fighter, defender: Fighter, punch: Dictionary, result: Dictionary)
signal clinch_requested(fighter: Fighter)
signal guard_broken(fighter: Fighter)

enum State{IDLE, PUNCH, HIT, CLINCH, DOWN, GETUP, INACTIVE, KO, VICTORY}
enum Phase{WINDUP, ACTIVE, RECOVERY}
enum Lean{NONE, LEFT, RIGHT, DUCK, BACK}

const RING_LIMIT: = 2.95
const ROPE_SOFT: = 2.66
const CLINCH_RANGE: = 0.95
const DAMAGE_SCALE: = Balance.DAMAGE_SCALE
const STAMINA_COST_SCALE: = Balance.STAMINA_COST_SCALE
const GUARD_MAX: = Balance.GUARD_MAX



const TEMPO_WINDUP: = Balance.TEMPO_WINDUP
const TEMPO_RECOVERY: = Balance.TEMPO_RECOVERY
const TEMPO_MOVE: = Balance.TEMPO_MOVE
static var tempo_level: = 1


var def: Dictionary = {}
var corner: int = 0
var display_name: = ""
var is_player: = false
var is_bag: = false

var training: = false
var stance_sign: int = 1
var height_m: = 1.8
var power: = 70.0
var speed: = 70.0
var stamina_stat: = 70.0
var chin: = 70.0
var defense: = 70.0
var reach_bonus: = 0.0

var division: = 4
var wphys: = {"tempo": 1.0, "move": 1.0, "dmg": 1.0, "kd": 1.0, "drain": 1.0, "regen": 1.0}

var opponent: Fighter
var rig: BoxerRig


var head_cap: = 110.0
var head_max: = 110.0
var head_hp: = 110.0
var body_cap: = 110.0
var body_max: = 110.0
var body_hp: = 110.0
var stamina: = 100.0
var stamina_max: = 100.0
var cut: = 0.0
var sweat: = 0.0

var nose_blood: = 0.0

var blood_spill: = 0.0
var stun_timer: = 0.0
var counter_window: = 0.0
var hit_timer: = 0.0
var since_hit: = 10.0
var knockdowns_round: = 0
var knockdowns_total: = 0
var clinch_cooldown: = 0.0
var clinch_initiator: = false
var down_body: = false
var getup_timer: = 0.0

var regen_boost: = 1.0

var out_cold: = false


var guard_hp: = GUARD_MAX
var guard_break_t: = 0.0
var since_block_hit: = 10.0


var state: int = State.INACTIVE
var punch: Dictionary = {}
var punch_phase: int = Phase.WINDUP
var punch_time: = 0.0
var punch_windup: = 0.2
var punch_active: = 0.08
var punch_recovery: = 0.25
var whiffed: = false
var last_punch_end: = -10.0
var last_punch_lead: = false
var clock: = 0.0

var arm_fatigue: = 0.0


var move_input: = Vector2.ZERO
var want_block: = false
var _stun_guard_t: = 0.0
var _stun_guard_open: = false
var want_block_low: = false
var lean_input: int = Lean.NONE

var lean_vec_input: = Vector2.ZERO
var queued: Dictionary = {}
var queued_time: = 0.0


var blocking: = false
var block_low: = false
var block_start: = -10.0
var lean: int = Lean.NONE
var lean_start: = -10.0
var lean_amount: = 0.0
var lean_vec: = Vector2.ZERO
var velocity: = Vector3.ZERO
var local_move: = Vector2.ZERO
var auto_target: = Vector3.ZERO
var auto_walk: = false
var dist_to_opp: = 2.0
var on_ropes: = false


var bag_hits: = 0
var bag_damage: = 0.0
var last_hit_info: Dictionary = {}

var _rng: = RandomNumberGenerator.new()


func setup(fighter_def: Dictionary, corner_idx: int, player: bool, use_mixamo: bool) -> void :
	_rng.randomize()
	def = fighter_def
	corner = corner_idx
	is_player = player
	is_bag = bool(def.get("bag", false))
	display_name = def.get("name", "Boxer")
	stance_sign = int(def.get("stance", 1))
	height_m = float(def.get("height", 1.8))
	power = float(def.get("power", 70))
	speed = float(def.get("speed", 70))
	stamina_stat = float(def.get("stamina", 70))
	chin = float(def.get("chin", 70))
	defense = float(def.get("defense", 70))
	reach_bonus = (height_m - 1.8) * 0.55
	division = Weight.of(def)
	wphys = Weight.phys(division)

	head_cap = 115.0 + chin * 0.6
	head_max = head_cap
	head_hp = head_cap
	body_cap = 100.0 + chin * 0.2 + stamina_stat * 0.3
	body_max = body_cap
	body_hp = body_cap
	stamina_max = 100.0
	stamina = 100.0
	guard_hp = GUARD_MAX

	rig = _make_rig(use_mixamo)
	add_child(rig)
	rig.setup(def, self)


func _make_rig(use_mixamo: bool) -> BoxerRig:
	if is_bag:
		return BagRig.new()
	if use_mixamo and MixamoRig.has_assets_for(def):
		var mr: = MixamoRig.new()
		return mr
	return ProceduralRig.new()




func request_punch(type: int, body: bool, power_punch: bool) -> void :
	if is_bag:
		return
	var p: = {"type": type, "body": body, "power": power_punch}
	match state:
		State.IDLE:
			if blocking:
				return
			_start_punch(p)
		State.PUNCH, State.HIT:
			queued = p
			queued_time = clock


func request_clinch() -> void :
	if is_bag or state != State.IDLE or clinch_cooldown > 0.0 or opponent == null or opponent.is_bag:
		return
	if dist_to_opp > CLINCH_RANGE:
		return
	if not (opponent.state == State.IDLE or opponent.state == State.PUNCH or opponent.state == State.HIT):
		return
	clinch_requested.emit(self)


func clear_inputs() -> void :
	move_input = Vector2.ZERO
	want_block = false
	want_block_low = false
	lean_input = Lean.NONE
	lean_vec_input = Vector2.ZERO
	queued = {}




func tick(delta: float) -> void :
	clock += delta
	since_hit += delta
	since_block_hit += delta
	if is_bag:
		_update_distance()
		if rig:
			rig.update_rig(delta)
		return
	counter_window = maxf(0.0, counter_window - delta)
	clinch_cooldown = maxf(0.0, clinch_cooldown - delta)
	guard_break_t = maxf(0.0, guard_break_t - delta)
	arm_fatigue = maxf(0.0, arm_fatigue - delta * 0.75)
	if stun_timer > 0.0:
		stun_timer -= delta * (2.0 if state == State.CLINCH else 1.0)
	_update_distance()

	match state:
		State.IDLE:
			_tick_idle(delta)
		State.PUNCH:
			_tick_punch(delta)
		State.HIT:
			hit_timer -= delta
			if hit_timer <= 0.0:
				state = State.IDLE
				if not queued.is_empty() and clock - queued_time < 0.3:
					var q: = queued
					queued = {}
					_start_punch(q)
		State.GETUP:
			getup_timer -= delta
			if getup_timer <= 0.0:
				state = State.IDLE
		State.INACTIVE:
			_tick_auto_walk(delta)

	_update_lean_visual(delta)
	_update_guard(delta)
	_regen(delta)
	_apply_movement(delta)
	_update_facing(delta)
	if rig:
		rig.update_rig(delta)
	if state == State.DOWN or state == State.KO or state == State.GETUP:
		if not (rig is MixamoRig and (rig as MixamoRig).is_ragdoll()):
			_keep_body_inside(delta)



func _wanted_lean_vec() -> Vector2:
	if lean_vec_input.length() > 0.05:
		return lean_vec_input.limit_length(1.0)
	match lean_input:
		Lean.LEFT:
			return Vector2(-1, 0)
		Lean.RIGHT:
			return Vector2(1, 0)
		Lean.DUCK:
			return Vector2(0, 1)
		Lean.BACK:
			return Vector2(0, -1)
	return Vector2.ZERO


static func _vec_to_lean(v: Vector2) -> int:
	if v.length() < 0.45:
		return Lean.NONE
	if absf(v.x) >= absf(v.y) * 0.85:
		return Lean.LEFT if v.x < 0.0 else Lean.RIGHT
	return Lean.DUCK if v.y > 0.0 else Lean.BACK


func _update_lean_visual(delta: float) -> void :
	var target: = Vector2.ZERO
	if state == State.IDLE and not blocking:
		target = _wanted_lean_vec()

	var rate: = 9.0 if target.length() > lean_vec.length() else 6.0
	lean_vec = lean_vec.move_toward(target, delta * rate)
	lean_amount = clampf(lean_vec.length(), 0.0, 1.0)


func _tick_idle(_delta: float) -> void :
	var new_lean: int = _vec_to_lean(_wanted_lean_vec())
	if new_lean != lean:
		lean = new_lean
		if lean != Lean.NONE:
			lean_start = clock
			stamina = maxf(0.0, stamina - 0.8)
	var was_blocking: = blocking
	blocking = want_block and lean == Lean.NONE and guard_break_t <= 0.0

	if blocking and stun_timer > 0.0:
		_stun_guard_t -= get_process_delta_time()
		if _stun_guard_t <= 0.0:
			_stun_guard_open = _rng.randf() < 0.5
			_stun_guard_t = _rng.randf_range(0.25, 0.5)
		if _stun_guard_open:
			blocking = false
	block_low = want_block_low
	if blocking and not was_blocking:
		block_start = clock
	if not queued.is_empty() and not blocking:
		var q: = queued
		queued = {}
		if clock - queued_time < 0.4:
			_start_punch(q)


func _start_punch(p: Dictionary) -> void :
	var t: int = p["type"]
	var body: bool = p["body"]
	var pw: bool = p["power"]
	var d: = Punches.get_data(t)
	var lead: = Punches.is_lead(t)
	var flow: = 1.0
	if clock - last_punch_end < 0.3:
		flow = 0.85 if lead != last_punch_lead else 0.94
	var tl: = clampi(tempo_level, 0, 2)
	var tm: = timing_mult() * float(wphys["tempo"])

	var fat: = clampf(arm_fatigue - 2.5, 0.0, 4.0)
	punch_windup = float(d["windup"]) * tm * flow * (Punches.POWER_WINDUP if pw else 1.0) * float(TEMPO_WINDUP[tl]) * (1.0 + fat * 0.06) + (0.025 if body else 0.0)
	punch_active = float(d["active"])
	punch_recovery = float(d["recovery"]) * tm * (Punches.POWER_RECOVERY if pw else 1.0) * float(TEMPO_RECOVERY[tl]) * (1.0 + fat * 0.05)
	var cost: float = float(d["stamina"]) * STAMINA_COST_SCALE * (Punches.POWER_STAMINA if pw else 1.0) * (1.3 - stamina_stat / 100.0 * 0.5) * float(wphys["drain"]) * (1.0 + fat * 0.12)
	var weak: = stamina < cost
	stamina = maxf(0.0, stamina - cost)
	arm_fatigue += 1.0 + (0.6 if pw else 0.0)
	punch = {
		"type": t, "body": body, "power": pw, "weak": weak, "cost": cost, "lead": lead, 
		"windup": punch_windup, "reach": float(d["reach"]) + reach_bonus, "fatigue": fat, 
		"from_lean": lean != Lean.NONE and clock - lean_start < 0.8, 
	}
	punch_phase = Phase.WINDUP
	punch_time = 0.0
	whiffed = false
	state = State.PUNCH
	lean = Lean.NONE
	blocking = false
	if rig:
		rig.on_punch_start(t, body, pw, punch_windup, punch_active, punch_recovery)
	punch_started.emit(self, punch)


func _tick_punch(delta: float) -> void :
	punch_time += delta
	match punch_phase:
		Phase.WINDUP:
			if punch_time >= punch_windup:
				punch_phase = Phase.ACTIVE
				_resolve()
		Phase.ACTIVE:
			if punch_time >= punch_windup + punch_active:
				punch_phase = Phase.RECOVERY
		Phase.RECOVERY:
			var rec_t: = punch_time - punch_windup - punch_active
			var rec_total: = punch_recovery * (1.35 if whiffed else 1.0)
			var chain_at: = 0.7 if whiffed else 0.5
			if not queued.is_empty() and rec_t >= rec_total * chain_at:
				var q: = queued
				var fresh: = clock - queued_time < 0.45
				queued = {}
				_end_punch()
				if fresh:
					_start_punch(q)
			elif rec_t >= rec_total:
				_end_punch()


func _end_punch() -> void :
	last_punch_end = clock
	last_punch_lead = bool(punch.get("lead", false))
	state = State.IDLE
	punch = {}


func _resolve() -> void :
	var p: = punch
	if p.is_empty():
		return
	var t: int = p["type"]
	var body: bool = p["body"]
	var pw: bool = p["power"]
	var d: = Punches.get_data(t)
	var reach: float = float(p["reach"]) - (0.08 if body else 0.0) + (0.04 if pw else 0.0)
	var result: Dictionary
	if opponent and opponent.can_be_hit() and dist_to_opp <= reach + 0.08 + (0.25 if opponent.is_bag else 0.0):
		var info: = p.duplicate()
		info["damage"] = _punch_damage(p)
		info["kd"] = float(d["kd"])
		info["hand_side"] = Punches.hand_side(t, stance_sign)
		info["reach"] = reach
		result = opponent.receive_punch(self, info)
	else:
		result = {"outcome": "miss", "damage": 0.0}
	var outcome: String = result["outcome"]
	if outcome == "miss" or outcome == "slipped":
		whiffed = true
		if outcome == "miss":
			stamina = maxf(0.0, stamina - float(p["cost"]) * 0.5)
	if outcome == "slipped" and bool(result.get("perfect", false)):
		punch_recovery += 0.15
	punch_resolved.emit(self, opponent, p, result)


func _punch_damage(p: Dictionary) -> float:
	var t: int = p["type"]
	var d: = Punches.get_data(t)
	var dmg: float = float(d["damage"]) * DAMAGE_SCALE
	dmg *= Balance.POWER_STAT_BASE + power / 100.0 * Balance.POWER_STAT_K
	if bool(p["power"]):
		dmg *= Punches.POWER_DAMAGE
	if bool(p["weak"]):
		dmg *= Balance.WEAK_PUNCH
	dmg *= clampf(stamina / Balance.TIRED_STAMINA + 0.35, Balance.TIRED_MIN, 1.0)
	dmg *= 1.0 - clampf(float(p.get("fatigue", 0.0)) * Balance.FATIGUE_STEP, 0.0, Balance.FATIGUE_MAX)
	dmg *= _rng.randf_range(1.0 - Balance.DAMAGE_RANDOM, 1.0 + Balance.DAMAGE_RANDOM)
	dmg *= float(wphys["dmg"])
	return dmg



func receive_punch(attacker: Fighter, info: Dictionary) -> Dictionary:
	var dmg: float = info["damage"]
	var t: int = info["type"]
	var body: bool = info["body"]
	var pw: bool = info["power"]
	var reach: float = info["reach"]
	var res: = {
		"outcome": "hit", "zone": "body" if body else "head", "damage": 0.0, "counter": false, 
		"stun": false, "kd": false, "perfect": false, "type": t, 
	}
	var incoming_side: int = - int(info["hand_side"])
	if is_bag:
		return _bag_hit(attacker, info, res, incoming_side)
	var can_defend: = state == State.IDLE



	var counter: = false
	var counter_mult: = 1.0
	if attacker.counter_window > 0.0:
		counter = true
		counter_mult = Balance.COUNTER_AFTER_DEFENSE
		if bool(info.get("from_lean", false)):
			counter_mult = Balance.COUNTER_FROM_LEAN
	elif state == State.PUNCH and whiffed:
		counter = true
		counter_mult = Balance.COUNTER_WHIFF
	elif state == State.PUNCH and (punch_phase == Phase.WINDUP or punch_phase == Phase.ACTIVE):
		counter_mult = Balance.COUNTER_TRADE


	if can_defend and lean != Lean.NONE and lean_amount > 0.3:
		var lean_side: = 0
		if lean == Lean.LEFT:
			lean_side = -1
		elif lean == Lean.RIGHT:
			lean_side = 1
		var held: = clock - lean_start
		var verdict: = "none"
		if body:
			if lean == Lean.BACK and dist_to_opp > reach - 0.3:
				verdict = "evade"
		elif Punches.is_straight(t):
			if lean == Lean.BACK:
				verdict = "evade" if dist_to_opp > reach - 0.35 else "partial"
			else:
				verdict = "evade"
		elif Punches.is_hook(t):
			if lean == Lean.DUCK or lean == Lean.BACK:
				verdict = "evade"
			elif lean_side == incoming_side:
				verdict = "into"
			else:
				verdict = "partial"
		else:
			if lean == Lean.DUCK:
				verdict = "into"
			else:
				verdict = "evade"

		if verdict == "evade" and held > Balance.LEAN_STALE + defense / 100.0 * 0.4:
			verdict = "partial"
		match verdict:
			"evade":
				var perfect_window: = Balance.PERFECT_SLIP + defense / 100.0 * 0.12
				var perfect: = held <= perfect_window
				stamina = maxf(0.0, stamina - 1.0)
				counter_window = maxf(counter_window, 0.8 if perfect else 0.35)
				res["outcome"] = "slipped"
				res["perfect"] = perfect
				return res
			"partial":
				dmg *= Balance.LEAN_GRAZE
				res["graze"] = true
			"into":
				dmg *= Balance.LEAN_INTO
				res["into"] = true


	var passive: = false
	if can_defend and not blocking and not body and Punches.is_straight(t) and guard_hp > GUARD_MAX * 0.3 and stun_timer <= 0.0:
		var pg: Dictionary = Balance.PASSIVE_GUARD
		var pch: = float(pg["base"]) + defense / 100.0 * float(pg["def"])
		if t == Punches.Type.CROSS:
			pch *= float(pg["cross"])
		if pw:
			pch *= 0.5
		passive = _rng.randf() < pch


	if can_defend and (blocking or passive):
		var covered: = passive or (body and block_low) or ( not body and not block_low)
		if covered:

			var parry_window: = (Balance.PARRY_WINDOW + defense / 100.0 * 0.08) * lerpf(1.0, float(TEMPO_WINDUP[clampi(tempo_level, 0, 2)]), 0.6)
			if not passive and clock - block_start <= parry_window:
				res["outcome"] = "parried"
				counter_window = 0.8
				attacker.stagger(0.45)
				if rig:
					rig.on_blocked_hit(0.5)
				return res
			var gcost: = float(Punches.GUARD_COST[t]) * (Punches.POWER_GUARD if pw else 1.0)
			gcost *= 0.75 + attacker.power / 100.0 * 0.5
			gcost *= 1.15 - defense / 100.0 * 0.3
			gcost *= sqrt(maxf(float(attacker.wphys["dmg"]), 0.1))
			gcost *= 1.0 + (1.0 - clampf(stamina / 100.0, 0.0, 1.0)) * 0.6
			if stun_timer > 0.0:
				gcost *= 1.5
			guard_hp -= gcost
			since_block_hit = 0.0

			stamina = maxf(0.0, stamina - float(info["cost"]) * Balance.BLOCK_STAMINA * (1.4 if pw else 1.0))
			if guard_hp > 0.0:
				var absorb: = Balance.BLOCK_ABSORB + defense / 100.0 * 0.08
				if pw:
					absorb -= Balance.BLOCK_ABSORB_POWER
				if stun_timer > 0.0:
					absorb -= Balance.BLOCK_ABSORB_STUN
				absorb -= (1.0 - guard_hp / GUARD_MAX) * Balance.BLOCK_ABSORB_WORN
				if Punches.is_upper(t) and not body:
					absorb -= Balance.BLOCK_ABSORB_UPPER
				absorb = clampf(absorb, 0.3, 0.97)
				var chip: = dmg * (1.0 - absorb)
				if body:
					body_hp -= chip
				else:
					head_hp -= chip
				since_hit = 0.0
				res["outcome"] = "blocked"
				res["damage"] = chip
				res["guard"] = guard_ratio()
				velocity += _push_dir(attacker) * minf(dmg * 0.025, 0.5)
				if rig:
					rig.on_blocked_hit(clampf(dmg / 13.0, 0.25, 1.2))
				if head_hp <= 0.0 or body_hp <= 0.0:
					head_hp = maxf(head_hp, 1.0)
					body_hp = maxf(body_hp, 1.0)
				return res

			guard_hp = 0.0
			guard_break_t = 1.0
			blocking = false
			res["guard_break"] = true
			dmg *= Balance.GUARD_BREAK_DAMAGE
			guard_broken.emit(self)


	dmg *= counter_mult + (Balance.COUNTER_POWER_BONUS if pw and counter else 0.0)
	if stun_timer > 0.0:
		dmg *= Balance.HIT_STUNNED
	if stamina < 20.0:
		dmg *= Balance.HIT_EXHAUSTED
	if body:
		dmg *= Balance.BODY_BASE - chin / 100.0 * 0.1 - stamina_stat / 100.0 * 0.1
		body_hp -= dmg
		body_max = maxf(body_cap * 0.35, body_max - dmg * Balance.BODY_MAX_WEAR)
		stamina = maxf(0.0, stamina - dmg * Balance.BODY_STAMINA_LOSS)
	else:
		dmg *= Balance.HEAD_BASE - chin / 100.0 * Balance.HEAD_CHIN
		head_hp -= dmg
		head_max = maxf(head_cap * 0.3, head_max - dmg * Balance.HEAD_MAX_WEAR)
		stamina = maxf(0.0, stamina - dmg * Balance.HEAD_STAMINA_LOSS)
		if (pw or counter) and _rng.randf() < 0.55:
			cut = minf(100.0, cut + dmg * _rng.randf_range(0.15, 0.5) * (0.4 if training else 1.0))
		var straight: = t == 0 or t == 1 or t == 4 or t == 5
		if dmg > 5.0 and (straight or _rng.randf() < 0.3):
			nose_blood = minf(1.0, nose_blood + dmg * (0.012 if straight else 0.006) * (1.25 - chin / 100.0 * 0.5))
		res["bleed"] = clampf(cut / 100.0 * 0.7 + nose_blood * 0.6, 0.0, 1.0) * clampf(dmg / 12.0, 0.2, 1.0)
		blood_spill += float(res["bleed"])
	since_hit = 0.0
	res["damage"] = dmg
	res["counter"] = counter
	velocity += _push_dir(attacker) * minf(dmg * 0.04, 0.85)

	if state == State.PUNCH and rig:
		rig.on_punch_cancel()
	punch = {}
	queued = {}
	var react: = minf(0.12 + dmg * 0.016, 0.48) + (0.08 if counter else 0.0)
	if bool(res.get("guard_break", false)):
		react = maxf(react, 0.45)
	state = State.HIT
	hit_timer = react
	blocking = false
	lean = Lean.NONE
	if rig:
		rig.on_hit(body, incoming_side, clampf(dmg / 18.0, 0.15, 1.3), t)

	if training:
		head_hp = maxf(head_hp, head_cap * 0.15)
		body_hp = maxf(body_hp, body_cap * 0.15)
		return res


	if not body and stun_timer <= 0.0:
		var hp_ratio: = clampf(head_hp / head_cap, 0.0, 1.0)
		if (dmg >= Balance.STUN_DMG and hp_ratio < Balance.STUN_HP) or (counter and pw and hp_ratio < Balance.STUN_COUNTER_HP)\
		or (dmg >= Balance.STUN_BIG_DMG and hp_ratio < Balance.STUN_BIG_HP):
			stun_timer = clampf(dmg * 0.2, float(Balance.STUN_TIME[0]), float(Balance.STUN_TIME[1]))
			res["stun"] = true


	var kd: = false
	var body_kd: = false
	if head_hp <= 0.0:
		kd = true
	elif body_hp <= 0.0:
		kd = true
		body_kd = true
	elif not body and (pw or counter) and dmg >= Balance.FLASH_MIN_DMG:
		var chance: = (dmg - (Balance.FLASH_MIN_DMG - 1.0)) * Balance.FLASH_K * (1.0 - clampf(head_hp / head_cap, 0.0, 1.0)) * (1.35 - chin / 100.0 * 0.7) * float(info["kd"]) * float(attacker.wphys["kd"])
		if stun_timer > 0.0:
			chance *= Balance.FLASH_STUN_MULT
		if _rng.randf() < chance:
			kd = true
			res["flash"] = true
	if kd:
		res["kd"] = true
		res["body_kd"] = body_kd

		if not body_kd and (counter or pw) and (head_hp <= head_cap * Balance.COLD_KO_HP or (knockdowns_total >= 2 and head_hp <= head_cap * Balance.COLD_KO_HP_REPEAT)):
			out_cold = true
			res["cold"] = true
		go_down(body_kd)
	return res


func _bag_hit(attacker: Fighter, info: Dictionary, res: Dictionary, incoming_side: int) -> Dictionary:
	var dmg: float = info["damage"]
	var body: bool = info["body"]
	var t: int = info["type"]
	if attacker.counter_window > 0.0:
		dmg *= 1.45
		res["counter"] = true
	res["damage"] = dmg
	since_hit = 0.0
	bag_hits += 1
	bag_damage += dmg
	last_hit_info = {"type": t, "body": body, "power": bool(info["power"]), "damage": dmg}
	if rig:
		var dir: = _push_dir(attacker)
		rig.call("on_bag_hit", dir, body, incoming_side, dmg, t)
	return res


func guard_ratio() -> float:
	return clampf(guard_hp / GUARD_MAX, 0.0, 1.0)


func is_guard_broken() -> bool:
	return guard_break_t > 0.0


func _update_guard(delta: float) -> void :
	if blocking:

		guard_hp = maxf(minf(guard_hp, 18.0), guard_hp - delta * 2.5)
	elif guard_break_t <= 0.0 and since_block_hit > 0.6:
		var k: = 0.45 + 0.55 * clampf(stamina / 60.0, 0.0, 1.0)
		guard_hp = minf(GUARD_MAX, guard_hp + (18.0 + defense * 0.1) * k * delta)


func _push_dir(attacker: Fighter) -> Vector3:
	var d: = global_position - attacker.global_position
	d.y = 0.0
	if d.length() < 0.01:
		return Vector3.ZERO
	return d.normalized()


func stagger(duration: float) -> void :
	if is_bag:
		return
	if state == State.PUNCH:
		if rig:
			rig.on_punch_cancel()
		punch = {}
	if state == State.IDLE or state == State.PUNCH or state == State.HIT:
		state = State.HIT
		hit_timer = duration
		queued = {}
		if rig:
			rig.on_parried()


func can_be_hit() -> bool:
	if is_bag:
		return true
	return state == State.IDLE or state == State.PUNCH or state == State.HIT


func is_active() -> bool:
	return state == State.IDLE or state == State.PUNCH or state == State.HIT


func is_down() -> bool:
	return state == State.DOWN or state == State.KO






func _keep_body_inside(delta: float) -> void :
	if rig == null:
		return
	var lim: = 2.9 + 0.06
	var shift: = Vector3.ZERO
	for q in rig.rope_points():
		var p4: Vector4 = q
		for ax in [0, 2]:
			var v: float = p4[ax]
			var over: = absf(v) + p4.w * 0.5 - lim
			if over > 0.0 and over > absf(shift[ax]):
				shift[ax] = - signf(v) * over
	if shift != Vector3.ZERO:
		global_position += shift * minf(delta * 14.0, 1.0)


func go_down(body_kd: bool) -> void :
	state = State.DOWN
	punch = {}
	queued = {}
	blocking = false
	lean = Lean.NONE
	lean_vec = Vector2.ZERO
	stun_timer = 0.0
	down_body = body_kd
	knockdowns_round += 1
	knockdowns_total += 1
	if rig:
		rig.on_knockdown(body_kd)



func start_getup(duration: float) -> void :
	state = State.GETUP
	getup_timer = duration
	var n: = float(knockdowns_total - 1)
	var gh: Array = Balance.GETUP_HEAD
	head_max = maxf(head_cap * 0.3, head_max * Balance.GETUP_HEAD_MAX)
	var factor: = clampf(float(gh[0]) - float(gh[1]) * n, float(gh[2]), float(gh[0]))
	head_hp = clampf(maxf(head_hp, head_max * factor), 1.0, head_max * float(gh[3]))
	if down_body:
		body_max = maxf(body_cap * 0.35, body_max * 0.9)
		body_hp = maxf(body_hp, body_max * 0.3)
	stamina = clampf(maxf(stamina, stamina_max * float(Balance.GETUP_STAMINA[0])), 0.0, stamina_max * float(Balance.GETUP_STAMINA[1]))
	guard_hp = GUARD_MAX * Balance.GETUP_GUARD
	stun_timer = 0.0
	down_body = false
	if rig:
		rig.on_getup(duration)



func wobble_after_getup() -> void :
	stun_timer = float(Balance.WOBBLE_TIME[0]) + float(Balance.WOBBLE_TIME[1]) * float(knockdowns_total - 1)


func set_ko() -> void :
	state = State.KO


func set_victory() -> void :
	state = State.VICTORY
	clear_inputs()
	if rig:
		rig.on_victory()


func enter_clinch(initiator: bool) -> void :
	if state == State.PUNCH and rig:
		rig.on_punch_cancel()
	state = State.CLINCH
	clinch_initiator = initiator
	punch = {}
	queued = {}
	blocking = false
	lean = Lean.NONE
	if rig:
		rig.on_clinch(true)


func exit_clinch() -> void :
	if state == State.CLINCH:
		state = State.IDLE
	clinch_cooldown = 6.0
	clinch_initiator = false
	if rig:
		rig.on_clinch(false)


func reset_for_round() -> void :
	state = State.INACTIVE
	knockdowns_round = 0
	stun_timer = 0.0
	counter_window = 0.0
	punch = {}
	queued = {}
	blocking = false
	lean = Lean.NONE
	lean_amount = 0.0
	lean_vec = Vector2.ZERO
	velocity = Vector3.ZERO
	auto_walk = false
	guard_hp = GUARD_MAX
	guard_break_t = 0.0
	arm_fatigue = 0.0
	regen_boost = 1.0
	clear_inputs()
	if rig:
		rig.on_reset()



func corner_recover(pts_health: int, pts_stamina: int, pts_cut: int) -> void :


	var k: Dictionary = Balance.CORNER
	head_max = minf(head_cap, head_max + (head_cap - head_max) * float(k["head_max"]) + pts_health * float(k["pts_max"]))
	head_hp = minf(head_max, head_hp + (head_max - head_hp) * (float(k["head"]) + float(k["per_pt"]) * pts_health))
	body_max = minf(body_cap, body_max + pts_stamina * float(k["pts_max"]))
	body_hp = minf(body_max, body_hp + (body_max - body_hp) * (float(k["body"]) + float(k["per_pt"]) * pts_stamina))
	_update_stamina_max()
	stamina = minf(stamina_max, stamina + (stamina_max - stamina) * (float(k["stamina"]) + float(k["stamina_pt"]) * pts_stamina))
	cut = maxf(0.0, cut - float(k["cut"]) - pts_cut * float(k["cut_pt"]))
	nose_blood = maxf(0.0, nose_blood * 0.55 - pts_cut * 0.08)
	sweat = minf(1.0, sweat + 0.16)


func begin_fight_state() -> void :
	state = State.IDLE
	auto_walk = false


func walk_to(target: Vector3) -> void :
	auto_target = target
	auto_walk = true




func timing_mult() -> float:
	var m: = 1.18 - speed / 100.0 * 0.36
	if stamina < 25.0:
		m *= 1.0 + (25.0 - stamina) / 25.0 * 0.25
	if stun_timer > 0.0:
		m *= 1.15
	return m


func move_speed() -> float:
	var s: = (1.15 + speed / 100.0 * 0.8) * float(wphys["move"]) * float(TEMPO_MOVE[clampi(tempo_level, 0, 2)])
	if stamina < 20.0:
		s *= 0.75
	if blocking:
		s *= 0.55
	if lean != Lean.NONE:
		s *= 0.6
	if stun_timer > 0.0:
		s *= 0.6
	return s


func _update_stamina_max() -> void :
	stamina_max = 55.0 + 45.0 * clampf(body_hp / body_cap, 0.0, 1.0)
	stamina = minf(stamina, stamina_max)


func _regen(delta: float) -> void :
	if state == State.IDLE or state == State.CLINCH or state == State.HIT or state == State.INACTIVE:
		var r: = (float(Balance.REGEN_STAMINA[0]) + stamina_stat / 100.0 * float(Balance.REGEN_STAMINA[1])) * float(wphys["regen"]) * regen_boost
		if blocking:
			r *= 0.5
		if lean != Lean.NONE:
			r *= 0.4
		if local_move.length() > 0.3:
			r *= 0.7
		if state == State.CLINCH and clinch_initiator:
			r *= 1.6
		if state == State.CLINCH and not clinch_initiator:
			r *= 0.3
		stamina = minf(stamina_max, stamina + r * delta)
	if lean != Lean.NONE:
		stamina = maxf(0.0, stamina - 1.5 * delta)
	if state != State.DOWN and state != State.KO:
		if since_hit > Balance.REGEN_DELAY:
			head_hp = minf(head_max, head_hp + (float(Balance.REGEN_HEAD[0]) + chin / 100.0 * float(Balance.REGEN_HEAD[1])) * regen_boost * delta)
			body_hp = minf(body_max, body_hp + Balance.REGEN_BODY * regen_boost * delta)
		if state == State.CLINCH and clinch_initiator:
			head_hp = minf(head_max, head_hp + 1.6 * delta)
		if training and since_hit > 2.0:
			head_hp = minf(head_cap, head_hp + 25.0 * delta)
			body_hp = minf(body_cap, body_hp + 25.0 * delta)
			head_max = minf(head_cap, head_max + 10.0 * delta)
			body_max = minf(body_cap, body_max + 10.0 * delta)
			stamina = minf(stamina_max, stamina + 10.0 * delta)
	_update_stamina_max()


func _update_distance() -> void :
	if opponent == null:
		return
	var d: = opponent.global_position - global_position
	d.y = 0.0
	dist_to_opp = d.length()


func _apply_movement(delta: float) -> void :
	var fwd: = - global_transform.basis.z
	if opponent:
		var to_opp: = opponent.global_position - global_position
		to_opp.y = 0.0
		if to_opp.length() > 0.01:
			fwd = to_opp.normalized()
	fwd.y = 0.0
	fwd = fwd.normalized()
	var right: = fwd.cross(Vector3.UP)
	var spd: = move_speed()

	match state:
		State.IDLE, State.PUNCH:
			var mv: = move_input.limit_length(1.0)
			var s: = spd * (0.3 if state == State.PUNCH else 1.0)

			var target_vel: = (fwd * mv.y + right * mv.x * 0.8) * s

			if state == State.PUNCH and punch_phase == Phase.WINDUP and opponent and not punch.is_empty():
				var need: = dist_to_opp - (float(punch.get("reach", 1.2)) - 0.1)
				if need > 0.0 and need < 0.9:
					var left_t: = maxf(punch_windup - punch_time, 0.06)
					target_vel += fwd * minf(need / left_t, 2.6)
			velocity = velocity.move_toward(target_vel, delta * (22.0 if state == State.PUNCH else 12.0))
		State.INACTIVE:
			pass
		State.CLINCH:
			velocity = Vector3.ZERO
		_:
			velocity = velocity.move_toward(Vector3.ZERO, delta * 6.0)

	global_position += velocity * delta
	global_position.y = 0.0
	local_move = Vector2(velocity.dot(right), velocity.dot(fwd)) / maxf(spd, 0.1)


	var p: = global_position
	for ax in [0, 2]:
		var c: float = p[ax]
		var pen: = absf(c) - ROPE_SOFT
		if pen > 0.0:
			c -= signf(c) * pen * minf(delta * 5.0, 1.0)
			p[ax] = clampf(c, - RING_LIMIT, RING_LIMIT)
	global_position = p
	on_ropes = absf(p.x) > ROPE_SOFT - 0.05 or absf(p.z) > ROPE_SOFT - 0.05


func _tick_auto_walk(delta: float) -> void :
	if not auto_walk:
		velocity = velocity.move_toward(Vector3.ZERO, delta * 8.0)
		return
	var d: = auto_target - global_position
	d.y = 0.0
	if d.length() < 0.08:
		auto_walk = false
		velocity = Vector3.ZERO
		return
	velocity = d.normalized() * minf(1.7, d.length() * 3.0)


func _update_facing(delta: float) -> void :
	if state == State.DOWN or state == State.KO:
		return
	var dir: = Vector3.ZERO
	if state == State.INACTIVE and auto_walk and velocity.length() > 0.3:
		dir = velocity
	elif opponent:
		dir = opponent.global_position - global_position
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	var target_yaw: = atan2( - dir.x, - dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * 10.0, 0.0, 1.0))




func head_ratio() -> float:
	return clampf(head_hp / head_cap, 0.0, 1.0)


func head_max_ratio() -> float:
	return clampf(head_max / head_cap, 0.0, 1.0)


func body_ratio() -> float:
	return clampf(body_hp / body_cap, 0.0, 1.0)


func stamina_ratio() -> float:
	return clampf(stamina / 100.0, 0.0, 1.0)


func stamina_max_ratio() -> float:
	return clampf(stamina_max / 100.0, 0.0, 1.0)


func head_global() -> Vector3:
	if rig:
		return rig.get_head_global()
	return global_position + Vector3(0, height_m * 0.92, 0)
