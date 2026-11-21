class_name RingRopes
extends Node3D




const SEGS: = 20
const RADIUS: = 0.034
const STIFF: = 900.0
const PULL: = 55.0
const DAMP: = 7.5
const MAX_OUT: = 0.55

var _ropes: Array = []


func build(half: float, heights: Array, mats: Array) -> void :
	var corners: = [Vector3( - half, 0, - half), Vector3(half, 0, - half), Vector3(half, 0, half), Vector3( - half, 0, half)]
	var seg_mesh_cache: = {}
	for r in heights.size():
		var h: float = heights[r]
		var mat: Material = mats[r]
		for s in 4:
			var a: Vector3 = corners[s] + Vector3(0, h, 0)
			var b: Vector3 = corners[(s + 1) % 4] + Vector3(0, h, 0)
			var mid: = (a + b) * 0.5
			var n: = Vector3(mid.x, 0, mid.z).normalized()
			var seg_len: = a.distance_to(b) / float(SEGS)
			var key: = snappedf(seg_len, 0.001)
			if not seg_mesh_cache.has(key):
				var cm: = CylinderMesh.new()
				cm.top_radius = RADIUS
				cm.bottom_radius = RADIUS
				cm.height = 1.0
				cm.radial_segments = 14
				cm.rings = 1
				seg_mesh_cache[key] = cm
			var segs: Array = []
			for i in SEGS:
				var mi: = MeshInstance3D.new()
				mi.mesh = seg_mesh_cache[key]
				mi.material_override = mat
				add_child(mi)
				segs.append(mi)
			var off: = PackedVector3Array()
			var vel: = PackedVector3Array()
			off.resize(SEGS + 1)
			vel.resize(SEGS + 1)
			_ropes.append({"a": a, "b": b, "h": h, "n": n, "off": off, "vel": vel, "segs": segs})
	_update_meshes()



func tick(delta: float, points: Array) -> void :
	var dt: = minf(delta, 0.033)
	var steps: = 2
	var h: = dt / float(steps)
	for rope in _ropes:
		var a: Vector3 = rope["a"]
		var b: Vector3 = rope["b"]
		var n: Vector3 = rope["n"]
		var rh: float = rope["h"]
		var off: PackedVector3Array = rope["off"]
		var vel: PackedVector3Array = rope["vel"]

		var near: Array = []
		for p in points:
			var p4: Vector4 = p
			var pp: = Vector3(p4.x, p4.y, p4.z)
			if absf(pp.y - rh) > p4.w + 0.16:
				continue
			var out_d: = pp.dot(n)
			var line_d: = a.dot(n)
			if out_d + p4.w < line_d - 0.02:
				continue
			near.append(p4)
		for _st in steps:
			for i in range(1, SEGS):
				var lap: = off[i - 1] + off[i + 1] - off[i] * 2.0
				var acc: = lap * STIFF / float(SEGS) - off[i] * PULL - vel[i] * DAMP
				vel[i] += acc * h
			for i in range(1, SEGS):
				off[i] += vel[i] * h



		if not near.is_empty():
			var axis: = (b - a).normalized()
			var line_d: = a.dot(n)
			var spacing: = a.distance_to(b) / float(SEGS)
			for i in range(1, SEGS):
				var base: = a.lerp(b, float(i) / float(SEGS))
				var on: = off[i].dot(n)
				var req: = -1000000000.0
				for p in near:
					var p4b: Vector4 = p
					var c: = Vector3(p4b.x, p4b.y, p4b.z)
					var da: = maxf(absf((c - base).dot(axis)) - spacing * 0.5, 0.0)
					var dy: = c.y - (base.y + off[i].y)
					var rad: = p4b.w + RADIUS
					var r2: = rad * rad - da * da - dy * dy
					if r2 > 0.0:
						req = maxf(req, c.dot(n) - line_d + sqrt(r2))
				if req > on:
					var o: = off[i] + n * (minf(req, MAX_OUT) - on)
					off[i] = o
					var vn: = vel[i].dot(n)
					if vn < 0.0:
						vel[i] -= n * vn
			for i in range(1, SEGS):
				var o2: = off[i]
				var outward: = clampf(o2.dot(n), -0.08, MAX_OUT)
				var vert: = clampf(o2.y, -0.2, 0.2)
				off[i] = n * outward + Vector3(0, vert, 0)
		rope["off"] = off
		rope["vel"] = vel
	_update_meshes()


func _update_meshes() -> void :
	for rope in _ropes:
		var a: Vector3 = rope["a"]
		var b: Vector3 = rope["b"]
		var off: PackedVector3Array = rope["off"]
		var segs: Array = rope["segs"]
		for i in SEGS:
			var p0: = a.lerp(b, float(i) / float(SEGS)) + off[i]
			var p1: = a.lerp(b, float(i + 1) / float(SEGS)) + off[i + 1]
			var d: = p1 - p0
			var l: = d.length()
			var mi: MeshInstance3D = segs[i]
			var y: = d / maxf(l, 0.0001)
			var x: = y.cross(Vector3.UP)
			if x.length() < 0.01:
				x = Vector3.RIGHT
			x = x.normalized()
			var z: = x.cross(y).normalized()

			mi.transform = Transform3D(Basis(x, y * (l + RADIUS * 0.6), z), (p0 + p1) * 0.5)



func max_deflection() -> float:
	var m: = 0.0
	for rope in _ropes:
		var n: Vector3 = rope["n"]
		for o in rope["off"]:
			m = maxf(m, (o as Vector3).dot(n))
	return m
