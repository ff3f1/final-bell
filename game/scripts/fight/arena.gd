class_name Arena
extends RefCounted


const ROPE_HALF: = 2.9
const APRON_HALF: = 3.5
const RING_HEIGHT: = 1.25
const CORNERS: = {
	"red": Vector3(-2.45, 0, 2.45), 
	"blue": Vector3(2.45, 0, -2.45), 
	"neutral_a": Vector3(2.45, 0, 2.45), 
	"neutral_b": Vector3(-2.45, 0, -2.45), 
}



const VENUES: = {
	"arena": {"name": "Final Bell Арена", "rows": 14, "board": true, "truss": true, "press": true, "walls": "", 
		"spot": Color(1.0, 0.95, 0.87), "spot_e": 3.0, "top_e": 4.5, "fill": [Color(0.25, 0.3, 0.8), Color(0.6, 0.2, 0.5)], 
		"fill_e": 0.25, "fog": 0.018, "ambient": 0.12, "skirt": Color(0.05, 0.07, 0.16), "logo": Color(0.1, 0.16, 0.38), 
		"bg": Color(0.008, 0.008, 0.014)}, 
	"club": {"name": "Клуб «Подвал»", "rows": 5, "board": false, "truss": false, "press": false, "walls": "brick", 
		"spot": Color(1.0, 0.84, 0.62), "spot_e": 2.6, "top_e": 3.6, "fill": [Color(0.9, 0.45, 0.2), Color(0.7, 0.3, 0.15)], 
		"fill_e": 0.35, "fog": 0.034, "ambient": 0.16, "skirt": Color(0.2, 0.05, 0.04), "logo": Color(0.32, 0.06, 0.05), 
		"bg": Color(0.02, 0.012, 0.01), "wall_d": 8.6, "wall_h": 6.0}, 
	"palace": {"name": "Дворец спорта «Олимп»", "rows": 14, "board": true, "truss": true, "press": true, "walls": "", 
		"spot": Color(1.0, 0.93, 0.8), "spot_e": 3.3, "top_e": 5.0, "fill": [Color(0.55, 0.2, 0.85), Color(0.95, 0.7, 0.25)], 
		"fill_e": 0.45, "fog": 0.022, "ambient": 0.13, "skirt": Color(0.04, 0.03, 0.02), "logo": Color(0.06, 0.05, 0.03), 
		"bg": Color(0.012, 0.006, 0.02), "led": Color(0.7, 0.3, 1.0)}, 
	"gym": {"name": "Тренировочный центр", "rows": 0, "board": false, "truss": false, "press": false, "walls": "gym", 
		"spot": Color(0.92, 0.97, 1.0), "spot_e": 1.6, "top_e": 2.2, "fill": [Color(0.85, 0.92, 1.0), Color(0.85, 0.92, 1.0)], 
		"fill_e": 0.6, "fog": 0.006, "ambient": 0.3, "skirt": Color(0.08, 0.08, 0.09), "logo": Color(0.12, 0.12, 0.13), 
		"bg": Color(0.05, 0.05, 0.055), "wall_d": 8.0, "wall_h": 5.2}, 
}
const VENUE_ORDER: = ["arena", "palace", "club"]


static func venue_name(id: String) -> String:
	return str(VENUES.get(id, VENUES["arena"])["name"])



static func venue_for(cfg: Dictionary) -> String:
	if str(cfg.get("training", "")) != "":
		return "gym"
	var v: = str(cfg.get("venue", "arena"))
	return v if VENUES.has(v) else "arena"


const BRICK_SHADER: = "\r\nshader_type spatial;\r\nuniform vec3 brick_col : source_color = vec3(0.34, 0.15, 0.1);\r\nuniform vec3 mortar_col : source_color = vec3(0.2, 0.19, 0.18);\r\nuniform vec2 brick = vec2(0.25, 0.085);\r\nuniform float paint = 0.0;\r\nvarying vec3 wp;\r\nfloat h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }\r\nvoid vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }\r\nvoid fragment() {\r\n\tvec2 uv = vec2(wp.x + wp.z, wp.y) / brick;\r\n\tfloat row = floor(uv.y);\r\n\tuv.x += mod(row, 2.0) * 0.5;\r\n\tvec2 id = floor(uv);\r\n\tvec2 f = fract(uv);\r\n\tvec2 m = vec2(0.012) / brick;\r\n\tfloat bx = smoothstep(0.0, m.x, f.x) * smoothstep(0.0, m.x, 1.0 - f.x);\r\n\tfloat by = smoothstep(0.0, m.y, f.y) * smoothstep(0.0, m.y, 1.0 - f.y);\r\n\tfloat b = bx * by;\r\n\tfloat v = 0.75 + 0.5 * h(id);\r\n\tvec3 c = mix(mortar_col, brick_col * v, b);\r\n\tALBEDO = mix(c, vec3(0.78, 0.78, 0.76) * (0.9 + 0.1 * v), paint);\r\n\tROUGHNESS = mix(0.95, 0.8, b);\r\n\tNORMAL_MAP = vec3(0.5 + (bx - 1.0) * 0.0 + (1.0 - by) * 0.0, 0.5, 1.0);\r\n\tNORMAL_MAP = normalize(vec3(0.5 - (1.0 - bx) * 0.35 * sign(f.x - 0.5), 0.5 - (1.0 - by) * 0.35 * sign(f.y - 0.5), 1.0)) * 0.5 + 0.5;\r\n}\r\n"




























const CROWD_SHADER: = "\r\nshader_type spatial;\r\nrender_mode cull_back;\r\n\r\nuniform float excitement = 0.3;\r\nuniform float flash_boost = 0.0;\r\nuniform bool is_head = false;\r\n\r\nvarying vec3 v_col;\r\nvarying float v_flash;\r\n\r\nfloat rnd1(float n) { return fract(sin(n) * 43758.5453); }\r\n\r\nvoid vertex() {\r\n\tfloat id = float(INSTANCE_ID);\r\n\tfloat seed = rnd1(id * 12.9898 + 0.31);\r\n\tfloat active = step(0.35 - excitement * 0.35, seed);\r\n\tfloat speed = 2.5 + seed * 4.0 + excitement * 3.0;\r\n\tfloat bob = max(0.0, sin(TIME * speed + seed * 6.2831)) * (0.03 + excitement * 0.16) * active;\r\n\tVERTEX.y += bob;\r\n\tVERTEX.x += sin(TIME * (1.0 + seed) + seed * 9.0) * 0.02 * excitement;\r\n\tv_col = COLOR.rgb;\r\n\tfloat rate = 2.0;\r\n\tfloat t = TIME * rate + seed * 13.0;\r\n\tfloat slot = floor(t);\r\n\tfloat within = fract(t);\r\n\tfloat h = rnd1(slot * 91.17 + seed * 311.7);\r\n\tfloat chance = 0.0015 + flash_boost * 0.05;\r\n\tv_flash = is_head ? step(1.0 - chance, h) * (1.0 - smoothstep(0.0, 0.22, within)) : 0.0;\r\n}\r\n\r\nvoid fragment() {\r\n\tALBEDO = v_col;\r\n\tROUGHNESS = 0.9;\r\n\tEMISSION = vec3(1.0, 0.97, 0.9) * v_flash * 14.0;\r\n}\r\n"








































