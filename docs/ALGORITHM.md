# Auto-player and report

## Board

23 cells wide, 11 high, 253 cells. Start length 3, 10 points per pellet,
so a full clear is 250 pellets and score 2500, length 253. Walls and the
body kill; if no legal heading remains the death reason is `trapped`.

The opening snake occupies three consecutive cells of the near-cycle and
heads Down:

- head (12, 6), neck (12, 5), tail (12, 4), direction Down.

Those cells lie on an even column that the cycle traverses downward
through rows 2..11.

## The 252-cell near-cycle

A 23×11 grid is odd×odd, so it has no Hamiltonian cycle (the chessboard
colouring is 127 vs 126). Delete one cell of the larger colour class,
`(23, 1)` (top of the last column, x+y even), and the remaining 252 cells
do admit a cycle.

The cycle, in order:

1. Row 1, columns 1..22, left to right: `(1,1) → … → (22,1)`.
2. A ladder on columns 22 and 23 through rows 2..11, in pairs:
   `(22,2) → (23,2) → (23,3) → (22,3) → (22,4) → … → (23,11) → (22,11)`.
3. Columns 21 down to 1, rows 2..11: odd columns go up from row 11 to
   row 2, even columns go down from row 2 to row 11, stepping left at
   the end of each column. Column 1 finishes `(1,2) → (1,1)` and closes.

`Cycle_Index` is 0..251 in that order; `Cycle_Next` is the heading to the
next cell. The functions are in `src/snake-auto.adb`. Native smoke walks
the cycle, checks that 252 indices are unique, and checks it returns to
the start head.

## Forward-gap shortcuts (no jump over the tail)

The auto-player uses only what a player can see. For each legal heading
it first asks whether, after the imagined step (eat or slide), the new
head can still reach the new tail by BFS. A last-pellet eat that fills
the board is treated as safe (it is a win; there is no free cell left to
walk).

Among those tail-safe headings, only a **forward-gap** move is taken
while head and tail are both on the cycle: the neighbour C must lie
strictly after the head and not after the tail along the cycle
(`Forward_Dist(head, C) ≤ Forward_Dist(head, tail)`, strict if this step
eats and the tail will not vacate).

- If the pellet is on the cycle and inside that gap, the player takes the
  **longest** such jump that does not skip the pellet. That is the
  strongest safe shortcut and is why turns stay well below a raw “follow
  the cycle all the way around” tour.
- If the pellet is behind the tail (in cells the last shortcut skipped)
  or is the omitted cell and the head is not yet adjacent, the player
  takes cycle-next (the smallest gap step) until a safe approach exists.

Stepping over the tail on the cycle is never allowed. That is what
trapped v0.1: a greedy path left the body off a coherent gap, then the
snake looped in a pocket with the pellet unapproachable.

## Early-game in-gap shortest path

While the snake is short, a longest cycle-jump still walks far around
the board when the pellet’s forward cycle distance is large (on
Robert’s v0.3 seeds 1/1 report the first pellet was Manhattan 13 but
cycle distance 143, and the first ten pellets used 214 turns against
a Manhattan sum of 102). v0.4 therefore, when `Length` is at most
`Early_Direct_Length` (60), takes a **shortest grid path that stays
inside the current forward gap and does not skip the pellet on the
cycle**, provided a virtual run of that path stays tail-safe (BFS to
the new tail after each imagined step, including the eat). Between 61
and `Direct_Blend_Length` (120) that path is taken only if the cycle
distance is at least twice the path length. Above 120, play is the
same 252-cycle / forward-gap policy as v0.3.

The path is rebuilt each turn and its first step is always a legal
no-skip gap neighbour, so the body stays a forward cycle set and
mid-game gap play is unchanged. An unconstrained shortest path that
leaves the gap (or jumps past the pellet) was tried and rejected: it
shaved more early turns but could loop without eating.

## Endgame hold (no new holes)

A cycle jump (`Forward_Dist > 1` to a grid neighbour) leaves a hole
behind the head, in cells the body now skips. If the next pellet lands
in that hole, it is not in the forward gap, and Auto must walk almost
the whole remaining cycle (often ~251 turns) before the tail opens it.
On Robert’s v0.5 seeds 1/1 report (18,396 turns), 96% of turns were
those “food not in the gap” chases, mostly mid and late game; in-gap
chases were already close to a shortest path (692 turns vs BFS 656).

From `Endgame_Hold_Length` (100), Auto therefore takes only
`Cycle_Next` (and the omitted-cell one-off). Early in-gap shortest
paths (length ≤ 60, blending until 120) are unchanged, so the first
ten pellets stay as in v0.4/v0.5. Raising the midgame direct thresholds
instead opened more holes and *increased* total turns on the 100-seed
batch.

## One-off for the omitted cell

`(23, 1)` is not on the cycle. If the pellet is there and the head is
adjacent and the step is tail-safe, the player steps onto it. Mid-game
it then steps back onto a tail-safe cycle neighbour. When 252 cells are
already filled and `(23, 1)` is the last empty cell, that one-off fills
the board and wins.

## Fitness and seeds

`fitness = score × 100000 − turns`. Length is not in the formula; it
only increases by one when a pellet is eaten. The pellet seed drives
`Place_Food`. The behaviour seed is used only to break ties between
equal-scoring headings (`Pick_Tied`).

## poncelet-report v1

On Auto-stop (Stop, death, or win) the page downloads a JSON file named
`snake-report-<stamp>-p<pellet>-b<behaviour>.json`. Fields include
stamp, both seeds, `test_key`, state hash, action log, events, and
`custom`:

- score, length, turns, bests, fitness, auto, alive, won
- `reason` (the JS stop reason: `win`, `die`, `stop`, …)
- `death_reason` (`none`, `wall`, `self`, `trapped`)
- `enclosed_area` (free cells reachable from the head)
- `grid_width`, `grid_height` (23 and 11)
- `interval_ms`, `log_cap` (65536), `log_truncated`
- `debug` (whether the Debug toggle was on; it only affects Auto speed)

The action log stores one integer per turn: `Code_Of(direction)`, plus
10 if the heading came from Auto (so 11..14 are auto moves). The log is
a fixed array, cap 65536. New moves after the cap are dropped and
`log_truncated` becomes true; the report still names the cap. A full
23×11 clear under this player has been well under the cap (about 10–12k
turns in the v0.6 batch, 18–19k in v0.3–v0.5).
