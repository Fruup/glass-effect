import type { TransitionConfig } from 'svelte/transition';

export function debounce<T extends (...args: any[]) => void>(
	fn: T,
	options: {
		/** @default 500 */
		wait?: number;
	} = {},
): T & {
	immediate: T;
} {
	const { wait = 500 } = options;

	let timer: ReturnType<typeof setTimeout> | undefined;

	const debouncedFn = (...args: Parameters<T>) => {
		clearTimeout(timer);
		timer = setTimeout(() => {
			fn(...args);
		}, wait);
	};

	Object.assign(debouncedFn, {
		immediate: (...args: Parameters<T>) => {
			if (timer) clearTimeout(timer);
			fn(...args);
		},
	});

	return debouncedFn as unknown as T & { immediate: T };
}

export function throttle<T extends (...args: any[]) => void>(
	fn: T,
	options: {
		/** @default 500 */
		wait?: number;
	} = {},
): T {
	const { wait = 500 } = options;

	let lastTime = 0;
	let timer: ReturnType<typeof setTimeout> | undefined;

	const throttledFn = (...args: Parameters<T>) => {
		const now = Date.now();
		const remaining = wait - (now - lastTime);

		if (remaining <= 0) {
			if (timer) {
				clearTimeout(timer);
				timer = undefined;
			}
			lastTime = now;
			fn(...args);
		} else if (!timer) {
			timer = setTimeout(() => {
				lastTime = Date.now();
				timer = undefined;
				fn(...args);
			}, remaining);
		}
	};

	return throttledFn as T;
}

export const vanish = (
	node: HTMLElement,
	options?: Partial<Omit<TransitionConfig, 'css' | 'tick'>>,
): TransitionConfig => {
	return {
		...options,
		css: (t, u) => `
				opacity: ${t};
				filter: blur(${8 * u}px);
				scale: ${1 + 0.2 * u}
			`,
	};
};
