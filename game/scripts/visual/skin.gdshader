// Кожа бойца: SSS, поры, пот и повреждения, которые копятся по ходу боя.
// Маска повреждений (одна на всех, в UV базовой сетки MPFB):
//   R — синяки/отёки, G — рассечение брови + струйка крови, B — кровь из носа на губы и подбородок.
//   Значение канала — «порог»: чем оно выше, тем раньше участок проявляется.
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D pores_tex : hint_normal, filter_linear_mipmap;
uniform float pores_strength = 0.14;
uniform sampler2D dmg_mask : hint_default_black, filter_linear_mipmap;
uniform sampler2D grain_tex : hint_default_white, filter_linear_mipmap;
// зоны: R — волосистая часть головы, G — пороги брызг крови на теле
uniform sampler2D zones_tex : hint_default_black, filter_linear_mipmap;
uniform float spatter : hint_range(0.0, 1.0) = 0.0;
uniform float bruise : hint_range(0.0, 1.0) = 0.0;
uniform float cut : hint_range(0.0, 1.0) = 0.0;
uniform float blood : hint_range(0.0, 1.0) = 0.0;
uniform float sweat : hint_range(0.0, 1.0) = 0.0;
uniform float roughness_base = 0.56;
// рельеф мышц (запечён с мускулистого эталона в общей UV): нормали + AO в ложбинках
uniform sampler2D detail_nrm : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D cavity_tex : hint_default_white, filter_linear_mipmap;
uniform float muscle_strength = 1.0;
uniform float cavity_strength = 0.5;
uniform float sss = 0.35;
// микрорельеф кожи (поры, сетка микроморщин), тайлится в двух масштабах — детализация крупнее 4K
uniform sampler2D micro_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float micro_strength = 0.32;
uniform vec2 micro_scale = vec2(23.0, 57.0);

// порог «проявления»: участок с маской m виден, когда уровень lvl его догнал
float reveal(float m, float lvl, float soft) {
	return smoothstep(1.0 - lvl, 1.0 - lvl + soft, m) * step(0.015, m);
}

void vertex() {
	vec4 m = textureLod(dmg_mask, UV, 0.0);
	// отёк: надбровья и скулы «вспухают», заплывает глаз
	VERTEX += NORMAL * (smoothstep(0.3, 1.0, m.r) * bruise * bruise * 0.006 + smoothstep(0.7, 1.0, m.g) * cut * 0.0018);
}

