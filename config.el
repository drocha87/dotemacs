
(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("melpa" . "http://melpa.org/packages/")
                         ("org" . "http://orgmode.org/elpa/")))

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(use-package delight :ensure t)
(use-package use-package-ensure-system-package :ensure t)

(setq-default
 ad-redefinition-action 'accept             ; Silence warnings for redefinition
 cursor-in-non-selected-windows t           ; Hide the cursor in inactive windows
 display-time-default-load-average nil      ; Don't display load average
 fill-column 80                             ; Set width for automatic line breaks
 help-window-select t                       ; Focus new help windows when opened
 indent-tabs-mode nil                       ; Prefers spaces over tabs
 inhibit-startup-screen t                   ; Disable start-up screen
 initial-scratch-message ""                 ; Empty the initial *scratch* buffer
 kill-ring-max 128                          ; Maximum length of kill ring
 load-prefer-newer t                        ; Prefers the newest version of a file
 mark-ring-max 128                          ; Maximum length of mark ring
 read-process-output-max (* 1024 1024)      ; Increase the amount of data reads from the process
 scroll-conservatively most-positive-fixnum ; Always scroll by one line
 select-enable-clipboard t                  ; Merge system's and Emacs' clipboard
 tab-width 4                                ; Set width for tabs
 use-package-always-ensure t                ; Avoid the :ensure keyword for each package
 user-full-name "Diego Rocha"               ; Set the full name of the current user
 user-mail-address "dlmrocha87@gmail.com"   ; Set the email address of the current user
 vc-follow-symlinks t                       ; Always follow the symlinks
 view-read-only t)                          ; Always open read-only buffers in view-mode
