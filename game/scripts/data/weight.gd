class_name Weight
extends RefCounted


const DEFAULT: = 4

const LEGEND_DIV: = {"ice": 2, "buzzsaw": 3, "ghost": 4, "wildcard": 4, "iron": 5, "hammer": 6, "tower": 7, "bigdan": 7, 
	"rocco": 5, "pete": 4, "okafor": 6}


static func of(def: Dictionary) -> int:
	if def.has("division"):
		return clampi(int(def["division"]), 0, 7)
	return int(LEGEND_DIV.get(str(def.get("id", "")), DEFAULT))



static func phys(d: int) -> Dictionary:
	var x: = float(d) - 3.5
	var out: = {}
	for k in Balance.WEIGHT_K.keys():
		out[k] = 1.0 + x * float(Balance.WEIGHT_K[k])
	return out
