#!/usr/bin/env bash
# Assembles the texlive_bundle module archive: a TeX Live tree (TinyTeX), the
# extra packages the consumers need, the Noto CJK faces, qpdf, ghostscript,
# and this repository's module files (MODULE.bazel, BUILD.bazel, *.sh).
#
#   TAG=v1.0.0 tools/make_bundle.sh          # stage + archive out/texlive_bundle-v1.0.0.tar.xz
#   SKIP_TAR=1 tools/make_bundle.sh          # stage only (integration test)
#
# The base archives are pinned by SHA-256 below. The `tlmgr install` step talks
# to a CTAN mirror, so ASSEMBLY is a snapshot of that mirror — but a RELEASED
# archive is immutable and consumers pin it by checksum, which is what makes
# the consuming builds hermetic and reproducible.
set -euo pipefail
cd "$(dirname "$0")/.."

TAG="${TAG:-v0.0.0-dev}"
VERSION="${TAG#v}"

TINYTEX_URL=https://github.com/rstudio/tinytex-releases/releases/download/v2026.08/TinyTeX-linux-x86_64-v2026.08.tar.xz
TINYTEX_SHA=59685643fb4160f779df5e3d7d78266a86818ebb86ac25c7900723b0fd73a7cd
QPDF_URL=https://github.com/qpdf/qpdf/releases/download/v12.4.0/qpdf-12.4.0-bin-linux-x86_64.zip
QPDF_SHA=a3bca240f3bb61efdc3a90be89d1da4ed5e125326c3458c4e62df53ff4f153e3
GS_URL=https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs1000/ghostscript-10.0.0-linux-x86_64.tgz
GS_SHA=176ad1cbad402ae5930521f954ad70dffaaf8d625cf508feeea4f9bf2e61f3d4
NOTO_BASE=https://github.com/notofonts/noto-cjk/raw/main/Sans/OTF/Japanese
NOTO_REGULAR_SHA=68a3fc98800b2a27b371f2fb79991daf3633bd89309d4ffaa6946fd587f375b5
NOTO_BOLD_SHA=e53dcb0dcb2922e45d01aae1ebd2f382bb81d4229b18b6b883bd170678af1f76
# TL2022 colortbl (v1.0f): v1.0l (2026) loops on tikz `align` nodes in
# documents that use xcolor's `table` mode.
COLORTBL_URL=https://texlive.info/tlnet-archive/2023/03/01/tlnet/archive/colortbl.tar.xz
COLORTBL_SHA=6fdd547222edc4bdd2c8ea0f4c31ae7c462bcc59ca0bc63cd3fedae7482fa849
# Beyond the full TinyTeX variant, the packages the consuming documents need.
PACKAGES="ieeetran pgfplots tikz-timing circuitikz pgfgantt esint pgfopts"

OUT=out
DL=$OUT/downloads
STAGE=$OUT/stage/texlive_bundle
mkdir -p "$DL"

fetch() { # url sha dest
  local url="$1" sha="$2" dest="$3"
  if [ -f "$dest" ] && echo "$sha  $dest" | sha256sum -c --quiet 2>/dev/null; then
    return
  fi
  curl -fsSL -o "$dest" "$url"
  echo "$sha  $dest" | sha256sum -c
}

echo ">> Fetching pinned archives"
fetch "$TINYTEX_URL" "$TINYTEX_SHA" "$DL/tinytex.tar.xz"
fetch "$QPDF_URL" "$QPDF_SHA" "$DL/qpdf.zip"
fetch "$GS_URL" "$GS_SHA" "$DL/gs.tgz"
fetch "$NOTO_BASE/NotoSansCJKjp-Regular.otf" "$NOTO_REGULAR_SHA" "$DL/NotoSansCJKjp-Regular.otf"
fetch "$NOTO_BASE/NotoSansCJKjp-Bold.otf" "$NOTO_BOLD_SHA" "$DL/NotoSansCJKjp-Bold.otf"
fetch "$COLORTBL_URL" "$COLORTBL_SHA" "$DL/colortbl.tar.xz"

echo ">> Staging the TeX tree"
rm -rf "$STAGE"; mkdir -p "$STAGE"
tar xf "$DL/tinytex.tar.xz" -C "$STAGE" --strip-components=1   # drops .TinyTeX/

# tlmgr and kpathsea locate the tree from their own path; it must be absolute.
STAGE_ABS="$(cd "$STAGE" && pwd)"
TLMGR="$STAGE_ABS/bin/x86_64-linux/tlmgr"
echo ">> Installing extra TeX packages: $PACKAGES"
"$TLMGR" update --self > /dev/null
# shellcheck disable=SC2086
"$TLMGR" install $PACKAGES > /dev/null

echo ">> Pinning colortbl v1.0f"
mkdir -p "$OUT/colortbl"; rm -rf "$OUT/colortbl"; mkdir -p "$OUT/colortbl"
tar xf "$DL/colortbl.tar.xz" -C "$OUT/colortbl"
mkdir -p "$STAGE/texmf-local/tex/latex/colortbl"
cp "$(find "$OUT/colortbl" -name colortbl.sty | head -1)" "$STAGE/texmf-local/tex/latex/colortbl/"

echo ">> Adding Noto Sans CJK JP"
mkdir -p "$STAGE/texmf-local/fonts/opentype/noto-cjk"
cp "$DL"/NotoSansCJKjp-*.otf "$STAGE/texmf-local/fonts/opentype/noto-cjk/"
"$STAGE_ABS/bin/x86_64-linux/mktexlsr" > /dev/null 2>&1

echo ">> Adding qpdf and ghostscript"
mkdir -p "$STAGE/tools/qpdf" "$STAGE/tools/gs"
unzip -q -o "$DL/qpdf.zip" -d "$STAGE/tools/qpdf"
tar xzf "$DL/gs.tgz" -C "$STAGE/tools/gs" --strip-components=1
chmod +x "$STAGE/tools/qpdf/bin/qpdf" "$STAGE/tools/gs/gs-1000-linux-x86_64"

echo ">> Pruning transient files"
rm -f "$STAGE"/texmf-var/web2c/tlmgr*.log
rm -rf "$STAGE"/tlpkg/backups/*

echo ">> Installing the module files (version $VERSION)"
cp BUILD.bazel pdflatex.sh pdfinfo.sh pdfunite.sh gs.sh "$STAGE/"
sed "s/^    version = \".*\",\$/    version = \"$VERSION\",/" MODULE.bazel > "$STAGE/MODULE.bazel"
chmod +x "$STAGE"/*.sh

if [ -n "${SKIP_TAR:-}" ]; then
  echo ">> SKIP_TAR set; staged tree at $STAGE"
  exit 0
fi

NAME="texlive_bundle-$TAG"
echo ">> Archiving $OUT/$NAME.tar.xz"
rm -rf "$OUT/$NAME"; cp -al "$STAGE" "$OUT/$NAME"
XZ_OPT="-6 -T0" tar --sort=name --owner=0 --group=0 -cJf "$OUT/$NAME.tar.xz" -C "$OUT" "$NAME"
sha256sum "$OUT/$NAME.tar.xz"
