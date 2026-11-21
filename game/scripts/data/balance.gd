class_name Balance
extends RefCounted







const PUNCHES: = {
	0: {"windup": 0.11, "active": 0.06, "recovery": 0.17, "reach": 1.34, "damage": 3.4, "stamina": 2.4, "kd": 0.25}, 
	1: {"windup": 0.17, "active": 0.07, "recovery": 0.24, "reach": 1.3, "damage": 7.2, "stamina": 4.8, "kd": 0.85}, 
	2: {"windup": 0.18, "active": 0.08, "recovery": 0.25, "reach": 1.1, "damage": 7.8, "stamina": 5.4, "kd": 1.0}, 
	3: {"windup": 0.22, "active": 0.08, "recovery": 0.3, "reach": 1.06, "damage": 9.8, "stamina": 6.6, "kd": 1.15}, 
	4: {"windup": 0.19, "active": 0.08, "recovery": 0.27, "reach": 1.14, "damage": 8.6, "stamina": 5.8, "kd": 1.1}, 
	5: {"windup": 0.23, "active": 0.08, "recovery": 0.31, "reach": 1.12, "damage": 10.6, "stamina": 7.2, "kd": 1.3}, 
}

const POWER_WINDUP: = 1.75
const POWER_RECOVERY: = 1.3
const POWER_DAMAGE: = 1.65
const POWER_STAMINA: = 1.85

const GUARD_COST: = [9.0, 15.0, 16.0, 19.0, 17.0, 20.0]
const POWER_GUARD: = 1.9
const GUARD_MAX: = 100.0


const DAMAGE_SCALE: = 0.48
const STAMINA_COST_SCALE: = 0.72
const POWER_STAT_BASE: = 0.72
const POWER_STAT_K: = 0.56
const WEAK_PUNCH: = 0.7
const TIRED_STAMINA: = 35.0
const TIRED_MIN: = 0.78
const FATIGUE_STEP: = 0.05
const FATIGUE_MAX: = 0.18
const DAMAGE_RANDOM: = 0.1


const COUNTER_AFTER_DEFENSE: = 1.45
const COUNTER_FROM_LEAN: = 1.55
const COUNTER_WHIFF: = 1.35
const COUNTER_TRADE: = 1.15
const COUNTER_POWER_BONUS: = 0.15


const LEAN_GRAZE: = 0.45
const LEAN_INTO: = 1.35
const LEAN_STALE: = 1.0
const PERFECT_SLIP: = 0.24


const PARRY_WINDOW: = 0.13
const BLOCK_ABSORB: = 0.88
const BLOCK_ABSORB_POWER: = 0.12
const BLOCK_ABSORB_STUN: = 0.3
const BLOCK_ABSORB_WORN: = 0.22
const BLOCK_ABSORB_UPPER: = 0.18
const BLOCK_STAMINA: = 0.85


const PASSIVE_GUARD: = {"base": 0.14, "def": 0.3, "cross": 0.5}
const GUARD_BREAK_DAMAGE: = 0.8


const HIT_STUNNED: = 1.2
const HIT_EXHAUSTED: = 1.12
const BODY_BASE: = 1.1
const HEAD_BASE: = 1.18
const HEAD_CHIN: = 0.36
const HEAD_MAX_WEAR: = 0.14
const BODY_MAX_WEAR: = 0.12
const BODY_STAMINA_LOSS: = 1.1
const HEAD_STAMINA_LOSS: = 0.45


const STUN_DMG: = 7.0
const STUN_HP: = 0.4
const STUN_COUNTER_HP: = 0.6
const STUN_BIG_DMG: = 13.0
const STUN_BIG_HP: = 0.7
const STUN_TIME: = [1.8, 3.6]


const FLASH_MIN_DMG: = 9.5
const FLASH_K: = 0.029
const FLASH_STUN_MULT: = 1.5
const COLD_KO_HP: = -0.16
const COLD_KO_HP_REPEAT: = -0.06


const GETUP_HEAD_MAX: = 0.86
const GETUP_HEAD: = [0.42, 0.08, 0.2, 0.5]
const GETUP_STAMINA: = [0.35, 0.55]
const GETUP_GUARD: = 0.55
const WOBBLE_TIME: = [1.1, 0.35]

