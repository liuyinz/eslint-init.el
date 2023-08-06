;;; eslint-init.el --- Initializing eslint environment -*- lexical-binding: t -*-

;; Copyright (C) 2023 liuyinz

;; Author: liuyinz <liuyinz95@gmail.com>
;; Maintainer: liuyinz <liuyinz95@gmail.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1"))
;; Keywords: convenience
;; Homepage: https://github.com/liuyinz/eslint-init

;; This file is not a part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; SEE https://github.com/AlloyTeam/eslint-config-alloy/blob/master/README.zh-CN.md

;;; Code:

(require 'seq)
(require 'cl-lib)

(defgroup eslint-init nil
  "Initializing eslint environment."
  :group 'eslint-init)

(defcustom eslint-init-configs
  '("alloy_builtin"
    "alloy_react"
    "alloy_vue"
    "alloy_typescript"
    "alloy_typescript_vue"
    "alloy_typescript_react")
  ""
  :type '(repeat string)
  :group 'eslint-init)

;; TODO user-define first
(defcustom eslint-init-extra-paths nil
  ""
  :type '(repeat string)
  :group 'eslint-init)

(defvar eslint-init--log "*eslint-init-log*" "")

(defvar eslint-init--eslintrc-regexp
  "\\`\\(\\.eslintrc\\(\\.\\(c?js\\|ya?ml\\|json\\)\\)?\\|eslint\\.config\\.js\\)\\'"
  "")

(defvar eslint-init--prettierrc-regexp
  "\\`\\(\\.prettierrc\\(\\.\\([mc]?js\\|ya?ml\\|json5?\\|toml\\)\\)?\\|prettier\\.config\\.[mc]?js\\)\\'" "")

;; (defvar eslint-init--map
;;   '((eslint
;;      :regexp "\\`\\.eslintrc\\(\\.\\(js\\|ya?ml\\|json\\)\\)?\\'"
;;      :des 'eslint-init--eslint)
;;     (prettier))
;;   "docstring")

(defvar eslint-init--list
  '(("alloy_builtin"
     :save-dev "eslint @babel/core @babel/eslint-parser eslint-config-alloy"
     :eslintrc "alloy_builtin.js"
     :prettierrc "alloy_prettierrc.js")
    ("alloy_react"
     :save-dev "eslint @babel/core @babel/eslint-parser @babel/preset-react@latest \
eslint-plugin-react eslint-config-alloy"
     :eslintrc "alloy_react.js"
     :prettierrc "alloy_prettierrc.js")
    ("alloy_vue"
     :save-dev "eslint @babel/core @babel/eslint-parser vue-eslint-parser \
eslint-plugin-vue eslint-config-alloy"
     :eslintrc "alloy_vue.js"
     :prettierrc "alloy_prettierrc.js")
    ("alloy_typescript"
     :save-dev "eslint typescript @typescript-eslint/parser \
@typescript-eslint/eslint-plugin eslint-config-alloy"
     :eslintrc "alloy_typescript.js"
     :prettierrc "alloy_prettierrc.js")
    ("alloy_typescript_react"
     :save-dev "eslint typescript @typescript-eslint/parser \
@typescript-eslint/eslint-plugin eslint-plugin-react eslint-config-alloy"
     :eslintrc "alloy_typescript_react.js"
     :prettierrc "alloy_prettierrc.js")
    ("alloy_typescript_vue"
     :save-dev "@babel/core @babel/eslint-parser @typescript-eslint/eslint-plugin \
@typescript-eslint/parser @vue/eslint-config-typescript eslint eslint-config-alloy \
eslint-plugin-vue vue-eslint-parser"
     :eslintrc "alloy_typescript_vue.js"
     :prettierrc "alloy_prettierrc.js"))
  "")

(defun eslint-init--call-process (args)
  "docstring"

  )


(defun eslint-init--get-prop (config prop)
  "docstring"
  (if-let ((plist (cdr (seq-find (lambda (x) (equal (car x) config))
                                 eslint-init--list))))
      (plist-get plist prop)))

;; TODO completing-read support
(defun eslint-init--project-root ()
  "docstring"
  (when buffer-file-name
    (or (cl-some (apply-partially #'locate-dominating-file buffer-file-name)
                 '(".git" "node_modules" ".eslintignore" "package.json"))
        (file-name-directory buffer-file-name))))

(defun eslint-init--get-plist (config)
  "docstring"
  (cdr (seq-find (lambda (x) (equal (car x) config))
                 eslint-init--list)))

(defun eslint-init--get-src (rc-name)
  "docstring"
  (locate-file rc-name
               (append eslint-init-extra-paths
                       (list (expand-file-name "eslintrc/"
                                               (file-name-directory
                                                (locate-library
                                                 "eslint-init"))))) nil nil))

(defun eslint-init--get-des-name (rc-name type)
  "docstring"
  (let* ((name (symbol-name type))
         (ext (file-name-extension rc-name))
         (rc-end (string-match-p "\\..+rc\\'" rc-name))
         (config-include (string-match-p "\\.config\\." rc-name)))
    (cond
     (rc-end (concat "." ext))
     (config-include (concat name ".config." ext))
     (t (concat "." name "rc." ext)))))

(defun eslint-init--copy-rc (rc type)
  "docstring"
  (let* ((default-directory (eslint-init--project-root)))
    (when-let ((existed-rc (directory-files
                            default-directory t
                            (if (equal type 'eslint)
                                eslint-init--eslintrc-regexp
                              eslint-init--prettierrc-regexp))))
      (mapc (lambda(str) (rename-file str (concat str ".bak") t)) existed-rc))
    (copy-file rc (concat default-directory (eslint-init--get-des-name rc type)))))

;; check whether already setup
(defun eslint-init--configured (&optional directory)
  "docstring"
  nil)


(defun eslint-init (&optional config)
  "docstring"
  (interactive)
  (let ((legal-configs (cl-intersection
                        eslint-init-configs
                        (mapcar #'car eslint-init--list)
                        :test #'string-equal)))
    (when (and config (not (memq config legal-configs)))
      (error "eslint-init: Config %s doesn't exist." config))
    (or config
        (setq config (completing-read "Select eslint conifg from: "
                                      legal-configs
                                      nil t nil))))
  (let* ((plist (eslint-init--get-plist config))
         (prettierrc (plist-get plist :prettierrc))
         (eslintrc (plist-get plist :eslintrc))
         (save-dev (concat (plist-get plist :save-dev) (and prettierrc " prettier"))))
    (if (equal eslint-init-current-config config)
        (message "already eslint setup.")
      (let ((default-directory (eslint-init--project-root)))
        (shell-command
         (concat "npm install --save-dev" save-dev)
         eslint-init--log)
        (eslint-init--copy-rc (eslint-init--get-src eslintrc) 'eslint)
        (eslint-init--copy-rc (eslint-init--get-src prettierrc) 'prettier)
        (add-dir-local-variable nil eslint-init-current-config config)))))

(provide 'eslint-init)
;;; eslint-init.el ends here
