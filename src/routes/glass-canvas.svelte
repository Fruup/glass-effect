<script lang="ts">
	import { onDestroy, onMount } from 'svelte';
	import { toCanvas } from 'html-to-image';
	import { debounce, throttle } from '$lib/utils/index.svelte';
	import { setup } from '$lib/utils/opengl';
	import { fade } from 'svelte/transition';

	let {
		width,
		height,
		onColorSchemeChange,
	}: {
		width: number;
		height: number;
		onColorSchemeChange?: (scheme: 'light' | 'dark') => any;
	} = $props();

	let canvas = $state() as HTMLCanvasElement;
	let pageCanvas: HTMLCanvasElement | undefined;

	let loaded = $state(false);

	let frameId: number;
	let ctx: ReturnType<typeof setup>;

	let shouldComputePrimaryColor = false;

	onMount(async () => {
		if (!canvas) throw new Error('Canvas not found');
		ctx = setup(canvas);

		function frame() {
			frameId = requestAnimationFrame(() => {
				const dpr = window.devicePixelRatio;

				// ctx.setMousePosition()

				const canvasRect = canvas.getBoundingClientRect();
				const bodyRect = document.body.getBoundingClientRect();

				ctx.setUV(
					dpr * (window.scrollX + canvasRect.x),
					dpr * (bodyRect.height - (window.scrollY + canvasRect.y + canvasRect.height)),
				);

				ctx.draw();

				if (shouldComputePrimaryColor) {
					shouldComputePrimaryColor = false;

					console.time('computeLuminance');

					const img = new Image();
					img.onload = () => {
						computePrimaryColor(img);
						console.timeEnd('computeLuminance');
					};
					img.src = canvas.toDataURL();
				}

				frame();
			});
		}

		frame();
	});

	async function computePrimaryColor(img: HTMLImageElement) {
		const tempCanvas = document.createElement('canvas');
		const context = tempCanvas.getContext('2d')!;
		tempCanvas.width = img.width;
		tempCanvas.height = img.height;
		context.drawImage(img, 0, 0);
		const imageData = context.getImageData(0, 0, img.width, img.height);

		console.log(imageData);

		// TODO: non rgba?
		let luminance = 0;

		for (let i = 0; i < imageData.data.length; i += 4) {
			if (imageData.data[i + 3] < 250) continue;

			// TODO: better luminance calculation
			luminance +=
				(imageData.data[i + 0] + imageData.data[i + 1] + imageData.data[i + 2]) / (255 * 3);
		}

		luminance /= imageData.data.length / 4;

		onColorSchemeChange?.(luminance < 0.6 ? 'dark' : 'light');

		console.log({ luminance });
	}

	onDestroy(() => {
		cancelAnimationFrame(frameId);
	});

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
				backgroundColor: getComputedStyle(document.body).backgroundColor,
			},
		);
		console.timeEnd('capture');

		const img = new Image();
		img.src = pageCanvas.toDataURL();
		await new Promise((r) => img.addEventListener('load', r));

		console.log(img.src, img.width, img.height);

		ctx.setTexture(img);

		loaded = true;
		shouldComputePrimaryColor = true;
	}

	const resetImage = debounce(_resetImage, { wait: 500 });

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

	const throttledScroll = throttle(
		() => {
			shouldComputePrimaryColor = true;
		},
		{ wait: 200 },
	);
</script>

<svelte:window
	onresize={resetImage}
	onkeydown={(e) => {
		if (e.key === 'p') {
			shouldComputePrimaryColor = true;
		}
	}}
	onscroll={() => throttledScroll()}
/>

<div class="relative w-fit overflow-clip rounded-full *:transition-opacity *:duration-500">
	<canvas
		bind:this={canvas}
		width={width * window.devicePixelRatio}
		height={height * window.devicePixelRatio}
		style="width: {width}px; height: {height}px"
		style:opacity={loaded ? 1 : 0}
	></canvas>

	{#if !loaded}
		<div
			class="pointer-events-none absolute inset-0 backdrop-blur-xs"
			out:fade={{ duration: 500 }}
		></div>
	{/if}
</div>

<style>
	@import url('https://fonts.googleapis.com/css2?family=SUSE+Mono:ital,wght@0,100..800;1,100..800&display=swap');
</style>
