;;; packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Keep non-file buffers (including Magit) on the theme's normal background.
(package! solaire-mode :disable t)

;; The mirror contains the same commit pinned by Doom core.
(when-let* ((entry (assq 'gcmh doom-packages)))
  (setcdr entry (plist-put (cdr entry) :recipe '(:host github :repo "emacsmirror/gcmh"))))
