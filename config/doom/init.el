;;; init.el -*- lexical-binding: t; -*-

(doom! :completion
       (corfu +orderless)
       vertico

       :ui
       doom
       modeline
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
       (:if (featurep :system 'macos) macos)

       :lang
       clojure
       emacs-lisp
       markdown
       nix
       org

       :config
       (default +bindings))
