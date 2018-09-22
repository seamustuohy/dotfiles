;; === Debugging ===
;; uncomment for Debugging
;;(setq debug-on-error t)
;; Set debug at point
;; (debug)



;; === Packages ===


(require 'package)
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  ;; Comment/uncomment these two lines to enable/disable MELPA and MELPA Stable as desired
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  ;;(add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
  (when (< emacs-major-version 24)
    ;; For important compatibility libraries like cl-lib
    (add-to-list 'package-archives '("gnu" . (concat proto "://elpa.gnu.org/packages/")))))
(package-initialize)


(unless package-archive-contents
  (package-refresh-contents))

(setq package-list '(yasnippet
                     smartscan
                     drag-stuff
                     guide-key
                     guru-mode
                     persp-projectile
                     helm-ag
                     helm-dash
                     helm-flycheck
                     helm-projectile
                     highlight-indentation
                     js2-mode
                     js3-mode
                     json-mode
                     logview
                     persp-mode
                     rainbow-mode
                     solarized-theme
                     switch-window
                     undo-tree
                     helm-swoop
                     use-package
                     web-beautify
                     web-mode
                     wrap-region
                     writegood-mode
                     yaml-mode))

(dolist (package package-list)
  (unless (package-installed-p package)
    (package-install package)))

