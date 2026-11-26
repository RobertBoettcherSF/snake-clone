#!/bin/sh
# Compile the Ada core to wasm32 and inline it into docs/index.html.
# Never downloads a toolchain (D-016).
set -e
cd "$(dirname "$0")"

ADAWEBPACK=${ADAWEBPACK:-$HOME/toolchains/adawebpack-24}
if [ ! -x "$ADAWEBPACK/usr/bin/llvm-gcc" ]; then
  echo "AdaWebPack not found at $ADAWEBPACK" >&2
  echo "Set ADAWEBPACK to the shared install (default: ~/toolchains/adawebpack-24)." >&2
  echo "This script never downloads the toolchain." >&2
  exit 1
fi

export LD_LIBRARY_PATH="$ADAWEBPACK/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
T=$ADAWEBPACK/usr
LD=$(command -v wasm-ld || true)
if [ -z "$LD" ]; then
  LD=$(ls /usr/bin/wasm-ld-* 2>/dev/null | tail -1 || true)
fi
if [ -z "$LD" ]; then
  echo "wasm-ld not found (install the lld package)" >&2
  exit 1
fi

SOURCE_SHA=${SOURCE_SHA:-$(git rev-parse --short=7 HEAD 2>/dev/null || echo 0000000)}
if git status --porcelain >/dev/null 2>&1 && [ -n "$(git status --porcelain)" ]; then
  SOURCE_SHA="${SOURCE_SHA}+"
fi
# Build clock is Europe/Berlin (D-005).
STAMP="v0.1 b$(TZ=Europe/Berlin date +%Y%m%d-%H%M) $SOURCE_SHA"

rm -rf obj/wasm
mkdir -p obj/wasm docs

# rts-native forbids exception propagation. -gnatp for the wasm build (D-027);
# contracts run in the native smoke (./run-tests.sh).
for F in src/snake.adb src/snake-auto.adb src/snake-api.adb src/last_chance_handler.adb
do
  echo "cc $F"
  "$T/bin/llvm-gcc" -c --target=wasm32 -O2 -gnat2022 -gnatwa -gnatp \
    --RTS="$T/lib/rts-native" -Isrc "$F" -o "obj/wasm/$(basename "${F%.adb}").o"
done

# Keep only wasm / bitcode objects from libgnat.a (spectrum-analyzer pattern).
python3 - "$T/lib/rts-native/adalib/libgnat.a" obj/wasm/libgnat-wasm.a << 'PY'
import os, subprocess, sys
src, dst = sys.argv[1:]
os.makedirs("obj/wasm/rts-pick", exist_ok=True)
members = subprocess.check_output(["ar", "t", src], text=True).split()
keep = []
for i, member in enumerate(members):
    data = subprocess.check_output(["ar", "p", src, member])
    if data.startswith(b"\0asm") or data.startswith(b"BC\xc0\xde"):
        path = os.path.join("obj/wasm/rts-pick", f"{i:04d}-{member}")
        open(path, "wb").write(data)
        keep.append(path)
if not keep:
    sys.exit("no wasm objects in libgnat.a")
subprocess.check_call(["ar", "rcs", dst, *keep])
print(f"rts archive {len(keep)} wasm members, skipped {len(members) - len(keep)}")
PY

EXPORTS="sn_init sn_restart sn_set_seeds sn_act sn_set_auto sn_set_paused
sn_tick sn_score sn_length sn_turns sn_best_score sn_best_turns
sn_best_length sn_fitness sn_alive sn_won sn_auto sn_paused
sn_pellet_seed sn_behaviour_seed sn_food_x sn_food_y sn_dir
sn_interval_ms sn_grid sn_cell sn_hash sn_log_count sn_log_entry
sn_last_event sn_error_line sn_error_length sn_error_char
__gnat_last_chance_handler"

set --
for E in $EXPORTS; do
  set -- "$@" "--export=$E"
done

"$LD" --no-entry --allow-undefined --export-memory --strip-all \
  "$@" \
  -z stack-size=1048576 --initial-memory=16777216 \
  -o obj/wasm/snake.wasm \
  obj/wasm/snake.o obj/wasm/snake-auto.o obj/wasm/snake-api.o obj/wasm/last_chance_handler.o \
  obj/wasm/libgnat-wasm.a

printf '%s\n' "$STAMP" > docs/version.txt
SOURCE_SHA="$SOURCE_SHA" STAMP="$STAMP" python3 tools/embed.py \
  obj/wasm/snake.wasm web/template.html docs/index.html
echo "Built docs/index.html ($(wc -c < obj/wasm/snake.wasm) bytes of WebAssembly), stamp $STAMP"
