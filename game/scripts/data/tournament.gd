class_name Tournament
extends RefCounted



const STAGES: = ["ЧЕТВЕРТЬФИНАЛ", "ПОЛУФИНАЛ", "ФИНАЛ"]


static func active() -> bool:
	return not Game.tournament.is_empty()


static func create(div: int, me: Dictionary, rounds: int, diff: int, secs: int) -> void :
	var pool: Array = []
	for f in Divisions.fighters_of(div):
		if str((f as Dictionary)["id"]) != str(me["id"]):
			pool.append(f)
	pool.shuffle()
	var entrants: Array = [me]
	for i in mini(7, pool.size()):
		entrants.append(pool[i])
	entrants.shuffle()
	var first: Array = []
	for i in 4:
		first.append({"a": i * 2, "b": i * 2 + 1, "w": -1, "method": ""})
	Game.tournament = {
		"div": div, "me": str(me["id"]), "entrants": entrants, "stages": [first], "stage": 0, 
		"rounds": rounds, "diff": diff, "secs": secs, "out": false, "champion": -1, 
	}


static func me_idx() -> int:
	var t: = Game.tournament
	var es: Array = t["entrants"]
	for i in es.size():
		if str(es[i]["id"]) == str(t["me"]):
			return i
	return 0


static func my_match() -> Dictionary:
	var t: = Game.tournament
	if t.is_empty() or bool(t["out"]) or int(t["champion"]) >= 0:
		return {}
	var st: Array = t["stages"][int(t["stage"])]
	var me: = me_idx()
	for m in st:
		if (int(m["a"]) == me or int(m["b"]) == me) and int(m["w"]) < 0:
			return m
	return {}


static func entrant(i: int) -> Dictionary:
	return Game.tournament["entrants"][i]


static func start_fight() -> void :
	var m: = my_match()
	if m.is_empty():
		return
	var me: = me_idx()
	var opp: = int(m["b"]) if int(m["a"]) == me else int(m["a"])
	var t: = Game.tournament
	var final: = int(t["stage"]) == 2
	var cfg: = Game.make_fight_config(entrant(me), entrant(opp), int(t["diff"]), int(t["rounds"]) + (2 if final else 0), 
		int(t["secs"]), false, false)
	cfg["tournament"] = true
	cfg["venue"] = "arena" if final else "palace"
	cfg["title"] = "Турнир — " + str(STAGES[int(t["stage"])]).to_lower()
	Game.start_fight(cfg)


static func _sim(a: Dictionary, b: Dictionary) -> bool:
	var oa: = float(Roster.overall(a))
	var ob: = float(Roster.overall(b))
	return randf() < 1.0 / (1.0 + pow(10.0, (ob - oa) / 12.0))


static func _sim_method() -> String:
	var r: = randf()
	if r < 0.3:
		return "KO"
	if r < 0.45:
		return "TKO"
	return "Решение"



static func apply_result(won: bool, method: String, rnd: int) -> Dictionary:
	var t: = Game.tournament
	if t.is_empty():
		return {}
	var m: = my_match()
	if m.is_empty():
		return {}
	var me: = me_idx()
	var opp: = int(m["b"]) if int(m["a"]) == me else int(m["a"])
	m["w"] = me if won else opp
	m["method"] = method + (" (%d р.)" % rnd if rnd > 0 and not method.begins_with("Реш") else "")
	if not won:
		t["out"] = true
	_finish_stage()
	var summary: = {"stage": str(STAGES[mini(int(t["stage"]), 2)]), "won": won, "champion": int(t["champion"]) == me, "out": bool(t["out"])}

	while bool(t["out"]) and int(t["champion"]) < 0:
		_finish_stage()
	return summary


static func _finish_stage() -> void :
	var t: = Game.tournament
	var si: = int(t["stage"])
	var st: Array = t["stages"][si]
	for m in st:
		if int(m["w"]) < 0:
			var a: = int(m["a"])
			var b: = int(m["b"])
			m["w"] = a if _sim(entrant(a), entrant(b)) else b
			m["method"] = _sim_method()
	if st.size() == 1:
		t["champion"] = int(st[0]["w"])
		return
	var nxt: Array = []
	for i in range(0, st.size(), 2):
		nxt.append({"a": int(st[i]["w"]), "b": int(st[i + 1]["w"]), "w": -1, "method": ""})
	var stages: Array = t["stages"]
	stages.append(nxt)
	t["stage"] = si + 1


static func clear() -> void :
	Game.tournament = {}