(require 'use-package)

;; === Information ===
;; Personal Information

(setq user-full-name "seamus tuohy"
      user-mail-address "code@seamustuohy.com")
(setq user-code-mail-address "code@seamustuohy.com")

;; GPG key to use for encryption
;; Either the Key ID or set to nil to use symmetric encryption.

(setq org-crypt-key "3CF07AA7")

;; Overwrite Highlighted Text
;; cua-selection-mode - enables typing over a region to replace it
(cua-selection-mode t)

;; Spaces vs. Tabs
;; Make tabs four spaces instead.
(setq-default indent-tabs-mode nil)
(setq tab-width 4)

;; UTF-8 by default
(setq org-export-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(set-charset-priority 'unicode)
(setq default-process-coding-system '(utf-8-unix . utf-8-unix))

;; === Emacs Environment ===
(message "Initializing Emacs Environment")

;; Personal key space
(define-prefix-command 'personal-global-map)
(global-set-key (kbd "C-C s") 'personal-global-map)

;; Server
;; Start a server when there is not a server already running.
(require 'server)
(or (server-running-p)
    (server-start))

;; Confirmation
;; I like to stay in my emacs environment. Make sure emacs isn't accidentally killed

(defun paranoid-exit-from-emacs()
 (interactive)
 (if (yes-or-no-p "Do you want to exit? ")
     (save-buffers-kill-emacs)))

;; I do hate typing the full yes or no though
;; yes/no turns to y/n

(fset 'yes-or-no-p 'y-or-n-p)

(global-set-key "\C-x\C-c" 'paranoid-exit-from-emacs)

;; Text Manipulation
(message "Initializing text manipulation")

;; Drag Stuff
;; Use the super key and the control key to drag lines in any file anywhere I want.

; drag stuff
(require 'drag-stuff)
(setq drag-stuff-modifier '(super control))
(drag-stuff-global-mode t)

;; Unfill Paragraph
;; [[https://emacs.stackexchange.com/questions/2606/opposite-of-fill-paragraph][From Stack Overflow user King Marvel]]

(defun unfill-paragraph ()
  "Takes a multi-line paragraph and makes it into a single line of text."
  (interactive)
  (let ((fill-column (point-max)))
    (fill-paragraph nil)))

 ;; Handy key definition
 (define-key global-map "\M-Q" 'unfill-paragraph)

;; Security
(message "Initializing security")

;; Remove the annoying EPA popup
(setq epa-popup-info-window nil)

;; Hacks
(message "Initializing hacks")

;; This little hack saves me from when pasting becomes VERY slow. It occurs at seeming random intervals.
;; [[https://lists.gnu.org/archive/html/bug-gnu-emacs/2015-04/msg00222.html][Problem]]
;; [[https://debbugs.gnu.org/cgi/bugreport.cgi?bug=16737][Solution]]
(setq x-selection-timeout 10)


;; Code Support

(message "Initializing code support")
(setq-default fill-column 80) ;; Sets a 80 character line width

;; Return and indent on prog-mode variants
(defun code/set-newline-and-indent ()
  (local-set-key [(return)] 'newline-and-indent))

(add-hook 'prog-mode-hook 'code/set-newline-and-indent)
(remove-hook 'prog-mode-hook 'code/set-newline-and-indent)
;; Wrap Regions

; wrap-region
(message "wrap region")
(require 'wrap-region)
(add-hook 'prog-mode-hook (lambda () (wrap-region-mode t)))
(add-hook 'markdown-mode-hook (lambda () (wrap-region-mode t)))
(wrap-region-add-wrapper "*" "*")

;; FlyCheck
(require 'flycheck)

;; Keybindings
(message "key binding")
(global-set-key (kbd "C-c m f") 'flycheck-mode)
(global-set-key (kbd "C-c f r")
                '(lambda ()
                   (interactive)
                   (flycheck-mode t)))
(global-set-key [(f5)] 'flycheck-previous-error)
(global-set-key [(f6)] 'flycheck-next-error)

;; Prettyness
(message "highlight")
(require 'highlight-indentation)

;; Tramp
(require 'tramp)
(setq tramp-default-method "ssh")


;; python

(message "python")
(add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))
(add-hook 'python-mode-hook
          (lambda () (highlight-indentation-current-column-mode)))

; turn on flycheck-mode in python-mode

(add-hook 'python-mode-hook '(lambda () (flycheck-mode)))
(add-hook 'python-mode-hook
          (lambda () (flyspell-prog-mode)))

;; Shell

(add-hook 'sh-mode-hook '(lambda () (flycheck-mode)))
(add-hook 'sh-mode-hook
            (lambda () (flyspell-prog-mode)))

;; Powershell

(unless (package-installed-p 'powershell)
    (package-refresh-contents)
      (package-install 'powershell))

(require 'powershell)

(add-to-list 'auto-mode-alist '("\\.ps[dm]?1\\'" . powershell-mode))


;; Lisp

(add-to-list 'auto-mode-alist '("\\.el\\'" . lisp-mode))
(add-hook 'lisp-mode-hook
            (lambda () (flyspell-prog-mode)))

;; Javascript
(require 'js2-mode)
(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
(add-hook 'js2-mode-hook '(lambda () (flycheck-mode)))
(add-hook 'js2-mode-hook
            (lambda () (flyspell-prog-mode)))

;; HTML

; web-mode
(require 'web-mode)
(add-to-list 'auto-mode-alist '("\\.html\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.hbs\\'" . web-mode))



;; UNESCAPE URLS
(defun func-region (start end func)
  "run a function over the region between START and END in current buffer."
  (save-excursion
    (let ((text (delete-and-extract-region start end)))
      (insert (funcall func text)))))

(defun hex-region (start end)
  "urlencode the region between START and END in current buffer."
  (interactive "r")
  (func-region start end #'url-hexify-string))

(defun unhex-region (start end)
  "de-urlencode the region between START and END in current buffer."
  (interactive "r")
  (func-region start end #'url-unhex-string))

;; Unescape Hex encoded strings
;; i.e. \x encoded strings
;; "\122\x45\115\117\x54\x45\x5f\101\x44\104\x52" == "REMOTE_ADDR"
(defun hex-decode-region (start end)
  "urlencode the region between START and END in current buffer."
  (interactive "r")
  (func-region start end #'epg--decode-hexstring))

;; Elisp: URL Percent Decode/Encode
;; http://ergoemacs.org/emacs/elisp_decode_uri_percent_encoding.html
(defun xah-html-decode-percent-encoded-url ()
  "Decode percent encoded URI of URI under cursor or selection.

Example:
    http://en.wikipedia.org/wiki/Saint_Jerome_in_His_Study_%28D%C3%BCrer%29
becomes
    http://en.wikipedia.org/wiki/Saint_Jerome_in_His_Study_(Dürer)

Example:
    http://zh.wikipedia.org/wiki/%E6%96%87%E6%9C%AC%E7%BC%96%E8%BE%91%E5%99%A8
becomes
    http://zh.wikipedia.org/wiki/文本编辑器

For string version, see `xah-html-url-percent-decode-string'.
To encode, see `xah-html-encode-percent-encoded-url'.
URL `http://ergoemacs.org/emacs/elisp_decode_uri_percent_encoding.html'
Version 2015-09-14."
  (interactive)
  (let ($boundaries $p1 $p2 $input-str)
    (if (use-region-p)
        (progn
          (setq $p1 (region-beginning))
          (setq $p2 (region-end)))
      (progn
        (setq $boundaries (bounds-of-thing-at-point 'url))
        (setq $p1 (car $boundaries))
        (setq $p2 (cdr $boundaries))))
    (setq $input-str (buffer-substring-no-properties $p1 $p2))
    (require 'url-util)
    (delete-region $p1 $p2)
    (insert (decode-coding-string (url-unhex-string $input-str) 'utf-8))))


;; Pretty format XML markup in region. You need to have nxml-mode
;; http://www.emacswiki.org/cgi-bin/wiki/NxmlMode installed to do
;; this.  The function inserts linebreaks to separate tags that have
;; nothing but whitespace between them.  It then indents the markup
;; by using nxml's indentation rules.

(require 'nxml-mode)
(defun bf-pretty-print-xml-region (begin end)
  "Pretty format XML markup in region. You need to have nxml-mode
http://www.emacswiki.org/cgi-bin/wiki/NxmlMode installed to do
this.  The function inserts linebreaks to separate tags that have
nothing but whitespace between them.  It then indents the markup
by using nxml's indentation rules."
  (interactive "r")
  (save-excursion
      (nxml-mode)
      (goto-char begin)
      (while (search-forward-regexp "\>[ \\t]*\<" nil t)
        (backward-char) (insert "\n"))
      (indent-region begin end))
    (message "Ah, much better!"))


;; rc files
(add-to-list 'auto-mode-alist '("\\.*rc$" . conf-unix-mode))
;; YAML

(require 'yaml-mode)
(add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))

;; JSON

(require 'json-mode)
(add-to-list 'auto-mode-alist '("\\.json\\'" . json-mode))

;; Markdown

(autoload 'markdown-mode "markdown-mode.el" nil t)
(add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))

;; flyspell mode for spell checking in markdown
(add-hook 'markdown-mode-hook 'turn-on-flyspell 'append)

;; LogFiles

;(require 'logview-mode)
(add-to-list 'auto-mode-alist '("/var/log.*\\'" . logview-mode))
(add-to-list 'auto-mode-alist '("\\.log\\'" . logview-mode))


;; Display
(message "Initializing display")
;; Mark and Cursor
;; I like to have the mark always active when I am selecting text.  This highlights the mark area.
;; NOTE: I am currently exploring how to correctly use the mark, so this may become an annoyance.
(setq transient-mark-mode t)


;; I like to know exactly what character my cursor is on. This sets the cursor to be a box on top of that character.
(setq-default cursor-type 'box)

;; I want to see parens highlighted and I want them immediately.
(setq show-paren-delay 0)
(show-paren-mode)

;; Line number mode
;; I want to know what line number I am on. Line-number-mode keeps track of this for me globally.
(line-number-mode 1)

;; Column number mode
;; I want to know what column I am on when dealing with error messages. I just keep it on globally
(setq column-number-mode t)


;; Frame shows buffer name
;; When not clocked into a task I want to see the full path of the current buffer I am in in the title frame.
(setq frame-title-format '(buffer-file-name "%f" ("%b")))

;; Display trailing whitespace in code
;; I want trailing whitespaces displayed when I am in programming mode.
(add-hook 'prog-mode-hook (lambda ()
                            (setq show-trailing-whitespace t)))

;; Line Numbers for coding
;; When coding I  want to have my line number displayed on every line.
(add-hook 'prog-mode-hook '(lambda () (linum-mode)))

;; visual bells
(setq ring-bell-function 'ignore)
(setq visible-bell t)

;; Clean up

;; Get rid of the annoying menubars, toolbars, scrollbars, bells, and splash screens.
(menu-bar-mode -1)
(if (boundp 'tool-bar-mode)
    (tool-bar-mode 0))
(if (fboundp 'scroll-bar-mode)
    (scroll-bar-mode 0))
(setq ring-bell-function 'ignore)
(setq inhibit-splash-screen t)

;; I use popwin mode to make sure that temporary buffers act as pop-up windows and can be closed with <C-g>.
(require 'popwin)
(popwin-mode 1)

;; Splitting Windows

(require 'switch-window)
(global-set-key (kbd "C-x o") 'switch-window)
(global-set-key (kbd "C-x 1") 'switch-window-then-maximize)
(global-set-key (kbd "C-x 2") 'switch-window-then-split-below)
(global-set-key (kbd "C-x 3") 'switch-window-then-split-right)
(global-set-key (kbd "C-x 0") 'switch-window-then-delete)

(setq switch-window-qwerty-shortcuts
      '("a" "s" "d" "f" "j" "k" "l" ";" "w" "e" "i" "o"))

;; Config
(require 'perspective)
(require 'projectile)

;; Enable perspective mode
(persp-mode t)

;; Projectile
(projectile-global-mode)
(projectile-mode)

(setq projectile-completion-system 'helm)
(helm-projectile-on)
(setq projectile-keymap-prefix (kbd "C-c p"))


;; ;;..fix link.. [[http://www.wickeddutch.com/2014/01/03/gaining-some-perspective-in-emacs/][Mostly taken from Wicked Dutch]]
;; Setup perspectives, or workspaces, to switch between
;; Enable perspective mode

;; (with-eval-after-load "persp-mode-autoloads"
;;   (setq wg-morph-on nil)
;;   ;; switch off the animation of restoring window configuration
;;   (add-hook 'after-init-hook #'(lambda () (persp-mode 1))))

(setq persp-keymap-prefix (kbd "C-x x"))

;; loading code for our custom perspectives
;; taken from Magnar Sveen
(defmacro custom-persp (name &rest body)
  `(let ((initialize (not (gethash ,name perspectives-hash)))
         (current-perspective persp-curr))
     (persp-switch ,name)
     (when initialize ,@body)
     (setq persp-last current-perspective)))

;; Jump to last perspective
;; taken from Magnar Sveen
(defun custom-persp-last ()
  (interactive)
  (persp-switch (persp-name persp-last)))

;; Easily switch to your last perspective
(define-key persp-mode-map (kbd "C-x p -") 'custom-persp-last)

;; org-agenda persp
(defun custom-persp/org-agenda ()
  (interactive)
  (custom-persp "org"))
(define-key persp-mode-map (kbd "C-x p o") 'custom-persp/org-agenda)

(defun custom-persp/org-agenda-start ()
  (interactive)
  (custom-persp "org")
  (delete-other-windows) ;Delete all windows in this perspective.
  (org-agenda nil "tw"))
(define-key persp-mode-map (kbd "C-x p O") 'custom-persp/org-agenda-start)


;; Init
(defun custom-persp/start-init ()
  (interactive)
  (custom-persp "init")
  (find-file (file-truename "~/.dotfiles/configs/emacs/emacs.org")))
(defun custom-persp/init ()
  (interactive)
  (custom-persp "init"))
(define-key persp-mode-map (kbd "C-x p I") 'custom-persp/start-init)
(define-key persp-mode-map (kbd "C-x p i") 'custom-persp/init)


;; Projectile
; (require 'helm-projectile)
(use-package helm-projectile
  :config
  (projectile-global-mode)
  (setq projectile-completion-system 'helm)
  (helm-projectile-on))

;; ;;..fix link.. [[https://github.com/bbatsov/projectile/blob/master/persp-projectile.el][Persp-Projectile]] allows me to push projects into new perspectives. This makes it far easier for me to switch between tasks.
;; (global-set-key (kbd "C-x p p") 'projectile-persp-switch-project)
(use-package persp-projectile
  :bind ("C-x p p" . projectile-persp-switch-project))




;; Themes
;; I keep my themes in a separate themes directory in my .emacs.d folder.
;; (add-to-list 'custom-theme-load-path (in-emacs-d "themes"))

;; Load my current theme.
(load-theme 'tango-dark t)

;; Colors
(require 'rainbow-mode)
(add-to-list 'find-file-hook
             (lambda () (unless (derived-mode-p 'web-mode) (rainbow-mode))))

;; File Management
(message "Initializing file management")

;; Cleanup

;; I use these files for cleaning buffers when I save, or get annoyed by red highlighted spaces everywhere.

;; Save a file without any of my automated buffer cleanup occurring
(defun save-buffer-without-cleanup ()
  (interactive)
  (let ((b (current-buffer)))   ; memorize the buffer
    (with-temp-buffer ; new temp buffer to bind the global value of before-save-hook
      (let ((before-save-hook (remove 'file-management/cleanup-buffer-safe before-save-hook)))
        (with-current-buffer b  ; go back to the current buffer, before-save-hook is now buffer-local
          (let ((before-save-hook (remove 'file-management/cleanup-buffer-safe before-save-hook)))
            (save-buffer)))))))

(defun file-management/cleanup-buffer-safe ()
  "Perform a bunch of safe operations on the whitespace content of a buffer.
Does not indent buffer, because it is used for a before-save-hook, and that
might be bad."
  (interactive)
  (if (not (or (string= major-mode 'makefile-gmake-mode)
               (string= major-mode 'makefile-mode)))
      (untabify (point-min) (point-max)))
  (delete-trailing-whitespace)
  (set-buffer-file-coding-system 'utf-8))

(defun file-management/cleanup-buffer ()
  "Perform a bunch of operations on the whitespace content of a buffer.
Including indent-buffer, which should not be called automatically on save."
  (interactive)
  (file-management/cleanup-buffer-safe)
  (indent-region (point-min) (point-max)))
(global-set-key (kbd "C-c n") 'file-management/cleanup-buffer)


;; Add the hook.
(add-hook 'before-save-hook 'file-management/cleanup-buffer-safe)

;; When files change on disk I want the buffers to change to match them.
;; I will modify text files in bash while they are open in emacs when I need to do more automated modification.
(global-auto-revert-mode 1)

;; Identification
;; uniquify shows a files location when it shares the same name as another file.
(require 'uniquify)
(setq
  uniquify-buffer-name-style 'post-forward
  uniquify-separator ":")





;; Backups
;; I use close to the basic backup setup described in the [[http://emacswiki.org/emacs/BackupDirectory][emacswiki.]]

;;(setq temporary-file-directory "/tmp/")
(setq
 backup-by-copying t      ; don't clobber symlinks
 backup-directory-alist
 `((".*" . ,temporary-file-directory))
 auto-save-file-name-transforms
 `((".*" ,temporary-file-directory t))
 kept-new-versions 6
 kept-old-versions 2
 version-control t)       ; use versioned backups


;; Automatically purge backup files not accessed in a week:
(message "Deleting old backup files...")
(let ((week (* 60 60 24 7))
      (current (float-time (current-time))))
  (dolist (file (directory-files temporary-file-directory t))
    (when (and (backup-file-name-p file)
               (> (- current (float-time (fifth (file-attributes file))))
                  week))
      (message "%s" file)
      (delete-file file))))

;; Help
(message "Initializing help")

;; Spell Checking
;; I use flyspell mode for spell checking for any text files.
(add-hook 'org-mode-hook 'turn-on-flyspell 'append)
(add-hook 'message-mode-hook 'turn-on-flyspell 'append)
(add-hook 'tex-mode-hook 'turn-on-flyspell 'append)

;; Define path for synonyms code and thesaurus
;(setq synonyms-file        "~/.emacs.d/resources/thesaurus/mthesaur.txt")
;(setq synonyms-cache-file  "~/.emacs.d/cache/thesaurus.txt")
;(require 'synonyms)

;; Writegood mode
;; helps me write-good.

(require 'writegood-mode)
(define-key personal-global-map (kbd "ww") 'writegood-mode)
(define-key personal-global-map (kbd "wl") 'writegood-grade-level)
(define-key personal-global-map (kbd "we") 'writegood-reading-ease)

;; Guide Key
;; ;;..fix link.. [[https://github.com/kai2nenobu/guide-key][guide-key.el]] displays the available key bindings automatically and dynamically. guide-key aims to be an alternative of one-key.el.
(require 'guide-key)
(setq guide-key/guide-key-sequence t)
(guide-key-mode 1)
(setq guide-key/idle-delay .5)
(setq guide-key/popup-window-position 'bottom)

;; Emacs Guru Mode
;  [[https://github.com/bbatsov/guru-mode][Guru mode]] disables some common keybindings and suggests the use of the established Emacs alternatives instead.
(require 'guru-mode)


;; Currently running this globally. I may want to change this if I get too annoyed.
(guru-global-mode +1)
;;(add-hook 'prog-mode-hook 'guru-mode)


;; I only want to get warnings when I use the arrow keys.
(setq guru-warn-only t)

;; Undo Help
;; Undo tree makes complex undo actions easy
(require 'undo-tree)
(global-undo-tree-mode t)

;; Keep region when undoing in region
;; Make it so the region does not keep jumping about when I use it.
;; Via" [[http://whattheemacsd.com/my-misc.el-02.html][what the emacs.d]]
(defadvice undo-tree-undo (around keep-region activate)
  (if (use-region-p)
      (let ((m (set-marker (make-marker) (mark)))
            (p (set-marker (make-marker) (point))))
        ad-do-it
        (goto-char p)
        (set-mark m)
        (set-marker p nil)
        (set-marker m nil))
    ad-do-it))


;; Yasnippet
(require 'yasnippet)
(yas/global-mode 1)
(setq yas/indent-line 'fixed) ; for indented snippets

;; Rebind yasnippet-expand to C-c tab. This is because the new version of yasnippet has a wrong fallback to the default <tab>, breaking Python's indentation cycling feature, and possibly other things too.
;;     - See:
;;        - https://github.com/fgallina/python.el/issues/123
;;        - https://github.com/capitaomorte/yasnippet/issues/332
(add-hook 'yas-minor-mode-hook
          '(lambda ()
             (define-key yas-minor-mode-map [(tab)] nil)
             (define-key yas-minor-mode-map (kbd "TAB") nil)
             (define-key yas-minor-mode-map  (kbd "<C-tab>") 'yas-expand-from-trigger-key)))


;; Navigation
(message "Initializing navigation")
;; In-File
;;   Movement and line based commands should operate on the lines that I see (even if they are using word wrap) by default.
(global-visual-line-mode t)

;; Smart beginning of the line
;; Move point to the first non-whitespace character on this line. If point was already at that position, move point to beginning of line.

;; Move to the beginning of the text
(defun smart-beginning-of-line ()
  "Move point to first non-whitespace character or beginning-of-line.

Move point to the first non-whitespace character on this line.
If point was already at that position, move point to beginning of line."
  (interactive) ; Use (interactive "^") in Emacs 23 to make shift-select work
  (let ((oldpos (point)))
    (back-to-indentation)
    (and (= oldpos (point))
         (beginning-of-line))))

(global-set-key (kbd "C-a") 'smart-beginning-of-line)

;; Move between symbols
;; - https://github.com/mickeynp/smart-scan
;; M-n and M-p move between symbols and type M-' to replace all symbols in the buffer matching the one under point, and C-u M-' to replace symbols in your current defun only (as used by narrow-to-defun.)
(smartscan-mode 1)
(global-set-key (kbd "M-n") 'smartscan-symbol-go-forward)
(global-set-key (kbd "M-p") 'smartscan-symbol-go-backward)
(global-set-key (kbd "M-'") 'smartscan-symbol-go-forward)

;; Helm
;; Use helm and turn the delay to nothing.
(use-package helm
  :init
  (progn
    (require 'helm-config)
    (setq helm-candidate-number-limit 100)
    ;; From https://gist.github.com/antifuchs/9238468
    (setq helm-idle-delay 0.0 ; update fast sources immediately (doesn't).
          helm-input-idle-delay 0.01  ; this actually updates things
                                        ; reeeelatively quickly.
          helm-quick-update t
          helm-M-x-requires-pattern nil
          helm-ff-skip-boring-files t)
    (helm-mode))
  :bind (("C-c h" . helm-mini)
         ("C-x y" . helm-show-kill-ring)
         ("M-x" . helm-M-x)
         ("C-x b" . helm-buffers-list)
         ("C-x C-f" . helm-find-files)
         ("M-i" . helm-semantic-or-imenu)))

;; Helm swoop is amazing! I use it far more than search, but I am still afraid to replace search with it.
(use-package helm-swoop
  :bind ("C-c C-M-s" . helm-swoop))

;; In current window/frame
;;
;; ace jump mode major function
;;
(add-to-list 'load-path "/full/path/where/ace-jump-mode.el/in/")
(autoload
  'ace-jump-mode
  "ace-jump-mode"
  "Emacs quick move minor mode"
  t)
;; you can select the key you prefer to
(define-key global-map (kbd "C-c SPC") 'ace-jump-mode)


;;
;; enable a more powerful jump back function from ace jump mode
;;
(autoload
  'ace-jump-mode-pop-mark
  "ace-jump-mode"
  "Ace jump back:-)"
  t)
(eval-after-load "ace-jump-mode"
  '(ace-jump-mode-enable-mark-sync))
(define-key global-map (kbd "C-x SPC") 'ace-jump-mode-pop-mark)


;; Add ability to move single lines
(defmacro save-column (&rest body)
  `(let ((column (current-column)))
     (unwind-protect
         (progn ,@body)
       (move-to-column column))))
(put 'save-column 'lisp-indent-function 0)

(defun move-line-up ()
  (interactive)
  (save-column
    (transpose-lines 1)
    (forward-line -2)))

(defun move-line-down ()
  (interactive)
  (save-column
    (forward-line 1)
    (transpose-lines 1)
    (forward-line -1)))

(global-set-key (kbd "M-<up>") 'move-line-up)
(global-set-key (kbd "M-<down>") 'move-line-down)

;; Org-Mode
(message "Initializing org mode")

(require 'org)

;; Files to activate org for
;; Open org-mode for .org files and for .org.gpg files.
;; Read [[http://ergoemacs.org/emacs/emacs_auto-activate_a_major-mode.html][this]] for how to format these strings. Then go and buy his book. It is the same content, but it is really good content and should be supported.
;; Ends with ".org"
(add-to-list 'auto-mode-alist
             '("\\.org\\'" . org-mode))

;; Auto Save
;;  Set auto-save for org mode files every hour, on the hour.
(run-at-time "00:59" 3600 'org-save-all-org-buffers)

;; Capture
;; Capture Mode
(setq org-default-notes-file "~/.org/todo/to_file.org")
(global-set-key (kbd "C-c c") 'org-capture)

;; Refile
;; Targets include this file and any file contributing to the agenda - up to 3 levels deep
(setq org-refile-targets (quote ((nil :maxlevel . 4)
                                 (org-agenda-files :maxlevel . 4))))

;; Allow refile to create parent tasks with confirmation
(setq org-refile-allow-creating-parent-nodes (quote confirm))

;; Targets complete in steps so we start with filename, TAB shows the next level of targets etc
(setq org-outline-path-complete-in-steps t)

;; Dont give me DONE tasks as targets for refiling
(defun org-init/verify-refile-target ()
  "Exclude todo keywords with a done state from refile targets"
  (not (member (nth 2 (org-heading-components)) org-done-keywords)))
(setq org-refile-target-verify-function 'org-init/verify-refile-target)

;; Display
;; Font-lock-mode will colorize/fontify text as I type it.
;; This is great for showing TODO items immediately as I type them out.
(global-font-lock-mode 1)

;; Also fold plain lists within major list items.
(setq org-cycle-include-plain-lists t)

;; Bullets Mode
(require 'org-bullets)
(add-hook 'org-mode-hook (lambda () (org-bullets-mode 1)))


;; Tasks & Events
;; TODO
  (add-to-list 'org-todo-keywords
               '(sequence "TODO(t!)" "ACTIVE(a!)" "WAIT(w/!)" "|" "DONE(d!)" "SOMEDAY(s!)" "CANCELED(C!)" "FAILED(f!)"))
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
        `(("t" "Create TODO" entry (file "~/.org/tasks.org")
            ,org-project-task-template-todo :clock-in t :clock-resume t)))
(setq org-capture-templates (append org-capture-templates
        `(("e" "Create EVENT" entry (file "~/.org/tasks.org")
            ,org-project-task-template-event :clock-in t :clock-resume t))))

;; Keybindings for Agenda Mode
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cb" 'org-iswitchb)

;; Agenda Files
;; TODO add back in "~/.org/work/library/"
(setq org-agenda-files (quote ("~/.org/todo"
                               "~/.org/personal/")))

;; Basic Settings
;;Start with the agenda log ON
(setq org-agenda-show-log t)

;; Set the agenda to skip scheduled items if they are done
(setq org-agenda-skip-scheduled-if-done t)

;; Set the agenda to skip deadlines if they are done
(setq org-agenda-skip-deadline-if-done t)

;; Agenda todo item configuration

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

;;Set time grid ON for day
(setq org-agenda-use-time-grid t)

;; Set time grid times (show always on day even if no tasks set.)
(setq org-agenda-time-grid
      '((daily today)
       "----------------"
       (600 800 1000 1200 1400 1600 1800 2000)))

;; Custom clock faces

;; The following custom-set-faces create the highlights
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(mode-line-buffer-id ((t (:foreground "black" :bold t))))
 '(org-block ((t (:background "#000000"))))
 '(org-block-background ((t (:background "#000000"))))
 '(org-block-begin-line ((t (:foreground "#008ED1" :background "#002E41"))) t)
 '(org-block-end-line ((t (:foreground "#008ED1" :background "#002E41"))) t)
 '(org-mode-line-clock ((t (:background "grey75" :foreground "red" :box (:line-width -1 :style released-button)))) t)
 '(which-func ((t (:foreground "green")))))

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

(defun org-archive-subtree-by-state (state-regex)
  (interactive "P")
  (save-excursion
    ;; Go to the start of the buffer no matter where we are
    (goto-char (point-min))
    ;; TODO map entries (only first level headers)
    ;; TODO if subtree make sure they are all done as well
    ;; TODO if not completed then move on to the next one
    ;; NOTE: All top level headers will have to be major project deliverables and meetings
    ;; NOTE: This is going to require a massive refactor on project files
    ;; NOTE: This will be diffficult for github issues
  ))

(defun org-archive-subtree-done (state-regex)
  (interactive "P")
  )

(defun org-my-archive-done-tasks ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((done-regexp
           (concat "\\* \\(" (regexp-opt org-done-keywords) "\\) "))
          (state-regexp
           (concat "- State \"\\(" (regexp-opt org-done-keywords)
                   "\\)\"\\s-*from \"[A-Za-z]+\"\\s-*\\[\\([^]\n]+\\)\\]")))
      (while (re-search-forward done-regexp nil t)
        (let ((end (save-excursion
                     (outline-next-heading)
                     (point)))
              begin)
          (goto-char (line-beginning-position))
          (setq begin (point))
          (when (re-search-forward state-regexp end t)
            (let* ((time-string (match-string 2))
                   (when-closed (org-parse-time-string time-string)))
              (if (>= (time-to-number-of-days
                       (time-subtract (current-time)
                                      (apply #'encode-time when-closed)))
                      org-my-archive-expiry-days)
                  (org-archive-subtree)
                ))))))))

(defalias 'archive-done-tasks 'org-my-archive-done-tasks)

(defun org-get-project-time ()
    (interactive) ;; Add a variable here to pull use tag to refine
    ;; tag_name
    (org-agenda nil "a")
    (org-agenda-filter-by-tag "\\")
    ;;(org-agenda-filter-by-tag tag_name &optional CHAR EXCLUDE)
    ;;(org-agenda-filter-by-tag-refine ARG &optional CHAR)
    (org-agenda-month-view)
    (org-agenda-log-mode t)
    ;;(org-agenda-earlier)
)

;; Don't allow me to edit invisible text
(setq org-catch-invisible-edits 'error)

;; Allow sub-tasks to block tasks above it.
;; I actually really hate this. But it forces me to address tasks below an item to identify old TODO's I will never do.
(setq org-enforce-todo-dependencies t)

;; Security
;; I use gpg encryption to secure my org-notes

(require 'epa-file)
(epa-file-enable)

(require 'org-crypt)
(org-crypt-use-before-save-magic)
(setq org-tags-exclude-from-inheritance (quote ("crypt")))

;; Linking
(global-set-key "\C-cl" 'org-store-link)

;; Link to custom ID, not to file location
(setq org-id-link-to-org-use-id 'create-if-interactive-and-no-custom-id)

;; Bookmarks with firefox
;; ;; http://orgmode.org/worg/org-contrib/org-protocol.html
(require 'org-protocol)

;; Replace a selected link with the archive version if available
(defun internet-archive-replace-link ()
  (interactive)
  (shell-command-on-region
   (point-min) (point-max)
   "xargs -I % python ~/.emacs.d/bin/wb.py %" t))

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

(defvar bh/organization-task-id "NONE")
(defun bh/is-task-p ()
  "Any task with a todo keyword and no subtask"
  (save-restriction
    (widen)
    (let ((has-subtask)
          (subtree-end (save-excursion (org-end-of-subtree t)))
          (is-a-task (member (nth 2 (org-heading-components)) org-todo-keywords-1)))
      (save-excursion
        (forward-line 1)
        (while (and (not has-subtask)
                    (< (point) subtree-end)
                    (re-search-forward "^\*+ " subtree-end t))
          (when (member (org-get-todo-state) org-todo-keywords-1)
            (setq has-subtask t))))
      (and is-a-task (not has-subtask)))))

(defun bh/is-project-p ()
  "Any task with a todo keyword subtask"
  (save-restriction
    (widen)
    (let ((has-subtask)
          (subtree-end (save-excursion (org-end-of-subtree t)))
          (is-a-task (member (nth 2 (org-heading-components)) org-todo-keywords-1)))
      (save-excursion
        (forward-line 1)
        (while (and (not has-subtask)
                    (< (point) subtree-end)
                    (re-search-forward "^\*+ " subtree-end t))
          (when (member (org-get-todo-state) org-todo-keywords-1)
            (setq has-subtask t))))
      (and is-a-task has-subtask))))


(defun bh/find-project-task ()
  "Move point to the parent (project) task if any"
  (save-restriction
    (widen)
    (let ((parent-task (save-excursion (org-back-to-heading 'invisible-ok) (point))))
      (while (org-up-heading-safe)
        (when (member (nth 2 (org-heading-components)) org-todo-keywords-1)
          (setq parent-task (point))))
      (goto-char parent-task)
      parent-task)))

;; Set acceptable languages (whatever I want Babel, whatever I want.)
(org-babel-do-load-languages
 'org-babel-load-languages
'((sh               . t)
  (js                . t)
  (emacs-lisp . t)
  (ditaa           . t)
  (gnuplot    . t)
  (C          . t)
  (latex     . t)
  (makefile   . t)
  (sql        . t)
  (sqlite     . t)
  (scala      . t)
  (org        . t)
  (python     . t)
  (dot        . t)
  (css        . t)))

;; Make code-blocks pretty
(setq org-src-tab-acts-natively t)
(setq org-src-fontify-natively t)

(defun org-src-color-blocks-light ()
  "Colors the block headers and footers to make them stand out more for lighter themes"
  (interactive)
  (custom-set-faces
   '(org-block-begin-line
    ((t (:underline "#A7A6AA" :foreground "#008ED1" :background "#EAEAFF"))))
   '(org-block-background
     ((t (:background "#FFFFEA"))))
   '(org-block
     ((t (:background "#FFFFEA"))))
   '(org-block-end-line
     ((t (:overline "#A7A6AA" :foreground "#008ED1" :background "#EAEAFF"))))

   '(mode-line-buffer-id ((t (:foreground "#005000" :bold t))))
   '(which-func ((t (:foreground "#008000"))))))

(defun org-src-color-blocks-dark ()
  "Colors the block headers and footers to make them stand out more for dark themes"
  (interactive)
  (custom-set-faces
   '(org-block-begin-line
     ((t (:foreground "#008ED1" :background "#002E41"))))
   '(org-block-background
     ((t (:background "#000000"))))
   '(org-block
     ((t (:background "#000000"))))
   '(org-block-end-line
     ((t (:foreground "#008ED1" :background "#002E41"))))

   '(mode-line-buffer-id ((t (:foreground "black" :bold t))))
   '(which-func ((t (:foreground "green"))))))

(org-src-color-blocks-dark)



;; Fix Drawers
(defun org-repair-property-drawers ()
  "Fix properties drawers in current buffer.
 Ignore non Org buffers."
  (when (eq major-mode 'org-mode)
    (org-with-wide-buffer
     (goto-char (point-min))
     (let ((case-fold-search t)
           (inline-re (and (featurep 'org-inlinetask)
                           (concat (org-inlinetask-outline-regexp)
                                   "END[ \t]*$"))))
       (org-map-entries
        (lambda ()
          (unless (and inline-re (org-looking-at-p inline-re))
            (save-excursion
              (let ((end (save-excursion (outline-next-heading) (point))))
                (forward-line)
                (when (org-looking-at-p org-planning-line-re) (forward-line))
                (when (and (< (point) end)
                           (not (org-looking-at-p org-property-drawer-re))
                           (save-excursion
                             (and (re-search-forward org-property-drawer-re end t)
                                  (eq (org-element-type
                                       (save-match-data (org-element-at-point)))
                                      'drawer))))
                  (insert (delete-and-extract-region
                           (match-beginning 0)
                           (min (1+ (match-end 0)) end)))
                  (unless (bolp) (insert "\n"))))))))))))

;; Snippets
(defun stuohy-paste-from-pdf-with-extra-spaces ()
  "When a PDF copy and paste adds extra lines into pasted text this will paste into a new buffer, merge the text, put the merged text in your kill ring, and then paste it into the buffer you were in."
  (interactive)
  (with-temp-buffer
    (yank)
    (beginning-of-buffer)
    (while (search-forward "

" nil t) (replace-match ""))
    (kill-new (buffer-string))
    )
  (yank))
(define-key personal-global-map (kbd "p") 'stuohy-paste-from-pdf-with-extra-spaces)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (markdown-mode+ markdown-mode ace-jump-mode graphviz-dot-mode php-refactor-mode php-mode org-bullets helm-swoop yasnippet yaml-mode writegood-mode wrap-region web-mode web-beautify use-package undo-tree switch-window solarized-theme smartscan rainbow-mode powershell persp-projectile logview json-mode js3-mode js2-mode highlight-indentation helm-projectile helm-flycheck helm-dash helm-ag guru-mode guide-key drag-stuff))))

;; Forensics & Data Cleaning

;; This is for decoding a single safe-link from microsoft exchange in a buffer
(fset 'decode_microsoft_safe_link_in_buffer
   [escape ?< ?\C-  ?\C-s ?? ?u ?r ?l ?= return ?\C-d ?\C-s ?& ?d ?a ?t ?a ?= return ?\C-b ?\C-b ?\C-b ?\C-b ?\C-b ?\C-b ?\C-  escape ?> ?\C-d ?\C-  escape ?< ?\M-x ?u ?n ?h ?e ?x ?- ?r ?e ?g ?i ?o ?n return])

;; This is for cleaning URLS that were suspended using "The great suspender" extension to only contain the actual current url
(fset 'clean_great_suspended_url
   [?\C-s ?c ?h ?r ?o ?m ?e ?- ?e ?x ?t ?e ?n ?s ?i ?o ?n ?: ?/ ?/ return ?\C-a ?\C-  ?\C-s ?u ?r ?i ?= return ?\C-d])
(put 'downcase-region 'disabled nil)


(fset 'convert_clipboard_to_underscored
   [escape ?< ?\C-  escape ?> ?\C-d ?\C-y nil ?\C-a ?\M-x ?r ?e ?p ?l ?a ?c ?e ?- ?s ?t ?r ?i ?n ?g return ?  return ?_ return ?\C-a ?\C-  ?\C-e ?\C-w])


(setq web-mode-html-entities
  '(("quot" . 34)
     ("amp" . 38)
     ("apos" . 39)
     ("lt" . 60)
     ("gt" . 62)
     ("nbsp" . 160)
     ("iexcl" . 161)
     ("cent" . 162)
     ("pound" . 163)
     ("curren" . 164)
     ("yen" . 165)
     ("brvbar" . 166)
     ("sect" . 167)
     ("uml" . 168)
     ("copy" . 169)
     ("ordf" . 170)
     ("laquo" . 171)
     ("not" . 172)
     ("shy" . 173)
     ("reg" . 174)
     ("macr" . 175)
     ("deg" . 176)
     ("plusmn" . 177)
     ("sup2" . 178)
     ("sup3" . 179)
     ("acute" . 180)
     ("micro" . 181)
     ("para" . 182)
     ("middot" . 183)
     ("cedil" . 184)
     ("sup1" . 185)
     ("ordm" . 186)
     ("raquo" . 187)
     ("frac14" . 188)
     ("frac12" . 189)
     ("frac34" . 190)
     ("iquest" . 191)
     ("Agrave" . 192)
     ("Aacute" . 193)
     ("Acirc" . 194)
     ("Atilde" . 195)
     ("Auml" . 196)
     ("Aring" . 197)
     ("AElig" . 198)
     ("Ccedil" . 199)
     ("Egrave" . 200)
     ("Eacute" . 201)
     ("Ecirc" . 202)
     ("Euml" . 203)
     ("Igrave" . 204)
     ("Iacute" . 205)
     ("Icirc" . 206)
     ("Iuml" . 207)
     ("ETH" . 208)
     ("Ntilde" . 209)
     ("Ograve" . 210)
     ("Oacute" . 211)
     ("Ocirc" . 212)
     ("Otilde" . 213)
     ("Ouml" . 214)
     ("times" . 215)
     ("Oslash" . 216)
     ("Ugrave" . 217)
     ("Uacute" . 218)
     ("Ucirc" . 219)
     ("Uuml" . 220)
     ("Yacute" . 221)
     ("THORN" . 222)
     ("szlig" . 223)
     ("agrave" . 224)
     ("aacute" . 225)
     ("acirc" . 226)
     ("atilde" . 227)
     ("auml" . 228)
     ("aring" . 229)
     ("aelig" . 230)
     ("ccedil" . 231)
     ("egrave" . 232)
     ("eacute" . 233)
     ("ecirc" . 234)
     ("euml" . 235)
     ("igrave" . 236)
     ("iacute" . 237)
     ("icirc" . 238)
     ("iuml" . 239)
     ("eth" . 240)
     ("ntilde" . 241)
     ("ograve" . 242)
     ("oacute" . 243)
     ("ocirc" . 244)
     ("otilde" . 245)
     ("ouml" . 246)
     ("divide" . 247)
     ("oslash" . 248)
     ("Ugrave" . 249)
     ("Uacute" . 250)
     ("Ucirc" . 251)
     ("Uuml" . 252)
     ("yacute" . 253)
     ("thorn" . 254)
     ("yuml" . 255)
     ("OElig" . 338)
     ("oelig" . 339)
     ("Scaron" . 352)
     ("scaron" . 353)
     ("Yuml" . 376)
     ("fnof" . 402)
     ("circ" . 710)
     ("tilde" . 732)
     ("Alpha" . 913)
     ("Beta" . 914)
     ("Gamma" . 915)
     ("Delta" . 916)
     ("Epsilon" . 917)
     ("Zeta" . 918)
     ("Eta" . 919)
     ("Theta" . 920)
     ("Iota" . 921)
     ("Kappa" . 922)
     ("Lambda" . 923)
     ("Mu" . 924)
     ("Nu" . 925)
     ("Xi" . 926)
     ("Omicron" . 927)
     ("Pi" . 928)
     ("Rho" . 929)
     ("Sigma" . 931)
     ("Tau" . 932)
     ("Upsilon" . 933)
     ("Phi" . 934)
     ("Chi" . 935)
     ("Psi" . 936)
     ("Omega" . 937)
     ("alpha" . 945)
     ("beta" . 946)
     ("gamma" . 947)
     ("delta" . 948)
     ("epsilon" . 949)
     ("zeta" . 950)
     ("eta" . 951)
     ("theta" . 952)
     ("iota" . 953)
     ("kappa" . 954)
     ("lambda" . 955)
     ("mu" . 956)
     ("nu" . 957)
     ("xi" . 958)
     ("omicron" . 959)
     ("pi" . 960)
     ("rho" . 961)
     ("sigmaf" . 962)
     ("sigma" . 963)
     ("tau" . 964)
     ("upsilon" . 965)
     ("phi" . 966)
     ("chi" . 967)
     ("psi" . 968)
     ("omega" . 969)
     ("thetasym" . 977)
     ("Upsih" . 978)
     ("piv" . 982)
     ("ensp" . 8194)
     ("emsp" . 8195)
     ("thinsp" . 8201)
     ("zwnj" . 8204)
     ("zwj" . 8205)
     ("lrm" . 8206)
     ("rlm" . 8207)
     ("ndash" . 8211)
     ("mdash" . 8212)
     ("lsquo" . 8216)
     ("rsquo" . 8217)
     ("sbquo" . 8218)
     ("ldquo" . 8220)
     ("rdquo" . 8221)
     ("bdquo" . 8222)
     ("dagger" . 8224)
     ("Dagger" . 8225)
     ("bull" . 8226)
     ("hellip" . 8230)
     ("permil" . 8240)
     ("prime" . 8242)
     ("Prime" . 8243)
     ("lsaquo" . 8249)
     ("rsaquo" . 8250)
     ("oline" . 8254)
     ("frasl" . 8260)
     ("euro" . 8364)
     ("image" . 8465)
     ("weierp" . 8472)
     ("real" . 8476)
     ("trade" . 8482)
     ("alefsym" . 8501)
     ("larr" . 8592)
     ("uarr" . 8593)
     ("rarr" . 8594)
     ("darr" . 8595)
     ("harr" . 8596)
     ("crarr" . 8629)
     ("lArr" . 8656)
     ("UArr" . 8657)
     ("rArr" . 8658)
     ("dArr" . 8659)
     ("hArr" . 8660)
     ("forall" . 8704)
     ("part" . 8706)
     ("exist" . 8707)
     ("empty" . 8709)
     ("nabla" . 8711)
     ("isin" . 8712)
     ("notin" . 8713)
     ("ni" . 8715)
     ("prod" . 8719)
     ("sum" . 8721)
     ("minus" . 8722)
     ("lowast" . 8727)
     ("radic" . 8730)
     ("prop" . 8733)
     ("infin" . 8734)
     ("ang" . 8736)
     ("and" . 8743)
     ("or" . 8744)
     ("cap" . 8745)
     ("cup" . 8746)
     ("int" . 8747)
     ("there4" . 8756)
     ("sim" . 8764)
     ("cong" . 8773)
     ("asymp" . 8776)
     ("ne" . 8800)
     ("equiv" . 8801)
     ("le" . 8804)
     ("ge" . 8805)
     ("sub" . 8834)
     ("sup" . 8835)
     ("nsub" . 8836)
     ("sube" . 8838)
     ("supe" . 8839)
     ("oplus" . 8853)
     ("otimes" . 8855)
     ("perp" . 8869)
     ("sdot" . 8901)
     ("lceil" . 8968)
     ("rceil" . 8969)
     ("lfloor" . 8970)
     ("rfloor" . 8971)
     ("lang" . 9001)
     ("rang" . 9002)
     ("loz" . 9674)
     ("spades" . 9824)
     ("clubs" . 9827)
     ("hearts" . 9829)
     ("diams" . 9830)))



(defun my-replace-symbols-with-html-entity-names (start end)
  (interactive "r")
  (let ((count (count-matches "&")))
    (replace-string "&" "&amp;" nil start end)
    (setq end (+ end (* count 4))))
  (dolist (pair web-mode-html-entities)
    (unless (= (cdr pair) 38)
      (let* ((str (char-to-string (cdr pair)))
              (count (count-matches str start end)))
        (setq end (+ end (* count (1+ (length (car pair))))))
        (replace-string str
          (concat "&" (car pair) ";")
          nil start end)))))
(put 'upcase-region 'disabled nil)

(defun title-to-filename (title)
  "Convert a copied document title into a filename"
  (interactive "sEnter document title: ")
  (let (working_string replacements)
    (message title)
    ;; replace all whitespace with single space (includes newlines)
    (setq replacements "[\t\n ]+")
    (setq working_string (replace-regexp-in-string replacements " " title))
    ;;(message "1:%s" working_string)
    ;; replace all seperators with dashes
    (setq replacements "[:;,_]")
    (setq working_string (replace-regexp-in-string replacements "-" working_string))
    ;;(message "2:%s" working_string)
    ;; replace all dashes with alphanum string (hack because ^ doesn't see groups)
    (setq replacements "-")
    (setq working_string (replace-regexp-in-string replacements "8675309" working_string))
    ;;(message "3:%s" working_string)
    ;; clear all other punctuation
    (setq replacements "[[:punct:]]")
    (setq working_string (replace-regexp-in-string replacements "" working_string))
    ;;(message "4:%s" working_string)
    ;; reverse above hack
    (setq replacements "8675309")
    (setq working_string (replace-regexp-in-string replacements "-" working_string))
    ;;(message "5:%s" working_string)
    ;; replace all " - " with "-" to clean extra space
    (setq replacements "[ ]*-[ ]*")
    (setq working_string (replace-regexp-in-string replacements "-" working_string))
    ;;(message "6:%s" working_string)
    ;; clean up duplicate -
    (setq replacements "-+")
    (setq working_string (replace-regexp-in-string replacements "-" working_string))
    ;;(message "6:%s" working_string)
    ;; clear first and last char if string
    (setq replacements "^ ")
    (setq working_string (replace-regexp-in-string replacements "" working_string))
    (setq replacements " $")
    (setq working_string (replace-regexp-in-string replacements "" working_string))
    ;;(message "6:%s" working_string)
    ;; replace all spaces with underscores
    (setq replacements " ")
    (setq working_string (replace-regexp-in-string replacements "_" working_string))
    ;;(message "7:%s" working_string)
    ;; clean up text case
    (setq working_string (upcase-initials (downcase working_string)))
    (kill-new working_string)
  ))
