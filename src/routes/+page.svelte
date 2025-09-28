<script lang="ts">
	import vertexShaderSource from '$lib/shaders/vertex.glsl?raw';
	import fragmentShaderSource from '$lib/shaders/fragment.glsl?raw';
	import { onDestroy, onMount } from 'svelte';
	import { toCanvas } from 'html-to-image';
	import { debounce } from '$lib/utils/index.svelte';
	import { resolve } from '$app/paths';

	let canvas = $state() as HTMLCanvasElement;

	let gl: WebGL2RenderingContext;
	let fragmentShader: WebGLShader;
	let program: WebGLProgram;

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

	let frameId: number;

	onMount(async () => {
		// const p = Promise.withResolvers<void>();
		// const image = new Image();
		// image.src = '/images/image.png';
		// image.addEventListener('load', () => p.resolve());
		// await p.promise;

		// canvas.width = image.width;
		// canvas.height = image.height;
		// canvas.style.width = '100vw';
		// canvas.style.aspectRatio = (image.width / image.height).toString();
		// canvas.style.height = 'auto';

		// Get A WebGL context
		gl = canvas.getContext('webgl2')!;
		if (!gl) throw new Error('Unable to get WebGL context');

		// create GLSL shaders, upload the GLSL source, compile the shaders
		const vertexShader = createShader(gl, gl.VERTEX_SHADER, vertexShaderSource);
		if (!vertexShader) throw new Error('Unable to create vertex shader');

		fragmentShader = createShader(gl, gl.FRAGMENT_SHADER, fragmentShaderSource)!;
		if (!fragmentShader) throw new Error('Unable to create fragment shader');

		// Link the two shaders into a program
		program = createProgram(gl, vertexShader, fragmentShader)!;
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

		// Create a texture
		// const texture = gl.createTexture();
		// gl.bindTexture(gl.TEXTURE_2D, texture);
		// gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
		// gl.generateMipmap(gl.TEXTURE_2D);

		// // Tell WebGL to use our texture
		// gl.activeTexture(gl.TEXTURE0);
		// gl.bindTexture(gl.TEXTURE_2D, texture);
		// gl.uniform1i(gl.getUniformLocation(program, 'u_texture'), 0);

		// Bind the attribute/buffer set we want.
		gl.bindVertexArray(vao);

		function frame() {
			frameId = requestAnimationFrame(() => {
				const dpr = window.devicePixelRatio;

				gl.uniform2f(
					gl.getUniformLocation(program, 'i_mouse_position'),
					dpr * mousePosition.x,
					dpr * mousePosition.y,
				);

				const canvasRect = canvas.getBoundingClientRect();
				const bodyRect = document.body.getBoundingClientRect();

				gl.uniform2f(
					gl.getUniformLocation(program, 'i_uv'),
					dpr * (window.scrollX + canvasRect.x * 1.00001 - 1.5),
					dpr * (bodyRect.height - (window.scrollY + canvasRect.y + canvasRect.height)),
				);

				// draw
				const primitiveType = gl.TRIANGLE_FAN;
				gl.drawArrays(primitiveType, /* offset */ 0, /* count */ 4);

				frame();
			});
		}

		frame();
	});

	onDestroy(() => {
		cancelAnimationFrame(frameId);
	});

	let mousePosition = { x: 0, y: 0 };
	let pageCanvas: HTMLCanvasElement | undefined;

	async function _resetImage() {
		console.log('CAPTURING...');
		console.time('capture');

		const bodyRect = document.body.getBoundingClientRect();
		console.log(bodyRect);

		pageCanvas = await toCanvas(
			// document.body,
			document.querySelector<HTMLElement>('.page')!,
			// document.querySelector<HTMLElement>('#app')!,
			{
				filter: (node) => {
					if (typeof node.hasAttribute !== 'function') return true;
					return !node.hasAttribute('data-no-capture');
				},
				// canvasWidth: bodyRect.width - 100,
				// canvasHeight: bodyRect.height,
				width: bodyRect.width - 1, // don't know why -1 is needed, but text wrap is wrong otherwise
				height: bodyRect.height,
				// pixelRatio: window.devicePixelRatio,
				skipAutoScale: true,
				style: {
					// paddingRight: '10px',
				},
				backgroundColor: 'white',
			},
		);
		console.timeEnd('capture');

		const img = new Image();
		img.src = pageCanvas.toDataURL();
		await new Promise((r) => img.addEventListener('load', r));

		// window.open(URL.createObjectURL(await fetch(img.src).then((r) => r.blob())), 'blank');
		console.log(img.src, img.width, img.height);

		const texture = gl.createTexture();
		gl.bindTexture(gl.TEXTURE_2D, texture);
		gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, img);
		// gl.generateMipmap(gl.TEXTURE_2D);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

		gl.activeTexture(gl.TEXTURE0);
		gl.bindTexture(gl.TEXTURE_2D, texture);
		gl.uniform1i(gl.getUniformLocation(program, 'u_texture'), 0);
	}

	const resetImage = debounce(_resetImage, { wait: 500 });

	onMount(() => {
		// resetImage.immediate();
	});

	const canvasSize = { width: 150, height: 50 };

	new MutationObserver(async () => {
		// Wait for all images to be loaded
		await Promise.all(
			Array.from(document.querySelectorAll<HTMLImageElement>('img')).map(async (img) => {
				if (img.complete) return;

				const { resolve, promise } = Promise.withResolvers<void>();
				img.onload = () => resolve();

				return promise;
			}),
		);

		resetImage();
	}).observe(document.body, {
		subtree: true,
		childList: true,
		characterData: true,
	});
