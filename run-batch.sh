#!/bin/sh
# Native 100-seed batch (not part of the default smoke).
# gnatmake, not gprbuild -P, same flags as run-tests.sh.
set -e
cd "$(dirname "$0")"
mkdir -p obj/native
gnatmake -O2 -gnat2022 -gnata -gnatwa -gnatwe \
  tests/batch.adb -Isrc -D obj/native -o obj/native/batch \
  -bargs -static
obj/native/batch
