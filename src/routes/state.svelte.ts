import { toJpeg } from 'html-to-image';
import { useDebounce, useThrottle } from 'runed';
import { on } from 'svelte/events';

export class SharedState {
	#loaded = $state(false);
	#backgroundImage: HTMLImageElement | undefined = $state();

	#shouldComputeColorScheme = false;

	private constructor() {
		const renderImage = useDebounce(this.#renderImage.bind(this), 1000);

		if (document.readyState === 'complete') renderImage();
		$effect(() => on(window, 'load', renderImage));
		$effect(() => on(window, 'resize', renderImage));

		const throttledSetComputeColorScheme = useThrottle(
			() => (this.#shouldComputeColorScheme = true),
			250,
		);
		$effect(() => on(window, 'scroll', throttledSetComputeColorScheme));
		throttledSetComputeColorScheme();
	}

	static get() {
		if (!sharedState) sharedState = new SharedState();
		return sharedState;
	}

	async #renderImage() {
		// TODO: Consider moving this to a web worker. Is this even possible?

		this.#loaded = false;

		const pageImage = await toJpeg(document.body, {
			filter: (node) => {
				if (typeof node.hasAttribute !== 'function') return true;
				return !node.hasAttribute('data-no-capture');
			},
			width: document.body.clientWidth,
			height: document.body.clientHeight,
			backgroundColor: getComputedStyle(document.body).backgroundColor,
			quality: 0.1,
		});

		const img = new Image();
		img.src = pageImage;
		await new Promise((resolve) => img.addEventListener('load', resolve));

		this.#backgroundImage = img;

		this.#loaded = true;
		this.#shouldComputeColorScheme = true;
	}

	get backgroundImage() {
		return this.#backgroundImage;
	}

	get loaded() {
		return this.#loaded;
	}

	getAndResetShouldComputeColorScheme() {
		const value = this.#shouldComputeColorScheme;
		this.#shouldComputeColorScheme = false;
		return value;
	}
}

let sharedState: SharedState | undefined;

// new MutationObserver(async () => {
// 	// Wait for all images to be loaded
// 	await Promise.all(
// 		Array.from(document.querySelectorAll<HTMLImageElement>('img')).map(async (img) => {
// 			if (img.complete) return;

// 			const { resolve, promise } = Promise.withResolvers<void>();
// 			img.onload = () => resolve();

// 			return promise;
// 		}),
// 	);

// 	resetImage();
// }).observe(document.body, {
// 	subtree: true,
// 	childList: true,
// 	characterData: true,
// });
