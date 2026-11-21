class_name SegBar
extends Control


var value: = 50:
	set(v):
		value = v
		queue_redraw()
var color: = Color(0.93, 0.72, 0.25)
var segs: = 20
var _shown: = 0.0


func _ready() -> void :
	var tw: = create_tween()
	tw.tween_property(self, "_shown", 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(queue_redraw)


func _process(_d: float) -> void :
	if _shown < 1.0:
		queue_redraw()


func _draw() -> void :
	var w: = size.x
	var h: = size.y
	var gap: = 3.0
	var sw: = (w - gap * float(segs - 1)) / float(segs)
	var filled: = float(value) / 100.0 * float(segs) * _shown
	var sk: = h * 0.35
	for i in segs:
		var x: = float(i) * (sw + gap)
		var pts: = PackedVector2Array([Vector2(x + sk, 0), Vector2(x + sw + sk, 0), Vector2(x + sw, h), Vector2(x, h)])
		var c: = Color(1, 1, 1, 0.07)
		if float(i) + 1.0 <= filled:
			c = color.darkened(0.25 * (1.0 - float(i) / float(segs)))
		elif float(i) < filled:
			c = color
			c.a = filled - float(i)
		draw_colored_polygon(pts, c)
