(package-initialize)

;; Add the emacs directory to the load path
(add-to-list 'load-path user-emacs-directory)

(defvar init-files
  '(
    init-directories ;; Setup directories and add things to the load-path
    init-defuns ;; Load all home made lisp functions
    init-packages ;; Handle missing packages, then package specific configuration
    ;; init-el-get ;; Handle packages managed by el-get
    init-defaults ;; Setup some better defaults
    init-modes ;; Setup mode specific configuration
    init-keybindings ;; Setup keybindings for everything
    init-experimental ;; Initialize things that are works in progress
    ))

(defun safe-require (feature)
  "Safely requires FEATURE."
  (condition-case ex
      (progn
        (message (format "@ Loading \"%s\"" (symbol-name feature)))
        (require feature))
    ('error (message (format "@ Error loading \"%s\": %s" (symbol-name feature) ex)))))

;; Safely load all the init files
(message "# Started loading init files")
(dolist (file init-files)
  (safe-require file))
(message "# Finished loading init files")

;; don't close emacs
(global-set-key (kbd "C-x C-c") '())

;; handle special keys
(define-key key-translation-map [S-dead-circumflex] "^")
(define-key key-translation-map [dead-tilde] "~")
(define-key key-translation-map [S-dead-grave] "´")
(define-key key-translation-map [dead-acute] "`")

(message (format "Emacs initialized in %s" (emacs-init-time)))

(provide 'init)
