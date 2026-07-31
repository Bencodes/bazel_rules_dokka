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
    echo "Missing multi-module documentation index: ${index}" >&2
    exit 1
  }
done

grep -Fq "Project API Reference" "${docs}/index.html" || {
  echo "Root index does not contain the aggregate title" >&2
  exit 1
}
grep -Fq 'href="api/index.html"' "${docs}/index.html" || {
  echo "Root index does not link to the API module" >&2
  exit 1
}
grep -Fq 'href="data/index.html"' "${docs}/index.html" || {
  echo "Root index does not link to the Data module" >&2
  exit 1
}
grep -Fq "API" "${docs}/api/index.html" || {
  echo "API module was not aggregated" >&2
  exit 1
}
grep -Fq "Data" "${docs}/data/index.html" || {
  echo "Data module was not aggregated" >&2
  exit 1
}
grep -Fq 'href="../index.html"' "${docs}/api/index.html" || {
  echo "API module does not link back to the aggregate root" >&2
  exit 1
}
if grep -R -Fq "dokka-template-command" "${docs}"; then
  echo "Aggregate output still contains delayed Dokka template commands" >&2
  exit 1
fi
if grep -R -Eq "bazel-out|[/\\\\]sandbox[/\\\\]" "${docs}"; then
  echo "Aggregate output contains a build-time path" >&2
  exit 1
fi
