;;; pyde-autoloads.el --- automatically extracted autoloads
;;
;;; Code:


;;;### (autoloads (pyde-mode pyde-disable pyde-enable) "pyde" "pyde.el"
;;;;;;  (21067 612))
;;; Generated autoloads from pyde.el

(autoload 'pyde-enable "pyde" "\
Enable Pyde in all future Python buffers.

\(fn)" t nil)

(autoload 'pyde-disable "pyde" "\
Disable Pyde in all future Python buffers.

\(fn)" t nil)

(autoload 'pyde-mode "pyde" "\
Minor mode in Python buffers for the Python Development Environment.

Key bindings

Indentation and Filling:

TAB          indent line if at the beginning of it, else complete
C-j          `newline-and-indent'
C-c <        `python-indent-shift-left'
C-c >        `python-indent-shift-right'
C-M-q        `prog-indent-sexp'
M-q          `python-fill-paragraph'

Python Shell Interaction:

C-c C-z      `python-shell-switch-to-shell'

C-M-x        `python-shell-send-defun'
C-c C-c      `pyde-shell-send-region-or-buffer'

Virtual Environments:

C-c C-e      `pyvirtualenv'

Code Navigation

C-c C-j      `imenu'
C-c C-f      `rope-find-file'
C-c C-g C-d  `rope-goto-definition'
C-c C-g C-c  `rope-find-occurrences'
C-c C-g C-i  `rope-find-implementations'
C-c C-g C-g  `rope-jump-to-global'

C-M-up       `python-nav-backward-up-list'
M-a          `pyde-nav-backward-statement'
M-e          `pyde-nav-forward-statement'

Documentation

C-c C-v      `pyde-check'

C-c C-d      `pyde-doc-rope'
C-c C-w C-s  `pyde-doc-search'
C-c C-w C-w  `pyde-doc-show'

Project support

C-c C-p C-o  `rope-open-project'
C-c C-p C-c  `rope-close-project'
C-c C-p C-p  `rope-project-config'

Refactoring

C-c C-r      `pyde-refactor'

\(fn &optional ARG)" t nil)

;;;***

;;;### (autoloads nil nil ("pyde-pkg.el") (21067 613 7000))

;;;***

(provide 'pyde-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; pyde-autoloads.el ends here
