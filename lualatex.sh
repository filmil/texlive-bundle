#!/usr/bin/env bash
# Hermetic LuaLaTeX (vendored tree in this module).
#
# The binary is relocatable: kpathsea locates `texmf-dist` from the engine's
# own path. It must be exec'd through its `lualatex` name: the engine selects
# its format from argv[0].
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# kpathsea shells out for anything it has to generate on demand; putting the
# vendored bin directory first keeps that path hermetic too.
export PATH="$here/bin/x86_64-linux${PATH:+:$PATH}"

# luaotfload keeps its font cache under TEXMFVAR (texmf.cnf points
# TEXMFCACHE at it). By default that is the distribution's own texmf-var,
# which every action shares. Send it somewhere writable and private to the
# caller instead; a caller that sets TEXMFVAR itself keeps its choice.
export TEXMFVAR="${TEXMFVAR:-$(mktemp -d "${TMPDIR:-/tmp}/texlive_bundle.XXXXXX")}"
mkdir -p "$TEXMFVAR"

exec "$here/bin/x86_64-linux/lualatex" "$@"
