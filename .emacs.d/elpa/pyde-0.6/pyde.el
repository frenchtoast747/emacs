;;; pyde.el --- Python Development Environment

;; Copyright (C) 2012  Jorgen Schaefer <forcer@forcix.cx>

;; Author: Jorgen Schaefer <forcer@forcix.cx>
;; URL: https://github.com/jorgenschaefer/pyde
;; Version: 0.6
;; Package-Requires: ((pymacs "0.25") (auto-complete "1.4") (yasnippet "0.8") (fuzzy "0.1") (pyvirtualenv "1.0"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; The Python Development Environment in Emacs

;; Emacs has excellent Python support through a number of packages.
;; The only problem is that every user needs to set up all of these
;; packages to work nicely with each other. This mode does not a lot
;; more than to combine those packages and give them a default
;; configuration for Python.

;; Features include:

;; - Code completion (using auto-complete and rope)
;;   Emacs will suggest completions as you type and, after a short
;;   delay, pop up a select box with proposed completions, including
;;   docstrings for those completions when available.

;; - Indentation highlighting (using highlight-indentation)
;;   Highlight indentation levels in code so you can always see which
;;   code belongs where.

;; - Snippet Expansion (using yasnippet and auto-complete)
;;   Some completion options are highlighted and will expand into full
;;   code snippets that you just need to fill out.

;; - Code hinting (using eldoc and rope)
;;   While you write, the minibuffer will show the call signature of
;;   the current function.

;; - Code Navigation (using rope and python.el)
;;   Quickly jump to the definition of a function or class, find
;;   callers of the current function, or browse all definitions in the
;;   current file. `find-file-at-point' will also find module source
;;   files from import statements.

;; - Inline Documentation (using rope)
;;   Read the help() output of the object at point with a quick key
;;   shortcut.

;; - On-the-fly checks (using flymake)
;;   Highlight errors in your code while you edit it.

;; - Virtualenv support (using pyvirtualenv)
;;   Use C-c C-e to activate a virtual environment thorough your Emacs
;;   and for subprocesses. Use C-u C-c C-e to disable a virtual
;;   environment.

;; - Python web documentation
;;   Simply access the Python web documentation using a tab-completed
;;   list of modules and objects.

;; - Refactoring (using rope)
;;   Use any of multiple powerful refactoring tools, such extracting
;;   the region to a variable or a separate function, renaming
;;   identifiers, modules or packages, or just automatically clean up
;;   your imports.

;; - Easy IPython support for those who use it
;;   Simply run (pyde-use-ipython).

;; Setup:

;; Add the following to your .emacs:

;; (package-initialize)
;; (pyde-enable)

;; To use on-the-fly highlighting of errors and for the code check
;; command, you need to set `python-check-command' to a command you
;; have installed. Any combination of pyflakes, pep8 and pylint are
;; useful, and all available via easy_install and pip. Also see the
;; python-check.sh utility from the same repository as this file to
;; use all of them at once.

;; (setq python-check-command "python-check.sh")

;; If you want to use IPython (make sure it's installed), add:

;; (pyde-use-ipython)

;; If you find the (Python Pyde yas AC Rope ElDoc Fill) mode line
;; annoying, also add:

;; (pyde-clean-modeline)

;;; Code:

;; Some global variables. Need to be set before the other modes are
;; loaded, as some of them define some silly global keys without these
;; set. We are using `defvar' to avoid overwriting a user's
;; configuration, if any.

(defvar flymake-no-changes-timeout 60
  "Time to wait after last change before starting compilation.

The original value of 0.5 is too short for Python code, as that
will result in the current line to be highlighted most of the
time, and that's annoying. This value might be on the long side,
but at least it does not, in general, interfere with normal
interaction.

Value set by pyde.")

(defvar flymake-start-syntax-check-on-newline nil
  "Start syntax check if newline char was added/removed from the buffer.

This should be nil for Python, as most lines with a colon at the
end will mean the next line is always highlighted as error, which
is not helpful and mostly annoying.

Value set by pyde.")

(defvar ropemacs-enable-autoimport t
  "Specifies whether autoimport should be enabled.

Value set by pyde.")

(defvar ropemacs-guess-project t
  "Try to guess the project when needed.

If non-nil, ropemacs tries to guess and open the project that contains
a file on which the rope command is performed when no project is
already opened.

Value set by pyde.")

(defvar ropemacs-confirm-saving nil
  "Shows whether to confirm saving modified buffers before refactorings.

If non-nil, you have to confirm saving all modified
python files before refactorings; otherwise they are
saved automatically.

Value set by pyde.")

(defvar ropemacs-enable-shortcuts nil
  "Shows whether to bind ropemacs shortcuts keys.

Value set by pyde, as we set our own key bindings.")

(defvar ropemacs-local-prefix nil
  "The prefix for ropemacs refactorings.

Use nil to prevent binding keys.

Value set by pyde, as we set our own key bindings.")

(defvar ropemacs-global-prefix nil
  "The prefix for ropemacs project commands.

Use nil to prevent binding keys.

Value set by pyde, as we set our own key bindings.")

(defvar ac-trigger-key "TAB"
  "Non-nil means `auto-complete' will start by typing this key.
If you specify this TAB, for example, `auto-complete' will start by typing TAB,
and if there is no completions, an original command will be fallbacked.

Value set by pyde.")

(defvar ac-auto-show-menu 0.5
  "Non-nil means completion menu will be automatically shown.

Value set by pyde.")

(defvar ac-quick-help-delay 0.5
  "Delay to show quick help.

Value set by pyde.")

(defvar yas/trigger-key (kbd "C-c C-p C-s")
  "The key bound to `yas-expand' when `yas-minor-mode' is active.

Value is a string that is converted to the internal Emacs key
representation using `read-kbd-macro'.

Value set by pyde.")

;; Now, load the various modes we use.

(defun pyde-install-python-packages (&optional ignored)
  "Install the required Python packages for the user."
  (with-current-buffer (get-buffer-create "*Python Install*")
    (fundamental-mode)
    (erase-buffer)
    (display-buffer (current-buffer))
    (with-selected-window (get-buffer-window (current-buffer))
      (insert "Installing Python packages.\n"
              "Scroll down to see if there were any errors.\n\n")
      (let ((commandlist nil)
            (packages '("rope" "ropemode" "ropemacs")))
        (cond
         ((executable-find "easy_install")
          (dolist (package packages)
            (add-to-list 'commandlist
                         (format "easy_install --user %s" package))))
         ((executable-find "pip")
          (dolist (package packages)
            (add-to-list 'commandlist
                         (format "pip install --user %s" package))))
         (t
          (insert "$ ...\n")
          (insert "ERROR: Can't find either easy_install or pip, can't "
                  "install packages.\n")))
        (setq commandlist
              (append commandlist
                      '("mkdir ~/pyde-temp-install"
                        "cd ~/pyde-temp-install && git clone https://github.com/pinard/Pymacs.git"
                        "cd ~/pyde-temp-install/Pymacs && make"
                        "cd ~/pyde-temp-install/Pymacs && python setup.py install --user")))
        (dolist (cmd commandlist)
          (insert "$ " cmd "\n")
          (sit-for 0)
          (call-process "sh" nil (current-buffer) t
                        "-c" cmd)
          (insert "\n")
          (goto-char (point-max)))
        (insert "\n"
                "All done. Check for errors above and try to load Pyde again.\n")))))

(defun pyde-installation-instructions (&optional error)
  "Show installation instructions."
  (interactive)
  (with-help-window "*Pyde Installation*"
    (with-current-buffer "*Pyde Installation*"
      (insert "Pyde could not be loaded successfully.\n"
              "\n")
      (cond
       ((and (eq (car error) 'error)
             (stringp (cadr error))
             (string-match "Python:" (cadr error)))
        (insert
"The following Python error occurred

" (cadr error)))
       ((and (eq (car error) 'error)
             (stringp (cadr error))
             (string-match "Pymacs helper did not start" (cadr error))
             (with-current-buffer (get-buffer-create "*Pymacs*")
               (goto-char (point-min))
               (re-search-forward "No module named Pymacs" nil t)))
        (insert
"Python can not find the Pymacs module, which means that the Python
side of Pymacs was not correctly installed.")))
      (insert "
The Python Development Environment requires a few Python packages
to be installed before working properly. You can just use the
following button to install them automatically, or you can follow
the instructions below to do so by hand.

")
        (insert-text-button "Install Python packages"
                            'action 'pyde-install-python-packages)
        (insert "

If you are still having trouble, visit #emacs on
irc.freenode.net.


Manual installation:

First, the easy ones. Please run the following command in a
shell:

  easy_install --user rope ropemode ropemacs

If you do not have easy_install, pip might be available:

  pip install --user rope ropemode ropemacs

The last missing module is Pymacs, which is sadly not available
via easy_install. You will need to run the following:

  git clone https://github.com/pinard/Pymacs.git
  cd Pymacs
  make
  python setup.py install --user

Try loading pyde again once that is done. Everything should work
then."))))

(require 'python)

(condition-case err
    (progn
      (require 'pymacs)
      (pymacs-load "ropemacs" "rope-"))
  (error
   (pyde-installation-instructions err)))

(require 'pyvirtualenv)
(require 'highlight-indentation)
(require 'yasnippet)
(require 'auto-complete-config)

;;;;;;;;;;;;;;;
;;; Pyde itself

(defvar pyde-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-f") 'rope-find-file)

    ;; Movement
    (define-key map (kbd "M-e") 'pyde-nav-forward-statement)
    (define-key map (kbd "M-a") 'pyde-nav-backward-statement)

    ;; Shell interaction
    (define-key map (kbd "C-c C-c") 'pyde-shell-send-region-or-buffer)

    ;; Virtual Env support
    (define-key map (kbd "C-c C-e") 'pyvirtualenv)

    ;; Goto
    (define-key map (kbd "C-c C-g C-d") 'rope-goto-definition)
    (define-key map (kbd "C-c C-g C-c") 'rope-find-occurrences)
    (define-key map (kbd "C-c C-g C-i") 'rope-find-implementations)
    (define-key map (kbd "C-c C-g C-g") 'rope-jump-to-global)

    ;; Documentation
    (define-key map (kbd "C-c C-v") 'pyde-check)
    (define-key map (kbd "C-c C-d") 'pyde-doc-rope)
    (define-key map (kbd "C-c C-w C-s") 'pyde-doc-search)
    (define-key map (kbd "C-c C-w C-w") 'pyde-doc-show)

    ;; Rope Project
    (define-key map (kbd "C-c C-p C-o") 'rope-open-project)
    (define-key map (kbd "C-c C-p C-c") 'rope-close-project)
    (define-key map (kbd "C-c C-p C-p") 'rope-project-config)

    ;; Rope Refactoring
    (define-key map (kbd "C-c C-r") 'pyde-refactor)
    map)
  "Key map for the Python Development Environment.")

;;;###autoload
(defun pyde-enable ()
  "Enable Pyde in all future Python buffers."
  (interactive)
  (add-hook 'python-mode-hook 'pyde-mode))

;;;###autoload
(defun pyde-disable ()
  "Disable Pyde in all future Python buffers."
  (interactive)
  (remove-hook 'python-mode-hook 'pyde-mode))

;;;###autoload
(define-minor-mode pyde-mode
  "Minor mode in Python buffers for the Python Development Environment.

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

C-c C-r      `pyde-refactor'"
  :lighter " Pyde"
  (when (not (eq major-mode 'python-mode))
    (error "Pyde only works with `python-mode'"))
  (when buffer-file-name
    (pyde-setup-project))
  (cond
   (pyde-mode
    (eldoc-mode 1)
    (set (make-local-variable 'eldoc-documentation-function)
         'pyde-eldoc-documentation)
    (flymake-mode 1)
    (pyvirtualenv-mode 1)
    (highlight-indentation-mode 1)
    (yas-reload-all)
    (yas-minor-mode 1)
    (setq ac-sources
          '(ac-source-yasnippet
            ac-source-nropemacs-dot
            ac-source-nropemacs
            ac-source-abbrev
            ac-source-dictionary
            ac-source-words-in-same-mode-buffers))
    (auto-complete-mode 1))
   (t
    (eldoc-mode 0)
    (flymake-mode 0)
    ;; Global mode, leave it alone
    ;; (pyvirtualenv-mode 0)
    (highlight-indentation-mode 0)
    (yas-minor-mode 0)
    (auto-complete-mode 0)
    (setq ac-sources '(ac-source-abbrev
                       ac-source-dictionary
                       ac-source-words-in-same-mode-buffers)))))

(defun pyde-setup-project ()
  "Set up the Rope project for the current file."
  (let ((old (rope-get-project-root))
        (new (locate-dominating-file buffer-file-name ".ropeproject")))
    (cond
     ;; Everything is set up correctly
     ((and old new (equal old new))
      t)
     ;; A better project exists, open it
     (new 
      (rope-open-project new))
     ;; Project doesn't exist, create a new one
     ((not new)
      (rope-open-project)))))

(defun pyde-use-ipython ()
  "Set defaults to use IPython instead of the standard interpreter."
  (interactive)
  (if (boundp 'python-python-command)
      ;; Emacs 24 until 24.3
      (setq python-python-command "ipython")
    ;; Emacs 24.3 and onwards.

    ;; This is from the python.el commentary.
    ;; Settings for IPython 0.11:
    (setq python-shell-interpreter "ipython"
          python-shell-interpreter-args ""
          python-shell-prompt-regexp "In \\[[0-9]+\\]: "
          python-shell-prompt-output-regexp "Out\\[[0-9]+\\]: "
          python-shell-completion-setup-code
          "from IPython.core.completerlib import module_completion"
          python-shell-completion-module-string-code
          "';'.join(module_completion('''%s'''))\n"
          python-shell-completion-string-code
          "';'.join(get_ipython().Completer.all_completions('''%s'''))\n")))

(defun pyde-clean-modeline ()
  "Clean up the mode line by removing some lighters.

It's not necessary to see (Python Pyde yas AC Rope ElDoc) all the
time. Honestly."
  (interactive)
  (setq eldoc-minor-mode-string nil)
  (dolist (mode '(pyde-mode yas-minor-mode auto-complete-mode
                            ropemacs-mode))
    (setcdr (assq mode minor-mode-alist)
            (list ""))))

(defun pyde-shell-send-region-or-buffer ()
  "Send the active region or the buffer to the Python shell.

If there is an active region, send that. Otherwise, send the
whole buffer."
  (interactive)
  (if (region-active-p)
      (python-shell-send-region)
    (python-shell-send-buffer)))

(defun pyde-check ()
  "Run `python-check-command' on the current buffer's file."
  (interactive)
  (when (not (buffer-file-name))
    (error "Can't check a buffer without a file."))
  (python-check (concat python-check-command
                        " "
                        (shell-quote-argument (buffer-file-name)))))


(defun pyde-nav-forward-statement ()
  "Move forward one statement.

This will go to the end of the current statement, or the end of
the next one if already at the end."
  (interactive)
  (let ((old (point)))
    (python-nav-end-of-statement)
    (when (= old (point))
      (python-nav-forward-statement)
      (python-nav-end-of-statement))))

(defun pyde-nav-backward-statement ()
  "Move backward one statement.

This will go to the beginning of the current statement, or the
beginning of the previous one if already at the beginning."
  (interactive)
  (let ((old (point)))
    (python-nav-beginning-of-statement)
    (when (= old (point))
      (python-nav-backward-statement))))

(defvar pyde-refactor-list
  '(("Redo" . rope-redo)
    ("Undo" . rope-undo)
    ("New Module" . rope-create-module)
    ("New Package" . rope-create-package)
    ("New Factory for Class at Point" . rope-introduce-factory)
    ("Inline Function at Point" . rope-inline)
    ("Region to Variable" . rope-extract-variable)
    ("Region to Method" . rope-extract-method)
    ("Module to Package" . rope-module-to-package)
    ("Organize Imports" . rope-organize-imports)
    ("Rename Identifier at Point" . rope-rename)
    ("Rename Current Module" . rope-rename-current-module)
    ("Move Current Module" . rope-move-current-module)
    ("Change Signature of Function at Point" . rope-change-signature)
    ("Move to Module" . rope-move)
    ;; Didn't get this one to work at all
    ;; ("Use Function Wherever Possible" . rope-use-function)
    ;; Templates would require more complex explanation
    ;; ("Restructure Code According to Template" . rope-restructure)
    )
  "Valid arguments and functions to call for `pyde-refactor'.")

(defvar pyde-refactor-history nil
  "The history used for `pyde-refactor'.")
(defun pyde-refactor ()
  "Call a Rope refactoring command.

See `pyde-refactor-list' for a list of commands."
  (interactive)
  (let* ((prompt (if pyde-refactor-history
                     (format "Refactor [%s]: "
                             (car pyde-refactor-history))
                   "Refactor: "))
         (action (completing-read prompt
                                  pyde-refactor-list
                                  nil t nil
                                  'pyde-refactor-history
                                  (car pyde-refactor-history)))
         (command (cdr (assoc action pyde-refactor-list))))
    (when (functionp command)
      (call-interactively command))))

;;;;;;;;;
;;; Eldoc

(defun pyde-eldoc-documentation ()
  "Return a call tip for the python call at point."
  (let ((calltip (rope-get-calltip)))
    (when calltip
      (with-temp-buffer
        ;; multiprocessing.queues.Queue.cancel_join_thread(self)
        (insert calltip)
        (goto-char (point-min))
        ;; First, remove the whole path up to the second-to-last dot. We
        ;; retain the class just to make it nicer.
        (while (search-forward "." nil t)
          nil)
        (when (search-backward "." nil t 2)
          (delete-region (point-min) (1+ (point))))
        ;; Then remove the occurrence of "self", that's not passed by
        ;; the user.
        (when (re-search-forward "(self\\(, \\)?" nil t)
          (replace-match "("))
        (goto-char (point-min))
        ;; Lastly, we'd like to highlight the argument are on.

        ;; This is tricky with keyword vs. positions arguments, and
        ;; possibly quite complex argument values making calculation of
        ;; the current argument tricky.

        ;; Hence, we don't do anything for now.
        (buffer-string)))))


;;;;;;;;;;;
;;; Flymake

(eval-after-load "flymake"
  '(add-to-list 'flymake-allowed-file-name-masks 
                '("\\.py\\'" pyde-flymake-python-init)))

(defun pyde-flymake-python-init () 
  ;; Make sure it's not a remote buffer or flymake would not work
  (let* ((temp-file (flymake-init-create-temp-buffer-copy 
                     'flymake-create-temp-inplace)) 
         (local-file (file-relative-name 
                      temp-file 
                      (file-name-directory buffer-file-name)))) 
    (list python-check-command (list local-file))))

;;;;;;;;;;;;;;;;;;;;;;
;;; Rope documentation

(defun pyde-rope-get-doc ()
  "Return a docstring for the symbol at point, or nil."
  (let ((doc (rope-get-doc)))
    (when (and doc
               (not (equal doc "")))
      doc)))

(defun pyde-doc-rope ()
  "Show Rope documentation on the thing at point."
  (interactive)
  (let ((doc (or (pyde-rope-get-doc)
                 ;; This will get the right position for
                 ;; multiprocessing.Queue(quxqux_|_)
                 (ignore-errors
                  (save-excursion
                    (pyde-nav-backward-statement)
                    (with-syntax-table python-dotty-syntax-table
                      (forward-symbol 1)
                      (backward-char 1))
                    (pyde-rope-get-doc))))))
    (if doc
        (with-help-window "*Python Doc*"
          (princ doc))
      (message "No documentation available."))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Python web documentation

(defun pyde-doc-search (what)
  "Search the Python web documentation for the string WHAT."
  (interactive "sSearch for: ")
  (browse-url
   (format "https://www.google.com/search?q=site:docs.python.org%%20%s"
           what)))

(defun pyde-doc-show (package object anchor)
  "Show the Python web documentation on package PACKAGE and object OBJECT.

ANCHOR is the package name in the HTML file."
  (interactive (pyde--doc-show-read-package-and-object))
  (browse-url (format"http://docs.python.org/library/%s.html#%s"
                     package
                     (format "%s.%s" anchor object))))

(defun pyde--doc-read-backspace (&rest args)
  "Function called on backspace when completing in minibuffer."
  (interactive)
  (if (equal "" (field-string))
      (throw 'one-level-up nil)
    (call-interactively 'delete-backward-char)))

(defun pyde--doc-show-read-package-and-object ()
  "Read a package and object within that package from the user."
  (let* ((package-map
          (let ((map (make-sparse-keymap)))
            (set-keymap-parent map minibuffer-local-must-match-map)
            (define-key map (kbd ".") 'minibuffer-complete-and-exit)
            map))
         (object-map
          (let ((map (make-sparse-keymap)))
            (set-keymap-parent map minibuffer-local-completion-map)
            (define-key map (kbd "DEL") 'pyde--doc-read-backspace)
            (define-key map (kbd "<backspace>") 'pyde--doc-read-backspace)
            map))
         package object anchor)
    (while (not object)
      (setq package
            (let ((minibuffer-local-must-match-map package-map))
              (completing-read "Documentation: "
                               (pyde--doc-package-index)
                               nil t package)))
      (setq object
            (catch 'one-level-up
              (let ((minibuffer-local-completion-map object-map))
                (completing-read (format "Documentation: %s."
                                         package)
                                 (pyde--doc-package-list package))))))
    (setq anchor (gethash (cons package object)
                          pyde--doc-package-anchors
                          object))
    (list package object (or anchor package))))

(defvar pyde--doc-package-index nil
  "Cache of the the documentation index for Python.")

(defun pyde--doc-package-index ()
  "Return the documentation index.

This is an alist mapping titles to URLs."
  (or pyde--doc-package-index
      (let ((buf (url-retrieve-synchronously
                  "http://docs.python.org/library/")))
        (unwind-protect
            (with-current-buffer buf
              (let ((result nil))
                (goto-char (point-min))
                (while (re-search-forward
                        "href=\"\\([a-zA-Z][^\"#]*\\)\\.html.*&#8212;"
                        nil t)
                  (add-to-list 'result (match-string 1)))
                (setq pyde--doc-package-index (nreverse result))))
          (kill-buffer buf)))))

(defvar pyde--doc-package-list (make-hash-table :test 'equal)
  "A hash mapping package names to their contents.")

(defvar pyde--doc-package-anchors (make-hash-table :test 'equal)
  "A hash mapping object names to their HTML anchors.")

(defun pyde--doc-package-list (package)
  "Return a list of objects in this package."
  (or (gethash package pyde--doc-package-list)
      (let ((buf (url-retrieve-synchronously
                  (format "http://docs.python.org/library/%s.html"
                          package))))
        (unwind-protect
            (with-current-buffer buf
              (let ((result nil)
                    (case-fold-search t))
                (goto-char (point-min))
                (while (re-search-forward
                        (format "id=\"\\([^\"]*\\)\\.\\([^\"]*\\)\"" package)
                        nil t)
                  (puthash (cons package (match-string 2))
                           (match-string 1)
                           pyde--doc-package-anchors)
                  (add-to-list 'result (match-string 2)))
                (setq result (nreverse result))
                (puthash package result pyde--doc-package-list)
                result))
          (kill-buffer buf)))))

;;;;;;;;;;;;;
;;; Yasnippet

;; No added configuration needed. Nice mode. :o)

;;;;;;;;;;;;;;;;;
;;; Auto-Complete

;; The default ropemacs interaction is distinctly broken and even
;; marked as unsupported. Make our own.

;; Adapted from Michael Markert:
;; https://github.com/cofi/dotfiles/blob/master/emacs.d/config/cofi-python.el

(defvar pyde--ropemacs-docs nil
  "List of current expansions and docstrings.")

(defun pyde--ropemacs-candidates ()
  "Return a list of possible expansions at points.

This also initializes `pyde--ropemacs-docs'."
  (setq pyde--ropemacs-docs nil)
  (dolist (completion (rope-extended-completions))
    (let ((name (car completion))
          (doc (cadr completion)))
      (when (not (string-prefix-p "_" name))
        (push (cons (concat ac-prefix name)
                    doc)
              pyde--ropemacs-docs))))
  (mapcar 'car pyde--ropemacs-docs))

(defun pyde--ropemacs-document (name)
  "Return the documentation for the symbol NAME."
  (assoc-default name pyde--ropemacs-docs))

(defun pyde--ropemacs-available ()
  "Return non-nil if rope is available for this file."
  (locate-dominating-file buffer-file-name ".ropeproject"))

(ac-define-source nropemacs
  '((candidates . pyde--ropemacs-candidates)
    (symbol     . "p")
    (document   . pyde--ropemacs-document)
    (cache      . t)
    (available .  pyde--ropemacs-available)))

(ac-define-source nropemacs-dot
  '((candidates . pyde--ropemacs-candidates)
    (symbol     . "p")
    (document   . pyde--ropemacs-document)
    (cache      . t)
    (prefix     . c-dot)
    (requires   . 0)
    (available . pyde--ropemacs-available)))

;;; Backports, because stuff's not current. Argh.

;;; auto-complete 1.4 does not work with yasnippet 0.8. This will be
;;; corrected in auto-complete 1.5.
(defun ac-yasnippet-candidates ()
  (all-completions ac-prefix (yas-active-keys)))

;;; yasnippet 0.8 lacks this useful helper function, will be included
;;; in yasnippet 0.9.
(when (not (fboundp 'yas-active-keys))
  (defun yas-active-keys ()
    "Return all active trigger keys for current buffer and point"
    (remove-duplicates (mapcan #'yas--table-all-keys (yas--get-snippet-tables))
                       :test #'string=)))

;; Functions for Emacs 24 before 24.3
(when (not (fboundp 'python-shell-send-region))
  (defalias 'python-shell-send-region 'python-send-region))
(when (not (fboundp 'python-shell-send-buffer))
  (defalias 'python-shell-send-buffer 'python-send-buffer))
(when (not (fboundp 'python-nav-end-of-statement))
  (defalias 'python-nav-end-of-statement 'python-end-of-statement))
(when (not (fboundp 'python-nav-beginning-of-statement))
  (defalias 'python-nav-beginning-of-statement 'beginning-of-sexp))
(when (not (fboundp 'python-nav-forward-statement))
  (defalias 'python-nav-forward-statement 'forward-sexp))
(when (not (fboundp 'python-nav-backward-statement))
  (defalias 'python-nav-backward-statement 'backward-sexp))

;; highlight-indentation 0.5 does not use modes yet
(when (not (fboundp 'highlight-indentation-mode))
  (defun highlight-indentation-mode (on-or-off)
    (cond
     ((and (= on-or-off 1)
           (not highlight-indent-active))
      (highlight-indentation))
     ((and (= on-or-off 0)
           highlight-indent-active)
      (highlight-indentation)))))

(provide 'pyde)
;;; pyde.el ends here
