#!/usr/bin/env sh
":"; exec emacs --quick --script "$0" "$@" # -*- mode: emacs-lisp; lexical-binding: t; -*-

;;; Code:
(load (expand-file-name "blog-export-basic.el" (getenv "ORGMODE_SCRIPTDIR")))
(setq org-hugo-base-dir (getenv "HUGOBASEDIR")
      org-hugo-section (get-dir-name (getenv "HUGOPOSTDIR"))
      org-hugo-default-static-subdirectory-for-externals (get-dir-name (getenv "HUGOIMAGEDIR"))
      org-hugo-date-format "%Y-%m-%dT%T%:z"
      org-hugo-goldmark t
      org-hugo-front-matter-format "toml"
      org-file-dir (getenv "ORGMODE_FILEDIR")
      )
;;; EXPORT HUGO POSTS
(straight-use-package '(ox-hugo :type git
                                :host github
                                :repo "kaushalmodi/ox-hugo"
                                :nonrecursive t))
(with-eval-after-load 'ox-hugo
  (add-to-list 'org-hugo-special-block-type-properties
               '("LaTeX" . (:raw t))))
(defun hugo/special-block/before-until (special-block contents _info)
  "Advice the function before until the org-hugo.
Args SPECIAL-BLOCK, CONTENTS, and _INFO, see `org-hugo-special-block'."
  (let* ((block-type (org-element-property :type special-block))
         (block-type-plist (cdr (assoc block-type org-hugo-special-block-type-properties)))
         (contents (when (stringp contents)
                     (org-trim
                      (if (plist-get block-type-plist :raw)
                          ;; https://lists.gnu.org/r/emacs-orgmode/2022-01/msg00132.html
                          (org-element-interpret-data (org-element-contents special-block))
                        contents)))))
    (when contents
      (cond
       ((string= block-type "LaTeX")
        (format "{{< math >}}\x5C\x5B\xA%s\x5C\x5D\xA{{< /math >}}"
                contents))
       ((member block-type '("success" "info" "warning" "error"))
        (format "{{< admonition type=\"%s\" >}}\xA%s\xA{{< /admonition >}}"
                block-type contents))
       (t nil)))))
(advice-add 'org-hugo-special-block :before-until #'hugo/special-block/before-until)
(defun hugo/export-all (dir)
  "Export all org files in directory DIR to markdown."
  (let ((files (directory-files-recursively dir "\\`[^.#].*\\.org\\'")))
    (dolist (file files)
      (with-current-buffer (find-file-noselect file)
        (org-hugo-export-wim-to-md t)))))
(defun hugo/export-one (file)
  "Export one org FILE to markdown."
  (let* ((mdfile (with-current-buffer (find-file-noselect file)
                   (org-export-output-file-name ".md" nil (expand-file-name (getenv "HUGOPOSTDIR"))))))
    (when (or (not (file-exists-p mdfile))
              (file-updatedp mdfile file))
      (with-current-buffer (find-file-noselect file) (org-hugo-export-to-md)))))
(let ((argc (length argv)) (counter 0))
  (while (< counter argc)
    (hugo/export-one (elt argv counter))
    (setq counter (1+ counter))))
(+blog-export/assets-copy (expand-file-name "private-assets" (getenv "HUGOGENDIR")))
;;; blog-export-hugo.el ends here
