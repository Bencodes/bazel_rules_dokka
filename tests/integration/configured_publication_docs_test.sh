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

for index in \
  "${docs}/index.html" \
  "${docs}/api/index.html" \
  "${docs}/data/index.html"; do
  test -f "${index}" || {
    echo "Missing configured publication index: ${index}" >&2
    exit 1
  }
done

grep -Fq "Configured Project API Reference" "${docs}/index.html" || {
  echo "Configured publication does not contain its title" >&2
  exit 1
}
grep -Fq "rules_dokka aggregate footer" "${docs}/index.html" || {
  echo "Configured publication does not use its reusable plugin configuration" >&2
  exit 1
}
grep -Fq 'href="api/index.html"' "${docs}/index.html" || {
  echo "Configured publication does not link to the API module" >&2
  exit 1
}
grep -Fq 'href="data/index.html"' "${docs}/index.html" || {
  echo "Configured publication does not link to the Data module" >&2
  exit 1
}
if grep -R -Fq "dokka-template-command" "${docs}"; then
  echo "Configured publication contains delayed Dokka template commands" >&2
  exit 1
fi
if grep -R -Eq "bazel-out|[/\\\\]sandbox[/\\\\]" "${docs}"; then
  echo "Configured publication contains a build-time path" >&2
  exit 1
fi
