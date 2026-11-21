class_name BoxerRig
extends Node3D





var fighter: Fighter


func setup(_def: Dictionary, f: Fighter) -> void :
	fighter = f


func update_rig(_delta: float) -> void :
	pass


func on_punch_start(_type: int, _body: bool, _power: bool, _windup: float, _active: float, _recovery: float) -> void :
	pass


func on_punch_cancel() -> void :
	pass


func on_hit(_body: bool, _incoming_side: int, _strength: float, _type: int) -> void :
	pass


func on_blocked_hit(_strength: float) -> void :
	pass


func on_parried() -> void :
	pass


func on_knockdown(_body_kd: bool) -> void :
	pass


func on_getup(_duration: float) -> void :
	pass


func on_victory() -> void :
	pass



func play_show(_name: String) -> float:
	return 0.0



func on_defeat() -> void :
	pass


func on_clinch(_active: bool) -> void :
	pass


func on_reset() -> void :
	pass


func get_head_global() -> Vector3:
	return global_position + Vector3(0, 1.65, 0)



func rope_points() -> Array:
	return []


func get_glove_global(_lead: bool) -> Vector3:
	return global_position + Vector3(0, 1.4, -0.4)
