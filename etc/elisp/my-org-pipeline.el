;;; org-pipeline.el --- Org-mode fundraising pipeline management -*- lexical-binding: t; -*-

;; Provides an Org-mode workflow for managing a fundraising pipeline:
;; - Defines pipeline stages from LEAD through CLOSED and STEWARDING.
;; - Captures prospects with relationship, quality, revenue, and close-date data.
;; - Automatically updates deal health, progress, and weighted revenue.
;; - Adds a custom agenda view for stale, low-quality, high-quality, active,
;;   and post-close pipeline work.
;; - Produces a cumulative Circle-3 booked/projected revenue trendline via Gnuplot.
;; - Audits active Circle-3 deals for overdue close dates and missing amounts.
;;
;; Configure `my-org-pipeline-agenda-file' and `my-org-pipeline-target',
;; then use:
;; - `org-capture' template "p" to create a pipeline entry.
;; - Agenda command "p" for the pipeline review.
;; - `C-c t' for the trendline, `C-c C-a' for the hygiene audit, and
;;   `C-c r' to refresh all entries in the current Org buffer.
;;
;; Requires org, cl-lib, and gnuplot.

(require 'cl-lib)
(use-package gnuplot
    :ensure t)
(use-package org
  :ensure t)

(defvar my-org-pipeline-agenda-file
  nil
  "The path to the my-org-pipeline agenda file.")

(defvar my-org-pipeline-target
  nil
  "The red line. One number, set from your budget, not from hope.

Can be set in .emacs config using the below:
    (setq my-org-pipeline-target ######)

Can be set in individual org-mode file frontmatter using the below:
    #+BIND: my-org-pipeline-target ######
")

(defconst my-org-pipeline--active-stages
  '("LEAD" "CONVERSATION" "SHAPING" "WORK" "CLOSING")
  "TODO states representing active, unclosed pipeline deals.")

(add-to-list 'org-todo-keywords
               '(sequence "LEAD(l)" "CONVERSATION(v)" "SHAPING(s)" "WORK(w!)" "CLOSING(c!)" "|" "CLOSED(d!)" "STEWARDING(t)"))

(setq org-todo-keyword-faces '(("LEAD" . org-warning)
                               ("CONVERSATION" . org-warning)
                               ("SHAPING" . org-warning)
                               ("WORK" . (:foreground "orange" :weight bold))
                               ("CLOSING" . (:foreground "red" :weight bold))
                               ("STEWARDING" . (:foreground "forest green"))))


;; ========== PIPELINE REVIEW ==============

;; ----------- AGENDA -------------------
;; Make sure org-agenda is loaded before modifying org-agenda-files
(with-eval-after-load 'org
  (add-to-list 'org-agenda-files my-org-pipeline-agenda-file))

;; A comparator that implements the bottom-up rule. Worse grades sort first.
(defun my-org-pipeline-cmp-quality (a b) "Bottom-up rule: C/D/F entries sort above A/B entries." (let* ((ma (or (get-text-property 0 'org-marker a) (get-text-property 0 'org-hd-marker a))) (mb (or (get-text-property 0 'org-marker b) (get-text-property 0 'org-hd-marker b))) (qa (or (org-entry-get ma "QUALITY") "F")) (qb (or (org-entry-get mb "QUALITY") "F"))) (cond ((string> qa qb) -1) ((string< qa qb) +1))))

;; A prefix format so every line is a decision line — grade, progress, and the next action:
(defvar my-org-pipeline-prefix " %-3(or (org-entry-get nil \"QUALITY\") \"?\") %-5(or (org-entry-get nil \"PROGRESS\") \"\") %-35(or (org-entry-get nil \"STATUS\") \"NO NEXT ACTION\") ")

(setq org-agenda-custom-commands
      '(("p" "Work the Pipeline"
         (;; 1. Stale — the trendline is lying until these are acted on
          (tags-todo "HEALTH<\"<-60d>\"+CIRCLE=\"3\"/!LEAD|CONVERSATION|SHAPING|WORK|CLOSING" ((org-agenda-overriding-header "STALE (60+ days) — cut the probability, demote the stage, or park deliberately") (org-agenda-prefix-format my-org-pipeline-prefix)))
          ;; 2. The quantity half, practice first
          (tags-todo "QUALITY={[C-F]}/!LEAD|CONVERSATION|SHAPING" ((org-agenda-overriding-header "QUANTITY HALF, WORK FIRST — the C's: practice, volume, candor") (org-agenda-cmp-user-defined 'my-org-pipeline-cmp-quality) (org-agenda-sorting-strategy '(user-defined-up)) (org-agenda-prefix-format my-org-pipeline-prefix)))
          ;; 3. The A's and B's — touch only when sharp
          (tags-todo "QUALITY={[AB]}/!LEAD|CONVERSATION|SHAPING" ((org-agenda-overriding-header "THE A'S AND B'S — leave these for when you are sharp") (org-agenda-prefix-format my-org-pipeline-prefix)))
          ;; 4. The quality half — invested; fallout here means an after-action review
          (todo "WORK|CLOSING" ((org-agenda-overriding-header "QUALITY HALF — resources committed; these cannot fall out") (org-agenda-prefix-format my-org-pipeline-prefix)))
          ;; 5. Post-close
          (todo "STEWARDING" ((org-agenda-overriding-header "STEWARDING — a renewal is easier than an initiation") (org-agenda-prefix-format my-org-pipeline-prefix)))))))


;; ------------- TIMELINE CREATION -------------------
(defun my-org-pipeline--monthly-buckets ()
  "Aggregate Circle-3 pipeline revenue by month across Org agenda files.

Scans all entries matching `CIRCLE=\"3\"' in `org-agenda-files' and
groups their dollar amounts by the `:EXPECTED_CLOSE:' property month
formatted as \"YYYY-MM\".

Only entries with a non-empty `:EXPECTED_CLOSE:', a positive dollar
value, and a recognized TODO keyword are included:
- Booked stages (\"CLOSED\", \"STEWARDING\"): sums `:AMOUNT:'.
- Active stages (\"LEAD\", \"CONVERSATION\", \"SHAPING\", \"WORK\",
  \"CLOSING\"): sums `:WEIGHTED_AMOUNT:'.

Return an alist of elements shaped like (\"YYYY-MM\" BOOKED . PROJECTED),
sorted chronologically in ascending order."
  (let ((buckets (make-hash-table :test #'equal)))
    (org-map-entries
     (lambda ()
       (let* ((stage (org-get-todo-state))
              (booked (member stage '("CLOSED" "STEWARDING")))
              (active (member stage '("LEAD" "CONVERSATION" "SHAPING" "WORK" "CLOSING")))
              (close (org-entry-get nil "EXPECTED_CLOSE"))
              (dollars (string-to-number
                        (or (org-entry-get nil (if booked "AMOUNT" "WEIGHTED_AMOUNT"))
                            "0"))))
         (when (and close (> dollars 0) (or booked active))
           (let* ((month (format-time-string "%Y-%m" (org-time-string-to-time close)))
                  (cell (gethash month buckets (cons 0 0))))
             (puthash month
                      (if booked
                          (cons (+ (car cell) dollars) (cdr cell))
                        (cons (car cell) (+ (cdr cell) dollars)))
                      buckets)))))
     "CIRCLE=\"3\"" 'agenda)
    (sort (let (rows)
            (maphash (lambda (k v) (push (cons k v) rows)) buckets)
            rows)
          (lambda (a b) (string< (car a) (car b))))))

(defun my-org-pipeline-trendline ()
  "Generate a cumulative pipeline Org table and render a Gnuplot trendline.

Fetches monthly Circle-3 revenue buckets via `my-org-pipeline--monthly-buckets',
accumulates running totals for confirmed (`Booked') and combined
(`Booked' + `Projected') revenue, and writes an Org table with `#+PLOT:'
headers into the \"Pipeline Trendline\" buffer.

The resulting 2D line chart plots three series over time (`YYYY-MM'):
- Target (`my-org-pipeline-target'): solid red line
- Cumulative Booked: solid forest-green line
- Cumulative Projected (Booked + Weighted Active): dashed forest-green line

Signals a `user-error' if no qualifying Circle-3 entries are found.
Requires `gnuplot' and Emacs's `org-plot' library."
  (interactive)
  (let ((rows (my-org-pipeline--monthly-buckets))
        (cum-booked 0.0)
        (cum-total 0.0))
    (unless rows
      (user-error "No Circle-3 entries with dates and real dollars"))
    (with-current-buffer (get-buffer-create "Pipeline Trendline")
      (erase-buffer)
      (org-mode)
      (insert "#+PLOT: title:\"Pipeline Trendline\" ind:1 deps:(2 3 4) type:2d"
              " with:lines"
              " set:\"xdata time\" set:\"timefmt '%Y-%m'\" set:\"format x '%b %y'\""
              " set:\"linetype 1 lc rgb 'red' lw 2\""
              " set:\"linetype 2 lc rgb 'forest-green' lw 2\""
              " set:\"linetype 3 lc rgb 'forest-green' lw 2 dt 2\""
              " set:\"key left top\"\n")
      (insert "| Month | Target | Booked | Projected |\n|---|\n")
      (dolist (row rows)
        (let ((month (car row))
              (booked (cadr row))
              (projected (cddr row)))
          (cl-incf cum-booked booked)
          (cl-incf cum-total (+ booked projected))
          (insert (format "| %s | %d | %.0f | %.0f |\n"
                          month my-org-pipeline-target cum-booked cum-total))))
      (org-table-align)
      (pop-to-buffer (current-buffer))
      (goto-char (point-min))
      (forward-line 2) ; move point inside the table for org-plot
      (org-plot/gnuplot))))

(add-hook 'org-mode-hook
          (lambda ()
            (define-key org-mode-map (kbd "C-c t") 'my-org-pipeline-trendline)))

(defun my-org-pipeline--collect-hygiene-issues ()
  "Scan Circle-3 agenda entries and return an alist of hygiene issues.
Returns `((past-due . LIST) (unpriced . LIST))' where each item is
a plist `(:heading :stage :close :amount :weighted :marker)'."
  (let ((today (format-time-string "%Y-%m-%d"))
        past-due
        unpriced)
    (org-map-entries
     (lambda ()
       (let ((stage (org-get-todo-state)))
         (when (member stage my-org-pipeline--active-stages)
           (let* ((heading (org-get-heading t t t t))
                  (close (org-entry-get nil "EXPECTED_CLOSE"))
                  (close-date (when close
                                (format-time-string
                                 "%Y-%m-%d"
                                 (org-time-string-to-time close))))
                  (amt (string-to-number (or (org-entry-get nil "AMOUNT") "0")))
                  (w-amt (string-to-number (or (org-entry-get nil "WEIGHTED_AMOUNT") "0")))
                  (item (list :heading heading
                              :stage stage
                              :close close-date
                              :amount amt
                              :weighted w-amt
                              :marker (point-marker))))
             (when (and close-date (string< close-date today))
               (push item past-due))
             (when (or (<= amt 0) (<= w-amt 0))
               (push item unpriced))))))
     "CIRCLE=\"3\"" 'agenda)
    `((past-due . ,(nreverse past-due))
      (unpriced . ,(nreverse unpriced)))))


(defun my-org-pipeline-audit ()
  "Open a clickable Org report of Circle-3 entries violating data discipline.
Flags:
1. Active entries with an `:EXPECTED_CLOSE:' date before today.
2. Active entries missing a positive `:AMOUNT:' or `:WEIGHTED_AMOUNT:'."
  (interactive)
  (let* ((issues (my-org-pipeline--collect-hygiene-issues))
         (past-due (alist-get 'past-due issues))
         (unpriced (alist-get 'unpriced issues)))
    (if (and (null past-due) (null unpriced))
        (message "Pipeline clean: all active Circle-3 entries are dated forward and priced.")
      (with-current-buffer (get-buffer-create "*Pipeline Hygiene Audit*")
        (erase-buffer)
        (org-mode)
        (insert (format "#+TITLE: Pipeline Hygiene Audit (%s)\n\n"
                        (format-time-string "%Y-%m-%d")))
        (insert (format "* Past-Dated Expected Close (%d)\n" (length past-due)))
        (insert "Active deals with close dates behind today silently pad past months.\n"
                "Re-date forward, or cut probability and demote stage.\n\n")
        (if (null past-due)
            (insert "- None\n")
          (dolist (it past-due)
            (let* ((m (plist-get it :marker))
                   (file (buffer-file-name (marker-buffer m)))
                   (heading (plist-get it :heading)))
              (insert (format "- [[file:%s::*%s][%s]] — Stage: =%s= | Close: *%s* | Weighted: $%.0f\n"
                              file heading heading
                              (plist-get it :stage)
                              (plist-get it :close)
                              (plist-get it :weighted))))))
        (insert (format "\n* Zero or Placeholder Amounts (%d)\n" (length unpriced)))
        (insert "Active Circle-3 entries excluded from the chart until assigned a real figure.\n\n")
        (if (null unpriced)
            (insert "- None\n")
          (dolist (it unpriced)
            (let* ((m (plist-get it :marker))
                   (file (buffer-file-name (marker-buffer m)))
                   (heading (plist-get it :heading)))
              (insert (format "- [[file:%s::*%s][%s]] — Stage: =%s= | Amount: $%.0f | Weighted: $%.0f\n"
                              file heading heading
                              (plist-get it :stage)
                              (plist-get it :amount)
                              (plist-get it :weighted))))))
        (goto-char (point-min))
        (pop-to-buffer (current-buffer))))))

(add-hook 'org-mode-hook
          (lambda ()
            (define-key org-mode-map (kbd "C-c C-a") 'my-org-pipeline-audit)))

;; ================= ITEM CREATION AND MODIFICATION ============

;; ---------------------- PROMPTS ----------------------
(defun my-org-pipeline-template-prompt-with-explanations (prompt choices-alist)
  "Prompt user with PROMPT using CHOICES-ALIST of (value . description).
Displays the description as an annotation, returning only the clean value."
  (let* ((table (lambda (string pred action)
                  (if (eq action 'metadata)
                      `(metadata
                        (annotation-function
                         . ,(lambda (cand)
                              (when-let ((desc (cdr (assoc cand choices-alist))))
                                (concat "  —  " desc)))))
                    (complete-with-action action choices-alist string pred)))))
    (completing-read prompt table nil t)))

(defvar my-org-pipeline-lead-quality-choices
  '(("A" . "Top-tier fit; high likelihood to join the work — save for peak focus & sharp energy")
    ("B" . "Strong fit; solid potential to be part of the work — prioritize after A's")
    ("C" . "Moderate/uncertain fit; good for practice, warm-ups, and testing your pitch")
    ("D" . "Weak fit; low likelihood to convert — low stakes, minimal time investment")
    ("F" . "Poor fit; unlikely to be part of the work — disqualify and focus on fostering friendship"))
  "Alist of lead Quality grades (A-F) and summaries for Org-mode pipeline prompts.")


;; Register QUALITY for property updates
(setf (alist-get "QUALITY" org-property-set-functions-alist nil nil #'equal)
      (lambda (prompt &rest _)
        (my-org-pipeline-template-prompt-with-explanations
         prompt
         my-org-pipeline-lead-quality-choices)))

(defvar my-org-pipeline-lead-circle-choices
  '(("Circle 1" . "Board and staff — core internal team and governance")
    ("Circle 2" . "Advisors and connectors — strategic guidance and network introductions")
    ("Circle 3" . "Potential funders — prospective financial supporters and donors"))
  "Alist of pipeline Circle tiers and descriptions for Org-mode prompts.")

;; Register CIRCLE for property updates
(setf (alist-get "CIRCLE" org-property-set-functions-alist nil nil #'equal)
      (lambda (prompt &rest _)
        (my-org-pipeline-template-prompt-with-explanations
         prompt
         my-org-pipeline-lead-circle-choices)))

(defvar my-org-pipeline-template-lead
  "* %(my-org-pipeline-capture-select-todo-keyword) %^{Name of person}
  :PROPERTIES:
  :ORGANIZATION: %^{Organization}
  :TITLE: %^{Title}
  :STATUS: %^{Current Status: the next thing to do with this person}
  :HEALTH: %U
  :CIRCLE: %(my-org-pipeline-template-prompt-with-explanations \"Which Circle does the person sit in\" my-org-pipeline-lead-circle-choices)
  :INTEREST: %^{Interest: Why this person is here at all}
  :CONNECTION: %^{Connection: The person who will connect you}
  :QUALITY: %(my-org-pipeline-template-prompt-with-explanations \"Quality of person for work: \" my-org-pipeline-lead-quality-choices)
  :PROGRESS: 0%
  :AMOUNT: %^{AMOUNT: A fixed dollar value the conversation is worth (BE PESSIMISTIC)}
  :WEIGHTED_AMOUNT: 0
  :ID: %(org-id-uuid)
  :EXPECTED_CLOSE: %^t
  :END:
  :LOGBOOK:
  - State \"CREATED\"       from \"NONE\"       %U
  :END:
%?
")

(with-eval-after-load 'org-capture
  (add-to-list 'org-capture-templates
               `("p" "Create PIPLINE entry" entry
                 (file ,my-org-pipeline-agenda-file)
                 ,my-org-pipeline-template-lead)
               t))

;; WEIGHTED STATUS FOR PROGRESS
(defvar my-org-pipeline-status-weights
  '(("LEAD" . 10)
    ("CONVERSATION" . 20)
    ("SHAPING" . 40)
    ("WORK" . 60)
    ("CLOSING" . 90)
    ("CLOSED" . 100)
    ("STEWARDING" . 100))
  "Alist mapping pipeline status to base progress rates.")

(defun my-org-pipeline-get-time-item-weight (days)
  "Map elapsed DAYS since the last :HEALTH: timestamp to a numerical weight."
  (cond
   ((null days) 1.0)    ; Default weight if :HEALTH: is not yet set
   ((< days 1.0) 1.2)   ; Updated within the last 24 hours
   ((< days 7.0) 1.0)   ; Updated within the last week
   ((< days 30.0) 0.8)  ; Updated within the last month
   (t 0.5)))            ; Older than 30 days

(defun my-org-pipeline-update-health-and-progress (&rest _)
  "Calculate :PROGRESS: from TODO state and previous :HEALTH: timestamp, then update :HEALTH:."
  (when (derived-mode-p 'org-mode)
    (save-excursion
      (org-back-to-heading t)
      (let* ((status (org-get-todo-state))
             (status-num (cdr (assoc status my-org-pipeline-status-weights)))
             (last-ts (org-entry-get nil "HEALTH"))
             (days-elapsed (when (and last-ts (not (string-empty-p last-ts)))
                             (/ (float-time
                                 (time-subtract (current-time)
                                                (org-time-string-to-time last-ts)))
                                86400.0)))
             (item-num (my-org-pipeline-get-time-item-weight days-elapsed)))
        ;; 1. Calculate and set :PROGRESS: using the old :HEALTH: timestamp
        (when status-num
          (let ((pct (min 100 (round (* status-num item-num)))))
            (org-set-property "PROGRESS" (format "%d%%" pct))))
        ;; 2. Update :HEALTH: to the current inactive timestamp
        (org-set-property
         "HEALTH"
         (format-time-string (org-time-stamp-format t t)))))))

(defun my-org-pipeline-update-weighted-amount ()
  "Calculate WEIGHTED_AMOUNT by multiplying AMOUNT and PROGRESS for the current heading."
  (interactive)
  (let ((amount-str (org-entry-get nil "AMOUNT"))
        (progress-str (org-entry-get nil "PROGRESS")))
    (if (and amount-str progress-str)
        (let* ((amount (string-to-number amount-str))
               ;; Handle both "50%" and "0.5" formats
               (is-percent (string-match-p "%" progress-str))
               (raw-progress (string-to-number (replace-regexp-in-string "%" "" progress-str)))
               (progress (if is-percent (/ raw-progress 100.0) raw-progress))
               (weighted (* amount progress)))
          ;; Format to 2 decimal places (adjust "%.2f" as needed)
          (org-entry-put nil "WEIGHTED_AMOUNT" (format "%.2f" weighted))
          (message "Updated WEIGHTED_AMOUNT to %.2f" weighted))
      (message "Missing AMOUNT or PROGRESS property on current heading."))))

;; Trigger on TODO state changes (C-c C-t)
(add-hook 'org-after-todo-state-change-hook #'my-org-pipeline-update-health-and-progress)

;; Trigger when adding a note or log entry (C-c C-z)
(add-hook 'org-log-buffer-setup-hook #'my-org-pipeline-update-health-and-progress)

;; Trigger when manually editing non-automatic properties (C-c C-x p), avoiding recursion
(defun my-org-pipeline-on-property-changed (property _value)
  (unless (member property '("HEALTH" "PROGRESS" "WEIGHTED_AMOUNT"))
    (my-org-pipeline-update-health-and-progress)))

(add-hook 'org-property-changed-functions #'my-org-pipeline-on-property-changed)

(defun my-org-pipeline-update-all-items-in-buffer ()
  "Run health/progress and weighted amount updates on all Org headings in the buffer."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in an Org-mode buffer"))
  (org-map-entries
   (lambda ()
     (my-org-pipeline-update-health-and-progress)
     (my-org-pipeline-update-weighted-amount))
   t
   'file))

(add-hook 'org-mode-hook
          (lambda ()
            (define-key org-mode-map (kbd "C-c r") 'my-org-pipeline-update-all-items-in-buffer)))

(defun my-org-pipeline-log-cur-status-change (orig-fun pom property value)
  "Log changes to the STATUS property into the entry's logbook/body."
  (let* ((is-target (string-equal-ignore-case property "STATUS"))
         (old-val (when is-target (org-entry-get pom "STATUS"))))
    ;; Execute the original org-entry-put function first
    (funcall orig-fun pom property value)
    ;; If CUR_STATUS changed, insert a timestamped log entry
    (when (and is-target (not (equal old-val value)))
      (org-with-point-at pom
        (let ((end (org-log-beginning t)))
          (goto-char end)
          (insert (format "- %S  [%s]\n"
                          (or old-val "NONE")
                          (format-time-string (org-time-stamp-format t t)))))))))

(advice-add 'org-entry-put :around #'my-org-pipeline-log-cur-status-change)

(defun my-org-pipeline-capture-select-todo-keyword ()
  "Prompt for a TODO keyword using the target buffer's active `org-todo-keywords-1`."
  (let* ((target-buffer (org-capture-get :buffer))
         (keywords (if (buffer-live-p target-buffer)
                       (with-current-buffer target-buffer
                         org-todo-keywords-1)
                     org-todo-keywords-1)))
    (completing-read "Pipeline state: " keywords nil t)))


(provide 'my-org-pipeline)
