<script lang="ts">
	import { ElementSize } from 'runed';
	import { onDestroy, onMount } from 'svelte';
	import { setup } from '$lib/utils/opengl';
	import { fade } from 'svelte/transition';
	import type { Config } from './config';
	import { cn } from '$lib/utils';
	import { SharedState } from './state.svelte';

	let {
		config,
		size,
		onColorSchemeChange,
	}: {
		config: Config;
		size?: { width: number; height: number };
		onColorSchemeChange?: (scheme: 'light' | 'dark') => any;
	} = $props();

	const sharedState = SharedState.get();

	let canvas = $state() as HTMLCanvasElement;

	let frameId: number;
	let ctx: ReturnType<typeof setup>;

	onMount(async () => {
		console.log('BEFORE', containerSize?.getSize());
		containerSize?.calculateSize();
		console.log('AFTER', containerSize?.getSize());

		if (containerSize) {
			canvas.width = containerSize.width * window.devicePixelRatio;
			canvas.height = containerSize.height * window.devicePixelRatio;
		}

		if (!canvas) throw new Error('Canvas not found');
		ctx = setup(canvas);

		// Start render loop
		renderLoop();
	});

	function renderLoop() {
		frameId = requestAnimationFrame(() => {
			const dpr = window.devicePixelRatio;
			const canvasRect = canvas.getBoundingClientRect();
			const bodyRect = document.body.getBoundingClientRect();

			ctx.setUV(
				dpr * (window.scrollX + canvasRect.x),
				dpr * (bodyRect.height - (window.scrollY + canvasRect.y + canvasRect.height)),
			);

			ctx.gl.uniform4f(
				ctx.gl.getUniformLocation(ctx.program, 'i_background_color'),
				...config.backgroundColor,
			);

			ctx.gl.uniform1f(
				ctx.gl.getUniformLocation(ctx.program, 'i_background_color_mix'),
				config.backgroundColorMix,
			);

			ctx.gl.uniform1f(
				ctx.gl.getUniformLocation(ctx.program, 'i_lense_flatness'),
				config.lenseFlatness,
			);

			// ctx.gl.uniform1f(
			// 	ctx.gl.getUniformLocation(ctx.program, 'i_lense_height'),
			// 	config.lenseHeight,
			// );

			ctx.gl.uniform1i(ctx.gl.getUniformLocation(ctx.program, 'i_blur_radius'), config.blurRadius);

			ctx.draw();

			if (sharedState.getAndResetShouldComputeColorScheme()) {
				const img = new Image();
				img.onload = () => computeColorScheme(img);
				img.src = canvas.toDataURL();
			}

			renderLoop();
		});
	}

	$effect(() => {
		if (sharedState.backgroundImage) {
			ctx.setTexture(sharedState.backgroundImage);
		}
	});

	async function computeColorScheme(img: HTMLImageElement) {
		const tempCanvas = document.createElement('canvas');
		const context = tempCanvas.getContext('2d')!;
		tempCanvas.width = img.width;
		tempCanvas.height = img.height;
		context.drawImage(img, 0, 0);
		const imageData = context.getImageData(0, 0, img.width, img.height);

		// TODO: non rgba?
		let luminance = 0;

		for (let i = 0; i < imageData.data.length; i += 4) {
			if (imageData.data[i + 3] < 250) continue;

			const r = imageData.data[i + 0] / 255;
			const g = imageData.data[i + 1] / 255;
			const b = imageData.data[i + 2] / 255;
			luminance += 0.2126 * r + 0.7152 * g + 0.0722 * b;
		}

		luminance /= imageData.data.length / 4;

		onColorSchemeChange?.(luminance < 0.6 ? 'dark' : 'light');
	}

	onDestroy(() => {
		cancelAnimationFrame(frameId);
	});

	let container = $state() as HTMLDivElement;

	const containerSize = !size ? new ElementSize(() => container) : null;

	const canvasSize: { width: number; height: number } = $derived(
		size ? size : containerSize!.getSize(),
	);
</script>

<div
	bind:this={container}
	class={cn(
		'relative overflow-clip rounded-full *:transition-opacity *:duration-500',
		size ? 'size-fit' : 'size-full',
	)}
>
	<canvas
		bind:this={canvas}
		width={canvasSize.width * window.devicePixelRatio}
		height={canvasSize.height * window.devicePixelRatio}
		style="width: {canvasSize.width}px; height: {canvasSize.height}px"
		style:opacity={sharedState.loaded ? 1 : 0}
	></canvas>

	{#if !sharedState.loaded}
		<div
			class="pointer-events-none absolute inset-0 backdrop-blur-xs"
			transition:fade={{ duration: 500 }}
		></div>
	{/if}
</div>
