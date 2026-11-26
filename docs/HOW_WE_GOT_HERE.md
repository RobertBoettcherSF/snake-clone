# How we got here

A short history of this Snake clone, for a human or an AI coming to the tree
cold. Standing Ada/web rules live in the private ada-bot-brain; this file only
records what happened in *this* repo.

## Intent

Plain Ada core compiled to WebAssembly, one self-contained page on GitHub
Pages from `main` `/docs`. The engine decides movement, pellets, score and
the auto-player. JavaScript draws the canvas, wires input, and writes the
F9 / Auto-stop `poncelet-report`. The host ABI is integers only.

The intended board was **23×11** (253 cells, odd). Because 253 is odd, a
grid graph has no Hamiltonian cycle, so the auto-player was meant to follow
a **252-cell near-cycle** with safe shortcuts.

## v0.1 — a greedy player on the wrong grid

v0.1 shipped a **20×20** board (400 cells). That was a slip: a single
`Grid_Size : constant := 20` was used for both axes, the page drew an n×n
canvas, and nothing in the smokes asserted 23×11. The auto-player was a
greedy fitness of “eat if legal, else walk toward the pellet, keep some
free space.” Fitness was already `score × 100000 − turns` (score first,
turns break ties). Two seeds: pellet placement, and behaviour for
tie-breaks only.

On seeds 1/1 that player died at score 570, length 60, turns 867
(best turns 849), trapped late in a pocket.

## v0.2 — a 400-cycle that worked, still on 20×20

v0.2 kept 20×20. Because 400 is even, a true Hamiltonian cycle exists, and
the auto-player was given tail-reach BFS, virtual food look-ahead, a
compact-space term, and a late cycle. A first version entered the cycle
only at length 252 (a leftover of the 23×11 plan) and livelocked: greedy
shortcuts had taken the body off the cycle, then tail-follow looped
without eating.

The fix was a 400-cycle that matches the opening snake (reserved column
20, even rows going right), with **forward-gap** shortcuts from turn one:
only step to a neighbour that lies on the cycle between the head and the
tail, and only jump toward a pellet that itself sits in that gap. A 100-seed
native batch then won 100/100 and filled the board every time (score 3970,
length 400, mean turns 44073). Seeds 1/1 won in 42590 turns.

Robert’s own v0.2 Auto-stop report on seeds 1/1 confirmed that win
(stamp `v0.2 b20261126-1123 a2f6d83`, fitness 396957410). The report did
not include the grid size.

v0.2 was still the wrong grid. The README even argued that a 252-cycle
was “not required” because 400 is even — honest for that board, wrong
against the original 23×11 request.

## v0.3 — 23×11, 252-cycle, simpler auto-player

v0.3 changes the core, the ABI and the page to **23×11**, with a smoke
test that the grid is 23×11 and not square so the slip cannot recur
quietly. The auto-player follows a 252-cell near-cycle that omits (23,1),
keeps the forward-gap / no-jump-over-tail rule, and takes a tail-safe
one-off onto the omitted cell (the last pellet is always such a move when
the head is adjacent). Unused recovery (shortest-path look-ahead, stall,
hug/hole scoring) was dropped; the 23×11 batch did not need a fallback.
`Body_Store` was folded into `Body_Array`. Magic `Mid := 10` is gone;
the opening snake is named start cells that already lie on the cycle.

The action log has a fixed cap of 65536 (no heap). That covers a full
23×11 fill even if every pellet waited a whole cycle (~63k turns). If a
run still overflows, later moves are dropped and the report sets
`log_truncated`. The report also carries `grid_width`, `grid_height`,
`death_reason`, `enclosed_area`, and `log_cap`.

Batch scores and turns are **not directly comparable** to v0.2: the board
is smaller (max score 2500, not 3970). See the README table.


## v0.4 — shorter early game, same 23×11 cycle

Robert’s v0.3 Auto-stop report on seeds 1/1 (stamp
`v0.3 b20261126-1310 8a923fb`) confirmed a full clear in 18830 turns
(score 2500, length 253, fitness 249981170, log not truncated). Mid
and endgame already played well. The waste was at the start: the first
pellet sat at Manhattan 13 but 143 steps forward on the cycle, and was
eaten on turn 41; the first ten pellets used 214 turns against a
Manhattan sum of 102 (extra 112). Many early pellets had a tiny
Manhattan distance and a huge forward cycle distance, because with a
short snake the forward gap is almost the whole board and “food in the
gap” still means walking the long way around.

v0.4 keeps the 252-cycle and the forward-gap / no-jump-over-tail rule,
and while the snake is short takes a shortest grid path that stays
inside that gap and does not skip the pellet, after a virtual
tail-safety check. A gradual blend (always at length ≤ 60, only if the
cycle way is at least twice as long until 120) hands play back to the
same mid/endgame policy. An earlier idea — an unconstrained shortest
path plus a “rejoin the cycle after eating” check — cut early turns
further but livelocked: the virtual rejoin did not match live play, and
chained shortcuts left a body the gap rule could not recover.

`Compact_Length` (unused since the v0.3 simplification) is removed. The
100-seed batch still wins 100/100, now also reporting turns to the first
ten pellets. See the README table. The v0.3 README figure of 44,544
bytes for `docs/index.html` was a two-byte slip; the deployed v0.3 page
was 44,542 bytes.

## Fitness, seeds, report, build

- Fitness of a finished run: `score × 100000 − turns`. Length is not a
  term; it only grows by eating (10 points per pellet).
- Pellet seed drives placement. Behaviour seed breaks auto-player ties
  only. Same seeds, same run.
- Auto starts immediately. Stop, or a death or win during Auto, downloads
  a `poncelet-report` v1 (see `docs/ALGORITHM.md` for the fields).
- Native smoke: `./run-tests.sh` (`-gnata -gnatwa -gnatwe`, gnatmake, not
  `gprbuild -P`). Batch: `./run-batch.sh`. Wasm: `./build.sh`, with
  `ADAWEBPACK` defaulting to `~/toolchains/adawebpack-24` and never
  downloading a toolchain.
- Pages deploys are two commits on `main`: sources first, then the built
  `docs/index.html` so the stamp can name the source SHA without a
  trailing `+`. Curl-verify the live page, `version.txt` from raw GitHub
  (not githack), and a commit-pinned githack URL of the built page.
