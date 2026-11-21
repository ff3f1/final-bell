class_name Divisions
extends RefCounted




const LIST: = [
	{"id": "fly", "name": "Наилегчайший", "short": "FLY", "lb": 112, "kg": 50.8, "h": [1.57, 1.7]}, 
	{"id": "bantam", "name": "Легчайший", "short": "BANTAM", "lb": 118, "kg": 53.5, "h": [1.6, 1.73]}, 
	{"id": "feather", "name": "Полулёгкий", "short": "FEATHER", "lb": 126, "kg": 57.2, "h": [1.63, 1.76]}, 
	{"id": "light", "name": "Лёгкий", "short": "LIGHT", "lb": 135, "kg": 61.2, "h": [1.66, 1.8]}, 
	{"id": "welter", "name": "Полусредний", "short": "WELTER", "lb": 147, "kg": 66.7, "h": [1.7, 1.84]}, 
	{"id": "middle", "name": "Средний", "short": "MIDDLE", "lb": 160, "kg": 72.6, "h": [1.74, 1.88]}, 
	{"id": "lightheavy", "name": "Полутяжёлый", "short": "LT HEAVY", "lb": 175, "kg": 79.4, "h": [1.78, 1.92]}, 
	{"id": "heavy", "name": "Тяжёлый", "short": "HEAVY", "lb": 200, "kg": 90.7, "h": [1.84, 2.01]}, 
]
const COUNT: = 8
const PER_DIV: = 20
const DEFAULT: = 4

const NEW_MODELS: = [18, 18, 17, 15, 13, 13, 11, 14]

const OLD_MODELS: = [
	[], [], ["ice"], ["buzzsaw", "opp_2", "opp_12"], ["ghost", "wildcard", "pete", "opp_6", "opp_7"], 
	["iron", "rocco", "opp_0", "opp_9", "opp_11"], ["hammer", "tower", "okafor", "opp_1", "opp_4", "opp_8", "opp_13"], 
	["bigdan", "opp_3", "opp_5", "opp_10"], 
]
const LEGEND_DIV: = Weight.LEGEND_DIV
const WORLD_SEED: = 777013

static var _world_cache: Array = []


static func name_of(d: int) -> String:
	return str(LIST[clampi(d, 0, COUNT - 1)]["name"])


static func label(d: int) -> String:
	var e: Dictionary = LIST[clampi(d, 0, COUNT - 1)]
	if d == COUNT - 1:
		return "%s (%d+ фунтов)" % [e["name"], int(e["lb"])]
	return "%s (до %d фунтов / %.1f кг)" % [e["name"], int(e["lb"]), float(e["kg"])]


static func of(def: Dictionary) -> int:
	return Weight.of(def)


static func phys(d: int) -> Dictionary:
	return Weight.phys(d)



static func models_for(d: int) -> Array:
	var out: Array = []
	for k in int(NEW_MODELS[d]):
		var id: = "w%d_%d" % [d, k]
		if MixamoRig.model_path_for_def({"id": id}) != "":
			out.append(id)
	for id in OLD_MODELS[d]:
		if MixamoRig.model_path_for_def({"id": str(id)}) != "":
			out.append(str(id))
	return out



static func player_model(face: int, d: int) -> String:
	var band: = 0 if d <= 2 else (1 if d <= 5 else 2)
	var id: = "pl_%d_%d" % [face, band]
	if MixamoRig.model_path_for_def({"id": id}) != "":
		return id
	return "career_%d" % mini(face, 5)


static func height_for(d: int, rng: RandomNumberGenerator) -> float:
	var h: Array = LIST[d]["h"]
	return snappedf(rng.randf_range(float(h[0]), float(h[1])), 0.01)



static func world() -> Array:
	if _world_cache.is_empty():
		_world_cache = generate(WORLD_SEED)
	return _world_cache


static func fighters_of(d: int) -> Array:
	return world()[clampi(d, 0, COUNT - 1)]


static func by_id(id: String) -> Dictionary:
	for div in world():
		for f in div:
			if str((f as Dictionary)["id"]) == id:
				return f
	return {}


