(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(show-paren-mode t))
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 )
 ;; Always end a file with a newline
(setq require-final-newline nil)

;; COLOR THEMES
(let ((default-directory "~/.emacs.d/color-theme-6.6.0/"))
(normal-top-level-add-to-load-path '("."))
(normal-top-level-add-subdirs-to-load-path))
(require 'color-theme)
(color-theme-initialize)
(color-theme-charcoal-black)

;; DJANGO MUMAMO MODE (Template Syntax Highlighting)
(autoload 'django-html-mumamo-mode "~/.emacs.d/plugins/nxhtml/autostart.el")
(setq auto-mode-alist
      (append '(("\\.html?$" . django-html-mumamo-mode)) auto-mode-alist))
(setq mumamo-background-colors nil) 
(add-to-list 'auto-mode-alist '("\\.html$" . django-html-mumamo-mode))

(add-to-list 'load-path
              "~/.emacs.d/plugins/yasnippet")
(require 'yasnippet)
(yas-global-mode 1)

(add-to-list 'load-path "~/.emacs.d/functions/")
(load "duplicate.el")
(load "shift_line.el")
(load "visws.el")

;; Bind Ctrl+c g as goto-line command
(global-set-key "\C-cg" 'goto-line)

;; spaces instead of tabs
(setq-default indent-tabs-mode nil)

;; Set delete to do what it should
(global-set-key [delete] 'delete-char)

;; Delete Selection Mode
(delete-selection-mode 1)

;; Set HTML tabs to 2 spaces
(add-hook 'html-mode-hook
          (lambda()
            (setq sgml-basic-offset 2)
            (setq indent-tabs-mode t)))

;; Set CSS tabs to 2 spaces
(setq css-indent-offset 2)

;; Set Javascript tabs to 2 spaces
(add-hook 'javascript-mode-hook 
      '(lambda() 
        (setq tab-width 2)))
