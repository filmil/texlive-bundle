#!/usr/bin/env bash
# `pdfinfo` contract (page count only), backed by vendored qpdf.
#   pdfinfo FILE.pdf   ->   a line "Pages:  <n>"
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pdf="${!#}"
pages="$(LD_LIBRARY_PATH="$here/tools/qpdf/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  "$here/tools/qpdf/bin/qpdf" --show-npages "$pdf")"
printf 'Pages:          %s\n' "$pages"
