shader_type spatial;

//render_mode ambient_light_disabled;

const float PI = 3.1415926536f;

uniform vec4 albedo : hint_color = vec4(1.0f);
uniform sampler2D albedo_texture : hint_albedo;
uniform bool clamp_diffuse_to_max = false;

uniform int cuts : hint_range(1, 8) = 3;
uniform float wrap : hint_range(-2.0f, 2.0f) = 0.0f;
uniform float steepness : hint_range(1.0f, 8.0f) = 1.0f;

uniform bool use_attenuation = false;

uniform bool use_specular = true;
uniform float specular_strength : hint_range(0.0f, 1.0f) = 1.0f;
uniform float specular_shininess : hint_range(0.0f, 32.0f) = 16.0f;
uniform sampler2D specular_map : hint_albedo;

uniform bool use_rim = true;
uniform float rim_width : hint_range(0.0f, 16.0f) = 8.0f;
uniform vec4 rim_color : hint_color = vec4(1.0f);

uniform bool use_ramp = false;
uniform sampler2D ramp : hint_albedo;

float staircase(int n, float x) {
	float res = 0.0f;
	float inc = 1.0f / float(n+1);
	for (float edge = 0.0f; edge < 1.0f - inc; edge+=inc) {
		res += step(edge, x);
	}
	return res / float(n);
}

float split_diffuse(float diffuse) {
	return staircase(cuts, diffuse*steepness);
}

float split_specular(float specular) {
	return step(0.5f, specular);
}

void fragment() {
	ALBEDO = albedo.rgb * texture(albedo_texture, UV).rgb;
}

void light() {
	// Attenuation.
	float attenuation = 1.0f;
	if (use_attenuation) {
		attenuation = ATTENUATION.x;
	}
	
	// Diffuse lighting.
	float NdotL = dot(NORMAL, LIGHT);
	float diffuse_amount = split_diffuse((NdotL * attenuation + wrap));
	
	vec3 diffuse = ALBEDO.rgb * LIGHT_COLOR / PI;
	if (use_ramp) {
		diffuse *= texture(ramp, vec2(diffuse_amount, 0.0f)).rgb;
	} else {
		diffuse *= diffuse_amount;
	}
	
	if (clamp_diffuse_to_max) {
		// Clamp diffuse to max for multiple light sources.
		DIFFUSE_LIGHT = max(DIFFUSE_LIGHT, diffuse);
	} else {
		DIFFUSE_LIGHT += diffuse;
	}
	
	// Specular lighting.
	if (use_specular) {
		vec3 H = normalize(LIGHT + VIEW);
		float NdotH = dot(NORMAL, H);
		float specular_amount = max(pow(NdotH, specular_shininess*specular_shininess), 0.0f)
							    * texture(specular_map, UV).r
								* attenuation;
		specular_amount = split_specular(specular_amount);
		SPECULAR_LIGHT += specular_strength * specular_amount * LIGHT_COLOR;
	}
	
	// Simple rim lighting.
	if (use_rim) {
		float NdotV = dot(NORMAL, VIEW);
		float rim_light = pow(1.0 - NdotV, rim_width);
		DIFFUSE_LIGHT += rim_light * rim_color.rgb * rim_color.a * LIGHT_COLOR / PI;
	}
}
