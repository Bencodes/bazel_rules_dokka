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

gfm_docs="$(rlocation "$1")"
html_docs="$(rlocation "$2")"
javadoc_docs="$(rlocation "$3")"

test -f "${gfm_docs}/index.md" || {
  echo "Missing GFM index under ${gfm_docs}" >&2
  exit 1
}
grep -q "Example API" "${gfm_docs}/index.md" || {
  echo "GFM index does not name the module" >&2
  exit 1
}

test -f "${html_docs}/index.html" || {
  echo "Missing HTML index under ${html_docs}" >&2
  exit 1
}
grep -q "Example API" "${html_docs}/index.html" || {
  echo "HTML index does not name the module" >&2
  exit 1
}

test -f "${javadoc_docs}/index.html" || {
  echo "Missing Javadoc index under ${javadoc_docs}" >&2
  exit 1
}
grep -q "Example API" "${javadoc_docs}/index.html" || {
  echo "Javadoc index does not name the module" >&2
  exit 1
}
