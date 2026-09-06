#!/usr/bin/env bash

set -euo pipefail

# meson compile -C _build cleanall
#
# Remove every build product: figures, latexmk intermediates, stamps,
# everything built into the pages repository (its .git stays), and the
# exported posts/images under the Hugo site, which the next export
# regenerates from the Org sources.  For a lighter wipe, `meson compile
# --clean` removes just the declared outputs (figures and stamps).

root=$(cd -- "$1" && pwd -P)

rm -rf "$root/_build/tikzgen" "$root/_build/latex" \
	"$root/_build/export.stamp" "$root/_build/site.stamp"

if [[ -e $root/_build/hugogen ]]; then
	find "$root/_build/hugogen" -mindepth 1 -maxdepth 1 ! -name .git \
		-exec rm -rf {} +
fi

rm -rf "$root/publisher/hugo/content/posts" \
	"$root/publisher/hugo/static/images" \
	"$root/publisher/hugo/static/ltximg"