const CANVAS_SHADER: = "\r\nshader_type spatial;\r\nrender_mode diffuse_burley;\r\nuniform vec3 base_col : source_color = vec3(0.62, 0.63, 0.66);\r\nuniform float wear = 1.0;\r\nvarying vec3 wp;\r\nfloat hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }\r\nfloat vn(vec2 p) {\r\n\tvec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);\r\n\treturn mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);\r\n}\r\nfloat fbm(vec2 p) { float a = 0.5; float r = 0.0; for (int i = 0; i < 5; i++) { r += vn(p) * a; p *= 2.03; a *= 0.5; } return r; }\r\nvoid vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }\r\nvoid fragment() {\r\n\tvec2 p = wp.xz;\r\n\t// переплетение: нити основы и утка ~1.5 мм, чуть неровные\r\n\tvec2 q = p * 420.0;\r\n\tfloat wx = sin(q.x + vn(p * 30.0) * 2.0) * 0.5 + 0.5;\r\n\tfloat wz = sin(q.y + vn(p * 31.0 + 7.0) * 2.0) * 0.5 + 0.5;\r\n\tfloat checker = step(0.5, fract((floor(q.x / 3.14159) + floor(q.y / 3.14159)) * 0.5));\r\n\tfloat weave = mix(wx, wz, checker);\r\n\t// вдали переплетение сливается — гасим его, иначе муар «сеткой»\r\n\tfloat aa = clamp(1.0 - fwidth(q.x) * 0.35, 0.0, 1.0);\r\n\tweave = mix(0.5, weave, aa);\r\n\twx = mix(0.5, wx, aa);\r\n\twz = mix(0.5, wz, aa);\r\n\t// крупные неровности: потёртости к центру, разводы, следы подошв\r\n\tfloat r = length(p);\r\n\tfloat scuff = smoothstep(2.6, 0.2, r) * wear;\r\n\tfloat stains = fbm(p * 1.3);\r\n\tfloat marks = smoothstep(0.62, 0.8, fbm(p * 6.0 + 3.0)) * scuff;\r\n\tvec3 col = base_col * (0.92 + 0.08 * weave);\r\n\tcol *= mix(1.0, 0.86 + 0.14 * stains, 0.8);\r\n\tcol = mix(col, col * vec3(0.78, 0.76, 0.74), marks * 0.6 + scuff * 0.12);\r\n\tALBEDO = col;\r\n\tROUGHNESS = 0.82 - marks * 0.12 + (1.0 - weave) * 0.06;\r\n\tSPECULAR = 0.3;\r\n\tvec2 nn = vec2(wx - 0.5, wz - 0.5) * 0.22 + (vec2(vn(p * 9.0), vn(p * 9.0 + 4.0)) - 0.5) * 0.12;\r\n\tNORMAL_MAP = vec3(nn + 0.5, 1.0);\r\n\tNORMAL_MAP_DEPTH = 1.0;\r\n}\r\n"











































const CROWD_ATLAS: = "res://assets/crowd/crowd_atlas.res"
const SPRITE_CROWD_SHADER: = "\r\nshader_type spatial;\r\nrender_mode unshaded, cull_disabled, depth_draw_opaque;\r\nuniform sampler2DArray atlas : source_color, filter_linear_mipmap, repeat_disable;\r\nuniform float excitement = 0.2;\r\nuniform float flash_boost = 0.0;\r\nuniform float frames = 16.0;\r\nuniform float anims = 6.0;\r\nuniform vec4 dur_a = vec4(4.0, 1.2, 2.9, 3.8);\r\nuniform vec2 dur_b = vec2(4.0, 1.9);\r\nvarying flat float v_layer;\r\nvarying flat float v_anim;\r\nvarying float v_t;\r\nvarying vec3 v_tint;\r\nvarying flat float v_cloth;\r\nvarying float v_flash;\r\n\r\nfloat rnd1(float n) { return fract(sin(n) * 43758.5453); }\r\n\r\nvec3 rgb2hsv(vec3 c) {\r\n\tvec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);\r\n\tvec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));\r\n\tvec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));\r\n\tfloat d = q.x - min(q.w, q.y);\r\n\tfloat e = 1.0e-10;\r\n\treturn vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);\r\n}\r\n\r\nvec3 hsv2rgb(vec3 c) {\r\n\tvec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);\r\n\tvec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);\r\n\treturn c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);\r\n}\r\n\r\nvoid vertex() {\r\n\tvec4 cd = INSTANCE_CUSTOM;\r\n\tfloat layer = floor(cd.r * 255.0 + 0.5);\r\n\tfloat phase = cd.g;\r\n\tfloat thr = cd.b;\r\n\tfloat r2 = cd.a;\r\n\tfloat e = excitement;\r\n\tfloat anim = 0.0;\r\n\tif (e > 0.6 + thr * 0.32) {\r\n\t\tanim = 2.0 + floor(r2 * 3.999);\r\n\t} else if (e > 0.22 + thr * 0.38) {\r\n\t\tanim = 1.0;\r\n\t}\r\n\tfloat d = anim < 0.5 ? dur_a.x : (anim < 1.5 ? dur_a.y : (anim < 2.5 ? dur_a.z : (anim < 3.5 ? dur_a.w : (anim < 4.5 ? dur_b.x : dur_b.y))));\r\n\tfloat spd = 0.85 + r2 * 0.3;\r\n\tv_t = fract(TIME * spd / d + phase);\r\n\tv_layer = layer;\r\n\tv_anim = anim;\r\n\tv_tint = COLOR.rgb;\r\n\tv_cloth = floor(fract(phase * 7.31 + thr * 3.17) * 6.0);\r\n\tfloat seed = rnd1(float(INSTANCE_ID) * 12.9898 + 0.31);\r\n\tfloat tt = TIME * 2.0 + seed * 13.0;\r\n\tfloat h = rnd1(floor(tt) * 91.17 + seed * 311.7);\r\n\tv_flash = step(1.0 - (0.0012 + flash_boost * 0.04), h) * (1.0 - smoothstep(0.0, 0.2, fract(tt)));\r\n\tMODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);\r\n\tMODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));\r\n\tMODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);\r\n}\r\n\r\nvoid fragment() {\r\n\t// между кадрами спрайта — плавный переход, иначе низкий FPS атласа бросается в глаза\r\n\tfloat ft = v_t * frames;\r\n\tfloat fr = mod(floor(ft), frames);\r\n\tfloat fr2 = mod(fr + 1.0, frames);\r\n\tfloat k = smoothstep(0.15, 0.85, fract(ft));\r\n\tvec4 c1 = texture(atlas, vec3(vec2((fr + UV.x) / frames, (v_anim + UV.y) / anims), v_layer));\r\n\tvec4 c2 = texture(atlas, vec3(vec2((fr2 + UV.x) / frames, (v_anim + UV.y) / anims), v_layer));\r\n\tvec4 c = mix(c1, c2, k);\r\n\tif (c.a < 0.5) {\r\n\t\tdiscard;\r\n\t}\r\n\tvec3 col = c.rgb;\r\n\tvec3 hsv = rgb2hsv(col);\r\n\t// перекрашиваем одежду (насыщенные не-телесные цвета), кожу не трогаем\r\n\tbool skin = hsv.x < 0.12 || hsv.x > 0.95;\r\n\tif (!skin && hsv.y > 0.22 && v_cloth > 0.5) {\r\n\t\tif (v_cloth < 1.5) { hsv.x = fract(hsv.x + 0.42); }                 // красные/оранжевые\r\n\t\telse if (v_cloth < 2.5) { hsv.x = fract(hsv.x - 0.28); }            // зелёные\r\n\t\telse if (v_cloth < 3.5) { hsv.y *= 0.1; hsv.z *= 0.55; }            // тёмно-серые\r\n\t\telse if (v_cloth < 4.5) { hsv.y *= 0.05; hsv.z *= 0.25; }           // чёрные\r\n\t\telse { hsv.y *= 0.08; hsv.z = min(1.0, hsv.z * 1.35); }             // светлые\r\n\t\tcol = hsv2rgb(hsv);\r\n\t}\r\n\tvec3 outc = col * v_tint * (1.0 + flash_boost * 0.25 + v_flash * 4.0);\r\n\tfloat spark = 1.0 - smoothstep(0.0, 0.045, distance(UV, vec2(0.56, 0.17)));\r\n\toutc += vec3(1.0, 0.97, 0.9) * spark * v_flash * 6.0;\r\n\tALBEDO = outc;\r\n}\r\n"






























































































