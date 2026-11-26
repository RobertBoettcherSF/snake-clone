# Snake Clone

A Snake game whose grid, movement, pellets, collisions, score and auto-player
all live in **Plain Ada**, compiled to WebAssembly and drawn by one
self-contained page.

**Live page:** https://robertboettchersf.github.io/snake-clone/

The Ada core talks to the page with integers only. JavaScript draws the
canvas, wires keys, swipes and buttons, and writes the F9 / Auto-stop report.
It does not decide where the snake turns or where a pellet lands.

## Play

- **23×11** grid (253 cells), wall and self-collision deaths, 10 points per
  pellet, length grows by 1. A full clear is score 2500, length 253. Speed
  rises every 5 pellets (150 ms down to a 50 ms floor).
- **Score**, **Length** and **Turns**, each with its best so far. The Turns
  best is the fewest turns used to reach the top score (a tie on score with
  fewer turns improves it). Bests are kept in the browser, keyed to 23×11
  so older 20×20 bests are not mixed in.
- Two seeds, both shown and editable: **pellet** placement and **behaviour**
  (auto-player tie-breaks only). Same seeds give the same run.
- **Auto** starts a run at once and becomes **Stop** while auto-play is
  running. Stop, or a death or win during Auto, downloads a `poncelet-report`
  v1 file (stamp, both seeds, score, length, turns, bests, fitness, action
  log, state hash, grid size, death reason, enclosed-area size, log cap).
- Arrows or WASD, swipe on a phone. Space pauses, R restarts, F9 (or
  **Debug**) pauses and downloads a report. Sound off, en-GB / de / es / fr.

The auto-player uses only what a player can see. It follows a 252-cell
near-cycle on the 23×11 board (253 is odd, so no Hamiltonian cycle; the
cell (23, 1) is omitted). A heading is taken only if the new head can
still reach its own tail (BFS), or if the step is the last pellet and
fills the board. Shortcuts stay in the forward cycle gap and never jump
over the tail; the omitted cell is taken by a tail-safe one-off when the
head is adjacent. Score ranks ahead of turns; turns break ties. A finished
run is ranked as `fitness = score × 100000 − turns`.

The cycle geometry, the gap rule, the report fields, and why v0.1 trapped
itself are in `docs/ALGORITHM.md`. How the project arrived at 23×11 after
shipping 20×20 by mistake is in `docs/HOW_WE_GOT_HERE.md`.

## Auto-player batch (v0.2 vs v0.3)

Native runs of 100 seed pairs `(k, k)` for `k = 1 .. 100`, each played to a
win, a death, or a 200 000-turn cap. **The boards differ**, so scores and
turns are not directly comparable: v0.2 is 20×20 (max score 3970, length
400) from commit `5c04bd7` / the v0.2 batch; v0.3 is 23×11 (max score 2500,
length 253).

| | v0.2 (20×20) | v0.3 (23×11) |
|---|---:|---:|
| Mean score | 3970.0 | 2500.0 |
| Median score | 3970.0 | 2500.0 |
| Mean length | 400.0 | 253.0 |
| Median length | 400.0 | 253.0 |
| Mean turns | 44073.0 | 18646.0 |
| Median turns | 44099.0 | 18722.0 |
| Wins | 100 / 100 | 100 / 100 |

Seeds **1/1**:

| | v0.2 (20×20) | v0.3 (23×11) |
|---|---:|---:|
| Score | 3970 | 2500 |
| Length | 400 | 253 |
| Turns | 42590 | 18830 |
| Result | won (board full) | won (board full) |

v0.1 on the same 20×20 seeds 1/1 died at score 570, length 60, turns 867.
The default `./run-tests.sh` smoke asserts the grid is 23×11 (and not
square) and requires seeds 1/1 to fill that board and terminate. The
100-seed batch is `./run-batch.sh`.

## Size (v0.2 → v0.3)

| | v0.2 | v0.3 |
|---|---:|---:|
| Ada `src/` lines | 1,752 | 1,531 |
| of which `snake-auto.adb` | 691 | 427 |
| `web/template.html` lines | 596 | 603 |
| `docs/index.html` | 65,971 bytes | 44,544 bytes |
| Wasm module | 31,412 bytes | 15,172 bytes |

## Build and test

Scripts work from a fresh clone. They expect GNAT 12.3 (or another warning-free
GNAT 14) on `PATH`. They never download a toolchain.

```sh
./run-tests.sh
```

That is a native `-gnata` smoke of the same sources as the wasm build
(`-gnat2022 -gnatwa -gnatwe`, statically linked). It checks the 23×11
grid, the 252-cycle, collisions, growth, scoring, both seeds, auto-player
determinism, and a seeds 1/1 full-board win.

```sh
# ADAWEBPACK defaults to ~/toolchains/adawebpack-24 and stops if it is missing
./build.sh
```

Then open `docs/index.html` (no server needed). GitHub Pages serves `docs/`
on `main`. Each deploy is two commits: sources first, then the built page.
Curl-verify the live URL and `version.txt` from raw GitHub before announcing.

## Layout

| Path | What it is |
|---|---|
| `src/snake.ads/.adb` | grid, snake, pellets, collisions, score, hashes, action log |
| `src/snake-auto.ads/.adb` | 252-cycle, forward-gap, tail-reach auto-player |
| `src/snake-api.ads/.adb` | integer exports the page calls (`sn_*`) |
| `src/last_chance_handler.adb` | reports file and line to the host if a check fails |
| `tests/smoke.adb` | native `-gnata` smokes, including 23×11 and seeds 1/1 |
| `tests/batch.adb` | 100-seed native batch runner |
| `web/template.html` | the page; `build.sh` fills in the module and the stamp |
| `docs/index.html` | the built page (one file, no CDN) |
| `docs/HOW_WE_GOT_HERE.md` | design history, including the 20×20 slip |
| `docs/ALGORITHM.md` | cycle, gap rule, fitness, report schema |
| `docs/WEB_SAFE.md` | web-safe checklist, ticked here |
| `docs/version.txt` | the same D-005 stamp as the page |

SPARK proofs are not started. Contracts are already in the sources; a proof
run waits until features are frozen.

## Licence

MIT. Copyright (c) 2026 Robert Boettcher.