static func generate(seed_v: int) -> Array:
	var rng: = RandomNumberGenerator.new()
	rng.seed = seed_v
	var out: Array = []
	var used_names: = {}
	for f in Roster.all_fighters():
		used_names[str((f as Dictionary)["name"])] = true
	for d in COUNT:
		var list: Array = []

		for f in Roster.all_fighters():
			var fd: Dictionary = f
			if int(LEGEND_DIV.get(str(fd["id"]), -1)) == d:
				var e: = fd.duplicate(true)
				e["division"] = d
				e["model"] = str(fd["id"])
				list.append(e)
		var models: = models_for(d)
		for id in LEGEND_DIV.keys():
			models.erase(str(id))
		var mi: = 0
		var reuse: = 0
		while list.size() < PER_DIV:
			var nm: = _make_name(rng, d)
			if used_names.has(str(nm["name"])):
				continue
			used_names[str(nm["name"])] = true
			var model: = ""
			var look_shift: = false
			if not models.is_empty():
				model = str(models[mi % models.size()])
				look_shift = mi >= models.size()
				mi += 1
			else:
				model = "opp_%d" % (reuse % 14)
				reuse += 1

			var slot: = list.size()
			var ovr: = lerpf(91.0, 58.0, float(slot) / float(PER_DIV - 1)) + rng.randf_range(-3.0, 3.0)
			var style: String = Roster.STYLE_ORDER[rng.randi() % Roster.STYLE_ORDER.size()]
			if d >= 6 and rng.randf() < 0.3:
				style = "slugger"
			elif d <= 2 and rng.randf() < 0.3:
				style = ["outboxer", "swarmer"][rng.randi() % 2]
			var st: = Career._stats_for(style, ovr, rng)
			var pal: Array = Career.TRUNK_PALETTE
			var tr: Color = pal[rng.randi() % pal.size()]
			var gl: Color = pal[rng.randi() % pal.size()]
			if rng.randf() < 0.35:
				gl = tr
			var e: = {
				"id": "d%d_%d" % [d, list.size()], "model": model, "division": d, 
				"name": nm["name"], "nick": nm["nick"], "country": nm["country"], "style": style, 
				"stance": -1 if rng.randf() < 0.2 else 1, "height": height_for(d, rng), 
				"trunks": tr, "trim": Color(0.95, 0.95, 0.95) if tr.v < 0.55 else Color(0.06, 0.06, 0.07), 
				"gloves": gl, "boots": Color(0.06, 0.06, 0.07) if rng.randf() < 0.55 else (Color(0.95, 0.95, 0.95) if rng.randf() < 0.6 else tr), 
				"skin_tint": Color(1, 1, 1), "hair_tint": Color(1, 1, 1), 
				"guard": Guards.pick_for(style, rng), 
			}
			var meta: Dictionary = ModelMeta.META.get(model, {})
			if not meta.is_empty():
				e["skin_tint"] = meta["skin"]
				e["hair_tint"] = meta["hair"]
			if look_shift:

				var k: = rng.randf_range(0.86, 1.06)
				var st0: Color = e["skin_tint"]
				e["skin_tint"] = Color(st0.r * k, st0.g * k * rng.randf_range(0.97, 1.02), st0.b * k * rng.randf_range(0.94, 1.0))
				e["hair_tint"] = Color(rng.randf_range(0.3, 1.2), rng.randf_range(0.25, 0.95), rng.randf_range(0.22, 0.8))
			e.merge(st, true)
			var rec: = _record(ovr, rng)
			e["rec"] = rec
			e["record"] = "%d-%d-%d" % [int(rec["w"]), int(rec["l"]), int(rec["d"])]
			list.append(e)
		for e2 in list:
			var ed: Dictionary = e2
			if not ed.has("guard"):
				ed["guard"] = Guards.pick_for(str(ed.get("style", "balanced")), rng)
			ed["ovr"] = Roster.overall(ed)
		list.sort_custom( func(a, b): return int(a["ovr"]) > int(b["ovr"]))
		out.append(list)
	return out


static func _record(ovr: float, rng: RandomNumberGenerator) -> Dictionary:
	var w: = int(clampf((ovr - 50.0) * 0.8 + rng.randf_range(0.0, 8.0), 3, 45))
	var l: = int(clampf(rng.randf_range(0.0, 5.0) + (82.0 - ovr) * 0.18, 0, 18))
	return {"w": w, "l": l, "d": rng.randi() % 3, "ko": int(w * rng.randf_range(0.3, 0.75))}



const COUNTRY_W: = [
	{"Japan": 4, "Philippines": 5, "Mexico": 5, "Cuba": 1, "Kazakhstan": 2, "Russia": 2, "USA": 2, "England": 1}, 
	{"Japan": 4, "Philippines": 4, "Mexico": 5, "Cuba": 2, "Kazakhstan": 2, "Russia": 2, "USA": 2, "England": 1}, 
	{"Japan": 2, "Philippines": 3, "Mexico": 5, "Cuba": 2, "Kazakhstan": 2, "Russia": 3, "USA": 3, "England": 2, "Ukraine": 1}, 
	{"Mexico": 4, "USA": 4, "Russia": 3, "Kazakhstan": 2, "Cuba": 2, "England": 2, "Philippines": 1, "Brazil": 1, "Ukraine": 1, "Ghana": 1}, 
	{"USA": 5, "Mexico": 3, "Russia": 3, "England": 3, "Kazakhstan": 2, "Cuba": 2, "Ghana": 1, "Brazil": 1, "Ireland": 1, "France": 1}, 
	{"USA": 4, "Russia": 3, "England": 3, "Kazakhstan": 3, "Mexico": 2, "Ghana": 1, "Germany": 2, "Ireland": 1, "France": 1, "Poland": 1}, 
	{"USA": 4, "Russia": 3, "England": 3, "Germany": 2, "Poland": 2, "Ukraine": 2, "Nigeria": 1, "Cuba": 1, "France": 1, "Kazakhstan": 1}, 
	{"USA": 5, "England": 3, "Russia": 3, "Ukraine": 3, "Nigeria": 3, "Germany": 2, "Poland": 2, "Cuba": 1, "Ireland": 1, "France": 1}, 
]


static func _make_name(rng: RandomNumberGenerator, d: int) -> Dictionary:
	var cw: Dictionary = COUNTRY_W[d]
	var tot: = 0.0
	for k in cw.keys():
		tot += float(cw[k])
	var x: = rng.randf() * tot
	var country: String = cw.keys()[0]
	for k in cw.keys():
		x -= float(cw[k])
		if x <= 0.0:
			country = k
			break
	var pool: Array = Career.NAMES.get(country, Career.NAMES["USA"])
	var nm: = "%s %s" % [pool[0][rng.randi() % pool[0].size()], pool[1][rng.randi() % pool[1].size()]]
	var nick: = ""
	if rng.randf() < 0.65:
		nick = Career.NICKS[rng.randi() % Career.NICKS.size()]
	return {"name": nm, "nick": nick, "country": country}