static func _mat(c: Color, rough: float = 0.7, metal: float = 0.0) -> StandardMaterial3D:
	var m: = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


static func _add_mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi: = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func _box(size: Vector3) -> BoxMesh:
	var b: = BoxMesh.new()
	b.size = size
	return b


static func _cyl(r: float, h: float) -> CylinderMesh:
	var c: = CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 12
	return c


static func _label(parent: Node3D, text: String, pos: Vector3, rot: Vector3, size: int, color: Color, pixel: float = 0.01) -> Label3D:
	var l: = Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = pixel
	l.modulate = color
	l.outline_size = 0
	l.position = pos
	l.rotation = rot
	l.double_sided = false
	if Game.title_font:
		l.font = Game.title_font
	parent.add_child(l)
	return l



static func build(parent: Node3D, venue: String = "arena") -> Dictionary:
	var refs: = {}
	var root: = Node3D.new()
	root.name = "Arena"
	parent.add_child(root)
	var v: Dictionary = VENUES.get(venue, VENUES["arena"])
	refs["venue"] = venue


	var env: = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = v["bg"]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.33, 0.45)
	env.ambient_light_energy = float(v["ambient"]) * 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.2
	env.ssao_enabled = true
	env.ssao_radius = 0.6
	env.ssao_intensity = 2.2
	env.ssao_power = 1.6
	env.ssao_detail = 0.8
	env.ssil_enabled = true
	env.ssil_radius = 4.0
	env.ssil_intensity = 0.9
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = float(v["fog"]) * 0.8
	env.volumetric_fog_albedo = Color(0.78, 0.8, 0.88)
	env.volumetric_fog_length = 40.0
	env.volumetric_fog_anisotropy = 0.55
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.12
	env.adjustment_saturation = 1.04
	env.ssr_enabled = true
	env.ssr_max_steps = 48
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0

	env.sdfgi_enabled = true
	env.sdfgi_use_occlusion = true
	env.sdfgi_cascades = 4
	env.sdfgi_min_cell_size = 0.1
	env.sdfgi_energy = 0.9
	env.sdfgi_bounce_feedback = 0.4
	var we: = WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	refs["environment"] = env


	var floor_mat: = _mat(Color(0.06, 0.06, 0.07), 0.9)
	_textured(floor_mat, Color(0.05, 0.05, 0.06), Color(0.085, 0.08, 0.085), 0.02, "cotton", 0.6, 40.0)
	_add_mesh(root, _box(Vector3(70, 0.2, 70)), floor_mat, Vector3(0, - RING_HEIGHT - 0.1, 0))

	var skirt_mat: = _mat(v["skirt"], 0.6)
	_add_mesh(root, _box(Vector3(APRON_HALF * 2.0, RING_HEIGHT, APRON_HALF * 2.0)), skirt_mat, Vector3(0, - RING_HEIGHT * 0.5 - 0.04, 0))
	var canvas_mat: = ShaderMaterial.new()
	var csh: = Shader.new()
	csh.code = CANVAS_SHADER
	canvas_mat.shader = csh
	canvas_mat.set_shader_parameter("base_col", Color(0.5, 0.51, 0.54) if venue != "gym" else Color(0.32, 0.34, 0.4))

	var canvas_mi: = _add_mesh(root, _box(Vector3(APRON_HALF * 2.0, 0.08, APRON_HALF * 2.0)), canvas_mat, Vector3(0, -0.04, 0))
	canvas_mi.layers = 3
	var logo_mat: = _mat(v["logo"], 0.85)
	var disk: = CylinderMesh.new()
	disk.top_radius = 1.25
	disk.bottom_radius = 1.25
	disk.height = 0.004
	disk.radial_segments = 64
	var disk_mi: = _add_mesh(root, disk, logo_mat, Vector3(0, 0.002, 0))
	disk_mi.layers = 3
	var ring_line: = TorusMesh.new()
	ring_line.inner_radius = 1.25
	ring_line.outer_radius = 1.32
	ring_line.rings = 64
	var line_mi: = _add_mesh(root, ring_line, _mat(Game.ACCENT, 0.5, 0.3), Vector3(0, 0.0, 0))
	line_mi.scale = Vector3(1, 0.05, 1)
	line_mi.layers = 3
	var logo: = _label(root, "FINAL BELL", Vector3(0, 0.006, 0), Vector3( - PI * 0.5, 0, 0), 150, Color(0.95, 0.78, 0.3), 0.0065)
	logo.shaded = true

	var apron_line_mat: = _mat(Color(0.55, 0.06, 0.06), 0.8)
	for i in 4:
		var a: = float(i) * PI * 0.5
		var pos: = Vector3(sin(a), 0, cos(a)) * (ROPE_HALF + 0.3)
		var strip: = _add_mesh(root, _box(Vector3(APRON_HALF * 2.0, 0.006, 0.2)), apron_line_mat, pos + Vector3(0, 0.003, 0))
		strip.rotation.y = a


	for i in 4:
		var a2: = float(i) * PI * 0.5
		var dir: = Vector3(sin(a2), 0, cos(a2))
		var txt: = "FINAL BELL" if i % 2 == 0 else "CHAMPIONSHIP BOXING"
		var lbl: = _label(root, txt, dir * (APRON_HALF + 0.01) + Vector3(0, -0.6, 0), Vector3(0, a2, 0), 110, Color(0.95, 0.8, 0.35), 0.006)
		lbl.shaded = false


	var post_mat: = _mat(Color(0.75, 0.76, 0.8), 0.25, 0.85)
	var pad_colors: = {
		"red": Color(0.75, 0.06, 0.06), "blue": Color(0.06, 0.18, 0.7), 
		"neutral_a": Color(0.92, 0.92, 0.92), "neutral_b": Color(0.92, 0.92, 0.92), 
	}
	var post_pos: = {}
	for key in CORNERS.keys():
		var k: String = key
		var c: Vector3 = CORNERS[k]
		var p: = Vector3(signf(c.x) * ROPE_HALF, 0, signf(c.z) * ROPE_HALF)
		post_pos[k] = p
		_add_mesh(root, _cyl(0.07, 1.6), post_mat, p + Vector3(0, 0.8, 0))
		var pad: = _add_mesh(root, _box(Vector3(0.24, 1.15, 0.24)), _mat(pad_colors[k], 0.55), p + Vector3(0, 0.82, 0) - Vector3(signf(c.x), 0, signf(c.z)) * 0.1)
		pad.rotation.y = PI * 0.25
	var rope_colors: = [Color(0.85, 0.08, 0.08), Color(0.95, 0.95, 0.95), Color(0.1, 0.22, 0.75), Color(0.95, 0.95, 0.95)]
	var rope_heights: = [1.32, 1.02, 0.72, 0.42]
	var sides: = [
		[Vector3( - ROPE_HALF, 0, - ROPE_HALF), Vector3(ROPE_HALF, 0, - ROPE_HALF)], 
		[Vector3(ROPE_HALF, 0, - ROPE_HALF), Vector3(ROPE_HALF, 0, ROPE_HALF)], 
		[Vector3(ROPE_HALF, 0, ROPE_HALF), Vector3( - ROPE_HALF, 0, ROPE_HALF)], 
		[Vector3( - ROPE_HALF, 0, ROPE_HALF), Vector3( - ROPE_HALF, 0, - ROPE_HALF)], 
	]
	var rope_mats: Array = []
	for r in rope_heights.size():

		var rmat: = ShaderMaterial.new()
		rmat.shader = preload("res://scripts/visual/rope.gdshader")
		rmat.set_shader_parameter("color", rope_colors[r])
		rope_mats.append(rmat)

	var rope_sim: = RingRopes.new()
	rope_sim.name = "RingRopes"
	root.add_child(rope_sim)
	rope_sim.build(ROPE_HALF, rope_heights, rope_mats)
	refs["rope_sim"] = rope_sim
	var tie_mat: = _mat(Color(0.92, 0.92, 0.92), 0.7)
	for sd in sides:
		var sa: Vector3 = sd[0]
		var sb: Vector3 = sd[1]
		for f in [0.33, 0.67]:
			var tp: Vector3 = sa.lerp(sb, f) + Vector3(0, 0.87, 0)
			var tie: = _add_mesh(root, _box(Vector3(0.05, 0.95, 0.05)), tie_mat, tp)
			tie.rotation.y = atan2((sb - sa).x, (sb - sa).z)
	_corner_props(root)


	if bool(v["press"]):
		_press_row(root)

	if str(v["walls"]) != "":
		_build_walls(root, v)
	if venue == "gym":
		_build_gym(root)
	var probe: = ReflectionProbe.new()
	probe.size = Vector3(16, 9, 16)
	probe.position = Vector3(0, 2.5, 0)
	probe.box_projection = true
	probe.intensity = 0.8
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	root.add_child(probe)
	_build_rest(root, refs, v, venue)
	return refs


