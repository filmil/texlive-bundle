#!/usr/bin/env bash
# Hermetic ghostscript (vendored in this module). Combined-PDF outline only.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$here/tools/gs/gs-1000-linux-x86_64" "$@"
