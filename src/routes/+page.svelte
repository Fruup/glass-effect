<script lang="ts">
	import { vanish } from '$lib/utils/index.svelte';
	import type { Config } from './config';
	import ConfigPanel from './config-panel.svelte';
	import GlassCanvas from './glass-canvas.svelte';
	import { Smoothed } from './smoothed.svelte';

	let config = $state<Config>({
		backgroundColor: [1, 1, 1, 1],
		backgroundColorMix: 0.5,
		blurRadius: 2,
	});

	let show = $state(true);

	const mousePosition = new Smoothed(
		{ x: 0, y: 0 },
		{ speed: 0.008, threshold: 1 / window.devicePixelRatio },
	);
</script>

<svelte:window onmousemove={(e) => mousePosition.set({ x: e.x, y: e.y })} />

<ConfigPanel bind:config />

<div
	class="pointer-events-none fixed size-[128px] -translate-1/2 cursor-none"
	style:left="{mousePosition.current.x}px"
	style:top="{mousePosition.current.y}px"
>
	<GlassCanvas class="rounded-full shadow-lg" {config} />
</div>

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
		forthwith adjust asunder thereupon ip
		<img src="https://picsum.photos/id/26/4209/2769" />
		<img src="https://picsum.photos/id/20/3670/2462" />
		<img src="https://picsum.photos/id/36/4179/2790" />
		<img src="https://picsum.photos/id/40/4106/2806" />
		<img src="https://picsum.photos/id/110/5000/3333" />

		om t. interrupt km l auf ter assign wherewith oder ed. o. apr pf bean administer fill j.
		outweighs aft fo fer im upper don mm brain info q format aa og parameter therefrom</span
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
</div>

<div data-no-capture class="pointer-events-none fixed inset-0">
	<div
		data-no-capture
		class="pointer-events-none absolute inset-0 grid place-content-center *:pointer-events-auto"
	>
		{#if show}
			<button
				transition:vanish={{ duration: 500 }}
				class="group relative grid place-content-center p-4 transition-all hover:scale-105"
				onclick={() => {
					show = false;
					setTimeout(() => {
						show = true;
					}, 2000);
				}}
			>
				<GlassCanvas
					{config}
					class="absolute inset-0 rounded-full border-[0.5px] border-zinc-100 shadow-lg"
					onColorSchemeChange={(scheme) => {
						document
							.querySelector('#glass-button-content')
							?.setAttribute('data-color-scheme', scheme);
					}}
				/>

				<div
					id="glass-button-content"
					class="z-10 transition-colors duration-500 data-[color-scheme=dark]:text-zinc-100 data-[color-scheme=light]:text-zinc-700"
				>
					Hello World!
				</div>
			</button>
		{/if}
	</div>
</div>