static func _press_row(root: Node3D) -> void :
	var table_mat: = _mat(Color(0.04, 0.04, 0.05), 0.5)
	var screen_mat: = _mat(Color(0.2, 0.35, 0.8), 0.3)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.3, 0.5, 1.0)
	screen_mat.emission_energy_multiplier = 1.5
	for i in 5:
		var x: = -3.0 + float(i) * 1.5
		_add_mesh(root, _box(Vector3(1.3, 0.75, 0.6)), table_mat, Vector3(x, - RING_HEIGHT + 0.375, APRON_HALF + 1.0))
		var scr: = _add_mesh(root, _box(Vector3(0.36, 0.24, 0.02)), screen_mat, Vector3(x + 0.2, - RING_HEIGHT + 0.9, APRON_HALF + 1.15))
		scr.rotation.x = -0.25
	var barrier_mat: = _mat(Color(0.08, 0.1, 0.22), 0.6)
	for i in 4:
		var a4: = float(i) * PI * 0.5
		var bpos: = Vector3(sin(a4), 0, cos(a4)) * 5.6 + Vector3(0, - RING_HEIGHT + 0.5, 0)
		var bar: = _add_mesh(root, _box(Vector3(11.2, 1.0, 0.12)), barrier_mat, bpos)
		bar.rotation.y = a4
		var btxt: = _label(root, "FINAL BELL  •  FIGHT NIGHT  •  FINAL BELL", bpos + Vector3(sin(a4), 0, cos(a4)) * -0.07, Vector3(0, a4 + PI, 0), 90, Color(0.9, 0.75, 0.3), 0.005)
		btxt.shaded = false


static func _build_rest(root: Node3D, refs: Dictionary, v: Dictionary, venue: String) -> void :

	var truss_mat: = _mat(Color(0.16, 0.16, 0.17), 0.35, 0.85)
	if bool(v["truss"]):
		_build_truss(root, truss_mat)
	refs["board_labels"] = []
	if bool(v["board"]):
		_build_board(root, refs, truss_mat, v)
	_build_lights(root, refs, v)
	_build_physics(root)
	if int(v["rows"]) > 0:
		refs["crowd_materials"] = _build_crowd(root, int(v["rows"]))
	else:
		refs["crowd_materials"] = []