const AI_GETUP: = {"base": 0.95, "per_kd": 0.22, "wear": 0.5, "chin": 0.2, "flash": 0.08}
const REF_STOP_UNANSWERED: = 7
const REF_STOP_HP: = 0.25
const CUT_STOP: = 100.0


const REGEN_STAMINA: = [6.5, 6.5]
const REGEN_HEAD: = [0.16, 0.16]
const REGEN_BODY: = 0.1
const REGEN_DELAY: = 4.0
const CORNER: = {"head_max": 0.12, "pts_max": 4.0, "head": 0.45, "body": 0.4, "per_pt": 0.12, 
	"stamina": 0.65, "stamina_pt": 0.1, "cut": 8.0, "cut_pt": 14.0}


const JUDGE_CLEAR: = 1.6
const JUDGE_EVEN_ROUND: = 0.1
const JUDGE_DEFENSE: = 0.15
const JUDGE_NOISE: = 0.06


const TEMPO_WINDUP: = [1.5, 1.28, 1.05]
const TEMPO_RECOVERY: = [1.3, 1.15, 1.0]
const TEMPO_MOVE: = [0.86, 0.93, 1.0]

const WEIGHT_K: = {"tempo": -0.028, "move": -0.03, "dmg": 0.045, "kd": 0.06, "drain": 0.04, "regen": -0.035}



const AI_DIFF: = {
	"react": [0.22, 0.4, 0.58, 0.72, 0.85], 
	"delay": [0.3, 0.22, 0.16, 0.12, 0.09], 
	"think": [0.3, 0.24, 0.18, 0.14, 0.1], 
	"aggr": [0.6, 0.8, 1.0, 1.1, 1.2], 
	"range_err": [0.25, 0.15, 0.08, 0.04, 0.0], 
	"counter": [0.25, 0.55, 0.85, 1.05, 1.25], 
	"adapt": [0.0, 0.5, 1.0, 1.2, 1.5], 
	"perfect": [0.0, 0.1, 0.25, 0.4, 0.55], 
}

const AI_STYLES: = {
	"outboxer": {"dist": 1.27, "aggr": 0.9, "block": 0.45, "slip": 0.34, "back": 0.25, "power": 0.18, 
		"clinch": 0.3, "circle": 0.8, "counter": 0.8, 
		"combos": ["J", "J", "J J", "J C", "J J C", "Jb J", "J C LH", "C"]}, 
	"swarmer": {"dist": 0.98, "aggr": 1.3, "block": 0.5, "slip": 0.35, "back": 0.05, "power": 0.2, 
		"clinch": 0.15, "circle": 0.35, "counter": 0.7, 
		"combos": ["LHb LH", "J C LH RH", "LU LH C", "Cb LH", "LHb RU", "J RHb LH", "LH RH", "J C LHb"]}, 
	"counter": {"dist": 1.2, "aggr": 0.6, "block": 0.3, "slip": 0.55, "back": 0.15, "power": 0.3, 
		"clinch": 0.2, "circle": 0.5, "counter": 1.4, 
		"combos": ["J", "C", "J C", "LH C", "C LH", "Jb C"]}, 
	"slugger": {"dist": 1.12, "aggr": 0.88, "block": 0.6, "slip": 0.15, "back": 0.2, "power": 0.46, 
		"clinch": 0.2, "circle": 0.3, "counter": 0.8, 
		"combos": ["C!", "J C!", "LH!", "RH!", "J RU!", "LH RH!", "J J C", "LHb! LH"]}, 
	"balanced": {"dist": 1.15, "aggr": 1.0, "block": 0.45, "slip": 0.35, "back": 0.2, "power": 0.25, 
		"clinch": 0.25, "circle": 0.5, "counter": 1.0, 
		"combos": ["J", "J C", "J C LH", "J Jb C", "C LH", "LHb LH", "J RU", "J C LH RH"]}, 
}
const AI_TEMPO_CD: = [1.65, 1.35, 1.0]
const AI_TEMPO_MAX_COMBO: = [[2, 2, 3, 3, 4], [2, 3, 3, 4, 4], [3, 3, 4, 4, 4]]


const HITSTOP: = [0.025, 0.1]
const HITSTOP_MIN_DMG: = 5.0
const SHAKE_BASE: = 0.06
const SHAKE_PER_DMG: = 0.02
const KD_SLOWMO: = 1.1
const KD_HITSTOP: = 0.12
const HIT_REACT: = {"head": 1.0, "body": 0.7, "max": 1.4}
