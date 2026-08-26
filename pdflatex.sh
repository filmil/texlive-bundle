#!/usr/bin/env bash
# Hermetic TeX engine (vendored tree in this module).
#
# The binary is relocatable: kpathsea locates `texmf-dist` from the engine's
# own path. It must be exec'd through its `pdflatex` name — the engine selects
# its format from argv[0].
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# kpathsea shells out for anything it has to generate on demand; putting the
# vendored bin directory first keeps that path hermetic too.
export PATH="$here/bin/x86_64-linux${PATH:+:$PATH}"

# On-demand generation writes under TEXMFVAR, which points into the
# distribution and is read-only in the sandbox. Send it somewhere writable.
export TEXMFVAR="${TEXMFVAR:-${HOME:-${TMPDIR:-/tmp}}/.texlive_bundle/texmf-var}"
mkdir -p "$TEXMFVAR"

exec "$here/bin/x86_64-linux/pdflatex" "$@"
