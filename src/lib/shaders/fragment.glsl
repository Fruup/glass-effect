#version 300 es

// fragment shaders don't have a default precision so we need
// to pick one. highp is a good default. It means "high precision"
precision highp float;

uniform vec2 i_resolution;
uniform vec2 i_mouse_position;
uniform vec2 i_uv;

uniform int i_blur_radius;
uniform vec4 i_background_color;
uniform float i_background_color_mix;
uniform float i_lense_flatness;
uniform float i_lense_height; // [0, 1]

uniform sampler2D u_texture;

// const float lense_flatness = 1.0f;
// const float lense_flatness = 7.0f;

const float lense_rim_size = 1.0f;
const float lense_border_radius = 1.0f;

const float refraction_strength = 0.05f;

// we need to declare an output for the fragment shader
out vec4 outColor;

vec3 lense_normal(vec2 r, vec2 bounds, float rim_size, out bool is_inside) {
	vec2 abs_r = abs(r);
	vec2 bounds_without_rim = bounds - vec2(rim_size);
	vec2 displacement = vec2(0.0f);

	// center
	if(abs_r.x <= bounds_without_rim.x && abs_r.y <= bounds_without_rim.y) {
		is_inside = true;
		return vec3(0.0f, 0.0f, -1.0f);
	}
	// top-center || bottom-center
	else if(abs_r.x <= bounds_without_rim.x && abs_r.y >= bounds_without_rim.y) {
		displacement.x = 0.0f;
		displacement.y = sign(r.y) * (abs_r.y - bounds_without_rim.y) / rim_size;
	}
	// left-center || right-center
	else if(abs_r.x >= bounds_without_rim.x && abs_r.y <= bounds_without_rim.y) {
		displacement.x = sign(r.x) * (abs_r.x - bounds_without_rim.x) / rim_size;
		displacement.y = 0.0f;
	}
	// corners
	else {
		vec2 r2 = abs_r - bounds_without_rim;

		if(dot(r2, r2) > rim_size * rim_size) {
			is_inside = false;
			return vec3(0.0f);
		}

		displacement.x = sign(r.x) * r2.x / rim_size;
		displacement.y = sign(r.y) * r2.y / rim_size;
	}

	is_inside = true;

	// return normalize(-vec3(displacement, i_lense_flatness + i_lense_height * (1.0f - length(displacement))));
	return normalize(-vec3(displacement, 1.0f - pow(length(displacement), i_lense_flatness)));
}

void main() {
	vec2 bg_resolution = vec2(textureSize(u_texture, 0).xy);

	// debug: just show the texture
#if 0
	vec2 _uv = (i_uv + gl_FragCoord.xy) / bg_resolution;
	_uv.y = 1.0f - _uv.y;
	outColor = vec4(texture(u_texture, _uv).rgb, 1.0f);
	return;
#endif

	vec2 r = 2.0f * (gl_FragCoord.xy - 0.5f * i_resolution) / i_resolution.y;

	// outColor = vec4(r, 0.0f, 1.0f);
	// return;

	// vec2 mouse = i_mouse_position / i_resolution.y;
	// mouse.y = 1.0f - mouse.y;

	// outColor = vec4(frag, 0.0f, 1.0f);
	// return;

	bool is_inside;
	vec3 normal = lense_normal(r, i_resolution / i_resolution.y, lense_rim_size, is_inside);

	if(!is_inside) {
		discard;
		return;
	}

	// debug: show normal
#if 0
	// outColor = vec4(normal, 1.0f);
	outColor = vec4(normal * .5f + .5f, 1.0f);
	return;
#endif

	float eta = 1.0f / 1.5f; // TODO: This should be configurable
	vec3 refracted_ray = refract(vec3(0.0f, 0.0f, 1.0f), normal, eta);
	vec2 uv_offset = -refracted_ray.xy / refracted_ray.z;
	// vec2 uv_offset = -refraction_strength * refracted_ray.xy / refracted_ray.z;
	// uv_offset.y *= -1.0f;
	// uv_offset.y = 1.0f - uv_offset.y;

	// debug: show refracted ray
#if 0
	outColor = vec4((uv_offset) / refraction_strength, 0.f, 1.0f);
	// outColor = vec4(refracted_ray, 1.0f);
	// outColor = vec4(refracted_ray * .5f + .5f, 1.0f);
	return;
#endif

#if 0
	vec2 uv = (i_uv + gl_FragCoord.xy) / bg_resolution;
#else
	// vec2 uv = (i_uv + gl_FragCoord.xy) / bg_resolution + uv_offset;
	vec2 uv = (i_uv + gl_FragCoord.xy + 100.0f * uv_offset) / bg_resolution;
#endif

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

	col = mix(col, i_background_color.rgb, i_background_color_mix);

	outColor = vec4(col, 1.0f);
}
