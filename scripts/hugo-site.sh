#!/usr/bin/env bash

set -euo pipefail

# Build the Hugo site into the pages repository, then stamp for ninja.
#
# Usage: hugo-site.sh SOURCE-ROOT STAMP
#
# _build/hugogen is the deploy repository (branch `hugo`, pushed to
# codeberg/github/bitbucket/gitlab by hand).  When it does not exist yet the
# bootstrap below recreates it and pulls the published state, so history
# accumulates across rebuilds; this only needs the network once.

root=$(cd -- "$1" && pwd -P)
stamp=$2
site=$root/publisher/hugo
pages=$root/_build/hugogen

if [[ ! -e $pages/.git ]]; then
	mkdir -p "$pages"
	git -C "$pages" init --initial-branch=hugo
	git -C "$pages" remote add origin https://codeberg.org/GinShio/ginshio.codeberg.page.git
	git -C "$pages" remote set-url --add --push origin codeberg:GinShio/ginshio.codeberg.page.git
	git -C "$pages" remote set-url --add --push origin github:GinShio/ginshio.github.io.git
	git -C "$pages" remote set-url --add --push origin gitlab:GinShio/ginshio.gitlab.io.git
	git -C "$pages" pull origin hugo
fi

hugo --environment production --logLevel info --gc \
	--source "$site" --destination "$pages"

touch "$stamp"