</script>

<!-- <button class="absolute" onclick={resetImage}>CAPTURE</button> -->

<svelte:window
	onmousemove={(e) => {
		mousePosition = { x: e.clientX, y: e.clientY };
	}}
	onresize={resetImage}
/>

<div class="page">
	of in for with as that on by from at if than about into between after because through over like
	before under during while without since against within upon out among although so per until though
	whether around along de toward above up across behind beyond except near throughout down towards
	below despite unless outside off whereas o v. inside in. n onto besides unlike till via beneath
	beside once p. past i round amongst en thereof unto ago whilst alongside b. der ln i. albeit amid
	aboard ot lest v lf a. notwithstanding underneath ol wherein par versus inter vs. tor opposite n.
	pp. irrespective amidst bv du atop width u ofthe oi whereupon lor teaspoon explain behavior plus
	identify pursuant r hy d. atom fore cf upto amino oj therefor ibn next repeat or author wherever
	aloof o'er m af un oneself int whereof ef w p ii op a.d. di behaviour begin herein insert j
	thereafter onwards cf. ore obtain il y au whence bout proof beforehand vapor whither df folder th
	anterior onward insofar anew ith thru h bladder ir observe thai ff inhibitor ou answer l' input
	afresh c. wi nearer astride hereof inasmuch save ft. enter iv por voor install pour aux vector m.
	ooo to ibid. perform iu layout s. accept intake abreast ion heat therewith inferior l.
	introduction iff diameter no. <span class="text-orange-300"
		>ar u. bypass nf orientation afterwards ix betwixt oxide ofa preheat donor transfer thro
		forthwith adjust asunder thereupon ip <img src="https://picsum.photos/id/239/3000/3000" /> om t.
		interrupt km l auf ter assign wherewith oder ed. o. apr pf bean administer fill j. outweighs aft
		fo fer im upper don mm brain info q format aa og parameter therefrom</span
	>
	eat ie iii attach autumn maintain tablespoon x. position onset beat pp brief io identifier k e. offish
	tn jn afterward min monitor afar outdoor saith ahout leaf intercept pepper allow noun favour k. w.
	interaction inf increase posterior hitherto prom si g. thereon f. kg arc cm learn right instruct error
	oz bj overview den integer thereunder tf behold er hereinafter tonight och fin ber onboard algorithm
	quoth ere hereunder sur index trans. os uptake ahead fn fron interval treat ab whereon vitamin observer
	z att stir instructor oft trom oscillator uf bor alongwith uptown bereft post adolf assess himself
	lb. irom astern henceforth albumin vith lb ut ior beef chat overleaf b.c. whomever downstream tensor
	al dat filter av herewith thereby z. immunoglobulin ai inform activator junior urchin downhill rf choose
	ash anchor yr has is pl. hr atm inspect aloft electron assay afore art. whom peer athwart fora um tumor
	für vpon verify untill using ft discard fig. forwards lo border enough upwards ref user bp binder hereafter
	amp actin inthe ac offender interface astray web fro bc nm indoor aster n.d. y. bei qf inner forgetful
	incl. must factor fot ig frown operator icon soever wth labour jor tion oa rom interferon belief overlap
	emperor mg amplifier aspirin superior ohn def whan box a.m.

	<div>NESTED??</div>
</div>

<div
	data-no-capture
	class="pointer-events-none fixed inset-0 grid place-content-center *:pointer-events-auto"
>
	<button class="relative w-fit transition-all hover:scale-105">
		<canvas
			bind:this={canvas}
			class="outline-red-400"
			width={canvasSize.width * window.devicePixelRatio}
			height={canvasSize.height * window.devicePixelRatio}
			style="width: {canvasSize.width}px; height: {canvasSize.height}px"
		></canvas>

		<div
			class="absolute inset-0 grid place-content-center rounded-full border-[0.5px] border-zinc-100 font-[SUSE_Mono] text-zinc-700 shadow-lg"
		>
			Hello World!
		</div>
	</button>
</div>

<style>
	@import url('https://fonts.googleapis.com/css2?family=SUSE+Mono:ital,wght@0,100..800;1,100..800&display=swap');
</style>
