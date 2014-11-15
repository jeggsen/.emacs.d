(require 'use-package)

;;; Major modes

(use-package botcode-mode
  :mode "\\.bot\\'")

(use-package latex
  :defer t
  :init (add-hook 'LaTeX-mode-hook 'reftex-mode) ;; enable reftex
  :config
  (progn
    (setq-default TeX-PDF-mode t) ;; default to pdf
    (setq-default TeX-global-PDF-mode t) ;; default to pdf
    (setq-default TeX-parse-self t) ;; parse on load
    (setq-default TeX-auto-save t) ;; parse on save
    (setq-default TeX-save-query nil) ;; save before compiling
    (setq-default TeX-master nil) ;; try to figure out which file is the master
    (setq-default reftex-plug-into-AUCTeX t) ;; make reftex and auctex work together
    ))

;;; Minor modes

(use-package fill-column-indicator
  :init
  (progn
    (setq fci-rule-width 1)
    (setq fci-rule-color "dark gray")
    (setq fci-rule-column 80)
    (define-globalized-minor-mode global-fci-mode fci-mode (lambda () (fci-mode 1)))
    (global-fci-mode 1)))

(use-package smartparens-config
  :diminish smartparens-mode
  :init
  (progn
    (setq sp-autoescape-string-quote nil)
    (smartparens-global-mode t)
    (show-smartparens-global-mode t)))

(use-package smex
  :bind
  (("M-x" . smex)
   ("M-X" . smex-major-mode-commands))
  :init
  (progn
    (smex-initialize)
    (setq smex-save-file (concat data-dir ".smex-items"))))

(use-package git-gutter+
  :diminish git-gutter+-mode
  :init (global-git-gutter+-mode t))

(use-package flycheck
  :diminish flycheck-mode
  :init (global-flycheck-mode))

(use-package multiple-cursors
  :bind
  (("C-d" . mc/mark-next-like-this)
   ("C-S-d" . mc/mark-all-like-this)
   ("C-M-a" . set-rectangular-region-anchor))
  :init (setq mc/list-file (concat data-dir ".mc-lists")))

(use-package undo-tree
  :init (setq global-undo-tree-mode t))

(use-package browse-kill-ring
  :init (setq browse-kill-ring-quit-action 'save-and-restore))

(use-package ace-jump-mode
  :bind
  (("C-ø" . ace-jump-mode)
   ("C-Ø" . ace-jump-char-mode)
   ("C-'" . ace-jump-line-mode)))

(use-package ace-jump-zap
  :bind ("C-å" . ace-jump-zap-to-char))

(use-package expand-region
  :bind
  (("M-e" . er/expand-region)
   ("C-M-e" . er/contract-region)))

(use-package change-inner
  :bind
  (("M-i" . copy-inner)
   ("M-o" . copy-outer)
   ("M-I" . change-inner)
   ("M-O" . change-outer)))

(use-package move-text
  :bind
  (("C-S-<up>" . move-text-up)
   ("C-S-<down>" . move-text-down)))

(use-package visual-regexp-steroids
  :bind
  (("C-c r" . vr/replace)
   ("C-c q" . vr/query-replace)
   ("C-s" . vr/isearch-forward)
   ("C-r" . vr/isearch-backward)
   ("C-M-s" . vr/mc-mark)))

(use-package magit
  :bind (("C-x m" . magit-status)
         ("C-c C-a" . magit-commit-amend))
  :config (setq magit-auto-revert-mode nil))

(use-package undo-tree
  :bind
  (("C-x u" . undo-tree-visualize)
   ("C-_" . undo-tree-undo)
   ("M-_" . undo-tree-redo)))

(use-package browse-kill-ring
  :bind ("C-x C-y" . browse-kill-ring))

(use-package ace-jump-buffer
  :bind ("C-x C-b" . ace-jump-buffer))

(use-package smooth-scrolling)

(use-package flyspell
  :diminish flyspell-mode
  :commands flyspell-prog-mode
  :init
  (progn
    (add-hook 'emacs-lisp-mode-hook 'flyspell-prog-mode)
    (add-hook 'lua-mode-hook 'flyspell-prog-mode)))

(use-package yasnippet
  :diminish yas-minor-mode
  :init
  (progn
    (setq yas-snippet-dirs '("~/.emacs.d/snippets"))
    (define-key yas-minor-mode-map (kbd "<tab>") nil) ;; remove default expand key
    (define-key yas-minor-mode-map (kbd "TAB") nil)
    (define-key yas-minor-mode-map (kbd "M-<tab>") 'yas-expand) ;; use M-tab instead
    (define-key yas-keymap (kbd "<return>") 'yas/exit-all-snippets) ;; exit snippets on enter
    (yas-global-mode 1)))

(use-package god-mode
  :bind ("<escape>" . god-mode-all))

(use-package goto-chg
  :bind ("M-." . goto-last-change))

(use-package ag
  :bind ("C-S-s" . ag)
  :config (setq ag-highlight-search t))

(use-package dired+
  :bind ("C-x C-d" . dired)
  :init
  (progn
    (require 'dired)
    (define-key dired-mode-map (kbd "<backspace>") 'diredp-up-directory-reuse-dir-buffer)
    (toggle-diredp-find-file-reuse-dir 1)
    ))

(use-package subword
  :diminish subword-mode)

(provide 'setup-packages)
