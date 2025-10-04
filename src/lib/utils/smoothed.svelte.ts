/**
 * A utility similar to Svelte's `Spring` and `Tween`.
 * It allows you to smoothly follow a `target` value without the possibility of overshooting (like with `Spring`).
 */
export class Smoothed<T_ extends number | { [k: string]: number }, T = T_ extends object ? T_ : number> {
	#current = $state() as T;
	#target = $state() as T;
	#touched = $state(false);

	options: SmoothedOptions = $state({
		threshold: 1,
		speed: 0.1,
	});

	#threshold2 = $derived(this.options.threshold * this.options.threshold);

	constructor(value: T, options: Partial<SmoothedOptions> = {}) {
		this.#current = value;
		this.#target = value;

		this.options = {
			...this.options,
			...options,
		};

		$effect(() => {
			let animationFrameId: number;
			let prevT: DOMHighResTimeStamp = 0;

			const frame = (t: DOMHighResTimeStamp) => {
				const delta = this.#delta(this.#target, this.#current);
				const distance2 = delta.reduce((sum, dx) => sum + dx * dx, 0);

				if (distance2 < this.#threshold2) {
					this.#current = this.#target;
				} else {
					const dt = t - (prevT || t);

					if (typeof this.#current === 'number') {
						// @ts-ignore
						this.#current += delta[0] * dt * this.options.speed;
					} else if (this.#current instanceof Object) {
						const factor = Math.min(dt * this.options.speed, 1);

						Object.keys(this.#current).forEach((key, i) => {
							// @ts-ignore
							this.#current[key] += delta[i] * factor;
						});
					}
				}

				prevT = t;
			};

			animationFrameId = requestAnimationFrame(function f(t) {
				frame(t);
				animationFrameId = requestAnimationFrame(f);
			});

			return () => {
				cancelAnimationFrame(animationFrameId);
			};
		});
	}

	get current() {
		return this.#current;
	}

	get target() {
		return this.#target;
	}

	/** Whether the value was changed at least once. */
	get touched() {
		return this.#touched;
	}

	set target(value: T) {
		this.set(value);
	}

	set(
		value: T,
		{
			instant,
		}: {
			/** Whether `current` should match `target` immediately */
			instant?: boolean;
		} = {},
	) {
		this.#target = value;
		this.#touched = true;

		if (instant) {
			this.#current = value;
		}
	}

	/** Calculates the difference of two vectors */
	#delta(a: T, b: T): number[] {
		if (typeof a === 'number' && typeof b === 'number') {
			return [a - b];
		}

		// @ts-ignore
		return Object.keys(a).map((key) => a[key] - b[key]);
	}
}

interface SmoothedOptions {
	/** The minimum distance below which the `current` value is set to the `target` value. */
	threshold: number;
	/** The speed with which `current` moves towards `target`. */
	speed: number;
}
