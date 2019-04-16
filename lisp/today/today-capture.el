;;; -*- lexical-binding: t -*-

(require 'f)
(require 's)
(require 'dash)
(require 'org-web-tools)
(require 'cl-lib)

(defun today-capture--url-to-org-link (url)
  "Try to get the website title of URL, then convert into
`org-link' format."
  (let ((title (today-capture--title-from-url url)))
    (org-make-link-string url title)))

(defun today-capture--title-from-url (url)
  "Get the website title of URL."
  (let* ((html (org-web-tools--get-url url))
         (title (org-web-tools--html-title html))
         (title (s-replace "[" "(" title))
         (title (s-replace "]" ")" title)))
    title))

(defun today-capture--count-lines-from-url (url)
  "Get the number of lines on the website of URL.

Requires system tool `lynx'."
  (let ((lines (s-trim (shell-command-to-string (format "lynx -dump %s | wc -l" url)))))
    (if (< (length lines) 5) lines "?")))

(defun today-capture--date-from-wayback-machine (url)
  "Try to return the date of the first time the wayback machine
saw URL. This may not be the real publishing date for URL."
  (let* ((wa-query "http://web.archive.org/cdx/search/cdx?url=")
         (wa-params "&fl=timestamp&output=json&limit=1")
         (query (s-concat wa-query url wa-params))
         (response (->> (shell-command-to-string (format "curl -s \"%s\"" query)) (s-trim)))
         (jq "jq -r '.[1]? | add?'")
         (date (unless (s-blank-str-p response)
                 (->> (shell-command-to-string (format "echo '%s' | %s" response jq)) (s-trim)))))
    (if (not (or (s-blank-str? date)
                 (string= (substring date 0 11) "parse error")))
        (let ((year (substring date 0 4))
              (month (substring date 4 6))
              (day (substring date 6 8)))
          (format "%s-%s-%s" year month day))
      "?")))

(defun today-capture--youtube-get-upload-date (url)
  "Return the upload date for a youtube URL.
Requires system tools `youtube-dl' and `jq'."
  (let* ((ytdl "youtube-dl --simulate --dump-json")
         (jq "jq '.upload_date'")
         (raw-date (shell-command-to-string
                    (format "%s '%s' | %s" ytdl url jq)))
         (clean-date (s-replace "\"" "" (s-trim raw-date)))
         (year (substring clean-date 0 4))
         (month (substring clean-date 4 6))
         (day (substring clean-date 6 8)))
    (format "%s-%s-%s" year month day)))

(defun today-capture--youtube-duration-from-url (url)
  "Get the duration of a youtube video.

Requires system tool `youtube-dl'."
  (letrec ((raw-duration (shell-command-to-string
                          (format "%s '%s'"
                                  "youtube-dl --get-duration"
                                  url))))
    (if (<= (length raw-duration) 10)
        (s-trim raw-duration)
      "?")))

(defun today-capture--read-link-handler (link)
  "Handler for READ task. Expects CONTENT to be a link to some
website. Will try to extract the number of lines on the website,
and add to the front of the entry. Will also try to extract the
title of the website, and convert the link into an `org-mode'
link, using the title."
  (letrec ((lines (today-capture--count-lines-from-url link))
           (date (today-capture--date-from-wayback-machine link))
           (org-link (today-capture--url-to-org-link link)))
    (format "%s (%s lines) %s" date lines org-link)))

(defun today-capture--watch-link-handler (link)
  "Handler for the WATCH task. Expects the LINK to be a source
compatible with `youtube-dl'.will try to extract the title of the
link, and create an `org-mode' link using that title, will also
extract the duration of the video."
  (letrec ((title (today-capture--title-from-url link))
           (title (replace-regexp-in-string " - YouTube$" "" title))
           (duration (today-capture--youtube-duration-from-url link))
           (upload-date (today-capture--youtube-get-upload-date link))
           (org-link (org-make-link-string link title))
           (entry (format "%s (%s) %s" upload-date duration org-link)))
    (format "%s" entry)))

(defvar today-capture-handlers-alist
  '((read . today-capture--read-link-handler)
    (watch . today-capture--watch-link-handler))
  "List of capture tasks and their associated handlers. A handler
  recieves the capture content as a parameter.")

(defun today-capture--apply-handler (task entry)
  "If a handler exists for TASK, then return the result of
applying handler on ENTRY, otherwise return ENTRY."
  (let ((handler (assoc task today-capture-handlers-alist)))
    (if handler
        (funcall (cdr handler) entry)
      entry)))

;;;###autoload
(defun today-capture-async (task entry)
  "Captures an ENTRY with TASK, into the the today-file, asynchronously."
  (async-start
   `(lambda ()
      ,(async-inject-variables "^load-path$")
      (require 'today)

      (today-capture--apply-handler ',task ,entry))
   `(lambda (result)
      ,(async-inject-variables "^load-path$")
      (require 'today)

      (with-current-buffer (find-file-noselect today-inbox-file)
        (save-excursion
          (goto-char (point-max))
          (insert "** " result)
          (org-set-property "CAPTURED_TIME" (format-time-string "%Y-%m-%d %H:%M:%S"))
          (org-cycle)
          (save-buffer))))))

;;;###autoload
(defun today-capture (task entry)
  "Capture ENTRY with TASK into todays file."
  (today-capture-async task entry))

(defun today-capture-link-with-task-from-clipboard (task)
  "Capture ENTRY with TASK into todays file."
  (let* ((entry (substring-no-properties
                 (gui-get-selection 'CLIPBOARD 'UTF8_STRING))))
    (message "capturing from clipboard: %s" entry)
    (today-capture-async task entry)))

;;;###autoload
(defun today-capture-link-with-task (task)
  "Prompt for ENTRY, then capture with TASK into today's file."
  (letrec ((link (completing-read "link: " '())))
    (today-capture task link)))

;;;###autoload
(defun today-capture-prompt ()
  "Captures a LINK into today's file, with the selected TASK."
  (interactive)
  (letrec ((task (completing-read "task: " today-capture-handlers-alist))
           (entry (completing-read "entry: " '())))
    (today-capture task entry)))

;;;###autoload
(defun today-capture-elfeed-at-point ()
  "Captures a TASK from selected elfeed entry."
  (interactive)
  (letrec ((entry (car (elfeed-search-selected)))
           (link (elfeed-entry-link entry))
           (title (elfeed-entry-title entry))
           (org-link (org-make-link-string link title)))
    (elfeed-untag entry 'unread)
    (elfeed-search-update-entry entry)
    (today-capture 'elfeed org-link)
    (next-line)))

(provide 'today-capture)
