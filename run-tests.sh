#!/bin/sh
# Native -gnata smoke of the same sources as the wasm build (D-027, D-015).
# gnatmake (not gprbuild -P) so a host with both GNAT 12 and 14 does not
# bind 12 objects against a 14 runtime. Flags match snake.gpr.
set -e
cd "$(dirname "$0")"
mkdir -p obj/native
gnatmake -gnat2022 -gnata -gnatwa -gnatwe \
  tests/smoke.adb -Isrc -D obj/native -o obj/native/smoke \
  -bargs -static
obj/native/smoke
