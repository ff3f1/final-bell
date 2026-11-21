class_name Roster
extends RefCounted


const STYLES: = {
	"outboxer": {"name": "Аутфайтер", "desc": "Держит дистанцию, кормит джебом и уходит"}, 
	"swarmer": {"name": "Свармер", "desc": "Давит, режет ринг, бьёт сериями вблизи"}, 
	"counter": {"name": "Контрпанчер", "desc": "Ждёт ошибку и наказывает встречными"}, 
	"slugger": {"name": "Панчер", "desc": "Медленный, но каждый удар может стать последним"}, 
	"balanced": {"name": "Универсал", "desc": "Всего понемногу, без слабых мест"}, 
}

const STYLE_ORDER: = ["balanced", "outboxer", "swarmer", "counter", "slugger"]

const SKIN_TONES: = [
	Color(0.93, 0.76, 0.63), Color(0.86, 0.66, 0.5), Color(0.76, 0.56, 0.4), 
	Color(0.58, 0.39, 0.26), Color(0.42, 0.27, 0.18), Color(0.3, 0.19, 0.13), 
]

const TRUNK_COLORS: = [
	Color(0.72, 0.08, 0.08), Color(0.08, 0.2, 0.62), Color(0.95, 0.95, 0.95), Color(0.06, 0.06, 0.07), 
	Color(0.85, 0.65, 0.12), Color(0.1, 0.45, 0.2), Color(0.42, 0.12, 0.55), Color(0.95, 0.45, 0.08), 
]


static func _f(id: String, full_name: String, nick: String, country: String, record: String, 
		style: String, stance: int, height: float, power: int, speed: int, stamina: int, 
		chin: int, defense: int, skin: Color, trunks: Color, trim: Color, gloves: Color, 
		hair: Color, bald: bool = false) -> Dictionary:
	return {
		"id": id, "name": full_name, "nick": nick, "country": country, "record": record, 
		"style": style, "stance": stance, "height": height, 
		"power": power, "speed": speed, "stamina": stamina, "chin": chin, "defense": defense, 
		"skin": skin, "trunks": trunks, "trim": trim, "gloves": gloves, "hair": hair, "bald": bald, 
	}



static func fighters() -> Array:
	return with_looks([
		_f("hammer", "Marcus Doyle", "Hammer", "USA", "27-3-0", "slugger", 1, 1.86, 
			92, 58, 70, 88, 55, SKIN_TONES[0], Color(0.72, 0.08, 0.08), Color(0.95, 0.75, 0.2), 
			Color(0.08, 0.08, 0.09), Color(0.32, 0.2, 0.12)), 
		_f("ghost", "Andre Silva", "The Ghost", "Brazil", "31-1-0", "counter", -1, 1.8, 
			72, 88, 76, 70, 92, SKIN_TONES[2], Color(0.95, 0.95, 0.95), Color(0.1, 0.55, 0.25), 
			Color(0.95, 0.95, 0.95), Color(0.08, 0.06, 0.05)), 
		_f("buzzsaw", "Tommy Reyes", "Buzzsaw", "Mexico", "24-2-1", "swarmer", 1, 1.72, 
			76, 86, 94, 80, 60, SKIN_TONES[2], Color(0.1, 0.45, 0.2), Color(0.95, 0.95, 0.95), 
			Color(0.75, 0.06, 0.06), Color(0.05, 0.04, 0.03)), 
		_f("tower", "Viktor Kane", "The Tower", "England", "22-0-0", "outboxer", 1, 1.94, 
			74, 78, 86, 70, 86, SKIN_TONES[0], Color(0.08, 0.2, 0.62), Color(0.8, 0.82, 0.86), 
			Color(0.08, 0.2, 0.62), Color(0.75, 0.6, 0.35)), 
		_f("iron", "Jamal Brooks", "Iron", "USA", "29-2-0", "balanced", 1, 1.83, 
			82, 80, 82, 82, 78, SKIN_TONES[4], Color(0.85, 0.65, 0.12), Color(0.06, 0.06, 0.07), 
			Color(0.75, 0.06, 0.06), Color(0.05, 0.04, 0.03), true), 
		_f("wildcard", "Liam O'Connor", "Wildcard", "Ireland", "19-4-0", "swarmer", -1, 1.78, 
			80, 80, 88, 76, 58, SKIN_TONES[0], Color(0.95, 0.45, 0.08), Color(0.95, 0.95, 0.95), 
			Color(0.1, 0.45, 0.2), Color(0.62, 0.25, 0.1)), 
		_f("ice", "Kenji Tanaka", "Ice", "Japan", "25-1-0", "counter", 1, 1.75, 
			70, 92, 80, 66, 88, SKIN_TONES[1], Color(0.06, 0.06, 0.07), Color(0.8, 0.08, 0.08), 
			Color(0.06, 0.06, 0.07), Color(0.04, 0.04, 0.04)), 
		_f("bigdan", "Dan Hollis", "Big Dan", "Australia", "21-5-0", "slugger", 1, 1.91, 
			96, 50, 64, 92, 50, SKIN_TONES[1], Color(0.42, 0.12, 0.55), Color(0.95, 0.75, 0.2), 
			Color(0.85, 0.65, 0.12), Color(0.55, 0.42, 0.25)), 
	])