static func _build_board(root: Node3D, refs: Dictionary, truss_mat: Material, v: Dictionary) -> void :
	var board: = Node3D.new()
	board.position = Vector3(0, 10.2, 0)
	root.add_child(board)
	_add_mesh(board, _box(Vector3(3.4, 1.9, 3.4)), truss_mat, Vector3.ZERO)
	var scr_mat: = _mat(Color(0.02, 0.02, 0.03), 0.3)
	scr_mat.emission_enabled = true
	scr_mat.emission = Color(0.05, 0.06, 0.12)
	var board_labels: Array = []
	for i in 4:
		var a6: = float(i) * PI * 0.5
		var n: = Vector3(sin(a6), 0, cos(a6))
		var face: = _add_mesh(board, _box(Vector3(3.0, 1.55, 0.02)), scr_mat, n * 1.71)
		face.rotation.y = a6
		var bl: = _label(board, "FINAL BELL", n * 1.73, Vector3(0, a6, 0), 120, Color(1.0, 0.82, 0.35), 0.008)
		bl.shaded = false
		board_labels.append(bl)
	refs["board_labels"] = board_labels
	if v.has("led"):

		var led: = TorusMesh.new()
		led.inner_radius = 2.6
		led.outer_radius = 2.75
		led.rings = 64
		var lm: = _mat(Color(0.05, 0.03, 0.08), 0.4)
		lm.emission_enabled = true
		lm.emission = v["led"]
		lm.emission_energy_multiplier = 3.0
		var lmi: = _add_mesh(root, led, lm, Vector3(0, 8.9, 0))
		lmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _build_lights(root: Node3D, refs: Dictionary, v: Dictionary) -> void :
	_build_ring_lights(root, refs, v)

	var fc0: Array = v["fill"]
	var fcols: = [fc0[0], fc0[1], fc0[0], fc0[1]]
	for i in 4:
		var a8: = float(i) * PI * 0.5 + PI * 0.25
		var om2: = OmniLight3D.new()
		om2.position = Vector3(sin(a8), 0, cos(a8)) * 11.0 + Vector3(0, 3.5, 0)
		om2.omni_range = 12.0
		om2.light_energy = float(v["fill_e"]) * 0.8
		om2.light_color = fcols[i]
		om2.light_volumetric_fog_energy = 0.25
		root.add_child(om2)





static func _build_ring_lights(root: Node3D, refs: Dictionary, v: Dictionary) -> void :
	var roof: = 6.4 if bool(v["truss"]) else float(v.get("wall_h", 6.0)) - RING_HEIGHT - 0.5
	var key_e: = float(v["top_e"]) * 0.62
	var warm: Color = v["spot"]
	var grid: = [Vector2(-1.35, -1.35), Vector2(1.35, -1.35), Vector2(-1.35, 1.35), Vector2(1.35, 1.35), 
		Vector2(0, -1.9), Vector2(0, 1.9), Vector2(-1.9, 0), Vector2(1.9, 0), Vector2.ZERO]
	var k: = 0
	var center_light: SpotLight3D = null
	for g in grid:
		var gp: Vector2 = g
		var sp: = SpotLight3D.new()
		root.add_child(sp)
		sp.position = Vector3(gp.x, roof, gp.y)

		sp.look_at(Vector3(gp.x * 1.25, 0.0, gp.y * 1.25 + 0.001), Vector3.FORWARD)
		sp.spot_range = roof + 6.0
		sp.spot_angle = 38.0
		sp.spot_angle_attenuation = 1.4
		sp.light_energy = key_e * (1.15 if k == 8 else 1.0)
		sp.light_color = warm
		sp.light_size = 0.55
		sp.light_specular = 0.75
		sp.light_volumetric_fog_energy = 0.6

		sp.shadow_enabled = k >= 4
		sp.shadow_blur = 1.6
		sp.shadow_bias = 0.03
		sp.shadow_normal_bias = 1.2
		if k == 8:
			center_light = sp
		k += 1
	refs["top_light"] = center_light

	for i in 4:
		var a: = float(i) * PI * 0.5 + PI * 0.25
		var kp: = Vector3(sin(a), 0, cos(a)) * 6.4 + Vector3(0, roof + 0.6, 0)
		var kk: = SpotLight3D.new()
		root.add_child(kk)
		kk.look_at_from_position(kp, Vector3(0, 1.2, 0), Vector3.UP)
		kk.spot_range = 14.0
		kk.spot_angle = 22.0
		kk.spot_angle_attenuation = 1.1
		kk.light_energy = float(v["spot_e"]) * 0.75
		kk.light_color = Color(0.86, 0.92, 1.0).lerp(warm, 0.3)
		kk.light_specular = 1.0
		kk.light_size = 0.2
		kk.light_volumetric_fog_energy = 0.9
		kk.shadow_enabled = false

	for i in 2:
		var a2: = float(i) * PI + 0.35
		var fp: = Vector3(sin(a2), 0, cos(a2)) * 9.0 + Vector3(0, 2.6, 0)
		var fl: = SpotLight3D.new()
		root.add_child(fl)
		fl.look_at_from_position(fp, Vector3(0, 1.3, 0), Vector3.UP)
		fl.spot_range = 16.0
		fl.spot_angle = 26.0
		fl.light_energy = float(v["spot_e"]) * 0.18
		fl.light_color = Color(1.0, 0.96, 0.9)
		fl.light_specular = 0.25
		fl.light_volumetric_fog_energy = 0.0

	var lamp_mat: = StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(0.1, 0.1, 0.1)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = warm
	lamp_mat.emission_energy_multiplier = 9.0
	var lamp: = CylinderMesh.new()
	lamp.top_radius = 0.16
	lamp.bottom_radius = 0.19
	lamp.height = 0.12
	for g2 in grid:
		var gp2: Vector2 = g2
		var lm: = _add_mesh(root, lamp, lamp_mat, Vector3(gp2.x, roof + 0.07, gp2.y))
		lm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var frame_mat: = _mat(Color(0.05, 0.05, 0.055), 0.5, 0.7)
	for side in 4:
		var bar: = _add_mesh(root, _box(Vector3(4.6, 0.12, 0.12)), frame_mat, Vector3(0, roof + 0.16, (float(side) - 1.5) * 1.27))
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func _build_lights_old(root: Node3D, refs: Dictionary, v: Dictionary) -> void :
	var spot_i: = 0

	var spot_y: = 6.95 if bool(v["truss"]) else float(v.get("wall_h", 6.0)) - RING_HEIGHT - 0.55
	var spot_r: = 3.6 if bool(v["truss"]) else 3.0
	for side in 4:
		var a: = float(side) * PI * 0.5
		var nrm: = Vector3(sin(a), 0, cos(a))
		var tg: = Vector3(cos(a), 0, - sin(a))
		for off in [-1.7, 1.7]:
			var sp: = SpotLight3D.new()
			var sp_pos: Vector3 = nrm * spot_r + tg * off + Vector3(0, spot_y, 0)
			root.add_child(sp)
			var aim: Vector3 = - nrm * 0.9 + tg * ( - off * 0.35) + Vector3(0, 0.4, 0)
			sp.look_at_from_position(sp_pos, aim, Vector3.UP)
			sp.spot_range = 16.0
			sp.spot_angle = 33.0
			sp.spot_angle_attenuation = 0.75
			sp.light_energy = float(v["spot_e"])
			sp.light_color = v["spot"]
			sp.light_volumetric_fog_energy = 0.55
			sp.shadow_enabled = true
			sp.shadow_blur = 2.2
			sp.shadow_bias = 0.04
			sp.light_size = 0.35
			spot_i += 1
	var top: = SpotLight3D.new()
	top.position = Vector3(0, 8.0 if bool(v["truss"]) else spot_y, 0)
	top.rotation = Vector3( - PI * 0.5, 0, 0)
	root.add_child(top)
	top.spot_range = 14.0
	top.spot_angle = 26.0
	top.light_energy = float(v["top_e"])
	top.light_color = Color(1.0, 0.97, 0.92)
	top.shadow_enabled = true
	top.shadow_blur = 2.5
	top.light_size = 0.5
	top.light_volumetric_fog_energy = 0.4
	refs["top_light"] = top

	var fc: Array = v["fill"]
	var fill_colors: = [fc[0], fc[1], fc[0], fc[1]]
	for i in 4:
		var a7: = float(i) * PI * 0.5 + PI * 0.25
		var om: = OmniLight3D.new()
		om.position = Vector3(sin(a7), 0, cos(a7)) * 11.0 + Vector3(0, 3.5, 0)
		om.omni_range = 12.0
		om.light_energy = float(v["fill_e"])
		om.light_color = fill_colors[i]
		om.light_volumetric_fog_energy = 0.3
		root.add_child(om)


