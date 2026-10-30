# texlive_bundle

[![Test](https://github.com/filmil/texlive-bundle/actions/workflows/test.yml/badge.svg)](https://github.com/filmil/texlive-bundle/actions/workflows/test.yml)
[![Tag and Release](https://github.com/filmil/texlive-bundle/actions/workflows/tag-and-release.yml/badge.svg)](https://github.com/filmil/texlive-bundle/actions/workflows/tag-and-release.yml)

A complete, self-contained hermetic LaTeX toolchain as a **Bazel module**: a
TeX Live tree (TinyTeX-based), qpdf backing the `pdfinfo`/`pdfunite` contract,
ghostscript, and the toolchain wiring for
[`rules_latex_host`](https://github.com/filmil/bazel_rules_latex_host) — all
in one pinned, checksummed module archive.

## Use

`.bazelrc` — the module lives in the custom registry; keep BCR too:

```
common --registry=https://raw.githubusercontent.com/filmil/bazel-registry/main
common --registry=https://bcr.bazel.build
```

`MODULE.bazel`:

```starlark
bazel_dep(name = "rules_latex_host", version = "0.1.0")
bazel_dep(name = "texlive_bundle", version = "1.0.0")

register_toolchains("@texlive_bundle//:all")
```

That is all: `latex_document` and `combined_pdf` targets now build in the
sandbox with the vendored tools; nothing needs to be installed on the machine.
The binaries are linux-x86_64; on other platforms this toolchain is skipped
and resolution falls back to the `system` toolchain of `rules_latex_host`.

A consumer that needs an engine directly (e.g. lualatex from a genrule) can
reference the tree: `@texlive_bundle//:files` stages it, and the engines are
under `bin/x86_64-linux/` next to `@texlive_bundle//:pdflatex.sh`.
`@texlive_bundle//:lualatex.sh` runs LuaLaTeX with its font cache outside the
tree (see below); prefer it to the bare engine.

LuaLaTeX's font loader, luaotfload, writes a cache under `TEXMFVAR`. TinyTeX
points `TEXMFVAR` at the tree's own `texmf-var`, which is writable inside
Bazel's repository cache, so actions calling the bare engine would share one
cache holding paths into each other's sandboxes. The bundle's `texmf.cnf`
makes `TEXMFCACHE` follow `TEXMFVAR`, and `lualatex.sh` points `TEXMFVAR` at a
fresh temporary directory unless the caller sets it. A consumer running the
engine directly should set `TEXMFVAR` to a directory of its own.

## What is inside

* TinyTeX v2026.08, full variant (TeX Live 2026) — pdflatex, lualatex, and
  their pregenerated formats.
* Extra packages: `ieeetran`, `pgfplots`, `tikz-timing`, `circuitikz`,
  `pgfgantt`, `esint`, `pgfopts`, `dvisvgm`, `xurl`, and for Serbian under
  LuaLaTeX with polyglossia, `hyphen-serbian` (registered in
  `language.dat.lua`) and `luavlna`.
* `dvisvgm` is a binary, under `bin/x86_64-linux/` like the engines, so a
  consumer can render a TikZ picture to SVG (`latex` then `dvisvgm`) without
  ghostscript: the DVI path needs none, while `dvisvgm --pdf` requires
  ghostscript older than 10.01.
* `colortbl` pinned back to v1.0f (2022): v1.0l (2026) loops on tikz `align`
  nodes in documents that use xcolor's `table` mode.
* Noto Sans CJK JP (Regular, Bold) in `texmf-local`, found by name through
  luaotfload.
* qpdf 12.4.0 (as `pdfinfo`/`pdfunite`) and ghostscript 10.0.0.

## Maintenance

The TeX tree is not in git; `tools/make_bundle.sh` assembles it from archives
pinned by SHA-256 at the top of the script, and CI builds real PDFs against
the staged result (`integration/`). To change the bundle, edit the pins or the
package list, and land the change as a conventional commit (`feat:` for new
content, `fix:` for repairs). The monthly `Tag and Release` workflow (or a
manual dispatch) then tags a release, uploads
`texlive_bundle-<tag>.tar.gz`, and opens a registry PR via `publish.yml`.

The `tlmgr install` step samples a moving CTAN mirror at assembly time, so
assembly is a snapshot — but every *released* archive is immutable and pinned
by checksum, which is what the consuming builds rely on.

Licenses: the TeX packages keep their upstream licenses (see `LICENSE.TL` and
`LICENSE.CTAN` in the tree); the Noto fonts are under the SIL OFL 1.1; qpdf
and ghostscript keep their own licenses in `tools/`.
