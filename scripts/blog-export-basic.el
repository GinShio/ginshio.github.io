;;; Code:
;;; FUNCTIONS
(defun parent-dir (file)
  "Return the parent directory of FILE, or nil if none."
  (file-name-directory (directory-file-name (expand-file-name file))))
(defun get-dir-name (file)
  "Return the directory name of FILE, or nil if none."
  (file-name-nondirectory
   (directory-file-name
    (expand-file-name
     (if (file-directory-p file) file (file-name-directory file))))))
(defun file-updatedp (file1 file2)
  "The FILE1 need regenerate if FILE1 modified time less than FILE2."
  (time-less-p (file-attribute-modification-time (file-attributes file1))
               (file-attribute-modification-time (file-attributes file2))))

;;; VARIABLES
(defvar bootstrap-version 5)
(defvar straight-base-dir (expand-file-name ".emacs.d/.local" (getenv "HOME")))
(defvar straight-fix-org t)
(defvar straight-vc-git-default-clone-depth 1)
(defvar publish--straight-repos-dir (expand-file-name "straight/repos/" straight-base-dir))
(defvar org-file-dir (getenv "ORGMODE_FILEDIR"))

;;; DEFAULTS
(setq gc-cons-threshold 134217728 ; 128 MiB
      )

;;; LOAD STRAIGHT AND ORG-MODE
(let ((bootstrap-file (expand-file-name "straight.el/bootstrap.el" publish--straight-repos-dir)))
  ;; (unless (file-exists-p bootstrap-file)
  ;;   (with-current-buffer
  ;;       (url-retrieve-synchronously
  ;;        "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
  ;;        'silent 'inhibit-cookies)
  ;;     (goto-char (point-max))
  ;;     (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))
(straight-use-package '(org :type built-in)
                      (require 'ox))
;;; ELIMINATES THE ZERO-WIDTH SPACE
(defun +org-export-remove-zero-width-space (text _backend _info)
  "Remove zero width spaces from TEXT."
  (unless (org-export-derived-backend-p 'org)
    (replace-regexp-in-string "\u200B" "" text)))
(add-to-list 'org-export-filter-final-output-functions #'+org-export-remove-zero-width-space t)

(defun +blog-export/assets-copy (targetdir)
  "Copy assets to TARGETDIR diretory"
  (copy-directory (expand-file-name "assets" (getenv "ORGMODE_DIRECTORY"))
                  targetdir
                  t t t))
;;; batch-export-publisher.el ends here
