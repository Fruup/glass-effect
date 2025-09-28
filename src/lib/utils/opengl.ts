import vertexShaderSource from '$lib/shaders/vertex.glsl?raw';
import fragmentShaderSource from '$lib/shaders/fragment.glsl?raw';

function createShader(gl: WebGL2RenderingContext, type: number, source: string) {
	const shader = gl.createShader(type);
	if (!shader) throw new Error('Unable to create shader');

	gl.shaderSource(shader, source);
	gl.compileShader(shader);
	const success = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
	if (success) return shader;

	console.log(gl.getShaderInfoLog(shader));
	gl.deleteShader(shader);
	return undefined;
}

function createProgram(
	gl: WebGL2RenderingContext,
	vertexShader: WebGLShader,
	fragmentShader: WebGLShader,
) {
	const program = gl.createProgram();
	gl.attachShader(program, vertexShader);
	gl.attachShader(program, fragmentShader);
	gl.linkProgram(program);
	const success = gl.getProgramParameter(program, gl.LINK_STATUS);
	if (success) {
		return program;
	}

	console.log(gl.getProgramInfoLog(program));
	gl.deleteProgram(program);
	return undefined;
}

export function setup(canvas: HTMLCanvasElement) {
	// Get A WebGL context
	const gl = canvas.getContext('webgl2')!;
	if (!gl) throw new Error('Unable to get WebGL context');

	// create GLSL shaders, upload the GLSL source, compile the shaders
	const vertexShader = createShader(gl, gl.VERTEX_SHADER, vertexShaderSource);
	if (!vertexShader) throw new Error('Unable to create vertex shader');

	const fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, fragmentShaderSource)!;
	if (!fragmentShader) throw new Error('Unable to create fragment shader');

	// Link the two shaders into a program
	const program = createProgram(gl, vertexShader, fragmentShader)!;
	if (!program) throw new Error('Unable to create program');

	// look up where the vertex data needs to go.
	const positionAttributeLocation = gl.getAttribLocation(program, 'a_position');

	// Create a buffer and put three 2d clip space points in it
	const positionBuffer = gl.createBuffer();

	// Bind it to ARRAY_BUFFER (think of it as ARRAY_BUFFER = positionBuffer)
	gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);

	const positions = [-1, -1, -1, 1, 1, 1, 1, -1];
	gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(positions), gl.STATIC_DRAW);

	// Create a vertex array object (attribute state)
	const vao = gl.createVertexArray();

	// and make it the one we're currently working with
	gl.bindVertexArray(vao);

	// Turn on the attribute
	gl.enableVertexAttribArray(positionAttributeLocation);

	// Tell the attribute how to get data out of positionBuffer (ARRAY_BUFFER)
	const size = 2; // 2 components per iteration
	const type = gl.FLOAT; // the data is 32bit floats
	const normalize = false; // don't normalize the data
	const stride = 0; // 0 = move forward size * sizeof(type) each iteration to get the next position
	var offset = 0; // start at the beginning of the buffer
	gl.vertexAttribPointer(positionAttributeLocation, size, type, normalize, stride, offset);

	// Tell WebGL how to convert from clip space to pixels
	gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);

	// Clear the canvas
	gl.clearColor(0, 0, 0, 0);
	gl.clear(gl.COLOR_BUFFER_BIT);

	// Tell it to use our program (pair of shaders)
	gl.useProgram(program);

	gl.uniform2f(gl.getUniformLocation(program, 'i_resolution'), gl.canvas.width, gl.canvas.height);

	// Bind the attribute/buffer set we want.
	gl.bindVertexArray(vao);

	let currentTexture: WebGLTexture | null = null;

	return {
		gl,
		// setMousePosition() {},
		setTexture(image: TexImageSource) {
			if (currentTexture) gl.deleteTexture(currentTexture);

			currentTexture = gl.createTexture();

			gl.bindTexture(gl.TEXTURE_2D, currentTexture);
			gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
			// gl.generateMipmap(gl.TEXTURE_2D);

			gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
			gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
			gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
			gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

			gl.activeTexture(gl.TEXTURE0);
			gl.bindTexture(gl.TEXTURE_2D, currentTexture);
			gl.uniform1i(gl.getUniformLocation(program, 'u_texture'), 0);
		},
		setUV(u: number, v: number) {
			gl.uniform2f(gl.getUniformLocation(program, 'i_uv'), u, v);
		},
		draw() {
			const primitiveType = gl.TRIANGLE_FAN;
			gl.drawArrays(primitiveType, /* offset */ 0, /* count */ 4);
		},
	};
}
