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
  log, state hash, grid size, death reason, enclosed-area size, log cap,
  Debug toggle).
- **Debug** is a toggle, on by default, remembered in the browser. With
  Debug on, Auto runs at full speed (as many ticks as fit in about 12 ms
  per animation frame, redraw once per frame) and shows a live moves/s
  figure. Human play always uses the ordinary speed-up, even if Debug is
  on. F9 still pauses and downloads a report.
- Arrows or WASD, swipe on a phone. Space pauses, R restarts, F9 downloads
  a report. Sound off, en-GB / de / es / fr.

The auto-player uses only what a player can see. It follows a 252-cell
near-cycle on the 23×11 board (253 is odd, so no Hamiltonian cycle; the
cell (23, 1) is omitted). A heading is taken only if the new head can
still reach its own tail (BFS), or if the step is the last pellet and
fills the board. Shortcuts stay in the forward cycle gap and never jump
over the tail; the omitted cell is taken by a tail-safe one-off when the
head is adjacent. While the snake is short, it takes a shortest grid path
that stays in that gap (and does not skip the pellet) if a virtual run
stays tail-safe, then blends back to cycle play as length grows. From
length 100 it only follows the cycle itself, so a late jump cannot leave
a hole that costs a full lap. Score ranks ahead of turns; turns break
ties. A finished run is ranked as `fitness = score × 100000 − turns`.

The cycle geometry, the gap rule, the report fields, and why v0.1 trapped
itself are in `docs/ALGORITHM.md`. How the project arrived at 23×11 after
shipping 20×20 by mistake is in `docs/HOW_WE_GOT_HERE.md`.

## Auto-player batch (v0.5 vs v0.6)

Native runs of 100 seed pairs `(k, k)` for `k = 1 .. 100` on the same
23×11 board, each played to a win, a death, or a 200 000-turn cap.
`first10` is the number of turns used to eat the first 10 pellets.
v0.5 is commit `76b2ab2` (the auto-player was unchanged from v0.4).
Earlier 23×11 batches are in `docs/HOW_WE_GOT_HERE.md`.

| | v0.5 (23×11) | v0.6 (23×11) |
|---|---:|---:|
| Mean score | 2500.0 | 2500.0 |
| Median score | 2500.0 | 2500.0 |
| Mean length | 253.0 | 253.0 |
| Median length | 253.0 | 253.0 |
| Mean turns | 18629.1 | 10682.8 |
| Median turns | 18499.0 | 10584.0 |
| Mean first10 | 165.5 | 165.5 |
| Median first10 | 164.0 | 164.0 |
| Wins | 100 / 100 | 100 / 100 |

Seeds **1/1**:

| | v0.5 | v0.6 |
|---|---:|---:|
| Score | 2500 | 2500 |
| Length | 253 | 253 |
| Turns | 18396 | 11790 |
| First 10 pellets | 146 | 146 |
| Result | won (board full) | won (board full) |

The default `./run-tests.sh` smoke asserts the grid is 23×11 (and not
square) and requires seeds 1/1 to fill that board and terminate. The
100-seed batch is `./run-batch.sh`.

## Size (v0.5 → v0.6)

| | v0.5 | v0.6 |
|---|---:|---:|
| Ada `src/` lines | 1,749 | 1,762 |
| of which `snake-auto.adb` | 636 | 643 |
| `web/template.html` lines | 688 | 688 |
| `docs/index.html` | 54,416 bytes | 54,464 bytes |
| Wasm module | 20,409 bytes | 20,444 bytes |

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
| `src/snake-auto.ads/.adb` | 252-cycle, forward-gap, early in-gap shortest path, endgame hold, tail-reach auto-player |
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
