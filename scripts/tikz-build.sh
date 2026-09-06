#!/usr/bin/env bash

set -euo pipefail

# Build one TikZ figure:  blog/images/<name>.tex -> _build/tikzgen/<name>.svg
#
# Usage: tikz-build.sh SRC.tex OUT.svg
#
# latexmk keeps its intermediates in the persistent _build/latex/, so a
# figure only recompiles when its source (or latexmk's own state) demands
# it; ninja runs one instance of this script per figure, in parallel.

src=$1
out=$2

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
latexdir=$root/_build/latex

mkdir -p "$latexdir" "$(dirname -- "$out")"

# Every lualatex run probes a fixed-name file ($TEXMFVAR/fonts/m_t_x_t_e_s_t.tmp)
# in the shared font-cache directory, so concurrent lualatex processes
# collide there: latexmk sees the foreign writes as unstable output ("needed
# too many passes") and luaotfload can abort outright.  Give this build its
# own TEXMFVAR and expose the (warm) caches read-only through symlinks; the
# per-run probe then lands in a private directory.  As a side effect the
# build no longer dirties the user's font cache.
texmfvar=$(mktemp -d)
trap 'rm -rf "$texmfvar"' EXIT
mkdir -p "$texmfvar/fonts"
if [[ -d $HOME/.cache/texmf/fonts ]]; then
	for entry in "$HOME/.cache/texmf/fonts"/*; do
		[[ -e $entry ]] || continue
		ln -s "$entry" "$texmfvar/fonts/$(basename -- "$entry")"
	done
fi

TEXMFVAR=$texmfvar latexmk -silent -lualatex -interaction=nonstopmode \
	-outdir="$latexdir" "$src"
# Without a usable session bus, inkscape skips its single-instance DBus
# handshake: concurrent converter instances would otherwise race for the
# bus name and abort (Gio::DBus::Error).
DBUS_SESSION_BUS_ADDRESS=/dev/null inkscape --pdf-poppler \
	--export-type=svg --export-text-to-path --export-area-drawing \
	--export-filename="$out" "$latexdir/$(basename -- "${src%.tex}").pdf"
