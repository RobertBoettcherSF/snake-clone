# Web-safe Ada subset (copied from ada-bot-brain PRACTICES)

Ticked in this project, not in the brain.

In the wasm / engine core (`src/snake.ads`, `src/snake.adb`, `src/snake-auto.ads`, `src/snake-auto.adb`):

- [x] No tasking
- [x] No heap, allocators, or unbounded containers
- [x] No exception handlers (a last-chance handler in the runtime contract is required)
- [x] No `Text_IO` or other OS/file units
- [x] Fixed-size arrays and records only
- [x] No access types, and no `Unchecked_Conversion` of a record address
- [x] Contracts and ranged subtypes on quantities
- [x] Functions have no side effects; pass world and RNG state in; no hidden globals
- [x] Fixed point where native and wasm results must match; no `Math.random` or wall-clock in rules
- [x] English identifiers

The host ABI (`src/snake-api.ads/.adb`) holds one `World` for the page to call. Native `tests/smoke.adb` may use `Text_IO`. The last-chance handler lives in `src/last_chance_handler.adb` and reports file and line to the JS host.
