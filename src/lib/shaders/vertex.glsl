#version 300 es

in vec4 a_position;

void main() {
	gl_Position = a_position + vec4(0.0f, -0, 0.0f, 0.0f);
}
