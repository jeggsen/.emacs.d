(require 'map)

(defcustom doc-at-point-alist '()
  "Alist of plists, containing metadata for documentation."
  :group 'doc-at-point)

(defcustom doc-at-point-display-fn (if (fboundp 'popup-tip)
                                       #'doc-at-point--display-fn-popup-tip
                                     #'message)
  "Function used to display documentation."
  :type 'function
  :group 'doc-at-point)

(defun doc-at-point--display-fn-popup-tip (doc-string)
  "Shows `doc-string' in a popup tooltip."
  (popup-tip doc-string :margin-left 1 :margin-right 1))

(defun doc-at-point--with-entry (entry)
  (let* ((symbol-fn (plist-get entry :symbol-fn))
         (doc-fn (plist-get entry :doc-fn))
         (sym (funcall symbol-fn))
         (doc (funcall doc-fn sym)))
    (if doc
        (funcall doc-at-point-display-fn doc)
      (message "No documentation found for %s" (symbol-name sym)))))

(cl-defun doc-at-point-register (&key mode symbol-fn doc-fn)
  "Register a new documentation backend."
  (map-put doc-at-point-alist mode
           (list `(:symbol-fn ,symbol-fn :doc-fn ,doc-fn))))

(defun doc-at-point ()
  "Show documentation for the symbol at point, based on relevant
backend."
  (interactive)
  (let* ((current-mode major-mode)
         (entry (car (map-elt doc-at-point-alist current-mode))))
    (if entry
        (doc-at-point--with-entry entry)
      (message "No doc-at-point backend for %s" current-mode))))

(provide 'doc-at-point-core)