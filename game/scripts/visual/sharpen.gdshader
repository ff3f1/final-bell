// Финальная «картинка трансляции» поверх 3D, под HUD:
//  - контрастно-адаптивная резкость (по мотивам AMD CAS) — без «мыла» после MSAA/тумана/свечения;
//  - киношная тонировка: холодные тени, тёплые света, мягкое плечо светов (кожа не «пластиковая»);
//  - виньетка, лёгкая хроматическая аберрация к краям кадра и плёночное зерно (убирает «стерильность» CG).
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float sharpness : hint_range(0.0, 1.0) = 0.6;
uniform float grade : hint_range(0.0, 1.0) = 1.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.38;
uniform float grain : hint_range(0.0, 0.2) = 0.035;
uniform float aberration : hint_range(0.0, 3.0) = 1.0;
// вспышка удара: короткое «сжатие» кадра к центру (усиливает ощущение попадания)
uniform float impact : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 tap(vec2 uv) {
	return textureLod(screen_tex, uv, 0.0).rgb;
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	vec2 uv = SCREEN_UV;
	vec2 dc = uv - 0.5;
	float r2 = dot(dc, dc);
	// удар: мгновенный «зум-пульс»
	uv -= dc * impact * 0.012;
	// хроматическая аберрация: только к краям кадра, центр — чистый
	vec2 ca = dc * r2 * aberration * 0.006;
	vec3 c = vec3(tap(uv + ca).r, tap(uv).g, tap(uv - ca).b);
	vec3 n = tap(uv + vec2(0.0, -px.y));
	vec3 s = tap(uv + vec2(0.0, px.y));
	vec3 e = tap(uv + vec2(px.x, 0.0));
	vec3 w = tap(uv + vec2(-px.x, 0.0));
	vec3 mn = min(c, min(min(n, s), min(e, w)));
	vec3 mx = max(c, max(max(n, s), max(e, w)));
	vec3 amp = sqrt(clamp(min(mn, 1.0 - mx) / max(mx, vec3(1e-4)), 0.0, 1.0));
	vec3 wgt = amp * (-1.0 / mix(8.0, 4.5, sharpness)) * step(0.001, sharpness);
	vec3 res = (c + (n + s + e + w) * wgt) / (1.0 + 4.0 * wgt);
	res = clamp(res, 0.0, 1.0);
	// тонировка: тени в сине-зелёный, света в тёплый; чуть приглушаем пересвеченные «пластиковые» блики
	float l = dot(res, vec3(0.2126, 0.7152, 0.0722));
	vec3 shadow_t = vec3(0.92, 0.98, 1.08);
	vec3 high_t = vec3(1.05, 1.0, 0.93);
	vec3 toned = res * mix(shadow_t, high_t, smoothstep(0.05, 0.75, l));
	// мягкое «плечо»: блики не упираются в белый
	toned = mix(toned, 1.0 - exp(-toned * 1.9) * 1.0, 0.25);
	// лёгкая S-кривая контраста вокруг средних тонов
	toned = mix(toned, toned * toned * (3.0 - 2.0 * toned), 0.18);
	res = mix(res, toned, grade);
	// виньетка — взгляд в центр ринга, как у телеоператора
	float vig = smoothstep(0.85, 0.18, r2 * (1.0 + vignette));
	res *= mix(1.0, vig, vignette + impact * 0.25);
	// плёночное зерно: сильнее в тенях, меняется каждый кадр
	float g = hash(uv * vec2(1920.0, 1080.0) + fract(TIME * 7.13) * 100.0) - 0.5;
	res += g * grain * (1.0 - l * 0.7);
	COLOR = vec4(clamp(res, 0.0, 1.0), 1.0);
}
