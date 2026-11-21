// Канат профессионального ринга: трос в мягком виниловом чехле (как на реальных турнирах) —
// гладкий, с мягким полуматовым бликом, едва заметной продольной «гармошкой» чехла и потёртостями.
// UV цилиндра: x — по окружности, y — вдоль сегмента 0.29 м.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 color : source_color = vec4(0.8, 0.1, 0.1, 1.0);
uniform float strands = 3.0;   // не используется (совместимость с прежними параметрами)
uniform float twist = 3.0;
varying vec3 wp;

float h1(float x) { return fract(sin(x * 127.1) * 43758.5453); }
float vnoise(float x) {
	float i = floor(x);
	float f = fract(x);
	return mix(h1(i), h1(i + 1.0), f * f * (3.0 - 2.0 * f));
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// координата вдоль каната (непрерывная между сегментами): по мировым x+z
	float along = (wp.x + wp.z) * 1.0;
	// мягкие складки чехла: редкие неровные кольца
	float wr = vnoise(along * 9.0) * 0.6 + vnoise(along * 23.0 + 3.1) * 0.4;
	float ring = sin(along * 38.0 + wr * 6.0) * 0.5 + 0.5;
	// потёртости и грязь: темнее и матовее местами
	float dirt = smoothstep(0.55, 0.95, vnoise(along * 3.3 + UV.x * 2.0) * 0.7 + vnoise(along * 17.0) * 0.3);
	vec3 base = color.rgb * (0.93 + 0.07 * wr);
	ALBEDO = mix(base, base * 0.72 + vec3(0.02, 0.018, 0.015), dirt * 0.45);
	ROUGHNESS = mix(0.38, 0.62, dirt) + ring * 0.05;
	SPECULAR = 0.42;
	CLEARCOAT = 0.12 * (1.0 - dirt);
	CLEARCOAT_ROUGHNESS = 0.35;
	NORMAL_MAP = vec3(0.5, 0.5 + (ring - 0.5) * 0.08 + (wr - 0.5) * 0.06, 1.0);
	NORMAL_MAP_DEPTH = 1.0;
}
