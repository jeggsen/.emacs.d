;;; etmux.el --- Communicating with tmux from emacs

(require 'dash)
(require 's)

(defun etmux-tmux-running? ()
  "Return whether `tmux' is running on the system."
  (zerop (process-file "tmux" nil nil nil "has-session")))

(defun etmux-tmux-run-command (&rest args)
  "Run a tmux-command in the running tmux session."
  (with-temp-buffer
    (let ((retval (apply 'process-file "tmux" nil (current-buffer) nil args)))
      (if (zerop retval)
          (buffer-string)
        (error (format "Failed: %s(status = %d)" (mapconcat 'identity (cons "tmux" args) " ") retval))))))

(defun etmux--send-keys (target keys)
  "Send a key combination to the tmux target."
  (etmux-tmux-run-command "send-keys" "-t" target keys "C-m"))

(defun etmux-reset-prompt (target)
  "Clears the prompt of the tmux target."
  (etmux-tmux-run-command "send-keys" "-t" target "C-u"))

(defun etmux-clear (target)
  "Clears the screen of the tmux target."
  (etmux-tmux-run-command "send-keys" "-t" target "C-l"))

(defun etmux-C-c (target)
  "Send interrupt signal to tmux target."
  (etmux-tmux-run-command "send-keys" "-t" target "C-c"))

(defun etmux-C-d (target)
  "Send EOF signal to tmux target."
  (etmux-tmux-run-command "send-keys" "-t" target "C-d"))

(defun etmux-C-z (target)
  "Send TSTP signal to tmux target."
  (etmux-tmux-run-command "send-keys" "-t" target "C-z"))

(defun etmux-run-command (target command)
  "Send a command to the tmux target."
  (interactive)
  (when (etmux-tmux-running?)
    (etmux--reset-prompt target)
    (etmux--send-keys target command)))

(defun etmux-list-sessions ()
  "List all running tmux sessions on the system."
  (if (etmux-tmux-running?)
      (let ((result (etmux-tmux-run-command "list-sessions" "-F" "#{session_name}")))
        (s-split "\n" (s-trim result)))
    (message "found no running tmux sessions")))

(defun etmux-list-windows (session)
  "List all windows in SESSION."
  (if (etmux-tmux-running?)
      (let ((result (etmux-tmux-run-command "list-windows" "-t" session "-F" "#{window_id},#{window_name}")))
        (-map (-partial #'s-split ",") (s-split "\n" (s-trim result))))
    (message "found no running tmux sessions")))

(defun etmux--window-exists? (window)
  "Returns whether a window exists."
  (let* ((sessions (etmux-list-sessions))
         (windows (-map #'etmux-list-windows sessions))
         (window-ids (-map #'caar windows)))
    (-contains? window-ids window)))

(defun etmux-list-panes (window)
  "List all panes in WINDOW."
  (cond
   ((not (etmux-tmux-running?)) (message "found no running tmux sessions"))
   ((not (etmux--window-exists? window)) (message "window does not exist"))
   (t (let ((result (etmux-tmux-run-command "list-panes" "-t" window "-F" "#{pane_id},#{pane_title}")))
        (-map (-partial #'s-split ",") (s-split "\n" (s-trim result)))))))

(provide 'etmux)
;;; etmux.el ends here
