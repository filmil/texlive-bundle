# texlive-bundle

Pinned, self-contained TeX Live trees for hermetic Bazel LaTeX builds with
[`rules_latex_host`](https://github.com/filmil/bazel_rules_latex_host). Each
release holds one immutable tarball; consumers reference it by URL and SHA-256
from `MODULE.bazel`:

```starlark
hermetic_latex = use_extension(
    "@rules_latex_host//latex:extensions.bzl",
    "hermetic_latex",
)
hermetic_latex.toolchain(
    texlive_url = "https://github.com/filmil/texlive-bundle/releases/download/<tag>/<name>.tar.xz",
    texlive_sha256 = "<sha256>",
    texlive_strip_prefix = "<name>",
)
```

## Bundles

* `20260826a` — `texlive-tutorials-20260826a`: TinyTeX v2026.08 (full
  variant) plus `ieeetran`, `pgfplots`, `tikz-timing`, `circuitikz`,
  `pgfgantt`, `esint`, `pgfopts`; Noto Sans CJK JP (Regular, Bold) in
  `texmf-local`; pregenerated `pdflatex` and `lualatex` formats; `colortbl`
  pinned back to v1.0f (2022) because v1.0l (2026) loops on tikz `align`
  nodes in documents that use xcolor's `table` mode. Built for
  [`filmil/tutorials`](https://git.hdlfactory.com/filmil/tutorials).
  sha256: `17a2091832dce666a27d62fa7957b3501aec562203529ceeb21c0ef59d4d9a3a`

## Rebuilding a bundle

Start from a TinyTeX release, `tlmgr install` the extra packages, drop fonts
into `texmf-local/fonts/opentype/`, run `mktexlsr`, delete
`texmf-var/web2c/tlmgr*.log` and `tlpkg/backups/*`, rename the tree to the
bundle name, and `tar cJf <name>.tar.xz <name>`.

Licenses: the TeX packages keep their upstream licenses (see the tree's
`LICENSE.TL`, `LICENSE.CTAN`); the Noto fonts are under the SIL OFL 1.1.
