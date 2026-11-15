;;; config.el -*- lexical-binding: t; -*-

(setq display-line-numbers-type nil
      doom-font (font-spec :family "Iosevka" :size 10)
      ;; Matches Ghostty's TokyoNight background (#1a1b26). Let the theme
      ;; provide syntax, current-line, and Magit faces without local overrides.
      doom-theme 'doom-tokyo-night)

(global-visual-line-mode 1)

(defun dotfiles-calc-terminal ()
  "Open Calc in a dedicated terminal client frame."
  (interactive)
  (full-calc)
  (set-frame-parameter nil 'dotfiles-calc-terminal t))

(defun dotfiles-calc-quit ()
  "Close a shell-launched Calc frame, or quit Calc normally."
  (interactive)
  (if (frame-parameter nil 'dotfiles-calc-terminal)
      (delete-frame)
    (call-interactively #'calc-quit)))

(after! calc
  (map! :map calc-mode-map
        "q" #'dotfiles-calc-quit
        :n "q" #'dotfiles-calc-quit))

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

(defun dotfiles-magit-terminal ()
  "Open Magit for the terminal client's directory in a dedicated frame."
  (interactive)
  ;; Use the client's cwd, not the daemon's current buffer directory.
  (magit-status (process-get (frame-parameter nil 'client)
                            'server-client-directory))
  (set-frame-parameter nil 'dotfiles-magit-terminal t))

(defun dotfiles-magit-status-quit (&optional kill-buffer)
  "Close a shell-launched Magit frame, or quit Magit normally."
  (interactive "P")
  (if (frame-parameter nil 'dotfiles-magit-terminal)
      (delete-frame)
    (+magit/quit kill-buffer)))

(after! magit
  (add-hook 'magit-refresh-buffer-hook #'dotfiles-magit-status-diffstats)
  (map! :map magit-status-mode-map
        "q" #'dotfiles-magit-status-quit
        :n "q" #'dotfiles-magit-status-quit))
