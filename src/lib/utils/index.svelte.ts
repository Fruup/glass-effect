import { cubicOut } from 'svelte/easing';
import type { TransitionConfig } from 'svelte/transition';

export const vanish = (
	_node: HTMLElement,
	options?: Partial<Omit<TransitionConfig, 'css' | 'tick'>>,
): TransitionConfig => {
	return {
		easing: cubicOut,
		...options,
		css: (t, u) => `
				opacity: ${t};
				filter: blur(${3 * Math.pow(u, 2)}px);
				scale: ${1 + 0.2 * u};
			`,
	};
};
