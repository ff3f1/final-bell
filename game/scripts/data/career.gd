class_name Career
extends RefCounted




const SAVE_PATH: = "user://career2.json"

const BELTS: = {
	"regional": {"name": "Региональный пояс", "short": "РЕГИОН", "max_rank": 15, "color": Color(0.72, 0.74, 0.8)}, 
	"national": {"name": "Пояс чемпиона страны", "short": "СТРАНА", "max_rank": 9, "color": Color(0.86, 0.56, 0.26)}, 
	"world": {"name": "Пояс чемпиона мира", "short": "МИР", "max_rank": 4, "color": Color(0.96, 0.78, 0.3)}, 
}
const BELT_ORDER: = ["regional", "national", "world"]

const STATUSES: = [[0, "Новичок"], [12, "Проспект"], [28, "Контендер"], [48, "Звезда"], [70, "Суперзвезда"]]

const CAMP: = {
	"bag": {"name": "Тяжёлый мешок", "desc": "Сила удара", "stat": "power", "cost": 0}, 
	"pads": {"name": "Лапы с тренером", "desc": "Скорость рук и связки", "stat": "speed", "cost": 0}, 
	"roadwork": {"name": "Бег и кардио", "desc": "Выносливость на поздние раунды", "stat": "stamina", "cost": 0}, 
	"defense": {"name": "Защита и уклоны", "desc": "Работа головой и блок", "stat": "defense", "cost": 0}, 
	"neck": {"name": "Шея и пресс", "desc": "Держать удар", "stat": "chin", "cost": 0}, 
	"sparring": {"name": "Спарринг-партнёр", "desc": "Всё понемногу и разбор стиля соперника", "stat": "", "cost": 800}, 
	"rest": {"name": "Восстановление", "desc": "Снимает износ после тяжёлых боёв", "stat": "", "cost": 0}, 
}
const CAMP_ORDER: = ["bag", "pads", "roadwork", "defense", "neck", "sparring", "rest"]
const CAMP_SLOTS: = 3

const NAMES: = {
	"USA": [["Marcus", "Jamal", "Tyrone", "Devin", "Darius", "Brandon", "Malik", "Jake", "Chris", "Terrell"], 
		["Johnson", "Carter", "Hayes", "Mitchell", "Coleman", "Reed", "Foster", "Bishop", "Grant", "Wallace"]], 
	"Mexico": [["Juan", "Carlos", "Luis", "Miguel", "Jorge", "Ruben", "Javier", "Emilio"], 
		["Ramirez", "Castillo", "Navarro", "Mendoza", "Ortega", "Vargas", "Salazar", "Ibarra"]], 
	"England": [["Callum", "Jack", "Harry", "Ryan", "Danny", "Josh", "Kieran"], 
		["Walsh", "Hughes", "Bennett", "Price", "Fletcher", "Hayward", "Clarke"]], 
	"Russia": [["Ivan", "Alexei", "Dmitry", "Sergei", "Artem", "Nikita", "Ruslan", "Timur", "Egor", "Maxim"], 
		["Volkov", "Sokolov", "Morozov", "Lebedev", "Orlov", "Gromov", "Biryukov", "Tarasov", "Kalinin", "Zaitsev"]], 
	"Kazakhstan": [["Daniyar", "Yerlan", "Aidos", "Nurlan", "Bekzat"], 
		["Abenov", "Seitkali", "Tokhtarov", "Nurgaliyev", "Kassymov"]], 
	"Cuba": [["Yordanis", "Osmel", "Roniel", "Yunier", "Lazaro"], ["Rojas", "Padron", "Valdes", "Sotolongo", "Mesa"]], 
	"Philippines": [["Jerwin", "Rey", "Jhack", "Romeo", "Marlon"], ["Bautista", "Villanueva", "Ramos", "Santos", "Mercado"]], 
	"Japan": [["Daichi", "Ryo", "Takeshi", "Shun", "Hiroto"], ["Sato", "Kimura", "Ishida", "Mori", "Hayashi"]], 
	"Nigeria": [["Chidi", "Emeka", "Tunde", "Ola", "Ifeanyi"], ["Adeyemi", "Nwosu", "Balogun", "Eze", "Okonkwo"]], 
	"Ghana": [["Kwame", "Kofi", "Isaac", "Yaw"], ["Mensah", "Boateng", "Owusu", "Asante"]], 
	"Brazil": [["Lucas", "Rafael", "Thiago", "Bruno", "Diego"], ["Souza", "Costa", "Ferreira", "Almeida", "Rocha"]], 
	"Germany": [["Lukas", "Felix", "Jonas", "Max"], ["Becker", "Wagner", "Hoffmann", "Krueger"]], 
	"Poland": [["Tomasz", "Krzysztof", "Mateusz", "Piotr"], ["Nowak", "Kowalski", "Wisniewski", "Zielinski"]], 
	"Ukraine": [["Oleksandr", "Vasyl", "Denys", "Andriy"], ["Bondarenko", "Shevchuk", "Kravets", "Tkachenko"]], 
	"Ireland": [["Sean", "Conor", "Padraig", "Eoin"], ["Murphy", "Byrne", "Kelly", "Doyle"]], 
	"France": [["Mathieu", "Hugo", "Karim", "Yanis"], ["Dubois", "Moreau", "Laurent", "Benali"]], 
}
const NICKS: = ["Thunder", "Hitman", "The Machine", "Lightning", "Bulldog", "Viper", "Razor", "Cobra", "El Toro", "Tank", 
	"Smokin'", "Diamond", "Bad Boy", "Dynamite", "Bomber", "Wolf", "Hurricane", "Pitbull", "Shadow", "The Saint", 
	"Sniper", "Volcano", "Magic", "Prince", "The Truth", "Kid", "Rhino", "Panther", "Steel", "Mad Dog"]