void fragment() {
	vec3 skin = texture(albedo_tex, UV).rgb * tint.rgb;
	vec3 col = skin;
	vec4 m = texture(dmg_mask, UV);
	float n = texture(grain_tex, UV * 6.0).r;
	float n2 = texture(grain_tex, UV * 21.0 + vec2(0.37, 0.11)).r;
	// синяк: сначала покраснение, на сильном уроне — багрово-лиловый отёк; кожа просвечивает
	float b = clamp(m.r * bruise * 1.25 * (0.6 + 0.8 * n), 0.0, 1.0);
	float lum = dot(skin, vec3(0.3, 0.59, 0.11));
	vec3 redden = skin * vec3(1.08, 0.72, 0.7);
	vec3 deep = mix(skin * vec3(0.55, 0.34, 0.45), vec3(lum) * vec3(0.62, 0.36, 0.5), 0.35);
	col = mix(col, redden, smoothstep(0.05, 0.4, b) * 0.75);
	col = mix(col, deep, smoothstep(0.35, 0.95, b) * 0.85);
	// кровь: тонкий слой полупрозрачный, густой — тёмный; свежая — ярче, засохшая по краям — бурая
	// альбедо крови тёмное (линейное ~0.07): на любой коже она темнее и краснее самой кожи
	vec3 fresh = mix(vec3(0.075, 0.003, 0.005), skin * vec3(0.8, 0.08, 0.08), 0.3);
	vec3 dried = fresh * vec3(0.5, 0.9, 0.8);
	float c = reveal(m.g + (n2 - 0.5) * 0.06, cut, 0.12);
	float bl = reveal(m.b + (n2 - 0.5) * 0.08, blood, 0.14);
	float thick_c = smoothstep(0.0, 0.5, m.g) * c;
	float thick_b = smoothstep(0.0, 0.55, m.b) * bl;
	vec3 bc = mix(dried, fresh, smoothstep(0.35, 0.8, n2));
	col = mix(col, bc, clamp(thick_c * 0.95 + thick_b * 0.9, 0.0, 0.96));
	// сама рана — тёмная щель
	col = mix(col, vec3(0.018, 0.0, 0.002), smoothstep(0.82, 0.98, m.g) * smoothstep(0.25, 0.6, cut));
	// брызги крови (свои и соперника) на лице, груди, плечах
	vec4 z = texture(zones_tex, UV);
	float sp = reveal(z.g, spatter, 0.05);
	col = mix(col, bc, sp * 0.85);
	float scalp = z.r;
	// короткая стрижка: щетина темнее и матовее кожи, не блестит от пота
	col = mix(col, col * (0.86 + 0.1 * n2), scalp * 0.6);
	vec4 cv = texture(cavity_tex, UV);
	float cav = mix(1.0, cv.r, cavity_strength * (1.0 - scalp));
	ALBEDO = col * mix(1.0, cav, 0.6);
	AO = cav;
	AO_LIGHT_AFFECT = 0.35;
	float wet_blood = max(max(thick_c, thick_b), sp * 0.8);
	float wet = max(sweat * (0.45 + 0.4 * n2) * (1.0 - scalp * 0.85), wet_blood);
	// пот даёт лёгкий влажный блеск (не «масло»), свежая кровь — заметно глянцевее
	float sweat_k = sweat * smoothstep(0.25, 0.75, n2 * 0.7 + n * 0.5) * (1.0 - scalp * 0.85);
	float r0 = mix(roughness_base, 0.8, scalp);
	ROUGHNESS = min(mix(r0, 0.42, clamp(sweat_k, 0.0, 1.0)), mix(r0, 0.2, clamp(wet_blood, 0.0, 1.0)));
	SPECULAR = mix(0.32, 0.2, scalp) + sweat_k * 0.06 + wet_blood * 0.16;
	vec3 pn = mix(texture(pores_tex, UV).rgb, texture(pores_tex, UV * 2.7).rgb, scalp) * 2.0 - 1.0;
	float pd = pores_strength * (1.0 + scalp * 1.6) * (1.0 - wet_blood * 0.6);
	vec2 dn = texture(detail_nrm, UV).rg * 2.0 - 1.0;
	vec2 mn1 = texture(micro_nrm, UV * micro_scale.x).rg * 2.0 - 1.0;
	vec2 mn2 = texture(micro_nrm, UV * micro_scale.y + vec2(0.31, 0.17)).rg * 2.0 - 1.0;
	vec2 micro = (mn1 * 0.65 + mn2 * 0.45) * micro_strength * (1.0 - scalp * 0.5) * (1.0 - wet_blood * 0.7);
	// в ямках пор блик гаснет — кожа не «пластиковая»
	SPECULAR *= 1.0 - clamp(length(micro) * 1.6, 0.0, 0.45);
	vec2 nxy = pn.xy * pd + dn * muscle_strength * (1.0 - scalp) + micro;
	NORMAL_MAP = vec3(clamp(nxy, vec2(-0.95), vec2(0.95)) * 0.5 + 0.5, 1.0);
	NORMAL_MAP_DEPTH = 1.0;
	SSS_STRENGTH = sss * (1.0 - wet_blood * 0.7);
	// просвечивание: уши и нос краснеют в контровом свете прожекторов
	SSS_TRANSMITTANCE_COLOR = vec4(0.95, 0.28, 0.16, 1.0);
	SSS_TRANSMITTANCE_DEPTH = 0.12;
	SSS_TRANSMITTANCE_BOOST = 0.15;
	// второй, резкий блик — кожный жир и пот поверх матовой кожи (двухслойная кожа)
	CLEARCOAT = (0.02 + sweat_k * 0.16) * (1.0 - scalp);
	CLEARCOAT_ROUGHNESS = mix(0.55, 0.36, clamp(sweat_k, 0.0, 1.0));
}
