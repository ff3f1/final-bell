class_name Punches
extends RefCounted


enum Type{JAB, CROSS, LEAD_HOOK, REAR_HOOK, LEAD_UPPER, REAR_UPPER}






const DATA: = Balance.PUNCHES

const NAMES_RU: = ["Джеб", "Кросс", "Хук передней", "Хук задней", "Апперкот передней", "Апперкот задней"]
const SHORT_RU: = ["ДЖЕБ", "КРОСС", "ХУК", "ХУК", "АППЕРКОТ", "АППЕРКОТ"]


const POWER_WINDUP: = Balance.POWER_WINDUP
const POWER_RECOVERY: = Balance.POWER_RECOVERY
const POWER_DAMAGE: = Balance.POWER_DAMAGE
const POWER_STAMINA: = Balance.POWER_STAMINA


const GUARD_COST: = Balance.GUARD_COST
const POWER_GUARD: = Balance.POWER_GUARD


static func is_lead(t: int) -> bool:
	return t == Type.JAB or t == Type.LEAD_HOOK or t == Type.LEAD_UPPER


static func is_straight(t: int) -> bool:
	return t == Type.JAB or t == Type.CROSS


static func is_hook(t: int) -> bool:
	return t == Type.LEAD_HOOK or t == Type.REAR_HOOK


static func is_upper(t: int) -> bool:
	return t == Type.LEAD_UPPER or t == Type.REAR_UPPER




static func hand_side(t: int, stance_sign: int) -> int:
	return - stance_sign if is_lead(t) else stance_sign


static func get_data(t: int) -> Dictionary:
	return DATA[t]


static func display_name(t: int, body: bool, power: bool) -> String:
	var s: String = NAMES_RU[t]
	if body:
		s += " в корпус"
	if power:
		s = "Силовой " + s.to_lower()
	return s
