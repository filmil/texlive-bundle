#!/usr/bin/env bash
# `pdfunite` contract, backed by vendored qpdf.
#   pdfunite IN1.pdf IN2.pdf ... OUT.pdf
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$#" -lt 2 ]]; then
  echo "usage: pdfunite IN.pdf... OUT.pdf" >&2
  exit 2
fi
inputs=("$@")
out="${inputs[-1]}"
unset 'inputs[-1]'
LD_LIBRARY_PATH="$here/tools/qpdf/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
  "$here/tools/qpdf/bin/qpdf" --empty --pages "${inputs[@]}" -- "$out"
