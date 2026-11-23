;; Agenda Files
(setq org-agenda-files (quote ("~/.org/tasks.org"
                               "~/.org/events/")))
;; Capture
(setq org-default-notes-file "~/.org/to_file.org")
;; Capture Mode
(global-set-key (kbd "C-c c") 'org-capture)

;; Tasks & Events
  (add-to-list 'org-todo-keywords
               '(sequence "TODO(t!)" "ACTIVE(a!)" "WAIT(W/!)" "|" "DONE(d!)" "SOMEDAY(s!)" "CANCELED(C!)" "FAILED(f!)"))
;; Event
  (add-to-list 'org-todo-keywords
               '(sequence "EVENT(e!)" "MEETING(m!)" "|" "DONE(d!)" "SOMEDAY(s!)" "CANCELED(C!)" "FAILED(f!)"))

(defvar org-project-task-template-todo
  "* TODO %?
  :PROPERTIES:
  :CATEGORY:
  :ID: %(org-id-uuid)
  :ASSIGNED:
  :IMPORTANCE:
  :URGENCY:
  :WITH:
  :AT:
  :STATE: todo
  :TYPE: task
  :END:
  :LOGBOOK:
  - State \"CREATED\"       from \"NONE\"       %U
  :END:"
  "TODO Template for org-project")

(setq org-capture-templates
        `(("t" "Create TODO" entry (file "~/.org/tasks.org")
               ,org-project-task-template-todo :clock-in t :clock-resume t)))

(defvar org-project-task-template-event
  "* EVENT
  :PROPERTIES:
  :CATEGORY:
  :ID: %(org-id-uuid)
  :ASSIGNED:
  :IMPORTANCE:
  :URGENCY:
  :WITH:
  :STATUS: todo
  :TYPE: event
  :END:
  :LOGBOOK:
  - State \"CREATED\"       from \"NONE\"       %U
  :END:
  %^t"
  "Task Template for org-project")

(setq org-capture-templates
      (append org-capture-templates
              `(("e" "Create EVENT" entry (file
                                           (lambda ()
                                             (expand-file-name
                                              (format-time-string "%Y-%m-events.org")
                                              "~/.org/events/")))
                 ,org-project-task-template-event :clock-in t :clock-resume t))))


;; Keybindings for Agenda Mode
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cb" 'org-iswitchb)

;; == Basic Settings ==
;; Start with the agenda log ON
(setq org-agenda-show-log t)
;; Set the agenda to skip scheduled items if they are done
(setq org-agenda-skip-scheduled-if-done t)
;; Set the agenda to skip deadlines if they are done
(setq org-agenda-skip-deadline-if-done t)

;; == Agenda todo item configuration ==
;; Keep tasks with dates on the global todo lists
(setq org-agenda-todo-ignore-with-date nil)

;; Keep tasks with deadlines on the global todo lists
(setq org-agenda-todo-ignore-deadlines nil)

;; Keep tasks with scheduled dates on the global todo lists
(setq org-agenda-todo-ignore-scheduled nil)

;; Keep tasks with timestamps on the global todo lists
(setq org-agenda-todo-ignore-timestamp nil)

;; Remove completed deadline tasks from the agenda view
(setq org-agenda-skip-deadline-if-done t)

;; Remove completed scheduled tasks from the agenda view
(setq org-agenda-skip-scheduled-if-done t)

;; Remove completed items from search results
(setq org-agenda-skip-timestamp-if-done t)

;; Always hilight the current agenda line

(add-hook 'org-agenda-mode-hook
          '(lambda () (hl-line-mode 1))
          'append)

;; Time Grid

;; The prompt to resolve running clocks before emacs closes causes more problems than it solves.
(setq org-clock-ask-before-exiting nil)

;;Set time grid ON for day
(setq org-agenda-use-time-grid t)

;; Set time grid times (show always on day even if no tasks set.)
(setq org-agenda-time-grid
      '((daily today)
       "----------------"
       (600 800 1000 1200 1400 1600 1800 2000)))

;; . [[http://orgmode.org/worg/agenda-optimization.html][Speed up agenda mode]]

;; Inhibit agenda files startup options (Org > 8.0)
;; http://orgmode.org/worg/agenda-optimization.html#sec-4
(setq org-agenda-inhibit-startup t)
(setq org-agenda-use-tag-inheritance nil)
;; Do not dim blocked tasks
(setq org-agenda-dim-blocked-tasks nil)

;; Custom agenda commands
(setq org-agenda-custom-commands
      (quote (("ts"
               "TODAY's SHORT"
               ((tags "CORE_TASK=\"true\"+LEVEL=1"
                      ((org-agenda-overriding-header "Core Clocking Tasks")))
                (agenda ""
                ((org-agenda-ndays 1)
                 (org-agenda-log-mode-items '(clock closed))
                 (org-agenda-entry-types '())))
                nil))
              ("tl"
               "TODAY's LOG"
               ((tags "CORE_TASK=\"true\"+LEVEL=1"
                      ((org-agenda-overriding-header "Core Clocking Tasks")))
                (agenda ""
                ((org-agenda-ndays 1)
                 (org-agenda-show-log t)
                 (org-agenda-log-mode-items '(clock closed))
                 (org-agenda-entry-types '())))
                nil))
              ("ta"
               "TODAY's Agenda"
               ((tags "CORE_TASK=\"true\"+LEVEL=1"
                      ((org-agenda-overriding-header "Current Projects")))
                (agenda ""
                        ((org-agenda-ndays 1)
                         (org-agenda-show-log t)
                         (org-agenda-log-mode-items '(clock closed))
                         (org-agenda-skip-function
                          '(org-agenda-skip-entry-if 'todo '("CANCELED" "SOMEDAY")))))
                nil))
              ("wa"
               "This Weeks's ALL TASKS"
               ((tags "CORE_TASK=\"true\"+LEVEL=1"
                      ((org-agenda-overriding-header "Core Clocking Tasks")))
                (tags "+SCHEDULED>=\"<+1w>\"TODO=\"TODO\"|+DEADLINE>=\"<+1w>\"+TODO=\"TODO\""
                      ((org-agenda-overriding-header "Upcoming tasks")))
                (agenda ""
                ((org-agenda-ndays 7)
                 (org-agenda-log-mode-items '(clock closed))))
                nil))
              ("wl"
               "This Weeks's LOGS"
               ((tags "CORE_TASK=\"true\"+LEVEL=1"
                      ((org-agenda-overriding-header "Core Clocking Tasks")))
                (agenda ""
                ((org-agenda-ndays 7)
                 (org-agenda-show-log t)
                 (org-agenda-log-mode-items '(clock closed))
                 (org-agenda-entry-types '())))
                nil)))))

;; Agenda Functions

(defvar org-state-prefix-regex "[ \t]*- State\\s-*"
    "The regex for identifying the prefix for state changes")

    (defvar org-state-done-heads-regex (concat "\"\\(" (regexp-opt org-done-keywords) "\\)\"")
    "The regex for identifying completed items in state changes")

    (defvar org-state-not-done-heads-regex (concat "\"\\(" (regexp-opt org-not-done-keywords) "\\)\"")
    "The regex for identifying incomplete items in  state changes")

    (defvar org-state-todo-heads-regex (concat "\"\\(" (regexp-opt org-todo-heads) "\\)\"")
    "The regex for identifying TODO items in state changes")

    (defvar org-state-clock-entry-regex (concat "\\[\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}"
                                                "\\s-+\\sw+\\s-+"
                                                "[012][0-9]:[0-5][0-9]\\)\\]")
    "The regex for identifying clock items in state changes")


  (defun org-state-get-state-change-regex (to-regex from-regex)
"Creates a regular expression that can be used to get a specific kind of state change.

This function relies on state changes using the style shown in the this example syntax.

- State \"DONE\"       from \"ACTIVE\"     [2015-07-22 Wed 18:10]

Usage example: To search for state changes that have moved from an non-done to done state one could use the following snippet.

(search-forward-regexp (org-state-get-state-change-regex org-state-done-heads-regex org-state-not-done-heads-regex))
"
  (concat org-state-prefix-regex to-regex "\\s-+from\\s-+" from-regex "\\s-+" org-state-clock-entry-regex))

(defvar org-my-archive-expiry-days 30
          "The number of days after which a completed task should be auto-archived.
        This can be 0 for immediate, or a floating point value.")


;; Clock settings
;; Resume clocking task when emacs is restarted
(org-clock-persistence-insinuate)
;; Show lot of clocking history so it's easy to pick items off the C-F11 list
(setq org-clock-history-length 23)
;; Resume clocking task on clock-in if the clock is open
(setq org-clock-in-resume t)
;; Change tasks to ACTIVE when clocking in
(setq org-clock-in-switch-to-state 'bh/clock-in-to-active)
;; Separate drawers for clocking and logs
(setq org-drawers (quote ("PROPERTIES" "LOGBOOK")))
;; Sometimes I change tasks I'm clocking quickly - this removes clocked tasks with 0:00 duration
(setq org-clock-out-remove-zero-time-clocks t)
;; Clock out when moving task to a done state
(setq org-clock-out-when-done t)
;; Save the running clock and all clock history when exiting Emacs, load it on startup
(setq org-clock-persist t)
;; Do not prompt to resume an active clock
(setq org-clock-persist-query-resume nil)
;; Enable auto clock resolution for finding open clocks
(setq org-clock-auto-clock-resolution (quote when-no-clock-is-running))
;; Include current clocking task in clock reports
(setq org-clock-report-include-clocking-task t)

;; To file todo-state changes into LOGBOOK drawer
(setq org-log-into-drawer t)
;; Save clock data and state changes and notes in the LOGBOOK drawer
(setq org-clock-into-drawer t)
(setq org-log-done 'time)
(setq org-log-redeadline 'time)
(setq org-log-reschedule 'time)

(provide 'my-org-agenda)
