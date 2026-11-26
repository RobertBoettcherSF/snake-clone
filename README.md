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
  grows by 1. Speed rises every 5 pellets.
- **Score**, **Length** and **Turns**, each with its best so far. The Turns
  best is the fewest turns used to reach the top score (a tie on score with
  fewer turns improves it). Bests are kept in the browser.
- Two seeds, both shown and editable: **pellet** placement and **behaviour**
  (auto-player tie-breaks only). Same seeds give the same run.
- **Auto** starts a run at once and becomes **Stop** while auto-play is
  running. Stop, or a death during Auto, downloads a `poncelet-report` v1
  file (stamp, both seeds, score, length, turns, bests, fitness, action log,
  state hash).
- Arrows or WASD, swipe on a phone. Space pauses, R restarts, F9 (or
  **Debug**) pauses and downloads a report. Sound off, en-GB / de / es / fr.

The auto-player uses only what a player can see. Each tick it scores the
legal headings: death is rejected, eating is worth a large bonus, a
free-space / tail-reach term prefers moves the snake can survive, and a
Manhattan term walks toward the pellet. Ties are broken from the behaviour
seed. A finished run is ranked as `fitness = score × 100000 − turns`.

## Build and test

Scripts work from a fresh clone. They expect GNAT 12.3 (or another warning-free
GNAT 14) on `PATH`. They never download a toolchain.

```sh
./run-tests.sh
```

That is a native `-gnata` smoke of the same sources as the wasm build
(`-gnat2022 -gnatwa -gnatwe`, statically linked). It checks collisions,
growth, scoring, both seeds, and auto-player determinism.

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
| `src/snake-auto.ads/.adb` | fitness-driven auto-player |
| `src/snake-api.ads/.adb` | integer exports the page calls (`sn_*`) |
| `src/last_chance_handler.adb` | reports file and line to the host if a check fails |
| `tests/smoke.adb` | native `-gnata` smokes |
| `web/template.html` | the page; `build.sh` fills in the module and the stamp |
| `docs/index.html` | the built page (one file, no CDN) |
| `docs/WEB_SAFE.md` | web-safe checklist, ticked here |
| `docs/version.txt` | the same D-005 stamp as the page |

SPARK proofs are not started. Contracts are already in the sources; a proof
run waits until features are frozen.

## Licence

MIT. Copyright (c) 2026 Robert Boettcher.
