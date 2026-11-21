// Глаз: влажная роговица (второй резкий блик) и «живой» взгляд — радужка сдвигается по UV
// (gaze задаёт MixamoRig: быстрые саккады + взгляд на соперника). Костей глаз в скелете Mixamo нет.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec2 gaze = vec2(0.0);
uniform float wet = 1.0;

void fragment() {
	vec4 c = texture(albedo_tex, UV - gaze) * tint;
	ALBEDO = c.rgb;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.08;
	SPECULAR = 0.65;
	CLEARCOAT = wet;
	CLEARCOAT_ROUGHNESS = 0.02;
}
