;;; config.el -*- lexical-binding: t; -*-

(setq display-line-numbers-type nil
      doom-font (font-spec :family "Iosevka" :size 10)
      ;; Matches Ghostty's TokyoNight background (#1a1b26). Let the theme
      ;; provide syntax, current-line, and Magit faces without local overrides.
      doom-theme 'doom-tokyo-night)

(global-visual-line-mode 1)

;; Decorate file headings without changing Magit's sections or patch text.
(defun dotfiles-magit-status-diffstats ()
  "Show added/removed line counts on each status file heading."
  (when (derived-mode-p 'magit-status-mode)
    (remove-overlays (point-min) (point-max) 'dotfiles-diffstat t)
    (dolist (group (oref magit-root-section children))
      (when (memq (oref group type) '(staged unstaged))
        (dolist (file (oref group children))
          (when (eq (oref file type) 'file)
            (let ((added 0) (removed 0))
              ;; Count the already-rendered hunks: no extra Git processes,
              ;; and the counts respect Magit's whitespace/diff options.
              (dolist (hunk (oref file children))
                (when (eq (oref hunk type) 'hunk)
                  (save-excursion
                    (goto-char (oref hunk content))
                    (while (re-search-forward "^[+-]" (oref hunk end) t)
                      (if (eq (char-before) ?+)
                          (cl-incf added)
                        (cl-incf removed))))))
              (when (> (+ added removed) 0)
                (save-excursion
                  (goto-char (oref file start))
                  (let ((overlay (make-overlay (line-end-position)
                                               (line-end-position))))
                    (overlay-put overlay 'dotfiles-diffstat t)
                    (overlay-put overlay 'before-string
                                 (concat (propertize " " 'display
                                                     '(space :align-to (- right-fringe 14)))
                                         (propertize (format "%+6d" added)
                                                     'face 'magit-diffstat-added)
                                         " "
                                         (propertize (format "%6s" (format "-%d" removed))
                                                     'face 'magit-diffstat-removed)))))))))))))

(after! magit
  (add-hook 'magit-refresh-buffer-hook #'dotfiles-magit-status-diffstats))
