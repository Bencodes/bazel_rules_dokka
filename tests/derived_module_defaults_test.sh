#!/usr/bin/env bash

# --- begin runfiles.bash initialization v3 ---
set -uo pipefail
f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null ||
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -d ' ' -f 2-)" 2>/dev/null ||
  source "$0.runfiles/$f" 2>/dev/null ||
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -d ' ' -f 2-)" 2>/dev/null ||
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -d ' ' -f 2-)" 2>/dev/null ||
  {
    echo >&2 "ERROR: cannot find $f"
    exit 1
  }
f=
set -e
# --- end runfiles.bash initialization v3 ---

docs="$(rlocation "$1")"
module_path="tests/fixtures/derived_defaults"

test -f "${docs}/index.html" || {
  echo "Missing aggregate index under ${docs}" >&2
  exit 1
}
test -f "${docs}/${module_path}/index.html" || {
  echo "Missing module at its label-derived path: ${module_path}" >&2
  exit 1
}
grep -Fq "Derived Module Defaults" "${docs}/index.html" || {
  echo "Aggregate index does not contain its title" >&2
  exit 1
}
grep -Fq ">docs</a>" "${docs}/index.html" || {
  echo "Aggregate index does not contain the label-derived module name" >&2
  exit 1
}
grep -Fq "href=\"${module_path}/index.html\"" "${docs}/index.html" || {
  echo "Aggregate index does not link to the label-derived module path" >&2
  exit 1
}