const TRUNK_PALETTE: = [Color(0.72, 0.08, 0.08), Color(0.08, 0.2, 0.62), Color(0.95, 0.95, 0.95), Color(0.06, 0.06, 0.07), 
	Color(0.85, 0.65, 0.12), Color(0.1, 0.45, 0.2), Color(0.42, 0.12, 0.55), Color(0.95, 0.45, 0.08), 
	Color(0.55, 0.05, 0.12), Color(0.15, 0.55, 0.75), Color(0.3, 0.3, 0.32), Color(0.95, 0.75, 0.8)]
const OPP_MODELS: = ["opp_0", "opp_1", "opp_2", "opp_3", "opp_4", "opp_5", "opp_6", "opp_7", "opp_8", "opp_9", 
	"opp_10", "opp_11", "opp_12", "opp_13"]
const PLAYER_FACES: = ["career_0", "career_1", "career_2", "career_3", "career_4", "career_5", 
	"career_6", "career_7", "career_8", "career_9", "career_10", "career_11"]




static func has() -> bool:
	return Game.career.has("v") and int(Game.career["v"]) == 3 and not bool(Game.career.get("retired", false))


static func save() -> void :
	if Game.no_save:
		return
	var f: = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_encode(Game.career)))
		f.close()


static func load_saved() -> void :
	if Game.no_save or not FileAccess.file_exists(SAVE_PATH):
		return
	var txt: = FileAccess.get_file_as_string(SAVE_PATH)
	var d: Variant = JSON.parse_string(txt)
	if d is Dictionary:
		Game.career = _decode(d)


static func delete_save() -> void :
	Game.career = {}
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))



static func _encode(v: Variant) -> Variant:
	if v is Color:
		return {"__c": (v as Color).to_html(false)}
	if v is Dictionary:
		var out: = {}
		for k in (v as Dictionary).keys():
			out[k] = _encode(v[k])
		return out
	if v is Array:
		var arr: = []
		for x in v:
			arr.append(_encode(x))
		return arr
	return v


static func _decode(v: Variant) -> Variant:
	if v is Dictionary:
		var d: Dictionary = v
		if d.has("__c"):
			return Color.html(str(d["__c"]))
		var out: = {}
		for k in d.keys():
			out[k] = _decode(d[k])
		return out
	if v is Array:
		var arr: = []
		for x in v:
			arr.append(_decode(x))
		return arr
	return v




