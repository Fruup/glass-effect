#version 300 es

#define PI 3.1415926535897932384626433832795

// fragment shaders don't have a default precision so we need
// to pick one. highp is a good default. It means "high precision"
precision highp float;

uniform vec2 i_resolution;
uniform vec2 i_uv;

uniform int i_blur_radius;
uniform vec4 i_background_color;
uniform float i_background_color_mix;
uniform float i_border_radius;

uniform sampler2D u_texture;

const float refraction_strength = 5.0f;

// we need to declare an output for the fragment shader
out vec4 outColor;

// https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection.html
vec2 ray_circle_intersection_far(
	vec2 O,
	vec2 D, // MUST BE NORMALIZED
	vec2 C,
	float r,
	out bool intersecting
) {
	vec2 L = C - O;
	float t_ca = dot(L, (D));
	if(t_ca < 0.0f) {
		intersecting = false;
		return vec2(0.0f);
	}

	float d = sqrt(dot(L, L) - t_ca * t_ca);
	if(d > r) {
		intersecting = false;
		return vec2(0.0f);
	}

	float t_hc = sqrt(r * r - d * d);
	float t1 = t_ca + t_hc;

	intersecting = true;
	return vec2(O + t1 * (D));
}

vec2 project_onto_border(vec2 x, vec2 bounds, float border_radius) {
	if(x.x == 0.0f && x.y == 0.0f) {
		return vec2(0.0f, bounds.y);
	}

	vec2 r = abs(x);

	// top
	if(bounds.y * r.x - (bounds.x - border_radius) * r.y <= 0.0f) {
		return sign(x) * vec2(r.x * bounds.y / r.y, bounds.y);
	}
	// right
	else if((bounds.y - border_radius) * r.x - bounds.x * r.y >= 0.0f) {
		return sign(x) * vec2(bounds.x, r.y * bounds.x / r.x);
	}
	// corner
	else {
		bool _;
		vec2 intersection = ray_circle_intersection_far(vec2(0.0f), normalize(r), bounds - vec2(border_radius), border_radius, _);
		if(!_) {
			discard;
		}
		return sign(x) * intersection;
	}
}

vec3 lense_normal_1(
	vec2 r,
	vec2 bounds,
	float border_radius,
	float exponent,
	/* [0, 1], 1 meaning 90 degrees */
	float end_angle,
	out bool is_inside
) {
	vec2 point_on_border = project_onto_border(r, bounds, border_radius);

	float t = length(r) / length(point_on_border);

	if(t == 0.0f) {
		is_inside = true;
		return vec3(0.0f, 0.0f, -1.0f);
	} else if(t > 1.0f) {
		is_inside = false;
		return vec3(0.0f);
	}

	is_inside = true;

	float angle = 0.5f * PI * end_angle * pow(t, exponent);

	vec2 dir = normalize(r);
	float cos_angle = cos(angle);
	float sin_angle = sin(angle);
	return vec3(dir * sin_angle, -cos_angle);
}

void main() {
	vec2 bg_resolution = vec2(textureSize(u_texture, 0).xy);

	// debug: just show the texture
#if 0
	vec2 _uv = i_uv + gl_FragCoord.xy / bg_resolution;
	_uv.y = 1.0f - _uv.y;
	outColor = vec4(texture(u_texture, _uv).rgb, 1.0f);
	return;
#endif

	vec2 r = 2.0f * (gl_FragCoord.xy - 0.5f * i_resolution) / i_resolution.y;

	bool is_inside;
	vec3 normal = lense_normal_1(r, i_resolution / i_resolution.y, i_border_radius, 1.0f, 1.0f, is_inside);

	if(!is_inside)
		discard;

	// debug: show normal
#if 0
	// outColor = vec4(normal, 1.0f);
	outColor = vec4(normal * .5f + .5f, 1.0f);
	return;
#endif

	vec2 uv_offset = refraction_strength * normal.xy / normal.z;

	// debug: show refracted ray
#if 0
	outColor = vec4((uv_offset) / refraction_strength, 0.f, 1.0f);
	return;
#endif

	vec2 uv = i_uv + (gl_FragCoord.xy + uv_offset) / bg_resolution;

	uv.y = 1.0f - uv.y;
	vec3 col = texture(u_texture, uv).xyz;

	// TODO: Blur image beforehand to improve performance
#if 1
		// blur
	int N = i_blur_radius;
	if(N > 0) {
		float sum = 0.0f;
		vec3 blur = vec3(0.0f);

		for(int i = -N; i < N; i++) {
			for(int j = -N; j < N; j++) {
				float factor = exp(-(float(i * i + j * j)) / float(N * N) * 4.0f);
				sum += factor;

				blur += factor * texture(u_texture, uv + vec2(i, j) / bg_resolution).xyz;
			}
		}

		col = blur / sum;
	}
#endif

	float edge_factor = dot(normal, vec3(0.0f, 0.0f, -1.0f));

	col = mix(col, i_background_color.rgb, i_background_color_mix * pow(edge_factor, 0.2f));
	col = mix(i_background_color.rgb, col, pow(edge_factor, 0.1f));

	outColor = vec4(col, 1.0f);
}
