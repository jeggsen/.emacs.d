;;; indset.el --- Quickly insert things. -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Jens Christian Jensen

;; Author: Jens Christian Jensen <jensecj@gmail.com>
;; URL:
;; Keywords:
;; Package-Version: 20200623
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.0.0.5"))


;;; Commentary:


;;; Code:
(require 'shut-up)
(require 's)
(require 'f)

(defun indset--calc-pi ()
  "Insert the value of PI, with an specified number of digits."
  (let ((digits (read-number "number of digits: "))
        (res))
    (shut-up
      (require 'calc-ext nil t)
      (calc)
      (calc-precision digits)
      (setq res (calc-eval "evalv(pi)"))
      (calc-quit))
    (insert (format "%s" res))))

(defun indset--mode-header ()
  "Insert mode-header for current mode."
  (goto-char (point-min))
  (insert (format "-*- mode: %s -*-\n"  (s-chop-suffix "-mode" (symbol-name major-mode))))
  (comment-line -1))

(defun indset--package-header ()
  "Insert standard elisp package header."
  (interactive)
  (goto-char (point-min))
  (insert
   (format ";;; %s. --- -*- lexical-binding: t; -*-\n" (file-name-nondirectory (buffer-file-name)))))

(defun indset--new-package ()
  "Insert standard template for new elisp packages."
  (goto-char (point-min))
  (insert
   (format
    ";;; %s --- Some description. -*- lexical-binding: t; -*-

;; Copyright (C) %s %s

;; Author: %s <%s>
;; URL:
;; Keywords:
;; Package-Requires ((%s))
;; Package-Version: %s
;; Version: 0.1.0


;;; Commentary:
;;

;;; Code:
"
    (buffer-name)
    (format-time-string "%Y")
    (user-full-name)
    (user-full-name)
    user-mail-address
    (format "emacs \"%s\"" emacs-version)
    (format-time-string "%Y%m%d")))
  (goto-char (point-max))
  (insert
   (format
    "


(provide '%s)
;;; %s ends here
"
    (f-base (buffer-name))
    (buffer-name))))

(defvar indset-alist
  '((date . (lambda () (format-time-string "%Y-%m-%d")))
    (date-compact . (lambda () (format-time-string "%Y%m%d")))
    (datetime . (lambda () (format-time-string "%Y-%m-%d %H:%M:%S")))
    (timestamp . (lambda () (float-time)))
    (shebang-sh . "#!/bin/sh")
    (shebang-bash . "#!/bin/bash")
    (shebang-env . "#!/usr/bin/env ")
    (shebang-python . "#!/usr/bin/env python")
    (current-file . (lambda () (buffer-file-name)))
    (pi . indset--calc-pi)
    (package-header . indset--package-header)
    (new-package . indset--new-package)
    (mode-header . indset--mode-header))
  "Alist of handlers for types to insert.

A handler can either be a function, in which case the result of
calling the function is inserted, otherwise the thing it is
inserted as-is.")

(defun indset ()
  (interactive)
  (when-let* ((pick (intern (completing-read "pick: " indset-alist nil t)))
              (el (cdr (assoc pick indset-alist))))
    (if (functionp el)
        (save-excursion (funcall el))
      (insert (format "%s" el)))))


(provide 'indset)
;;; indset.el ends here
