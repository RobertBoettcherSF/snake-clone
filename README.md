# Snake Clone

A Snake game whose grid, movement, pellets, collisions, score and auto-player
all live in **Plain Ada**, compiled to WebAssembly and drawn by one
self-contained page.

**Live page:** https://robertboettchersf.github.io/snake-clone/

The Ada core talks to the page with integers only. JavaScript draws the
canvas, wires keys, swipes and buttons, and writes the F9 / Auto-stop report.
It does not decide where the snake turns or where a pellet lands.

## Play

- 20×20 grid, wall and self-collision deaths, 10 points per pellet, length
  grows by 1. Speed rises every 5 pellets (150 ms down to a 50 ms floor).
- **Score**, **Length** and **Turns**, each with its best so far. The Turns
  best is the fewest turns used to reach the top score (a tie on score with
  fewer turns improves it). Bests are kept in the browser.
- Two seeds, both shown and editable: **pellet** placement and **behaviour**
  (auto-player tie-breaks only). Same seeds give the same run.
- **Auto** starts a run at once and becomes **Stop** while auto-play is
  running. Stop, or a death or win during Auto, downloads a `poncelet-report`
  v1 file (stamp, both seeds, score, length, turns, bests, fitness, action
  log, state hash, death reason, enclosed-area size).
- Arrows or WASD, swipe on a phone. Space pauses, R restarts, F9 (or
  **Debug**) pauses and downloads a report. Sound off, en-GB / de / es / fr.

The auto-player uses only what a player can see. A heading is taken only if
the new head can still reach its own tail (BFS). A pellet is taken only when
it sits in the forward gap of a zig-zag Hamiltonian cycle on the 20×20 grid
(after the eat, the tail is still ahead on the cycle); otherwise the snake
follows the cycle until a safe approach exists. From about one third of the
board (length 133) the stall-recovery term prefers moves that hug walls or
the body and penalises holes in the free area. Score still ranks ahead of
turns; turns break ties. A finished run is ranked as
`fitness = score × 100000 − turns`.

The grid has 400 cells (even), so a true Hamiltonian cycle exists. The
player follows that 400-cycle from the first turn, with safe shortcuts
toward the pellet. A 252-cell near-cycle is not required on this board.

## Auto-player batch (v0.1 vs v0.2)

Native runs of 100 seed pairs `(k, k)` for `k = 1 .. 100`, each played to a
win, a death, or a 200 000-turn cap. v0.1 numbers come from the same runner
against commit `5c04bd7`.

| | v0.1 | v0.2 |
|---|---:|---:|
| Mean score | 761.7 | 3970.0 |
| Median score | 775.0 | 3970.0 |
| Mean length | 79.1 | 400.0 |
| Median length | 80.5 | 400.0 |
| Mean turns | 1597.0 | 44073.0 |
| Median turns | 1535.0 | 44099.0 |
| Wins | 0 / 100 | 100 / 100 |

Seeds **1/1** (the v0.1 run that died at score 570, length 60, turns 867,
best turns 849):

| | v0.1 | v0.2 |
|---|---:|---:|
| Score | 570 | 3970 |
| Length | 60 | 400 |
| Turns | 867 | 42590 |
| Result | died | won (board full) |

v0.2 fills the board on every batch seed (score 3970 is 397 pellets × 10).
Turns are higher because the player stays on the cycle instead of taking
unsafe shortcuts that used to trap it.

The default `./run-tests.sh` smoke includes a seeds 1/1 check that must beat
score 570 and must terminate. The 100-seed batch is `./run-batch.sh`.

## Build and test

Scripts work from a fresh clone. They expect GNAT 12.3 (or another warning-free
GNAT 14) on `PATH`. They never download a toolchain.

```sh
./run-tests.sh
```

That is a native `-gnata` smoke of the same sources as the wasm build
(`-gnat2022 -gnatwa -gnatwe`, statically linked). It checks collisions,
growth, scoring, both seeds, auto-player determinism, and the seeds 1/1
score floor.

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
| `src/snake-auto.ads/.adb` | tail-safe, cycle-following auto-player |
| `src/snake-api.ads/.adb` | integer exports the page calls (`sn_*`) |
| `src/last_chance_handler.adb` | reports file and line to the host if a check fails |
| `tests/smoke.adb` | native `-gnata` smokes, including seeds 1/1 |
| `tests/batch.adb` | 100-seed native batch runner |
| `web/template.html` | the page; `build.sh` fills in the module and the stamp |
| `docs/index.html` | the built page (one file, no CDN) |
| `docs/WEB_SAFE.md` | web-safe checklist, ticked here |
| `docs/version.txt` | the same D-005 stamp as the page |

SPARK proofs are not started. Contracts are already in the sources; a proof
run waits until features are frozen.

## Licence

MIT. Copyright (c) 2026 Robert Boettcher.
