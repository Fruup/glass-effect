<script lang="ts">
	import { ElementSize, useThrottle } from 'runed';
	import { onDestroy, onMount } from 'svelte';
	import { setup } from '$lib/utils/opengl';
	import type { Config } from './config';
	import { cn } from '$lib/utils';
	import { SharedState } from './state.svelte';
	import { on } from 'svelte/events';

	let {
		config,
		onColorSchemeChange,
		class: className,
	}: {
		config: Config;
		onColorSchemeChange?: (scheme: 'light' | 'dark') => any;
		class?: string;
	} = $props();

	const sharedState = SharedState.get();

	let canvas = $state() as HTMLCanvasElement;

	let frameId: number;
	let ctx: ReturnType<typeof setup>;

	let lastCanvasPosition = { x: 0, y: 0 };
	let shouldComputeColorScheme = true;

	const throttledSetComputeColorScheme = useThrottle(() => (shouldComputeColorScheme = true), 250);
	$effect(() => on(window, 'scroll', () => throttledSetComputeColorScheme()));

	$effect(() => {
		canvas.width = containerSize.width * window.devicePixelRatio;
		canvas.height = containerSize.height * window.devicePixelRatio;
	});

	onMount(async () => {
		if (!canvas) throw new Error('Canvas not found');
		ctx = setup(canvas);

		// Start render loop
		renderLoop();
	});

	function renderLoop() {
		frameId = requestAnimationFrame(() => {
			const containerStyle = getComputedStyle(container);

			const borderRadius = parseFloat(containerStyle.borderRadius.slice(0, -2));

			const canvasRect = canvas.getBoundingClientRect();
			const bodyRect = {
				width: document.body.clientWidth,
				height: document.body.clientHeight,
			};

			ctx.setUV(
				(window.scrollX + canvasRect.x) / bodyRect.width,
				(bodyRect.height - (window.scrollY + canvasRect.y + canvasRect.height)) / bodyRect.height,
			);

			ctx.gl.uniform2f(
				ctx.gl.getUniformLocation(ctx.program, 'i_resolution'),
				canvas.width,
				canvas.height,
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
				ctx.gl.getUniformLocation(ctx.program, 'i_border_radius'),
				Math.max(0, Math.min(1, borderRadius / Math.min(canvasRect.width, canvasRect.height))),
			);

			ctx.gl.uniform1i(ctx.gl.getUniformLocation(ctx.program, 'i_blur_radius'), config.blurRadius);

			ctx.draw();

			if (
				shouldComputeColorScheme ||
				lastCanvasPosition.x !== canvasRect.x ||
				lastCanvasPosition.y !== canvasRect.y
			) {
				shouldComputeColorScheme = false;

				const img = new Image();
				img.onload = () => computeColorScheme(img);
				img.src = canvas.toDataURL();
			}

			lastCanvasPosition = {
				x: canvasRect.x,
				y: canvasRect.y,
			};

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

	const containerSize = new ElementSize(() => container);
</script>

<div
	data-no-capture
	bind:this={container}
	class={cn('size-full', !sharedState.loaded && 'backdrop-blur-xs', className)}
>
	<canvas
		bind:this={canvas}
		width={containerSize.width * window.devicePixelRatio}
		height={containerSize.height * window.devicePixelRatio}
		class="size-full transition-opacity duration-500"
		style:opacity={sharedState.loaded ? 1 : 0}
	></canvas>
</div>
