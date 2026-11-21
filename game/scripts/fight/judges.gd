class_name Judges
extends RefCounted



const JUDGES: = [
	{"name": "Harold Pratt", "volume": 1.2, "power": 0.9, "defense": 0.8, "aggression": 1.0}, 
	{"name": "Elena Ruiz", "volume": 0.9, "power": 1.3, "defense": 0.9, "aggression": 0.9}, 
	{"name": "Oscar Lindqvist", "volume": 1.0, "power": 1.0, "defense": 1.3, "aggression": 0.8}, 
]


var cards: Array = [[], [], []]
var rng: = RandomNumberGenerator.new()


func _init() -> void :
	rng.randomize()



func score_round(red: Dictionary, blue: Dictionary) -> Array:
	var result: Array = []
	for j in JUDGES.size():
		var w: Dictionary = JUDGES[j]
		var pr: = _points(red, blue, w)
		var pb: = _points(blue, red, w)
		var diff: = pr - pb
		var r: = 10
		var b: = 10
		if absf(diff) >= Balance.JUDGE_CLEAR:
			if diff > 0.0:
				b = 9
			else:
				r = 9
		elif rng.randf() >= Balance.JUDGE_EVEN_ROUND:

			if diff > 0.0:
				b = 9
			elif diff < 0.0:
				r = 9
		r -= int(red.get("kd_suffered", 0))
		b -= int(blue.get("kd_suffered", 0))
		var shift: = 10 - maxi(r, b)
		r += shift
		b += shift
		var card: Array = cards[j]
		card.append([r, b])
		result.append([r, b])
	return result


func _points(me: Dictionary, other: Dictionary, w: Dictionary) -> float:
	var landed: float = float(me.get("landed", 0))
	var power_landed: float = float(me.get("power_landed", 0))
	var dmg: float = float(me.get("damage", 0.0))
	var thrown: float = float(me.get("thrown", 0))
	var opp_thrown: float = float(other.get("thrown", 0))
	var opp_landed: float = float(other.get("landed", 0))
	var p: = 0.0
	p += float(w["volume"]) * landed
	p += float(w["power"]) * power_landed * 1.5
	p += float(w["power"]) * dmg * 0.1
	p += float(w["defense"]) * maxf(opp_thrown - opp_landed, 0.0) * Balance.JUDGE_DEFENSE
	p += float(w["aggression"]) * thrown * 0.05
	return p * (1.0 + rng.randf_range( - Balance.JUDGE_NOISE, Balance.JUDGE_NOISE))


func totals() -> Array:
	var out: Array = []
	for j in JUDGES.size():
		var r: = 0
		var b: = 0
		for rs in cards[j]:
			var pair: Array = rs
			r += int(pair[0])
			b += int(pair[1])
		out.append([r, b])
	return out



func decision() -> Dictionary:
	var t: = totals()
	var red_votes: = 0
	var blue_votes: = 0
	var draws: = 0
	for pair in t:
		var p: Array = pair
		if int(p[0]) > int(p[1]):
			red_votes += 1
		elif int(p[1]) > int(p[0]):
			blue_votes += 1
		else:
			draws += 1
	var winner: = -1
	var method: = "Ничья"
	if red_votes >= 2:
		winner = 0
	elif blue_votes >= 2:
		winner = 1
	if winner == -1:
		if red_votes == 1 and blue_votes == 1:
			method = "Раздельная ничья"
		elif draws >= 2:
			method = "Ничья (большинство)" if (red_votes + blue_votes) == 1 else "Ничья"
	else:
		var win_votes: = red_votes if winner == 0 else blue_votes
		var lose_votes: = blue_votes if winner == 0 else red_votes
		if win_votes == 3:
			method = "Единогласное решение"
		elif lose_votes == 1:
			method = "Раздельное решение"
		else:
			method = "Решение большинства"
	return {"winner": winner, "method": method, "totals": t}
