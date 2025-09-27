#version 300 es

// fragment shaders don't have a default precision so we need
// to pick one. highp is a good default. It means "high precision"
precision highp float;

uniform vec2 i_resolution;
uniform vec2 i_mouse_position;
uniform vec2 i_uv;

uniform sampler2D u_texture;

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

	// float flatness = 1.0f;
	float flatness = 15.0f;

	return normalize(vec3(-displacement, pow(length(displacement), flatness) - 1.0f));
}

void main() {
	vec2 bg_resolution = vec2(textureSize(u_texture, 0).xy) / 2.0f;

	// vec2 _uv = (i_uv + gl_FragCoord.xy) / bg_resolution;
	// _uv.y = 1.0f - _uv.y;
	// outColor = vec4(texture(u_texture, _uv).rgb, 1.0f);
	// return;

	vec2 r = 2.0f * (gl_FragCoord.xy - 0.5f * i_resolution) / i_resolution.y;

	// outColor = vec4(r, 0.0f, 1.0f);
	// return;

	// vec2 mouse = i_mouse_position / i_resolution.y;
	// mouse.y = 1.0f - mouse.y;

	// outColor = vec4(frag, 0.0f, 1.0f);
	// return;

	bool is_inside;
	vec3 normal = lense_normal(r, i_resolution / i_resolution.y, 1.0f, is_inside);

	if(!is_inside) {
		return;
	}

#if 0
	outColor = vec4(normal * .5f + .5f, 1.0f);
	return;
#endif

	vec3 refracted_ray = refract(vec3(0.0f, 0.0f, 1.0f), normal, 1.0f / 1.5f);
	vec2 uv_offset = 0.1f * refracted_ray.xy / refracted_ray.z;

	// outColor = vec4(refracted_ray * .5f + .5f, 1.0f);
	// return;

	// vec2 uv_ = vec2(0.0f, 0.0f) + 0.1f * r;

	// vec2 uv = i_uv + gl_FragCoord.xy / i_resolution.xy;

	// vec2 uv = (i_uv + gl_FragCoord.xy) / bg_resolution;
	vec2 uv = (i_uv + gl_FragCoord.xy) / bg_resolution + uv_offset;

	uv.y = 1.0f - uv.y;
	vec3 col = texture(u_texture, uv).xyz;

	// vec3 col = vec3(uv, 0.5f);

#if 1
	if(is_inside) {
		// blur
		const int N = 10;
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

	outColor = vec4(col, 1.0f);
}