static func create(profile: Dictionary) -> void :
	var rng: = RandomNumberGenerator.new()
	rng.randomize()
	var base: = Roster.career_base_stats(str(profile.get("style", "balanced")))
	var c: = {
		"v": 3, "seed": rng.randi(), 
		"name": str(profile.get("name", "Ivan Volkov")), "nick": str(profile.get("nick", "")), 
		"country": str(profile.get("country", "Russia")), "style": str(profile.get("style", "balanced")), 
		"stance": int(profile.get("stance", 1)), "height": float(profile.get("height", 1.82)), 
		"division": int(profile.get("division", Divisions.DEFAULT)), "guard": str(profile.get("guard", "classic")), 
		"div_history": [int(profile.get("division", Divisions.DEFAULT))], 
		"look": profile.get("look", default_look()), 
		"stats": base, 
		"age": 21.0, "month": 0, "money": 2500, "fame": 0.0, "wear": 0.0, 
		"rating": 930.0, "rec": {"w": 0, "l": 0, "d": 0, "ko": 0}, 
		"history": [], "news": [], "belts_held": [], "defenses": {}, 
		"camp_level": 1, "offers": [], "pending": {}, "retired": false, "best_rank": 99, 
	}
	Game.career = c
	_build_world(rng)
	_make_offers()
	_news("%s подписывает первый профессиональный контракт." % display_name_me())
	save()


static func default_look() -> Dictionary:
	return {"model": "career_0", "face": 0, "trunks": TRUNK_PALETTE[0], "trim": Game.ACCENT, "gloves": Color(0.75, 0.06, 0.06), 
		"cuff": Color(0.95, 0.95, 0.95), "boots": Color(0.08, 0.08, 0.09), "skin_tint": 1.0, "hair_tint": Color(1, 1, 1)}


static func _build_world(rng: RandomNumberGenerator) -> void :
	var world: Array = []

	var gen: = Divisions.generate(int(Game.career.get("seed", 1)))
	for d in gen.size():
		for f in gen[d]:
			var e: Dictionary = (f as Dictionary).duplicate(true)
			e["division"] = d
			var ovr: = float(Roster.overall(e))
			e["rating"] = 1000.0 + (ovr - 65.0) * 22.0 + rng.randf_range(-25.0, 25.0)
			e["age"] = rng.randf_range(21.0, 35.0)
			if not e.has("rec"):
				var w: = int(clampf((ovr - 50.0) * 0.9 + rng.randf_range(0.0, 8.0), 3, 45))
				e["rec"] = {"w": w, "l": rng.randi() % 6, "d": rng.randi() % 3, "ko": int(w * 0.5)}
			e["record"] = record_str(e["rec"])
			world.append(e)
	Game.career["world"] = world
	_assign_belts()


static func _stats_for(style: String, ovr: float, rng: RandomNumberGenerator) -> Dictionary:
	var bias: = {"power": 0.0, "speed": 0.0, "stamina": 0.0, "chin": 0.0, "defense": 0.0}
	match style:
		"outboxer":
			bias = {"power": -6.0, "speed": 5.0, "stamina": 3.0, "chin": -3.0, "defense": 7.0}
		"swarmer":
			bias = {"power": 2.0, "speed": 3.0, "stamina": 8.0, "chin": 2.0, "defense": -8.0}
		"counter":
			bias = {"power": -2.0, "speed": 6.0, "stamina": -2.0, "chin": -4.0, "defense": 8.0}
		"slugger":
			bias = {"power": 10.0, "speed": -7.0, "stamina": -3.0, "chin": 7.0, "defense": -6.0}
	var out: = {}
	for k in bias.keys():
		out[k] = clampi(int(round(ovr + float(bias[k]) + rng.randf_range(-4.0, 4.0))), 40, 97)
	return out