static func _build_physics(root: Node3D) -> void :

	var body: = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	root.add_child(body)
	var floor_cs: = CollisionShape3D.new()
	var fb: = BoxShape3D.new()
	fb.size = Vector3(APRON_HALF * 2.0, 0.2, APRON_HALF * 2.0)
	floor_cs.shape = fb
	floor_cs.position = Vector3(0, -0.1, 0)
	body.add_child(floor_cs)
	for i in 4:
		var aw: = float(i) * PI * 0.5
		var wall: = CollisionShape3D.new()
		var wb: = BoxShape3D.new()
		wb.size = Vector3(ROPE_HALF * 2.0 + 0.8, 1.6, 0.4)
		wall.shape = wb

		wall.position = Vector3(sin(aw), 0, cos(aw)) * (ROPE_HALF + 0.32) + Vector3(0, 0.8, 0)
		wall.rotation.y = aw
		body.add_child(wall)



static func _build_walls(root: Node3D, v: Dictionary) -> void :
	var d: = float(v.get("wall_d", 8.5))
	var h: = float(v.get("wall_h", 6.0))
	var sh: = Shader.new()
	sh.code = BRICK_SHADER
	var wm: = ShaderMaterial.new()
	wm.shader = sh
	var gym: = str(v["walls"]) == "gym"
	wm.set_shader_parameter("paint", 0.82 if gym else 0.0)
	for i in 4:
		var a: = float(i) * PI * 0.5
		var n: = Vector3(sin(a), 0, cos(a))
		var w: = _add_mesh(root, _box(Vector3(d * 2.0, h, 0.3)), wm, n * d + Vector3(0, - RING_HEIGHT + h * 0.5, 0))
		w.rotation.y = a
	var ceil_mat: = _mat(Color(0.09, 0.09, 0.1) if not gym else Color(0.6, 0.6, 0.62), 0.9)
	_add_mesh(root, _box(Vector3(d * 2.0, 0.2, d * 2.0)), ceil_mat, Vector3(0, - RING_HEIGHT + h, 0))

	var beam_mat: = _mat(Color(0.12, 0.12, 0.13), 0.5, 0.7)
	for k in [-1, 1]:
		_add_mesh(root, _box(Vector3(d * 2.0, 0.25, 0.25)), beam_mat, Vector3(0, - RING_HEIGHT + h - 0.3, float(k) * d * 0.45))
	if not gym:

		var sign_l: = _label(root, "БОКСЁРСКИЙ КЛУБ  •  FINAL BELL", Vector3(0, 2.6, - d + 0.17), Vector3.ZERO, 140, Color(1.0, 0.55, 0.2), 0.0045)
		sign_l.shaded = false
		sign_l.modulate = Color(1.0, 0.55, 0.2)
		for x in [-2.0, 0.0, 2.0]:
			var shade: = CylinderMesh.new()
			shade.top_radius = 0.12
			shade.bottom_radius = 0.55
			shade.height = 0.35
			_add_mesh(root, shade, _mat(Color(0.08, 0.2, 0.12), 0.4, 0.6), Vector3(x, 4.2, 0))



static func _build_gym(root: Node3D) -> void :
	var floor_y: = - RING_HEIGHT
	var mat_m: = _mat(Color(0.07, 0.07, 0.08), 0.95)
	_textured(mat_m, Color(0.05, 0.05, 0.06), Color(0.09, 0.09, 0.1), 0.05, "cotton", 0.4, 12.0)
	for i in 6:
		var mx: = -6.0 + float(i) * 2.4
		_add_mesh(root, _box(Vector3(2.3, 0.04, 2.3)), mat_m, Vector3(mx, floor_y + 0.02, 6.0))
	var leather: = [_mat(Color(0.5, 0.05, 0.05), 0.45), _mat(Color(0.05, 0.05, 0.06), 0.4), _mat(Color(0.1, 0.18, 0.5), 0.45)]
	var chain: = _mat(Color(0.5, 0.5, 0.52), 0.3, 0.9)
	var bag_pos: = [Vector3(-5.6, 0, 5.4), Vector3(-3.2, 0, 5.8), Vector3(3.2, 0, 5.8), Vector3(5.6, 0, 5.4), 
		Vector3(-6.2, 0, -3.0), Vector3(6.2, 0, -3.0)]
	for i in bag_pos.size():
		var bp: Vector3 = bag_pos[i]
		var bag: = _cyl(0.19, 1.15)
		_add_mesh(root, bag, leather[i % 3], bp + Vector3(0, floor_y + 1.05, 0))
		_add_mesh(root, _cyl(0.012, 2.4), chain, bp + Vector3(0, floor_y + 2.85, 0))

	var plat_m: = _mat(Color(0.3, 0.2, 0.12), 0.6)
	_add_mesh(root, _box(Vector3(0.9, 0.08, 0.7)), plat_m, Vector3(-7.2, floor_y + 2.3, 1.5))
	var sb: = SphereMesh.new()
	sb.radius = 0.11
	sb.height = 0.3
	_add_mesh(root, sb, leather[0], Vector3(-7.2, floor_y + 2.05, 1.5))

	var mirror: = StandardMaterial3D.new()
	mirror.albedo_color = Color(0.85, 0.88, 0.9)
	mirror.metallic = 1.0
	mirror.roughness = 0.03
	var mw: = _add_mesh(root, _box(Vector3(9.0, 2.2, 0.03)), mirror, Vector3(0, floor_y + 1.4, -7.8))
	mw.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_mesh(root, _box(Vector3(9.2, 0.06, 0.06)), chain, Vector3(0, floor_y + 2.53, -7.78))

	var posters: = [["FINAL BELL GYM", Color(0.95, 0.75, 0.25)], ["РАБОТАЙ НОГАМИ", Color(0.9, 0.2, 0.15)], 
		["ДЖЕБ — ЛУЧШИЙ ДРУГ", Color(0.85, 0.85, 0.85)], ["РУКИ У ЛИЦА", Color(0.3, 0.55, 0.95)]]
	for i in posters.size():
		var a: = PI * 0.5 if i < 2 else - PI * 0.5
		var x: = -7.83 if i < 2 else 7.83
		var z: = -2.5 + float(i % 2) * 5.0
		var pl: = _label(root, str(posters[i][0]), Vector3(x, 1.9, z * 1.2), Vector3(0, a, 0), 110, posters[i][1], 0.0035)
		pl.shaded = true

	var bench: = _mat(Color(0.12, 0.12, 0.13), 0.6, 0.4)
	_add_mesh(root, _box(Vector3(2.2, 0.45, 0.45)), bench, Vector3(4.5, floor_y + 0.22, -6.8))
	for k in 4:
		var g: = SphereMesh.new()
		g.radius = 0.13
		g.height = 0.3
		_add_mesh(root, g, leather[k % 3], Vector3(3.6 + float(k) * 0.55, floor_y + 1.4, -7.6))

	var tube: = _mat(Color(0.9, 0.95, 1.0), 0.3)
	tube.emission_enabled = true
	tube.emission = Color(0.9, 0.96, 1.0)
	tube.emission_energy_multiplier = 4.0
	for x in [-5.0, 0.0, 5.0]:
		for z in [-4.5, 4.5]:
			var t: = _add_mesh(root, _box(Vector3(1.6, 0.05, 0.12)), tube, Vector3(x, 3.85, z))
			t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var om: = OmniLight3D.new()
			om.position = Vector3(x, 3.6, z)
			om.omni_range = 7.0
			om.light_energy = 0.8
			om.light_color = Color(0.92, 0.97, 1.0)
			om.shadow_enabled = false
			root.add_child(om)


