vec3 lense_normal(vec2 r_) {
	float flatness = 7.0;
	float offset = 0.1;
	float radius = 0.1;

	vec2 r = r_ / radius;

	if(length(r) > 1.0) {
		return vec3(0.0, 0.0, 1.0);
	}

	vec3 n = normalize(vec3(r, pow(length(r), flatness) - 1.0));

	return refract(vec3(0.0, 0.0, 1.0), n, 1.0 / 1.5);
}

void main() {
	vec2 frag = gl_FragCoord.xy;
	gl_FragColor = vec4(frag, 0., 0.);
	return;

	// vec3 normal = lense_normal(frag - iMouse.xy / iResolution.y);

	// vec2 uv = frag + 0.1 * normal.xy / normal.z;

	// vec3 col = texture(iChannel0, uv).xyz;

	// gl_FragColor = vec4(col, 1.0);
}
