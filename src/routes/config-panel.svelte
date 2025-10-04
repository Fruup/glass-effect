<script lang="ts">
	import Label from '$lib/components/ui/label/label.svelte';
	import Slider from '$lib/components/ui/slider/slider.svelte';
	import type { Config } from './config';

	let {
		config = $bindable(),
	}: {
		config: Config;
	} = $props();
</script>

<div
	data-no-capture
	class="fixed right-0 bottom-0 m-4 rounded-xl border bg-white p-4 opacity-10 shadow-xl transition-opacity hover:opacity-100"
>
	<Label>
		Blur Radius [px]
		<Slider type="single" bind:value={config.blurRadius} min={0} max={10} step={1} />
		{config.blurRadius}px
	</Label>

	<Label>
		Background Color
		<input
			type="color"
			bind:value={
				() =>
					'#' +
					config.backgroundColor
						.slice(0, 3)
						.map((value) =>
							Math.round(value * 255)
								.toString(16)
								.padStart(2, '0'),
						)
						.join(''),
				(value: string) => {
					config.backgroundColor = [
						parseInt(value.slice(1, 3), 16) / 255,
						parseInt(value.slice(3, 5), 16) / 255,
						parseInt(value.slice(5, 7), 16) / 255,
						1,
					];
				}
			}
		/>
	</Label>

	<Label>
		Background Color Mix
		<Slider type="single" bind:value={config.backgroundColorMix} min={0} max={1} step={0.001} />
		{Math.round(config.backgroundColorMix * 100)}%
	</Label>
</div>