static var _noise_cache: Dictionary = {}



static func _textured(m: StandardMaterial3D, c0: Color, c1: Color, freq: float, nkind: String, nstrength: float, uv: float) -> void :
	var key: = "%s|%s|%.3f" % [c0, c1, freq]
	var tex: NoiseTexture2D = _noise_cache.get(key)
	if tex == null:
		var n: = FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.frequency = freq
		n.fractal_octaves = 5
		tex = NoiseTexture2D.new()
		tex.width = 1024
		tex.height = 1024
		tex.seamless = true
		var g: = Gradient.new()
		g.set_color(0, c0)
		g.set_color(1, c1)
		tex.color_ramp = g
		tex.noise = n
		_noise_cache[key] = tex
	m.albedo_texture = tex
	m.albedo_color = Color(1, 1, 1)
	m.normal_enabled = true
	m.normal_texture = MixamoRig._detail_normal(nkind)
	m.normal_scale = nstrength
	m.uv1_scale = Vector3(uv, uv, uv)



static func _tube_xf(a: Vector3, b: Vector3, r: float) -> Transform3D:
	var d: = b - a
	var ln: = d.length()
	var y: = d / maxf(ln, 0.0001)
	var x: = y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z: = x.cross(y).normalized()
	return Transform3D(Basis(x * r, y * ln, z * r), (a + b) * 0.5)


static func _build_truss(root: Node3D, mat: Material) -> void :
	var xf: Array[Transform3D] = []
	var h: = 7.2
	var rad: = 3.6
	var half: = 0.18
	var length: = 7.6
	for side in 4:
		var a: = float(side) * PI * 0.5
		var nrm: = Vector3(sin(a), 0, cos(a))
		var tg: = Vector3(cos(a), 0, - sin(a))
		var c0: = nrm * rad + Vector3(0, h, 0)
		var offs: = [Vector2( - half, - half), Vector2(half, - half), Vector2(half, half), Vector2( - half, half)]
		for o in offs:
			var ov: Vector2 = o
			var base: = c0 + nrm * ov.x + Vector3(0, ov.y, 0)
			xf.append(_tube_xf(base - tg * length * 0.5, base + tg * length * 0.5, 0.025))
		var steps: = 12
		for k in steps:
			var t0: = - length * 0.5 + length * float(k) / float(steps)
			var t1: = - length * 0.5 + length * float(k + 1) / float(steps)
			for fi in 4:
				var p: Vector2 = offs[fi]
				var q: Vector2 = offs[(fi + 1) % 4]
				var pa: = c0 + nrm * p.x + Vector3(0, p.y, 0) + tg * (t0 if k % 2 == 0 else t1)
				var pb: = c0 + nrm * q.x + Vector3(0, q.y, 0) + tg * (t1 if k % 2 == 0 else t0)
				xf.append(_tube_xf(pa, pb, 0.012))
	var cyl: = CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 1.0
	cyl.radial_segments = 8
	cyl.rings = 1
	var mm: = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cyl
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
	var mmi: = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	root.add_child(mmi)

	var can_mat: = _mat(Color(0.05, 0.05, 0.06), 0.4, 0.6)
	var lens_mat: = _mat(Color(1, 0.97, 0.9), 0.2)
	lens_mat.emission_enabled = true
	lens_mat.emission = Color(1.0, 0.94, 0.82)
	lens_mat.emission_energy_multiplier = 9.0
	var can: = _cyl(0.1, 0.26)
	var lens: = _cyl(0.085, 0.01)
	for side in 4:
		var a: = float(side) * PI * 0.5
		var nrm: = Vector3(sin(a), 0, cos(a))
		var tg: = Vector3(cos(a), 0, - sin(a))
		for j in 6:
			var off: = (float(j) - 2.5) * 1.2
			var p: = nrm * rad + tg * off + Vector3(0, h - 0.36, 0)
			var aim: = Vector3(0, 0.6, 0) + tg * off * 0.25
			var holder: = Node3D.new()
			root.add_child(holder)
			holder.look_at_from_position(p, aim, Vector3.UP)
			var c: = _add_mesh(holder, can, can_mat, Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var l: = _add_mesh(holder, lens, lens_mat, Vector3(0, 0, -0.135), Vector3(PI * 0.5, 0, 0))
			l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF



static func _corner_props(root: Node3D) -> void :
	var step_mat: = _mat(Color(0.08, 0.08, 0.1), 0.7)
	var metal: = _mat(Color(0.7, 0.7, 0.72), 0.3, 0.9)
	for key in ["red", "blue"]:
		var c: Vector3 = CORNERS[key]
		var dir: = Vector3(signf(c.x), 0, signf(c.z))
		var col: Color = Color(0.7, 0.07, 0.07) if key == "red" else Color(0.07, 0.17, 0.65)

		for k in 3:
			var hgt: = RING_HEIGHT * float(3 - k) / 3.0
			var pos: = dir * (APRON_HALF + 0.35 + float(k) * 0.35) * 0.7071 * 1.41 + Vector3(0, - RING_HEIGHT + hgt * 0.5, 0)
			var st: = _add_mesh(root, _box(Vector3(0.9, hgt, 0.34)), step_mat, pos)
			st.rotation.y = atan2(dir.x, dir.z)

		var sp: = dir * (ROPE_HALF + 0.3) + Vector3(0, 0, 0)
		var seat_mat: = _mat(col, 0.6)
		_add_mesh(root, _cyl(0.19, 0.05), seat_mat, sp + Vector3(0, 0.52, 0))
		for lg in 4:
			var la: = float(lg) * PI * 0.5 + PI * 0.25
			_add_mesh(root, _cyl(0.012, 0.5), metal, sp + Vector3(cos(la), 0, sin(la)) * 0.13 + Vector3(0, 0.25, 0))
		var bucket: = CylinderMesh.new()
		bucket.top_radius = 0.15
		bucket.bottom_radius = 0.12
		bucket.height = 0.3
		bucket.radial_segments = 16
		var side: = Vector3( - dir.z, 0, dir.x) * 0.42
		_add_mesh(root, bucket, _mat(col.lightened(0.1), 0.5), sp + side + Vector3(0, 0.15, 0))
		var bottle: = _cyl(0.035, 0.22)
		_add_mesh(root, bottle, _mat(Color(0.85, 0.9, 0.95), 0.1), sp - side + Vector3(0, 0.11, 0))


static func _build_crowd(root: Node3D, rows: int = 14) -> Array:
	if ResourceLoader.exists(CROWD_ATLAS):
		var tex: Texture2DArray = load(CROWD_ATLAS)
		if tex:
			return _build_sprite_crowd(root, tex, rows)
	return _build_capsule_crowd(root, rows)




static func _build_sprite_crowd(root: Node3D, tex: Texture2DArray, rows: int = 14) -> Array:
	var rng: = RandomNumberGenerator.new()
	rng.seed = 4242
	var mat: = ShaderMaterial.new()
	var sh: = Shader.new()
	sh.code = SPRITE_CROWD_SHADER
	mat.shader = sh
	mat.set_shader_parameter("atlas", tex)
	var layers: = tex.get_layers()
	var quad: = QuadMesh.new()
	quad.size = Vector2(1.05, 2.1)
	quad.center_offset = Vector3(0, 1.0, 0)
	var xf: Array[Transform3D] = []
	var cols: Array[Color] = []
	var cds: Array[Color] = []
	for side in 4:
		var a: = float(side) * PI * 0.5
		var normal: = Vector3(sin(a), 0, cos(a))
		var tangent: = Vector3(cos(a), 0, - sin(a))
		for row in rows:
			var d: = 6.3 + float(row) * 0.85
			var base_y: = - RING_HEIGHT + float(row) * 0.42
			var half: = d - 0.4
			var count: = int(half * 2.0 / 0.58)
			for k in count:
				var along: = - half + (float(k) + 0.5) * (half * 2.0 / float(count))
				if absf(fposmod(along + 20.0, 6.0) - 3.0) < 0.35:
					continue
				if rng.randf() < 0.05:
					continue
				var p: = normal * (d + rng.randf_range(-0.08, 0.08)) + tangent * (along + rng.randf_range(-0.08, 0.08))
				p.y = base_y
				var sc: = rng.randf_range(0.94, 1.06)
				xf.append(Transform3D(Basis.from_scale(Vector3.ONE * sc), p))
				var lum: = lerpf(0.045, 0.008, pow(float(row) / 13.0, 0.6)) * rng.randf_range(0.65, 1.05)
				cols.append(Color(lum * 0.95, lum * 0.97, lum * 1.08))
				cds.append(Color(float(rng.randi() % layers) / 255.0, rng.randf(), rng.randf(), rng.randf()))
	var mm: = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
		mm.set_instance_color(i, cols[i])
		mm.set_instance_custom_data(i, cds[i])
	var mmi: = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)
	return [mat]