static func _ai_entry(d: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var ovr: = float(Roster.overall(d))
	var w: = int(clampf((ovr - 50.0) * 0.9 + rng.randf_range(0.0, 8.0), 3, 45))
	var l: = int(clampf(rng.randf_range(0.0, 6.0) + (80.0 - ovr) * 0.15, 0, 20))
	d["rating"] = 1000.0 + (ovr - 65.0) * 22.0 + rng.randf_range(-25.0, 25.0)
	d["rec"] = {"w": w, "l": l, "d": rng.randi() % 3, "ko": int(w * rng.randf_range(0.3, 0.8) * float(d.get("power", 60)) / 75.0)}
	d["age"] = rng.randf_range(22.0, 35.0)
	d["record"] = "%d-%d-%d" % [w, l, int(d["rec"]["d"])]
	return d


static func _assign_belts() -> void :
	var all: = {}
	for d in Divisions.COUNT:
		var ranked: Array = []
		for e in ranking(d):
			if str(e["id"]) != "me":
				ranked.append(e)
		if ranked.is_empty():
			continue

		all[str(d)] = {"world": str(ranked[0]["id"]), "national": str(ranked[mini(4, ranked.size() - 1)]["id"]), 
			"regional": str(ranked[mini(9, ranked.size() - 1)]["id"])}
	Game.career["belts"] = all



static func belts_div(d: int = -1) -> Dictionary:
	if d < 0:
		d = my_div()
	var all: Dictionary = Game.career.get("belts", {})
	var key: = str(d)
	if not all.has(key) or not (all[key] is Dictionary):
		all[key] = {}
	Game.career["belts"] = all
	return all[key]


static func my_div() -> int:
	return int(Game.career.get("division", Divisions.DEFAULT))


static func div_of(id: String) -> int:
	if id == "me":
		return my_div()
	return int(entry(id).get("division", my_div()))





static func ranking(d: int = -1) -> Array:
	if d < 0:
		d = my_div()
	var all: Array = []
	for w in Game.career.get("world", []):
		if int((w as Dictionary).get("division", Divisions.DEFAULT)) == d:
			all.append(w)
	if Game.career.has("rating") and my_div() == d:
		all.append({"id": "me", "name": Game.career["name"], "nick": Game.career["nick"], "rating": float(Game.career["rating"]), 
			"country": Game.career.get("country", "Russia"), "rec": Game.career["rec"]})
	all.sort_custom( func(a, b): return float(a["rating"]) > float(b["rating"]))
	return all


static func rank_of(id: String) -> int:
	var r: = ranking(div_of(id))
	for i in r.size():
		if str(r[i]["id"]) == id:
			return i + 1
	return r.size()


static func my_rank() -> int:
	return rank_of("me")


static func status() -> String:
	if str(belts_div().get("world", "")) == "me":
		var dfs: int = int(Game.career.get("defenses", {}).get("world", 0))
		return "Легенда" if dfs >= 5 else "Чемпион мира"
	var fame: = float(Game.career.get("fame", 0.0))
	var s: = "Новичок"
	for row in STATUSES:
		if fame >= float(row[0]):
			s = str(row[1])
	return s


static func belts_of(id: String) -> Array:
	var out: Array = []
	var b: Dictionary = belts_div(div_of(id))
	for k in BELT_ORDER:
		if str(b.get(k, "")) == id:
			out.append(k)
	return out


static func entry(id: String) -> Dictionary:
	if id == "me":
		return {"id": "me", "name": Game.career["name"], "nick": Game.career["nick"]}
	for w in Game.career.get("world", []):
		if str(w["id"]) == id:
			return w
	return {}


static func display_name_me() -> String:
	return Roster.display_full({"name": Game.career.get("name", "?"), "nick": Game.career.get("nick", "")})


static func record_str(rec: Dictionary) -> String:
	return "%d-%d-%d" % [int(rec.get("w", 0)), int(rec.get("l", 0)), int(rec.get("d", 0))]




static func player_def() -> Dictionary:
	var c: = Game.career
	var look: Dictionary = c.get("look", default_look())
	var st: Dictionary = c["stats"]
	var wear: = float(c.get("wear", 0.0))
	var st_t: = float(look.get("skin_tint", 1.0))
	return {
		"id": "career", "model": Divisions.player_model(int(look.get("face", 0)), my_div()), "name": c["name"], "nick": c["nick"], 
		"division": my_div(), "guard": str(c.get("guard", "classic")), 
		"country": c.get("country", "Russia"), "record": record_str(c["rec"]), "style": c["style"], 
		"stance": int(c["stance"]), "height": float(c.get("height", 1.82)), 
		"power": int(st["power"]), "speed": int(st["speed"]), "stamina": int(st["stamina"]), 
		"chin": clampi(int(st["chin"]) - int(wear * 0.6), 30, 99), "defense": int(st["defense"]), 
		"trunks": look.get("trunks", TRUNK_PALETTE[0]), "trim": look.get("trim", Game.ACCENT), 
		"gloves": look.get("gloves", Color(0.75, 0.06, 0.06)), "glove_cuff": look.get("cuff", Color(0.95, 0.95, 0.95)), 
		"boots": look.get("boots", Color(0.08, 0.08, 0.09)), 
		"skin_tint": Color(st_t, st_t * 0.98 + 0.02, st_t * 0.97 + 0.03), "hair_tint": look.get("hair_tint", Color(1, 1, 1)), 
		"skin": Roster.SKIN_TONES[1], "hair": Color(0.1, 0.07, 0.05), "bald": false, 
	}


static func opponent_def(id: String) -> Dictionary:
	var e: = entry(id).duplicate(true)
	e["record"] = record_str(e.get("rec", {}))
	if not e.has("skin"):
		e["skin"] = Roster.SKIN_TONES[1]
		e["hair"] = Color(0.1, 0.07, 0.05)
		e["bald"] = false
	return e


static func overall_me() -> int:
	var d: = player_def()
	return Roster.overall(d)




static func rounds_for(rank: int, title: String) -> int:
	if title == "world":
		return 12
	if title != "":
		return 10
	if rank > 16:
		return 4
	if rank > 11:
		return 6
	if rank > 6:
		return 8
	return 10


static func _make_offers() -> void :
	var rng: = RandomNumberGenerator.new()
	rng.seed = int(Game.career.get("seed", 1)) + int(Game.career.get("month", 0)) * 7919
	var ranked: = ranking()
	var me: = my_rank()
	var recent: Array = []
	var hist: Array = Game.career.get("history", [])
	for i in range(maxi(0, hist.size() - 2), hist.size()):
		recent.append(str(hist[i].get("opp", "")))
	var offers: Array = []

	var belts: Dictionary = belts_div()
	for k in BELT_ORDER:
		var holder: = str(belts.get(k, ""))
		if holder == "me":

			var ch: = _best_challenger(k, ranked)
			if ch != "":
				offers.append(_offer(ch, k, true, rng))
			continue
		if me <= int(BELTS[k]["max_rank"]) and holder != "" and not _holds_higher(k):
			offers.append(_offer(holder, k, false, rng))
	var pools: = [[me + 2, me + 9], [me - 2, me + 2], [me - 8, me - 2]]
	for p in pools:
		var cands: Array = []
		for i in ranked.size():
			var r: = i + 1
			var id: = str(ranked[i]["id"])
			if id == "me" or recent.has(id) or r < int(p[0]) or r > int(p[1]):
				continue
			var dup: = false
			for o in offers:
				if str(o["opp"]) == id:
					dup = true
			if not dup:
				cands.append(id)
		if cands.is_empty():
			continue
		offers.append(_offer(cands[rng.randi() % cands.size()], "", false, rng))
	Game.career["offers"] = offers


static func _holds_higher(belt: String) -> bool:
	var idx: = BELT_ORDER.find(belt)
	var b: Dictionary = belts_div()
	for k in range(idx + 1, BELT_ORDER.size()):
		if str(b.get(BELT_ORDER[k], "")) == "me":
			return true
	return false


static func _best_challenger(belt: String, ranked: Array) -> String:
	var max_r: = int(BELTS[belt]["max_rank"])
	for i in ranked.size():
		var id: = str(ranked[i]["id"])
		if id == "me" or not belts_of(id).is_empty():
			continue
		if i + 1 <= max_r + 6:
			return id
	return ""


static func _offer(opp: String, title: String, defense: bool, rng: RandomNumberGenerator) -> Dictionary:
	var orank: = rank_of(opp)
	var me: = my_rank()
	var fame: = float(Game.career.get("fame", 0.0))
	var purse: = 1200.0 + fame * 140.0 + maxf(0.0, 21.0 - float(orank)) * 340.0
	purse *= 0.8 + float(my_div()) * 0.06
	if title != "":
		purse *= {"regional": 1.8, "national": 2.6, "world": 4.5}[title]
	purse *= rng.randf_range(0.9, 1.15)
	return {"opp": opp, "title": title, "defense": defense, "rounds": rounds_for(mini(me, orank), title), 
		"purse": int(round(purse / 50.0) * 50.0), "opp_rank": orank}


static func offers() -> Array:
	return Game.career.get("offers", [])




static func camp_gain(stat_name: String) -> float:
	var age: = float(Game.career.get("age", 21.0))
	var age_k: = 1.0 if age < 28.0 else (0.7 if age < 32.0 else 0.4)
	var lvl: = float(Game.career.get("camp_level", 1))
	var cur: = float(Game.career["stats"].get(stat_name, 60))
	var cap_k: = clampf((99.0 - cur) / 35.0, 0.15, 1.0)
	return (1.6 + lvl * 0.5) * age_k * cap_k



static func run_camp(choices: Array) -> Array:
	var lines: Array = []
	var st: Dictionary = Game.career["stats"]
	for ch in choices:
		var a: Dictionary = CAMP[str(ch)]
		var cost: = int(a["cost"])
		if cost > int(Game.career["money"]):
			lines.append("%s — не хватило денег" % a["name"])
			continue
		Game.career["money"] = int(Game.career["money"]) - cost
		match str(ch):
			"rest":
				var w: = float(Game.career.get("wear", 0.0))
				Game.career["wear"] = maxf(0.0, w - 6.0)
				lines.append("Восстановление: износ −%d" % int(minf(w, 6.0)))
			"sparring":
				for k in ["power", "speed", "stamina", "chin", "defense"]:
					var g: = camp_gain(k) * 0.4
					st[k] = mini(99, int(round(float(st[k]) + g)))
				lines.append("Спарринг: +1 ко всему, видишь привычки соперника")
				Game.career["scouted"] = true
			_:
				var k2: String = a["stat"]
				var g2: = camp_gain(k2)
				var before: = int(st[k2])
				st[k2] = mini(99, int(round(float(st[k2]) + g2)))
				lines.append("%s: %s %d → %d" % [a["name"], stat_label(k2), before, int(st[k2])])
	Game.career["stats"] = st
	save()
	return lines


static func stat_label(k: String) -> String:
	return {"power": "Сила", "speed": "Скорость", "stamina": "Выносливость", "chin": "Подбородок", "defense": "Защита"}.get(k, k)


static func upgrade_camp_cost() -> int:
	return [0, 6000, 18000, 45000][clampi(int(Game.career.get("camp_level", 1)), 0, 3)] if int(Game.career.get("camp_level", 1)) < 3 else -1


static func upgrade_camp() -> bool:
	var cost: = upgrade_camp_cost()
	if cost < 0 or int(Game.career["money"]) < cost:
		return false
	Game.career["money"] = int(Game.career["money"]) - cost
	Game.career["camp_level"] = int(Game.career.get("camp_level", 1)) + 1
	save()
	return true




static func difficulty_vs(opp: Dictionary) -> int:
	var diff: = float(Roster.overall(opp)) - float(overall_me())
	var base: = Game.setting_i("difficulty")
	var shift: = 0
	if diff > 8.0:
		shift = 1
	elif diff < -8.0:
		shift = -1
	return clampi(base + shift, 0, 4)


static func start_offer(idx: int) -> void :
	var off: Dictionary = offers()[idx]
	Game.career["pending"] = off
	save()
	var opp: = opponent_def(str(off["opp"]))
	var me: = player_def()
	var cfg: = Game.make_fight_config(me, opp, difficulty_vs(opp), int(off["rounds"]), 
		Game.setting_i("round_seconds"), false, true)
	cfg["title"] = str(off.get("title", ""))

	cfg["venue"] = "arena" if cfg["title"] != "" else ("palace" if int(off.get("opp_rank", 20)) <= 10 else "club")
	Game.start_fight(cfg)



static func apply_result(result: Dictionary) -> Dictionary:
	var c: = Game.career
	var off: Dictionary = c.get("pending", {})
	if off.is_empty():
		return {}
	var opp_id: = str(off["opp"])
	var opp: = entry(opp_id)
	var won: bool = result.get("won", false)
	var draw: bool = result.get("draw", false)
	var method: String = str(result.get("method", ""))
	var ko: = method.begins_with("KO") or method.begins_with("TKO")
	var summary: = {"money": 0, "fame": 0.0, "rank_before": my_rank(), "belt": ""}

	var ra: = float(c["rating"])
	var rb: = float(opp.get("rating", 1000.0))
	var ea: = 1.0 / (1.0 + pow(10.0, (rb - ra) / 400.0))
	var s: = 1.0 if won else (0.5 if draw else 0.0)
	var k: = 48.0 + (10.0 if ko else 0.0)
	c["rating"] = ra + k * (s - ea)
	opp["rating"] = rb - k * (s - ea)

	var rec: Dictionary = c["rec"]
	var orec: Dictionary = opp.get("rec", {"w": 0, "l": 0, "d": 0, "ko": 0})
	if draw:
		rec["d"] = int(rec["d"]) + 1
		orec["d"] = int(orec["d"]) + 1
	elif won:
		rec["w"] = int(rec["w"]) + 1
		orec["l"] = int(orec["l"]) + 1
		if ko:
			rec["ko"] = int(rec["ko"]) + 1
	else:
		rec["l"] = int(rec["l"]) + 1
		orec["w"] = int(orec["w"]) + 1
		if ko:
			orec["ko"] = int(orec.get("ko", 0)) + 1
			c["wear"] = float(c.get("wear", 0.0)) + 4.0
	opp["rec"] = orec
	opp["record"] = record_str(orec)

	var purse: = int(off["purse"])
	var paid: = purse if won else int(purse * 0.6)
	c["money"] = int(c["money"]) + paid
	summary["money"] = paid
	var orank: = int(off.get("opp_rank", 30))
	var fame_gain: = 0.0
	if won:
		fame_gain = 2.0 + maxf(0.0, 30.0 - float(orank)) * 0.25 + (2.0 if ko else 0.0)
	elif draw:
		fame_gain = 0.5
	else:
		fame_gain = -2.0

	var title: = str(off.get("title", ""))
	if title != "":
		var belts: Dictionary = belts_div()
		if won:
			if str(belts.get(title, "")) == "me":
				var dfs: Dictionary = c.get("defenses", {})
				dfs[title] = int(dfs.get(title, 0)) + 1
				c["defenses"] = dfs
				summary["belt"] = "Защита титула: " + str(BELTS[title]["name"])
			else:
				belts[title] = "me"
				summary["belt"] = "ЗАВОЁВАН: " + str(BELTS[title]["name"])
				_news("%s завоёвывает %s!" % [display_name_me(), str(BELTS[title]["name"]).to_lower()])
			fame_gain += {"regional": 5.0, "national": 9.0, "world": 18.0}[title]
		elif str(belts.get(title, "")) == "me" and not draw:
			belts[title] = opp_id
			summary["belt"] = "Пояс потерян: " + str(BELTS[title]["name"])
			_news("%s отбирает %s у %s." % [str(opp.get("name", "?")), str(BELTS[title]["name"]).to_lower(), display_name_me()])
	c["fame"] = clampf(float(c.get("fame", 0.0)) + fame_gain, 0.0, 100.0)
	summary["fame"] = fame_gain
	var hist: Array = c.get("history", [])
	hist.append({"opp": opp_id, "name": str(opp.get("name", "?")), "res": "W" if won else ("D" if draw else "L"), 
		"method": method, "round": int(result.get("round", 0)), "purse": paid, "title": title, "month": int(c["month"])})
	c["history"] = hist
	c["pending"] = {}
	c["scouted"] = false
	c["camp_done"] = false

	_advance(2)
	var rk: = my_rank()
	c["best_rank"] = mini(int(c.get("best_rank", 99)), rk)
	summary["rank_after"] = rk
	_make_offers()
	save()
	return summary


static func _advance(months: int) -> void :
	var c: = Game.career
	var rng: = RandomNumberGenerator.new()
	rng.seed = int(c.get("seed", 1)) + int(c.get("month", 0)) * 104729 + 17
	for m in months:
		c["month"] = int(c["month"]) + 1
		c["age"] = float(c["age"]) + 1.0 / 12.0
		_simulate_month(rng)

	var age: = float(c["age"])
	if age > 31.0:
		var st: Dictionary = c["stats"]
		for k in ["speed", "stamina", "chin"]:
			if rng.randf() < (age - 31.0) * 0.12:
				st[k] = maxi(40, int(st[k]) - 1)
		c["stats"] = st



static func _simulate_month(rng: RandomNumberGenerator) -> void :
	var world: Array = Game.career["world"]
	for d in Divisions.COUNT:
		var ranked: Array = []
		for e in ranking(d):
			if str(e["id"]) != "me":
				ranked.append(e)
		if ranked.size() < 4:
			continue
		var belts: = belts_div(d)
		var done: = {}
		for i in 4:
			var ai: = rng.randi() % ranked.size()
			var bi: = clampi(ai + rng.randi_range(-3, 3), 0, ranked.size() - 1)
			var a: Dictionary = ranked[ai]
			var b: Dictionary = ranked[bi]
			if ai == bi or done.has(a["id"]) or done.has(b["id"]):
				continue
			done[a["id"]] = true
			done[b["id"]] = true
			_sim_fight(a, b, belts, rng)
	Game.career["world"] = world


static func _entry_idx(world: Array, id: String) -> int:
	for i in world.size():
		if str(world[i]["id"]) == id:
			return i
	return 0


static func _sim_fight(a: Dictionary, b: Dictionary, belts: Dictionary, rng: RandomNumberGenerator) -> void :
	var oa: = float(Roster.overall(a))
	var ob: = float(Roster.overall(b))
	var p: = 1.0 / (1.0 + pow(10.0, (ob - oa) / 12.0))
	var a_won: = rng.randf() < p
	var w: Dictionary = a if a_won else b
	var l: Dictionary = b if a_won else a
	var ko: = rng.randf() < 0.35 + float(w.get("power", 60)) / 400.0
	var ew: = 1.0 / (1.0 + pow(10.0, (float(l["rating"]) - float(w["rating"])) / 400.0))
	w["rating"] = float(w["rating"]) + 40.0 * (1.0 - ew)
	l["rating"] = float(l["rating"]) - 40.0 * (1.0 - ew)
	var wr: Dictionary = w["rec"]
	var lr: Dictionary = l["rec"]
	wr["w"] = int(wr["w"]) + 1
	lr["l"] = int(lr["l"]) + 1
	if ko:
		wr["ko"] = int(wr.get("ko", 0)) + 1
	w["record"] = record_str(wr)
	l["record"] = record_str(lr)
	for k in BELT_ORDER:
		if str(belts.get(k, "")) == str(l["id"]):
			belts[k] = str(w["id"])
			_news("%s забирает %s у %s%s." % [Roster.display_full(w), str(BELTS[k]["name"]).to_lower(), str(l["name"]), " нокаутом" if ko else ""])
	if rng.randf() < 0.25:
		_news("%s %s %s%s." % [str(w["name"]), "нокаутирует" if ko else "побеждает", str(l["name"]), "" if ko else " по очкам"])


static func _news(t: String) -> void :
	var n: Array = Game.career.get("news", [])
	n.push_front({"m": int(Game.career.get("month", 0)), "t": t})
	while n.size() > 14:
		n.pop_back()
	Game.career["news"] = n




static func can_change_division(dir: int) -> bool:
	var nd: = my_div() + dir
	return nd >= 0 and nd < Divisions.COUNT and Game.career.get("pending", {}).is_empty()


static func change_division(dir: int) -> Dictionary:
	if not can_change_division(dir):
		return {}
	var c: = Game.career
	var old: = my_div()
	var nd: = old + dir

	var ob: = belts_div(old)
	var vacated: Array = []
	for k in BELT_ORDER:
		if str(ob.get(k, "")) == "me":
			var best: = ""
			for e in ranking(old):
				if str(e["id"]) != "me" and belts_of(str(e["id"])).is_empty():
					best = str(e["id"])
					break
			ob[k] = best
			vacated.append(k)
	var st: Dictionary = c["stats"]
	var delta: = {}
	if dir > 0:
		delta = {"power": 3, "chin": 2, "speed": -3, "stamina": -1}
	else:
		delta = {"speed": 3, "power": -3, "stamina": -2, "chin": -1}
	for k in delta.keys():
		st[k] = clampi(int(st[k]) + int(delta[k]), 35, 99)
	c["stats"] = st

	var r: = float(c["rating"])
	c["rating"] = 960.0 + (r - 960.0) * 0.65
	c["division"] = nd
	var h: Array = c.get("div_history", [])
	h.append(nd)
	c["div_history"] = h
	c["fame"] = clampf(float(c.get("fame", 0.0)) + (2.0 if dir > 0 else 0.0), 0.0, 100.0)
	var dh: Array = c.get("div_titles", [])
	c["div_titles"] = dh

	var hr: Array = Divisions.LIST[nd]["h"]
	c["height"] = clampf(float(c.get("height", 1.8)) + (0.015 if dir > 0 else -0.01), float(hr[0]), float(hr[1]))
	_news("%s переходит в %s вес." % [display_name_me(), str(Divisions.LIST[nd]["name"]).to_lower()])
	_make_offers()
	save()
	return {"from": old, "to": nd, "vacated": vacated, "delta": delta}


static func date_str() -> String:
	var months: = ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]
	var m: = int(Game.career.get("month", 0))
	return "%s %d" % [months[m % 12], 2026 + m / 12]


static func retire() -> Dictionary:
	var c: = Game.career
	var rec: Dictionary = c["rec"]
	var score: = int(rec["w"]) * 2 + int(rec["ko"]) + int(float(c.get("fame", 0.0)))
	for k in belts_of("me"):
		score += {"regional": 10, "national": 20, "world": 50}[k]
	for k in c.get("defenses", {}).keys():
		score += int(c["defenses"][k]) * 6
	c["retired"] = true
	save()
	return {"score": score, "hof": score >= 120}
