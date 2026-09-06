#!/usr/bin/env sh

# Load scripts/export-hugo.el in batch emacs under the ginshio
# configuration, the same startup the configuration's own `validate' path
# uses.  Run from anywhere; the elisp file locates the repository itself.

exec ${EMACS:-emacs} -Q --batch \
	--init-directory="${HOME}/.config/emacs" \
	-l "${HOME}/.config/emacs/early-init.el" \
	-l "${HOME}/.config/emacs/init.el" \
	-l "$(dirname -- "$0")/export-hugo.el"