static func _build_capsule_crowd(root: Node3D, rows: int = 14) -> Array:
	var rng: = RandomNumberGenerator.new()
	rng.seed = 4242
	var shader: = Shader.new()
	shader.code = CROWD_SHADER
	var body_mat: = ShaderMaterial.new()
	body_mat.shader = shader
	body_mat.set_shader_parameter("is_head", false)
	var head_mat: = ShaderMaterial.new()
	head_mat.shader = shader
	head_mat.set_shader_parameter("is_head", true)

	var body_mesh: = CapsuleMesh.new()
	body_mesh.radius = 0.2
	body_mesh.height = 0.72
	body_mesh.radial_segments = 8
	body_mesh.rings = 2
	var head_mesh: = SphereMesh.new()
	head_mesh.radius = 0.11
	head_mesh.height = 0.24
	head_mesh.radial_segments = 8
	head_mesh.rings = 4

	var bodies: Array[Transform3D] = []
	var heads: Array[Transform3D] = []
	var body_cols: Array[Color] = []
	var head_cols: Array[Color] = []
	var clothes: = [Color(0.08, 0.1, 0.2), Color(0.15, 0.15, 0.16), Color(0.04, 0.04, 0.05), Color(0.35, 0.06, 0.06), 
		Color(0.7, 0.7, 0.72), Color(0.12, 0.25, 0.15), Color(0.4, 0.3, 0.15), Color(0.2, 0.08, 0.3)]
	for side in 4:
		var a: = float(side) * PI * 0.5
		var normal: = Vector3(sin(a), 0, cos(a))
		var tangent: = Vector3(cos(a), 0, - sin(a))
		for row in rows:
			var d: = 6.3 + float(row) * 0.85
			var base_y: = - RING_HEIGHT + float(row) * 0.42
			var half: = d - 0.4
			var count: = int(half * 2.0 / 0.62)
			for k in count:
				var along: = - half + (float(k) + 0.5) * (half * 2.0 / float(count))
				if absf(fposmod(along + 20.0, 6.0) - 3.0) < 0.35:
					continue
				if rng.randf() < 0.07:
					continue
				var p: = normal * (d + rng.randf_range(-0.05, 0.05)) + tangent * (along + rng.randf_range(-0.06, 0.06))
				p.y = base_y
				var sc: = rng.randf_range(0.92, 1.08)
				var bt: = Transform3D(Basis.from_scale(Vector3.ONE * sc), p + Vector3(0, 0.5 * sc, 0))
				var ht: = Transform3D(Basis.from_scale(Vector3.ONE * sc), p + Vector3(0, 1.02 * sc, 0))
				bodies.append(bt)
				heads.append(ht)
				var cc: Color = clothes[rng.randi() % clothes.size()]
				body_cols.append(cc * rng.randf_range(0.6, 1.0))
				var sk: Color = Roster.SKIN_TONES[rng.randi() % Roster.SKIN_TONES.size()]
				head_cols.append(sk * 0.75)
	_make_multimesh(root, body_mesh, body_mat, bodies, body_cols)
	_make_multimesh(root, head_mesh, head_mat, heads, head_cols)
	return [body_mat, head_mat]


static func _make_multimesh(root: Node3D, mesh: Mesh, mat: Material, xforms: Array[Transform3D], cols: Array[Color]) -> void :
	var mm: = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, cols[i])
	var mmi: = MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)


static func set_crowd(refs: Dictionary, excitement: float, flash: float) -> void :
	if not refs.has("crowd_materials"):
		return
	for m in refs["crowd_materials"]:
		var sm: ShaderMaterial = m
		sm.set_shader_parameter("excitement", clampf(excitement, 0.0, 1.0))
		sm.set_shader_parameter("flash_boost", clampf(flash, 0.0, 1.0))


static func set_board(refs: Dictionary, text: String) -> void :
	if not refs.has("board_labels"):
		return
	for l in refs["board_labels"]:
		var lb: Label3D = l
		lb.text = text
