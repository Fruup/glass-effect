<script lang="ts">
	import type { TransitionConfig } from 'svelte/transition';
	import ConfigPanel from './config-panel.svelte';
	import GlassCanvas from './glass-canvas.svelte';

	const canvasSize = { width: 150, height: 50 };

	let visible = $state(true);
</script>

<!-- <ConfigPanel bind:config /> -->

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
		<!-- <img src="https://picsum.photos/id/239/3000/3000" /> -->
		<!-- <img src="https://picsum.photos/id/240/3000/3000" /> -->
		<!-- <img src="https://picsum.photos/id/241/3000/3000" /> -->
		om t. interrupt km l auf ter assign wherewith oder ed. o. apr pf bean administer fill j. outweighs
		aft fo fer im upper don mm brain info q format aa og parameter therefrom</span
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
	<button class="group relative w-fit transition-all hover:scale-105">
		<GlassCanvas
			width={canvasSize.width}
			height={canvasSize.height}
			onColorSchemeChange={(scheme) => {
				console.log(scheme);

				document.querySelector('#glass-button-content')?.setAttribute('data-color-scheme', scheme);
			}}
		/>

		<div
			id="glass-button-content"
			class="absolute inset-0 grid place-content-center rounded-full border-[0.5px] border-zinc-100 font-[SUSE_Mono] shadow-lg transition-colors duration-500 data-[color-scheme=dark]:text-zinc-100 data-[color-scheme=light]:text-zinc-700"
		>
			Hello World!
		</div>
	</button>
</div>

<style>
	@import url('https://fonts.googleapis.com/css2?family=SUSE+Mono:ital,wght@0,100..800;1,100..800&display=swap');
</style>