(delete-selection-mode 1)                   ; Always override selection
(cd "~/")                                   ; Move to the user directory
(column-number-mode 1)                      ; Show the column number
(display-time-mode 1)                       ; Enable time in the mode-line
(fset 'yes-or-no-p 'y-or-n-p)               ; Replace yes/no prompts with y/n
(global-hl-line-mode)                       ; Hightlight current line
(set-default-coding-systems 'utf-8)         ; Default to utf-8 encoding
(show-paren-mode 1)                         ; Show the parent

(setq ring-bell-function 'ignore)
(setq visible-bell nil)

;; I'm used to ctrl-z undo stuff
(use-package emacs
  :bind (("C-z" . undo)
         ("C-x C-z" . undo)
         ("C-h h" . nil)))

(defvar xdg-bin (getenv "XDG_BIN_HOME")
  "The XDG bin base directory.")

(defvar xdg-cache (getenv "XDG_CACHE_HOME")
  "The XDG cache base directory.")

(defvar xdg-config (getenv "XDG_CONFIG_HOME")
  "The XDG config base directory.")

(defvar xdg-data (getenv "XDG_DATA_HOME")
  "The XDG data base directory.")

(defvar xdg-lib (getenv "XDG_LIB_HOME")
  "The XDG lib base directory.")

(setq-default
 auto-save-list-file-name (expand-file-name (format "%s/emacs/auto-save-list" xdg-data))
 custom-file (expand-file-name (format "%s/emacs/custom.el" xdg-data)))
(when (file-exists-p custom-file)
  (load custom-file t))

(set-face-attribute 'default nil :font "Monospace 11")

(use-package lsp-mode
  ;; :hook ((web-mode c-mode c++-mode dart-mode java-mode json-mode python-mode
  ;;                  typescript-mode xml-mode) . lsp)
  :hook ((web-mode c-mode c++-mode dart-mode java-mode json-mode python-mode xml-mode) . lsp)
  :custom
  ;; (lsp-clients-typescript-server-args '("--stdio" "--tsserver-log-file" "/dev/stderr"))
  (lsp-enable-folding nil)
  (lsp-enable-links nil)
  (lsp-enable-snippet nil)
  (lsp-prefer-flymake nil)
  (lsp-session-file (expand-file-name (format "%s/emacs/lsp-session-v1" xdg-data)))
  (lsp-restart 'auto-restart))

(use-package lsp-ui)

(use-package dap-mode
  :after lsp-mode
  :config
  (dap-mode t)
  (dap-ui-mode t))

(use-package doom-themes
  :config (load-theme 'doom-nord-light t))

(use-package doom-modeline
  :defer 0.1
  :config (doom-modeline-mode))

(use-package fancy-battery
  :after doom-modeline
  :hook (after-init . fancy-battery-mode))

(use-package solaire-mode
  :custom (solaire-mode-remap-fringe t)
  :config
  (solaire-mode-swap-bg)
  (solaire-global-mode +1))

(when window-system
  (menu-bar-mode -1)              ; Disable the menu bar
  (scroll-bar-mode -1)            ; Disable the scroll bar
  (tool-bar-mode -1)              ; Disable the tool bar
  (tooltip-mode -1))              ; Disable the tooltips

(use-package ccls
  :after projectile
  :ensure-system-package ccls
  :custom
  (ccls-args nil)
  (ccls-executable (executable-find "ccls"))
  (projectile-project-root-files-top-down-recurring
   (append '("compile_commands.json" ".ccls")
           projectile-project-root-files-top-down-recurring))
  :config (add-to-list 'projectile-globally-ignored-directories ".ccls-cache"))

(use-package google-c-style
  :hook ((c-mode c++-mode) . google-set-c-style)
         (c-mode-common . google-make-newline-indent))

(use-package cmake-mode
  :mode ("CMakeLists\\.txt\\'" "\\.cmake\\'"))

(use-package cmake-font-lock
  :after (cmake-mode)
  :hook (cmake-mode . cmake-font-lock-activate))

(use-package cmake-ide
  :after projectile
  :hook (c++-mode . my/cmake-ide-find-project)
  :preface
  (defun my/cmake-ide-find-project ()
    "Finds the directory of the project for cmake-ide."
    (with-eval-after-load 'projectile
      (setq cmake-ide-project-dir (projectile-project-root))
      (setq cmake-ide-build-dir (concat cmake-ide-project-dir "build")))
    (setq cmake-ide-compile-command
          (concat "cd " cmake-ide-build-dir " && cmake .. && make"))
    (cmake-ide-load-db))

  (defun my/switch-to-compilation-window ()
    "Switches to the *compilation* buffer after compilation."
    (other-window 1))
  :bind ([remap comment-region] . cmake-ide-compile)
  :init (cmake-ide-setup)
  :config (advice-add 'cmake-ide-compile :after #'my/switch-to-compilation-window))

(use-package css-mode
  :custom (css-indent-offset 2))

(use-package less-css-mode
  :mode "\\.less\\'")

(use-package scss-mode
  :mode "\\.scss\\'")

(use-package csv-mode)

(use-package dockerfile-mode
  :delight "δ "
  :mode "Dockerfile\\'")

(use-package elisp-mode :ensure nil :delight "ξ ")

(use-package eldoc
  :delight
  :hook (emacs-lisp-mode . eldoc-mode))

(use-package emmet-mode
  :delight
  :hook (css-mode sgml-mode web-mode))

(use-package ini-mode
  :defer 0.4
  :mode ("\\.ini\\'"))

(use-package prettier-js
  :delight
  :custom (prettier-js-args '("--print-width" "100"
                              "--single-quote" "true"
                              "--trailing-comma" "all")))

(use-package js2-mode
  :hook ((js2-mode . js2-imenu-extras-mode)
         (js2-mode . prettier-js-mode))
  :mode "\\.js\\'"
  :custom (js-indent-level 2))

(use-package js2-refactor
  :bind (:map js2-mode-map
              ("C-k" . js2r-kill)
              ("M-." . nil))
  :hook ((js2-mode . js2-refactor-mode)
         (js2-mode . (lambda ()
                       (add-hook 'xref-backend-functions #'xref-js2-xref-backend nil t))))
  :config (js2r-add-keybindings-with-prefix "C-c C-r"))

(use-package xref-js2 :defer 5)

(use-package json-mode
  :delight "J "
  :mode "\\.json\\'"
  :hook (before-save . my/json-mode-before-save-hook)
  :preface
  (defun my/json-mode-before-save-hook ()
    (when (eq major-mode 'json-mode)
      (json-pretty-print-buffer)))

  (defun my/json-array-of-numbers-on-one-line (encode array)
    "Prints the arrays of numbers in one line."
    (let* ((json-encoding-pretty-print
            (and json-encoding-pretty-print
                 (not (loop for x across array always (numberp x)))))
           (json-encoding-separator (if json-encoding-pretty-print "," ", ")))
      (funcall encode array)))
  :config (advice-add 'json-encode-array :around #'my/json-array-of-numbers-on-one-line))

(use-package blacken
  :delight
  :hook (python-mode . blacken-mode)
  :custom (blacken-line-length 79))

(use-package lsp-pyright
  :if (executable-find "pyright")
  :hook (python-mode . (lambda ()
                         (require 'lsp-pyright)
                         (lsp))))

(use-package lsp-python-ms
  :defer 0.3
  :custom (lsp-python-ms-auto-install-server t))

(use-package python
  :delight "π "
  :bind (("M-[" . python-nav-backward-block)
         ("M-]" . python-nav-forward-block))
  :preface
  (defun python-remove-unused-imports()
    "Removes unused imports and unused variables with autoflake."
    (interactive)
    (if (executable-find "autoflake")
        (progn
          (shell-command (format "autoflake --remove-all-unused-imports -i %s"
                                 (shell-quote-argument (buffer-file-name))))
          (revert-buffer t t t))
      (warn "python-mode: Cannot find autoflake executable."))))

(use-package py-isort
  :after python
  :hook ((python-mode . pyvenv-mode)
         (before-save . py-isort-before-save)))

(use-package pyenv-mode
  :after python
  :hook ((python-mode . pyenv-mode)
         (projectile-switch-project . projectile-pyenv-mode-set))
  :custom (pyenv-mode-set "3.8.5")
  :preface
  (defun projectile-pyenv-mode-set ()
    "Set pyenv version matching project name."
    (let ((project (projectile-project-name)))
      (if (member project (pyenv-mode-versions))
          (pyenv-mode-set project)
        (pyenv-mode-unset)))))

(use-package pyvenv
  :after python
  :hook ((python-mode . pyvenv-mode)
         (python-mode . (lambda ()
                          (if-let ((pyvenv-directory (find-pyvenv-directory (buffer-file-name))))
                              (pyvenv-activate pyvenv-directory))
                          (lsp))))
  :custom
  (pyvenv-default-virtual-env-name "env")
  (pyvenv-mode-line-indicator '(pyvenv-virtual-env-name ("[venv:"
                                                         pyvenv-virtual-env-name "]")))
  :preface
  (defun find-pyvenv-directory (path)
    "Checks if a pyvenv directory exists."
    (cond
     ((not path) nil)
     ((file-regular-p path) (find-pyvenv-directory (file-name-directory path)))
     ((file-directory-p path)
      (or
       (seq-find
        (lambda (path) (file-regular-p (expand-file-name "pyvenv.cfg" path)))
        (directory-files path t))
       (let ((parent (file-name-directory (directory-file-name path))))
         (unless (equal parent path) (find-pyvenv-directory parent))))))))

;;(use-package sh-script
;;  :ensure nil
;;  :hook (after-save . executable-make-buffer-file-executable-if-script-p))

(use-package sql-indent
  :after (:any sql sql-interactive-mode)
  :delight sql-mode "Σ ")

(use-package typescript-mode
  :mode ("\\.ts\\'" "\\.tsx\\'")
  ;; :hook (typescript-mode . prettier-js-mode)
  :custom

  (add-hook 'typescript-mode-hook #'(lambda ()
                                      (enable-minor-mode
                                       '("\\.tsx?\\'" . prettier-js-mode)))))

(setq-default typescript-indent-level 2)

(defun setup-tide-mode ()
  "Setup tide mode."
  (interactive)
  (tide-setup)
  (flycheck-mode +1)
  (setq flycheck-check-syntax-automatically '(save mode-enabled))
  (eldoc-mode +1)
  (tide-hl-identifier-mode +1)
  ;; company is an optional dependency. You have to
  ;; install it separately via package-install
  ;; `M-x package-install [ret] company`
  (company-mode +1)
  (setq typescript-indent-level 2)
  (setq tide-always-show-documentation t)
  (setq tide-jump-to-definition-reuse-window t)
  (add-hook 'before-save-hook 'tide-format-before-save))

;;; Typescript tide integration
(use-package tide
  :ensure t
  :after (typescript-mode company flycheck))

(add-hook 'typescript-mode-hook #'setup-tide-mode)

(global-set-key (kbd "C-.") 'tide-fix)
(global-set-key (kbd "M-.") 'tide-jump-to-definition)



(use-package yaml-mode
  :delight "ψ "
  :mode "\\.yml\\'"
  :interpreter ("yml" . yml-mode))

;;(use-package alert
;;  :defer 1
;;  :custom (alert-default-style 'libnotify))

(use-package company
  :defer 0.5
  :delight
  :custom
  (company-begin-commands '(self-insert-command))
  (company-idle-delay 0)
  (company-minimum-prefix-length 2)
  (company-show-numbers t)
  (company-tooltip-align-annotations 't)
  (global-company-mode t))

(use-package company-box
  :after company
  :delight
  :hook (company-mode . company-box-mode))

;; (use-package files
;;   :ensure nil
;;   :preface
;;   (defvar *afilename-cmd*
;;     `((,(format "%s/X11/Xresources" xdg-config) . ,(format "xrdb -merge %s/X11/Xresources" xdg-config))
;;       (,(format "%s/xbindkeysrc" (getenv "HOME")) . "xbindkeys -p"))
;;     "File association list with their respective command.")

;;   (defun my/cmd-after-saved-file ()
;;     "Execute a command after saved a specific file."
;;     (let* ((match (assoc (buffer-file-name) *afilename-cmd*)))
;;       (when match
;;         (shell-command (cdr match)))))
;;   :hook (after-save . my/cmd-after-saved-file)
;;   :custom
;;   (backup-directory-alist `(("." . ,(expand-file-name (format "%s/emacs/backups/" xdg-data)))))
;;   (delete-old-versions -1)
;;   (vc-make-backup-files t)
;;   (version-control t))

(use-package ibuffer
  :bind ("C-x C-b" . ibuffer))

(use-package ibuffer-projectile
  :after ibuffer
  :preface
  (defun my/ibuffer-projectile ()
    (ibuffer-projectile-set-filter-groups)
    (unless (eq ibuffer-sorting-mode 'alphabetic)
      (ibuffer-do-sort-by-alphabetic)))
  :hook (ibuffer . my/ibuffer-projectile))

;;(defvar *protected-buffers* '("*scratch*" "*Messages*")
;;  "Buffers that cannot be killed.")
;;
;;(defun my/protected-buffers ()
;;  "Protects some buffers from being killed."
;;  (dolist (buffer *protected-buffers*)
;;    (with-current-buffer buffer
;;      (emacs-lock-mode 'kill))))
;;
;;(add-hook 'after-init-hook #'my/protected-buffers)

;;(use-package dashboard
;;  :if (< (length command-line-args) 2)
;;  :preface
;;  (defun dashboard-load-packages (list-size)
;;    (insert (make-string (ceiling (max 0 (- dashboard-banner-length 38)) 5) ? )
;;            (format "%d packages loaded in %s" (length package-activated-list) (emacs-init-time))))
;;  :custom
;;  (dashboard-banner-logo-title "With Great Power Comes Great Responsibility")
;;  (dashboard-center-content t)
;;  (dashboard-items '((packages)
;;                     (agenda)
;;                     (projects . 5)))
;;  (dashboard-set-file-icons t)
;;  (dashboard-set-heading-icons t)
;;  (dashboard-set-init-info nil)
;;  (dashboard-set-navigator t)
;;  (dashboard-startup-banner 'logo)
;;  :config
;;  (add-to-list 'dashboard-item-generators '(packages . dashboard-load-packages))
;;  (dashboard-setup-startup-hook))

(use-package dired
  :ensure nil
  :delight "Dired "
  :custom
  (dired-auto-revert-buffer t)
  (dired-dwim-target t)
  (dired-hide-details-hide-symlink-targets nil)
  (dired-listing-switches "-alh")
  (dired-ls-F-marks-symlinks nil)
  (dired-recursive-copies 'always))

(use-package dired-narrow
  :bind (("C-c C-n" . dired-narrow)
         ("C-c C-f" . dired-narrow-fuzzy)
         ("C-c C-r" . dired-narrow-regexp)))

(use-package dired-subtree
  :bind (:map dired-mode-map
              ("<backtab>" . dired-subtree-cycle)
              ("<tab>" . dired-subtree-toggle)))

(use-package editorconfig
  :defer 0.3
  :config (editorconfig-mode 1))

(use-package async)

;;(use-package nov
;;  :mode ("\\.epub\\'" . nov-mode)
;;  :custom (nov-text-width 75))

(use-package abbrev
  :ensure nil
  :delight
  :hook (text-mode . abbrev-mode)
  :custom (abbrev-file-name (expand-file-name (format "%s/emacs/abbrev_defs" xdg-data)))
  :config
  (if (file-exists-p abbrev-file-name)
      (quietly-read-abbrev-file)))

(use-package flyspell
  :delight
  :hook ((markdown-mode org-mode text-mode) . flyspell-mode)
         (prog-mode . flyspell-prog-mode)
  :custom
  (flyspell-abbrev-p t)
  (flyspell-default-dictionary "en_US")
  (flyspell-issue-message-flag nil)
  (flyspell-issue-welcome-flag nil))

(use-package flyspell-correct-ivy
  :after (flyspell ivy)
  :init (setq flyspell-correct-interface #'flyspell-correct-ivy))

(use-package ispell
  :defer 2
  :ensure-system-package (hunspell . "yay -S hunspell")
  :custom
  ;; to remove
  (ispell-local-dictionary "en_US")
  (ispell-local-dictionary-alist
   '(("en_US" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "en_US") nil utf-8)))

  (ispell-dictionary "en_US")
  (ispell-dictionary-alist
   '(("en_US" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "en_US") nil utf-8)))
  (ispell-program-name (executable-find "hunspell"))
  (ispell-really-hunspell t)
  (ispell-silently-savep t))

(use-package langtool
  :defer 2
  :delight
  :custom
  (langtool-default-language "en")
  (langtool-disabled-rules '("COMMA_PARENTHESIS_WHITESPACE"
                             "COPYRIGHT"
                             "DASH_RULE"
                             "EN_QUOTES"
                             "EN_UNPAIRED_BRACKETS"
                             "UPPERCASE_SENTENCE_START"
                             "WHITESPACE_RULE"))
  (langtool-language-tool-jar (expand-file-name
                               (format "%s/LangueageTool-4.2/languagetool-commandline.jar" xdg-lib)))
  (langtool-language-tool-server-jar (expand-file-name
                                      (format "%s/LanguageTool-4.2/languagetool-server.jar" xdg-lib)))
  (langtool-mother-tongue "fr"))

(use-package savehist
  :ensure nil
  :custom
  (history-delete-duplicates t)
  (history-length t)
  (savehist-additional-variables '(kill-ring search-ring regexp-search-ring))
  (savehist-file (expand-file-name (format "%s/emacs/history" xdg-cache)))
  (savehist-save-minibuffer-history 1)
  :config (savehist-mode 1))

(use-package highlight-indent-guides
  :defer 0.3
  :hook (prog-mode . highlight-indent-guides-mode)
  :custom (highlight-indent-guides-method 'character))

(use-package hydra
  :bind (("C-c I" . hydra-image/body)
         ("C-c L" . hydra-ledger/body)
         ("C-c M" . hydra-merge/body)
         ("C-c T" . hydra-tool/body)
         ("C-c b" . hydra-btoggle/body)
         ("C-c c" . hydra-clock/body)
         ("C-c e" . hydra-erc/body)
         ("C-c f" . hydra-flycheck/body)
         ("C-c m" . hydra-magit/body)
         ("C-c o" . hydra-org/body)
         ("C-c p" . hydra-projectile/body)
         ("C-c q" . hydra-query/body)
         ("C-c s" . hydra-spelling/body)
         ("C-c t" . hydra-tex/body)
         ("C-c u" . hydra-upload/body)
         ("C-c w" . hydra-windows/body)))

(use-package major-mode-hydra
  :after hydra
  :preface
  (defun with-alltheicon (icon str &optional height v-adjust)
    "Displays an icon from all-the-icon."
    (s-concat (all-the-icons-alltheicon icon :v-adjust (or v-adjust 0) :height (or height 1)) " " str))

  (defun with-faicon (icon str &optional height v-adjust)
    "Displays an icon from Font Awesome icon."
    (s-concat (all-the-icons-faicon icon :v-adjust (or v-adjust 0) :height (or height 1)) " " str))

  (defun with-fileicon (icon str &optional height v-adjust)
    "Displays an icon from the Atom File Icons package."
    (s-concat (all-the-icons-fileicon icon :v-adjust (or v-adjust 0) :height (or height 1)) " " str))

  (defun with-octicon (icon str &optional height v-adjust)
    "Displays an icon from the GitHub Octicons."
    (s-concat (all-the-icons-octicon icon :v-adjust (or v-adjust 0) :height (or height 1)) " " str)))

(pretty-hydra-define hydra-btoggle
  (:hint nil :color amaranth :quit-key "q" :title (with-faicon "toggle-on" "Toggle" 1 -0.05))
  ("Basic"
   (("a" abbrev-mode "abbrev" :toggle t)
    ("h" global-hungry-delete-mode "hungry delete" :toggle t))
   "Coding"
   (("e" electric-operator-mode "electric operator" :toggle t)
    ("F" flyspell-mode "flyspell" :toggle t)
    ("f" flycheck-mode "flycheck" :toggle t)
    ("l" lsp-mode "lsp" :toggle t)
    ("s" smartparens-mode "smartparens" :toggle t))
   "UI"
   (("i" ivy-rich-mode "ivy-rich" :toggle t))))

(pretty-hydra-define hydra-flycheck
  (:hint nil :color teal :quit-key "q" :title (with-faicon "plane" "Flycheck" 1 -0.05))
  ("Checker"
   (("?" flycheck-describe-checker "describe")
    ("d" flycheck-disable-checker "disable")
    ("m" flycheck-mode "mode")
    ("s" flycheck-select-checker "select"))
   "Errors"
   (("<" flycheck-previous-error "previous" :color pink)
    (">" flycheck-next-error "next" :color pink)
    ("f" flycheck-buffer "check")
    ("l" flycheck-list-errors "list"))
   "Other"
   (("M" flycheck-manual "manual")
    ("v" flycheck-verify-setup "verify setup"))))

(pretty-hydra-define hydra-magit
  (:hint nil :color teal :quit-key "q" :title (with-alltheicon "git" "Magit" 1 -0.05))
  ("Action"
   (("b" magit-blame "blame")
    ("c" magit-clone "clone")
    ("i" magit-init "init")
    ("l" magit-log-buffer-file "commit log (current file)")
    ("L" magit-log-current "commit log (project)")
    ("s" magit-status "status"))))

(pretty-hydra-define hydra-org
  (:hint nil :color teal :quit-key "q" :title (with-fileicon "org" "Org" 1 -0.05))
  ("Action"
   (("A" my/org-archive-done-tasks "archive")
    ("a" org-agenda "agenda")
    ("c" org-capture "capture")
    ("d" org-decrypt-entry "decrypt")
    ("i" org-insert-link-global "insert-link")
    ("j" my/org-jump "jump-task")
    ("k" org-cut-subtree "cut-subtree")
    ("o" org-open-at-point-global "open-link")
    ("r" org-refile "refile")
    ("s" org-store-link "store-link")
    ("t" org-show-todo-tree "todo-tree"))))

(pretty-hydra-define hydra-projectile
  (:hint nil :color teal :quit-key "q" :title (with-faicon "rocket" "Projectile" 1 -0.05))
  ("Buffers"
   (("b" counsel-projectile-switch-to-buffer "list")
    ("k" projectile-kill-buffers "kill all")
    ("S" projectile-save-project-buffers "save all"))
   "Find"
   (("d" counsel-projectile-find-dir "directory")
    ("D" projectile-dired "root")
    ("f" counsel-projectile-find-file "file")
    ("p" counsel-projectile-switch-project "project"))
   "Other"
   (("i" projectile-invalidate-cache "reset cache"))
   "Search"
   (("r" projectile-replace "replace")
    ("R" projectile-replace-regexp "regexp replace")
    ("s" counsel-rg "search"))))

(pretty-hydra-define hydra-spelling
  (:hint nil :color teal :quit-key "q" :title (with-faicon "magic" "Spelling" 1 -0.05))
  ("Checker"
   (("c" langtool-correct-buffer "correction")
    ("C" langtool-check-done "clear")
    ("d" ispell-change-dictionary "dictionary")
    ("l" (message "Current language: %s (%s)" langtool-default-language ispell-current-dictionary) "language")
    ("w" wiki-summary "wiki"))
   "Errors"
   (("<" flyspell-correct-previous "previous" :color pink)
    (">" flyspell-correct-next "next" :color pink)
    ("f" langtool-check "find"))))


(defhydra hydra-typescript (:color blue)
  "
  ^
  ^TypeScript^          ^Do^
  ^──────────^──────────^──^───────────
  _q_ quit             _b_ back
  ^^                   _e_ errors
  ^^                   _j_ jump
  ^^                   _r_ references
  ^^                   _R_ restart
  ^^                   ^^
  "
  ("q" nil)
  ("b" tide-jump-back)
  ("e" tide-project-errors)
  ("j" tide-jump-to-definition)
  ("r" tide-references)
  ("R" tide-restart-server))

(pretty-hydra-define hydra-upload
  (:hint nil :color teal :quit-key "q" :title (with-faicon "cloud-upload" "Upload" 1 -0.05))
  ("Action"
   (("b" webpaste-paste-buffe "buffer")
    ("i" imgbb-upload "image")
    ("r" webpaste-paste-region "region"))))

(pretty-hydra-define hydra-windows
  (:hint nil :forein-keys warn :quit-key "q" :title (with-faicon "windows" "Windows" 1 -0.05))
  ("Window"
   (("b" balance-windows "balance")
    ("<up>" enlarge-window "heighten")
    ("<left>" shrink-window-horizontally "narrow")
    ("<down>" shrink-window "lower")
    ("<right>" enlarge-window-horizontally "widen")
    ("s" switch-window-then-swap-buffer "swap" :color teal))
   "Zoom"
   (("-" text-scale-decrease "out")
    ("+" text-scale-increase "in")
    ("=" (text-scale-increase 0) "reset"))))

(use-package aggressive-indent
  :hook ((css-mode . aggressive-indent-mode)
         (emacs-lisp-mode . aggressive-indent-mode)
         (js-mode . aggressive-indent-mode)
         (lisp-mode . aggressive-indent-mode))
  :custom (aggressive-indent-comments-too))

(use-package electric-operator
  :delight
  :hook (python-mode . electric-operator-mode))

(use-package move-text
  ;; I need to pay attention if this gonna conflict with other keybinds
  ;;  :bind (("M-p" . move-text-up)
  ;;         ("M-n" . move-text-down))
  :config (move-text-default-bindings))

;;(use-package paradox
;;  :defer 1
;;  :custom
;;  (paradox-column-width-package 27)
;;  (paradox-column-width-version 13)
;;  (paradox-execute-asynchronously t)
;;  (paradox-hide-wiki-packages t)
;;  :config
;;  (paradox-enable)
;;  (remove-hook 'paradox-after-execute-functions #'paradox--report-buffer-print))

(use-package rainbow-mode
  :delight
  :hook (prog-mode))

(use-package autorevert
  :ensure nil
  :delight auto-revert-mode
  :bind ("C-x R" . revert-buffer)
  :custom (auto-revert-verbose nil)
  :config (global-auto-revert-mode 1))

;; (use-package try :defer 5)

(use-package undo-tree
  :delight
  :bind ("C--" . undo-tree-redo)
  :init (global-undo-tree-mode)
  :custom
  (undo-tree-visualizer-timestamps t)
  (undo-tree-visualizer-diff t))

(use-package web-mode
  :delight "☸ "
  :hook ((css-mode web-mode) . rainbow-mode)
  :mode (("\\.blade\\.php\\'" . web-mode)
         ("\\.html?\\'" . web-mode)
         ("\\.jsx\\'" . web-mode)
         ("\\.vue\\'" . web-mode)
         ("\\.php$" . my/php-setup))
  :preface
  (defun enable-minor-mode (my-pair)
    "Enable minor mode if filename match the regexp."
    (if (buffer-file-name)
        (if (string-match (car my-pair) buffer-file-name)
            (funcall (cdr my-pair)))))
  ;; :custom
  ;; (web-mode-attr-indent-offset 2)
  ;; (web-mode-comment-style 2)
  ;; (web-mode-enable-current-element-highlight t)
  ;; (web-mode-block-padding 0)
  ;; (web-mode-style-padding 0)
  ;; (web-mode-script-padding 0)
  )


(add-hook 'web-mode-hook #'(lambda ()
                             (enable-minor-mode
                              '("\\.js?\\'" . prettier-js-mode))))

(add-hook 'web-mode-hook #'(lambda ()
                             (enable-minor-mode
                              '("\\.vue?\\'" . prettier-js-mode))))

;;(add-hook 'web-mode-hook #'(lambda ()
;;                             (enable-minor-mode
;;                              '("\\.jsx?\\'" . prettier-js-mode))))

(add-hook 'web-mode-hook #'(lambda ()
                             (enable-minor-mode
                              '("\\.ts?\\'" . prettier-js-mode))))

(defun my-web-mode-hook ()
  "Hooks for Web mode."
  (setq web-mode-code-indent-offset                   2)
  (setq web-mode-markup-indent-offset                 2)
  (setq web-mode-css-indent-offset                    2)
  (setq web-mode-block-padding                        0)
  (setq web-mode-style-padding                        0)
  (setq web-mode-script-padding                       0)
  (setq web-mode-enable-html-entities-fontification   nil)
  (setq web-mode-enable-block-face                    nil)
  (setq web-mode-enable-comment-annotation            nil)
  (setq web-mode-enable-comment-interpolation         nil)
  (setq web-mode-enable-control-block-indentation     nil)
  (setq web-mode-enable-css-colorization              nil)
  (setq web-mode-enable-current-column-highlight      nil)
  (setq web-mode-enable-current-element-highlight     nil)
  (setq web-mode-enable-element-content-fontification nil)
  (setq web-mode-enable-heredoc-fontification         nil)
  (setq web-mode-enable-inlays                        nil)
  (setq web-mode-enable-optional-tags                 nil)
  (setq web-mode-enable-part-face                     nil)
  (setq web-mode-enable-sexp-functions                nil)
  (setq web-mode-enable-sql-detection                 nil)
  (setq web-mode-enable-string-interpolation          nil)
  (setq web-mode-enable-whitespace-fontification      nil)
  (setq web-mode-enable-auto-expanding                nil)
  (setq web-mode-enable-auto-indentation              nil)
  (setq web-mode-enable-auto-closing                  nil)
  (setq web-mode-enable-auto-opening                  nil)
  (setq web-mode-enable-auto-pairing                  nil)
  (setq web-mode-enable-auto-quoting                  nil))
(add-hook 'web-mode-hook 'my-web-mode-hook)

(use-package which-key
  :defer 0.2
  :delight
  :config (which-key-mode))

(use-package wiki-summary
  :defer 1
  :preface
  (defun my/format-summary-in-buffer (summary)
    "Given a summary, sticks it in the *wiki-summary* buffer and displays
     the buffer."
    (let ((buf (generate-new-buffer "*wiki-summary*")))
      (with-current-buffer buf
        (princ summary buf)
        (fill-paragraph)
        (goto-char (point-min))
        (view-mode))
      (pop-to-buffer buf))))

(advice-add 'wiki-summary/format-summary-in-buffer :override #'my/format-summary-in-buffer)

(use-package all-the-icons
  :if (display-graphic-p)
  :config (unless (find-font (font-spec :name "all-the-icons"))
            (all-the-icons-install-fonts t)))

(use-package counsel
  :after ivy
  :delight
  :bind (("C-x C-d" . counsel-dired-jump)
         ("C-x C-h" . counsel-minibuffer-history)
         ("C-x C-l" . counsel-find-library)
         ("C-x C-r" . counsel-recentf)
         ("C-x C-u" . counsel-unicode-char)
         ("C-x C-v" . counsel-set-variable))
  :config (counsel-mode)
  :custom (counsel-rg-base-command "rg -S -M 150 --no-heading --line-number --color never %s"))

(use-package ivy
  :delight
  :after ivy-rich
  :bind (("C-x b" . ivy-switch-buffer)
         ("C-x B" . ivy-switch-buffer-other-window)
         ("M-H"   . ivy-resume)
         :map ivy-minibuffer-map
         ("<tab>" . ivy-alt-done)
         ("C-i" . ivy-partial-or-done)
         ("S-SPC" . nil)
         :map ivy-switch-buffer-map
         ("C-k" . ivy-switch-buffer-kill))
  :custom
  (ivy-case-fold-search-default t)
  (ivy-count-format "(%d/%d) ")
  (ivy-re-builders-alist '((t . ivy--regex-plus)))
  (ivy-use-virtual-buffers t)
  :config (ivy-mode))

;;(use-package ivy-pass
;;  :after ivy
;;  :commands ivy-pass)

(use-package ivy-rich
  :defer 0.1
  :preface
  (defun ivy-rich-branch-candidate (candidate)
    "Displays the branch candidate of the candidate for ivy-rich."
    (let ((candidate (expand-file-name candidate ivy--directory)))
      (if (or (not (file-exists-p candidate)) (file-remote-p candidate))
          ""
        (format "%s%s"
                (propertize
                 (replace-regexp-in-string abbreviated-home-dir "~/"
                                           (file-name-directory
                                            (directory-file-name candidate)))
                 'face 'font-lock-doc-face)
                (propertize
                 (file-name-nondirectory
                  (directory-file-name candidate))
                 'face 'success)))))

  (defun ivy-rich-compiling (candidate)
    "Displays compiling buffers of the candidate for ivy-rich."
    (let* ((candidate (expand-file-name candidate ivy--directory)))
      (if (or (not (file-exists-p candidate)) (file-remote-p candidate)
              (not (magit-git-repo-p candidate)))
          ""
        (if (my/projectile-compilation-buffers candidate)
            "compiling"
          ""))))

  (defun ivy-rich-file-group (candidate)
    "Displays the file group of the candidate for ivy-rich"
    (let ((candidate (expand-file-name candidate ivy--directory)))
      (if (or (not (file-exists-p candidate)) (file-remote-p candidate))
          ""
        (let* ((group-id (file-attribute-group-id (file-attributes candidate)))
               (group-function (if (fboundp #'group-name) #'group-name #'identity))
               (group-name (funcall group-function group-id)))
          (format "%s" group-name)))))

  (defun ivy-rich-file-modes (candidate)
    "Displays the file mode of the candidate for ivy-rich."
    (let ((candidate (expand-file-name candidate ivy--directory)))
      (if (or (not (file-exists-p candidate)) (file-remote-p candidate))
          ""
        (format "%s" (file-attribute-modes (file-attributes candidate))))))

  (defun ivy-rich-file-size (candidate)
    "Displays the file size of the candidate for ivy-rich."
    (let ((candidate (expand-file-name candidate ivy--directory)))
      (if (or (not (file-exists-p candidate)) (file-remote-p candidate))
          ""
        (let ((size (file-attribute-size (file-attributes candidate))))
          (cond
           ((> size 1000000) (format "%.1fM " (/ size 1000000.0)))
           ((> size 1000) (format "%.1fk " (/ size 1000.0)))
           (t (format "%d " size)))))))

  (defun ivy-rich-file-user (candidate)
    "Displays the file user of the candidate for ivy-rich."
    (let ((candidate (expand-file-name candidate ivy--directory)))
      (if (or (not (file-exists-p candidate)) (file-remote-p candidate))
          ""
        (let* ((user-id (file-attribute-user-id (file-attributes candidate)))
               (user-name (user-login-name user-id)))
          (format "%s" user-name)))))

  (defun ivy-rich-switch-buffer-icon (candidate)
    "Returns an icon for the candidate out of `all-the-icons'."
    (with-current-buffer
        (get-buffer candidate)
      (let ((icon (all-the-icons-icon-for-mode major-mode :height 0.9)))
        (if (symbolp icon)
            (all-the-icons-icon-for-mode 'fundamental-mode :height 0.9)
          icon))))
  :config
  (plist-put ivy-rich-display-transformers-list
             'counsel-find-file
             '(:columns
               ((ivy-rich-candidate               (:width 73))
                (ivy-rich-file-user               (:width 8 :face font-lock-doc-face))
                (ivy-rich-file-group              (:width 4 :face font-lock-doc-face))
                (ivy-rich-file-modes              (:width 11 :face font-lock-doc-face))
                (ivy-rich-file-size               (:width 7 :face font-lock-doc-face))
                (ivy-rich-file-last-modified-time (:width 30 :face font-lock-doc-face)))))
  (plist-put ivy-rich-display-transformers-list
             'counsel-projectile-switch-project
             '(:columns
               ((ivy-rich-branch-candidate        (:width 80))
                (ivy-rich-compiling))))
  (plist-put ivy-rich-display-transformers-list
             'ivy-switch-buffer
             '(:columns
               ((ivy-rich-switch-buffer-icon       (:width 2))
                (ivy-rich-candidate                (:width 40))
                (ivy-rich-switch-buffer-size       (:width 7))
                (ivy-rich-switch-buffer-indicators (:width 4 :face error :align right))
                (ivy-rich-switch-buffer-major-mode (:width 20 :face warning)))
               :predicate (lambda (cand) (get-buffer cand))))
  (ivy-rich-mode 1))

(use-package all-the-icons-ivy
  :after (all-the-icons ivy)
  :custom (all-the-icons-ivy-buffer-commands '(ivy-switch-buffer-other-window))
  :config
  (add-to-list 'all-the-icons-ivy-file-commands 'counsel-dired-jump)
  (add-to-list 'all-the-icons-ivy-file-commands 'counsel-find-library)
  (all-the-icons-ivy-setup))

(use-package swiper
  :after ivy
  :bind (("C-s" . swiper)
         :map swiper-map
         ("M-%" . swiper-query-replace)))

(use-package flycheck
  :defer 2
  :delight
  :init (global-flycheck-mode)
  :custom
  (flycheck-display-errors-delay .3)
  (flycheck-pylintrc "~/.pylintrc")
  (flycheck-python-pylint-executable "/usr/bin/pylint")
  (flycheck-stylelintrc "~/.stylelintrc.json")
  :config
  (flycheck-add-mode 'javascript-eslint 'web-mode)
  (flycheck-add-mode 'typescript-tslint 'web-mode))

(use-package lorem-ipsum
  :bind (("C-c C-v l" . lorem-ipsum-insert-list)
         ("C-c C-v p" . lorem-ipsum-insert-paragraphs)
         ("C-c C-v s" . lorem-ipsum-insert-sentences)))

(defun my/smarter-move-beginning-of-line (arg)
  "Moves point back to indentation of beginning of line.

   Move point to the first non-whitespace character on this line.
   If point is already there, move to the beginning of the line.
   Effectively toggle between the first non-whitespace character and
   the beginning of the line.

   If ARG is not nil or 1, move forward ARG - 1 lines first. If
   point reaches the beginning or end of the buffer, stop there."
  (interactive "^p")
  (setq arg (or arg 1))

  ;; Move lines first
  (when (/= arg 1)
    (let ((line-move-visual nil))
      (forward-line (1- arg))))

  (let ((orig-point (point)))
    (back-to-indentation)
    (when (= orig-point (point))
      (move-beginning-of-line 1))))

(global-set-key (kbd "C-a") 'my/smarter-move-beginning-of-line)

(use-package imenu
  :ensure nil
  :bind ("C-r" . imenu))

(use-package faces
  :ensure nil
  :custom (show-paren-delay 0)
  :config
  (set-face-background 'show-paren-match "#262b36")
  (set-face-bold 'show-paren-match t)
  (set-face-foreground 'show-paren-match "#ffffff"))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package smartparens
  :defer 1
  :delight
  :custom (sp-escape-quotes-after-insert nil)
  :config (smartparens-global-mode 1))

(use-package expand-region
  :bind (("C-+" . er/contract-region)
         ;; ("C-=" . er/expand-region)
         ;; basically I like to use <delete> to delete and not ctrl-d
         ("C-d" . er/expand-region)))

(defadvice kill-region (before slick-cut activate compile)
  "When called interactively with no active region, kill a single line instead."
  (interactive
   (if mark-active (list (region-beginning) (region-end))
     (list (line-beginning-position)
           (line-beginning-position 2)))))

(use-package projectile
  :defer 1
  :preface
  (defun my/projectile-compilation-buffers (&optional project)
    "Get a list of a project's compilation buffers.
  If PROJECT is not specified the command acts on the current project."
    (let* ((project-root (or project (projectile-project-root)))
           (buffer-list (mapcar #'process-buffer compilation-in-progress))
           (all-buffers (cl-remove-if-not
                         (lambda (buffer)
                           (projectile-project-buffer-p buffer project-root))
                         buffer-list)))
      (if projectile-buffers-filter-function
          (funcall projectile-buffers-filter-function all-buffers)
        all-buffers)))
  :custom
  (projectile-cache-file (expand-file-name (format "%s/emacs/projectile.cache" xdg-cache)))
  (projectile-completion-system 'ivy)
  (projectile-enable-caching t)
  (projectile-keymap-prefix (kbd "C-c C-p"))
  (projectile-known-projects-file (expand-file-name (format "%s/emacs/projectile-bookmarks.eld" xdg-cache)))
  (projectile-mode-line '(:eval (projectile-project-name)))
  :config (projectile-global-mode)
  :init
  (when (file-directory-p "~/devel")
    (setq projectile-project-search-path '("~/devel" "~/devel/euyome")))
  (setq projectile-switch-project-action #'projectile-dired))

(use-package counsel-projectile
  :after (counsel projectile)
  :config (counsel-projectile-mode 1))

;;(use-package recentf
;;  :bind ("C-c r" . recentf-open-files)
;;  :init (recentf-mode)
;;  :custom
;;  (recentf-exclude (list "COMMIT_EDITMSG"
;;                         "~$"
;;                         "/scp:"
;;                         "/ssh:"
;;                         "/sudo:"
;;                         "/tmp/"))
;;  (recentf-max-menu-items 15)
;;  (recentf-max-saved-items 200)
;;  (recentf-save-file (expand-file-name (format "%s/emacs/recentf" xdg-cache)))
;;  :config (run-at-time nil (* 5 60) 'recentf-save-list))

;;(use-package request
;;  :ensure nil
;;  :custom
;;  (request-storage-directory (expand-file-name (format "%s/emacs/request/" xdg-data))))

;;(use-package url-cookie
;;  :ensure nil
;;  :custom
;;  (url-cookie-file (expand-file-name (format "%s/emacs/url/cookies/" xdg-data))))

(use-package git-commit
  :after magit
  :hook (git-commit-mode . my/git-commit-auto-fill-everywhere)
  :custom (git-commit-summary-max-length 50)
  :preface
  (defun my/git-commit-auto-fill-everywhere ()
    "Ensures that the commit body does not exceed 72 characters."
    (setq fill-column 72)
    (setq-local comment-auto-fill-only-comments nil)))

(use-package magit :defer 0.3)

(use-package smerge-mode
  :after hydra
  :hook (magit-diff-visit-file . (lambda ()
                                   (when smerge-mode
                                     (hydra-merge/body)))))

(use-package git-gutter
  :defer 0.3
  :delight
  :init (global-git-gutter-mode +1))

(use-package git-timemachine
  :defer 1
  :delight)

(use-package simple
  :ensure nil
  :hook (before-save . delete-trailing-whitespace))

(defun drocha/backward-kill-word ()
  "Remove all whitespace if the character behind the cursor is whitespace, otherwise remove a word."
  (interactive)
  (cond ((looking-back " ") (delete-horizontal-space))
        ((looking-back "\n") (backward-delete-char 1))
        ((looking-back "_") (backward-delete-char 1))
        ((looking-back "[()#\"\-]") (backward-delete-char 1))
        (t (backward-kill-word 1))))

(global-set-key (kbd "C-<backspace>") 'drocha/backward-kill-word)

(defun drocha/forward-kill-word ()
  "Remove all whitespace if the character behind the cursor is whitespace, otherwise remove a word."
  (interactive)
  (setq drocha/delete-forward-whites-regex "[ \n]")
  (setq drocha/delete-forward-special-regex "[:;]")
  (cond ((looking-at drocha/delete-forward-whites-regex)
         (progn (while (looking-at drocha/delete-forward-whites-regex)
                  (delete-char 1))))
        ((looking-at drocha/delete-forward-special-chars-regex)
         (delete-char 1))
        (t (kill-word 1))))

(global-set-key (kbd "C-<delete>") 'drocha/forward-kill-word)

;; TODO: review this one
;; (use-package hungry-delete
;;   :defer 0.7
;;   :delight
;;   :config (global-hungry-delete-mode))

(global-set-key [remap kill-buffer] #'kill-this-buffer)

(use-package window
  :ensure nil
  :bind (("C-x 3" . hsplit-last-buffer)
         ("C-x 2" . vsplit-last-buffer))
  :preface
  (defun hsplit-last-buffer ()
    "Gives the focus to the last created horizontal window."
    (interactive)
    (split-window-horizontally)
    (other-window 1))

  (defun vsplit-last-buffer ()
    "Gives the focus to the last created vertical window."
    (interactive)
    (split-window-vertically)
    (other-window 1)))

(use-package switch-window
  :bind (("C-x o" . switch-window)
         ("C-x w" . switch-window-then-swap-buffer)))

(use-package windmove
  :bind (("C-c h" . windmove-left)
         ("C-c j" . windmove-down)
         ("C-c k" . windmove-up)
         ("C-c l" . windmove-right)))

(use-package winner
  :defer 2
  :config (winner-mode 1))

(use-package simple
  :ensure nil
  :delight (auto-fill-function)
  :bind ("C-x p" . pop-to-mark-command)
  :hook ((prog-mode . turn-on-auto-fill)
         (text-mode . turn-on-auto-fill))
  :custom (set-mark-command-repeat-pop t))

(use-package yasnippet-snippets
  :after yasnippet
  :config (yasnippet-snippets-initialize))

(use-package yasnippet
  :delight yas-minor-mode " υ"
  :hook (yas-minor-mode . my/disable-yas-if-no-snippets)
  :config (yas-global-mode)
  :preface
  (defun my/disable-yas-if-no-snippets ()
    (when (and yas-minor-mode (null (yas--get-snippet-tables)))
      (yas-minor-mode -1))))

(use-package ivy-yasnippet :after yasnippet)
(use-package react-snippets :after yasnippet)

;;(use-package org
;;  :ensure org-plus-contrib
;;  :delight "Θ "
;;  :bind ("C-c i" . org-insert-structure-template))
;;
;;(use-package org-bullets
;;  :hook (org-mode . org-bullets-mode)
;;  :custom
;;  (org-bullets-bullet-list '("●" "►" "▸")))

;; helm git grep
;; replace to counsel and ivy in future `https://oremacs.com/2015/04/19/git-grep-ivy/`
;; (use-package helm)
;; (use-package
;;   helm-git-grep)
;; (global-set-key (kbd "C-c g") 'helm-git-grep)
;; (define-key isearch-mode-map (kbd "C-c g") 'helm-git-grep-from-isearch)
;; (eval-after-load 'helm
;;   '(define-key helm-map (kbd "C-c g") 'helm-git-grep-from-helm))

;; Custom keybinds
(global-set-key (kbd "C-c g") 'counsel-rg)
(global-set-key (kbd "C-p") 'counsel-projectile-find-file)
;; Insert line below like vim o
(global-set-key (kbd "C-<return>") (kbd "C-e <return>"))
(global-set-key (kbd "C-<enter>") (kbd "C-e <return>"))
