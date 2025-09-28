<script lang="ts">
	import Label from '$lib/components/ui/label/label.svelte';
	import Slider from '$lib/components/ui/slider/slider.svelte';

	let {
		blurPixels,
	}: {
		blurPixels: number;
	} = $props();
</script>

<div class="fixed top-0 right-0 m-4 rounded-xl border bg-white p-4 shadow-xl">
	<Label>
		Blur Pixels
		<Slider type="single" bind:value={blurPixels} min={0} max={16} step={1} />
	</Label>
</div>
