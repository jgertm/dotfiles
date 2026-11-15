;;; init.el -*- lexical-binding: t; -*-

;; Evil reads this before loading its movement commands.
(setq evil-respect-visual-line-mode t)

(doom! :completion
       (corfu +orderless)
       vertico

       :ui
       doom
       modeline
       vc-gutter
       (popup +defaults)

       :editor
       (evil +everywhere)
       fold

       :emacs
       dired
       electric
       undo
       vc

       :tools
       lookup
       magit

       :os
       tty
       (:if (featurep :system 'macos) macos)

       :lang
       clojure
       emacs-lisp
       markdown
       nix
       org

       :config
       (default +bindings))
