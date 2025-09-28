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
