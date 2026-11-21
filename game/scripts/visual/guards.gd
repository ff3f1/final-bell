class_name Guards
extends RefCounted



const LIST: = {
	"classic": {
		"name": "Классическая", "desc": "Перчатки у скул, локти закрывают корпус", 
		"lead": Vector3(0, 0, 0), "rear": Vector3(0, 0, 0), 
		"crouch": 0.0, "bounce": 0.012, "bounce_hz": 1.6, "weave": 0.0, "weave_hz": 0.0, 
		"twist": 0.0, "shoulder": 0.0, "paw": 0.0, "upright": 0.0, 
	}, 
	"peekaboo": {
		"name": "Пик-а-бу", "desc": "Перчатки у лба, низкий присед, постоянный маятник", 
		"lead": Vector3(-0.035, 0.07, -0.025), "rear": Vector3(0.035, 0.07, -0.02), 
		"crouch": 0.07, "bounce": 0.007, "bounce_hz": 1.9, "weave": 0.32, "weave_hz": 0.62, 
		"twist": -0.05, "shoulder": 0.0, "paw": 0.0, "upright": -0.06, 
	}, 
	"philly": {
		"name": "Плечевая защита", "desc": "Передняя рука низко поперёк корпуса, плечо прикрывает подбородок", 
		"lead": Vector3(-0.07, -0.27, 0.03), "rear": Vector3(-0.02, 0.035, -0.01), 
		"crouch": 0.015, "bounce": 0.006, "bounce_hz": 1.2, "weave": 0.1, "weave_hz": 0.35, 
		"twist": 0.16, "shoulder": 0.1, "paw": 0.0, "upright": 0.02, 
	}, 
	"long": {
		"name": "Длинная", "desc": "Передняя рука вытянута, щупает дистанцию; боец пружинит на носках", 
		"lead": Vector3(0.0, -0.05, 0.2), "rear": Vector3(0.0, 0.02, 0.0), 
		"crouch": -0.01, "bounce": 0.02, "bounce_hz": 2.1, "weave": 0.0, "weave_hz": 0.0, 
		"twist": 0.06, "shoulder": 0.0, "paw": 1.0, "upright": 0.05, 
	}, 
	"low": {
		"name": "Опущенные руки", "desc": "Перчатки на уровне груди, уверенное покачивание", 
		"lead": Vector3(0.02, -0.21, 0.07), "rear": Vector3(0.0, -0.18, 0.04), 
		"crouch": 0.0, "bounce": 0.011, "bounce_hz": 1.4, "weave": 0.16, "weave_hz": 0.42, 
		"twist": 0.03, "shoulder": 0.0, "paw": 0.4, "upright": 0.06, 
	}, 
	"crab": {
		"name": "Скрещённые руки", "desc": "Передняя рука поперёк лица, задняя прикрывает печень", 
		"lead": Vector3(-0.12, 0.01, 0.0), "rear": Vector3(0.05, -0.19, 0.01), 
		"crouch": 0.035, "bounce": 0.005, "bounce_hz": 1.1, "weave": 0.06, "weave_hz": 0.3, 
		"twist": 0.1, "shoulder": 0.06, "paw": 0.0, "upright": -0.02, 
	}, 
}
const ORDER: = ["classic", "peekaboo", "philly", "long", "low", "crab"]


static func get_data(id: String) -> Dictionary:
	return LIST.get(id, LIST["classic"])



static func for_def(def: Dictionary) -> String:
	var g: = str(def.get("guard", ""))
	if LIST.has(g):
		return g
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash("guard-" + str(def.get("name", def.get("id", ""))))
	return pick_for(str(def.get("style", "balanced")), rng)


static func name_of(id: String) -> String:
	return str(get_data(id)["name"])



static func pick_for(style: String, rng: RandomNumberGenerator) -> String:
	var w: = {}
	match style:
		"swarmer":
			w = {"peekaboo": 5.0, "classic": 3.0, "crab": 0.3}
		"counter":
			w = {"philly": 4.0, "classic": 2.0, "low": 1.0, "crab": 0.5}
		"outboxer":
			w = {"long": 5.0, "classic": 2.0, "low": 1.5}
		"slugger":
			w = {"classic": 3.0, "low": 2.5, "peekaboo": 1.0, "crab": 0.4}
		_:
			w = {"classic": 5.0, "peekaboo": 1.0, "long": 1.0, "philly": 1.0, "low": 0.5}
	var tot: = 0.0
	for k in w.keys():
		tot += float(w[k])
	var x: = rng.randf() * tot
	for k in w.keys():
		x -= float(w[k])
		if x <= 0.0:
			return str(k)
	return "classic"