static func journeymen() -> Array:
	return with_looks([
		_f("rocco", "Rocco Bianchi", "The Bull", "Italy", "9-6-1", "balanced", 1, 1.79, 
			62, 58, 66, 64, 56, SKIN_TONES[1], Color(0.1, 0.35, 0.15), Color(0.95, 0.95, 0.95), 
			Color(0.6, 0.05, 0.05), Color(0.1, 0.07, 0.05)), 
		_f("pete", "Pete Morgan", "Lefty", "Wales", "12-5-0", "outboxer", -1, 1.84, 
			60, 66, 70, 60, 64, SKIN_TONES[0], Color(0.75, 0.08, 0.1), Color(0.95, 0.95, 0.95), 
			Color(0.95, 0.95, 0.95), Color(0.45, 0.3, 0.15)), 
		_f("okafor", "Sam Okafor", "Thunder", "Nigeria", "14-3-0", "slugger", 1, 1.85, 
			74, 58, 64, 72, 56, SKIN_TONES[5], Color(0.1, 0.5, 0.25), Color(0.95, 0.95, 0.95), 
			Color(0.08, 0.08, 0.09), Color(0.04, 0.03, 0.03), true), 
	])



const LOOKS: = {
	"ghost": {"skin_tint": Color(0.93, 0.82, 0.72)}, 
	"buzzsaw": {"skin_tint": Color(0.92, 0.8, 0.68)}, 
	"rocco": {"skin_tint": Color(0.96, 0.88, 0.8)}, 
	"wildcard": {"hair_tint": Color(1.0, 0.55, 0.35)}, 
	"tower": {"hair_tint": Color(1.0, 0.92, 0.75)}, 
	"hammer": {"boots": Color(0.08, 0.08, 0.09)}, 
	"iron": {"boots": Color(0.85, 0.65, 0.12)}, 
}


static func with_looks(list: Array) -> Array:
	for f in list:
		var d: Dictionary = f
		var extra: Dictionary = LOOKS.get(str(d["id"]), {})
		d.merge(extra, true)
	return list


static func all_fighters() -> Array:
	var list: Array = fighters()
	list.append_array(journeymen())
	return list


static func by_id(id: String) -> Dictionary:
	for f in all_fighters():
		var d: Dictionary = f
		if d["id"] == id:
			return d
	var first: Dictionary = fighters()[0]
	return first


static func style_name(style: String) -> String:
	if STYLES.has(style):
		var s: Dictionary = STYLES[style]
		return s["name"]
	return style


static func overall(def: Dictionary) -> int:
	var sum: float = float(def["power"]) + float(def["speed"]) + float(def["stamina"]) + float(def["chin"]) + float(def["defense"])
	return int(round(sum / 5.0))


static func display_full(def: Dictionary) -> String:
	var full: String = def["name"]
	var nick: String = def.get("nick", "")
	if nick == "":
		return full
	var parts: = full.split(" ", false, 1)
	if parts.size() == 2:
		return "%s «%s» %s" % [parts[0], nick, parts[1]]
	return "%s «%s»" % [full, nick]



static func career_base_stats(style: String) -> Dictionary:
	match style:
		"outboxer":
			return {"power": 56, "speed": 64, "stamina": 64, "chin": 56, "defense": 64}
		"swarmer":
			return {"power": 60, "speed": 62, "stamina": 68, "chin": 60, "defense": 52}
		"counter":
			return {"power": 56, "speed": 66, "stamina": 58, "chin": 56, "defense": 66}
		"slugger":
			return {"power": 68, "speed": 52, "stamina": 58, "chin": 66, "defense": 52}
	return {"power": 60, "speed": 60, "stamina": 60, "chin": 60, "defense": 60}
