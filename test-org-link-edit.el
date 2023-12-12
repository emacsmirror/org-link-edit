;;; test-org-link-edit.el --- Tests for org-link-edit.el  -*- lexical-binding: t; -*-

;; Copyright (C) 2015-2020 Kyle Meyer <kyle@kyleam.com>

;; Author:  Kyle Meyer <kyle@kyleam.com>

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

;;; Code:

(require 'org-link-edit)
(require 'ert)

;; This is taken from `org-tests.el' (55c0708).
(defmacro org-test-with-temp-text (text &rest body)
  "Run body in a temporary buffer with Org-mode as the active
mode holding TEXT.  If the string \"<point>\" appears in TEXT
then remove it and place the point there before running BODY,
otherwise place the point at the beginning of the inserted text."
  (declare (indent 1))
  `(let ((inside-text (if (stringp ,text) ,text (eval ,text)))
         (org-mode-hook nil))
     (with-temp-buffer
       (org-mode)
       (let ((point (string-match "<point>" inside-text)))
         (if point
             (progn
               (insert (replace-match "" nil nil inside-text))
               (goto-char (1+ (match-beginning 0))))
           (insert inside-text)
           (goto-char (point-min))))
       ,@body)))
(def-edebug-spec org-test-with-temp-text (form body))


;;; Slurping

(ert-deftest test-org-link-edit/forward-slurp ()
  "Test `org-link-edit-forward-slurp'."
  ;; Slurp one blob into plain link.
  (should
   (string=
    "\[\[https://orgmode.org/\]\[Org's\]\] website is"
    (org-test-with-temp-text
        "https://orgmode.org/ Org's website is"
      (org-link-edit-forward-slurp)
      (buffer-string))))
  ;; Slurp one blob into empty bracket link.
  (should
   (string=
    "\[\[https://orgmode.org/\]\[Org's\]\] website is"
    (org-test-with-temp-text
        "\[\[https://orgmode.org/\]\] Org's website is"
      (org-link-edit-forward-slurp)
      (buffer-string))))
  ;; Slurp one blob into bracket link.
  (should
   (string=
    "\[\[https://orgmode.org/\]\[Org's website\]\] is"
    (org-test-with-temp-text
        "\[\[https://orgmode.org/\]\[Org's\]\] website is"
      (org-link-edit-forward-slurp)
      (buffer-string))))
  ;; Slurp one blob, but not trailing punctuation, into bracket link.
  (should
   (string=
    "\[\[https://orgmode.org/\]\[Org's website\]\]."
    (org-test-with-temp-text
        "\[\[https://orgmode.org/\]\[Org's\]\] website."
      (org-link-edit-forward-slurp)
      (buffer-string))))
  ;; Slurp all-punctuation blob into bracket link.
  (should
   (string=
    "\[\[https://orgmode.org/\]\[Org's .?.?\]\]"
    (org-test-with-temp-text
        "\[\[https://orgmode.org/\]\[Org's\]\] .?.?"
      (org-link-edit-forward-slurp)
      (buffer-string))))
  ;; Slurping blob with point beyond link, but technically still
  ;; within link element.
  (should
   (string=
    "Org's \[\[https://orgmode.org/\]\[website  is\]\]"
    (org-test-with-temp-text
        "Org's \[\[https://orgmode.org/\]\[website\]\] <point> is"
      (org-link-edit-forward-slurp)
      (buffer-string))))
  ;; Slurp two blobs into plain link.
  (should
   (string=
    "\[\[https://orgmode.org/\]\[Org's website\]\] is"
    (org-test-with-temp-text
        "https://orgmode.org/ Org's website is"
      (org-link-edit-forward-slurp 2)
      (buffer-string))))
  ;; Slurp two blobs into bracket link.
  (should
   (string=
    "\[\[https://orgmode.org/\]\[Org's website is\]\]"
    (org-test-with-temp-text
        "\[\[https://orgmode.org/\]\[Org's\]\] website is"
      (org-link-edit-forward-slurp 2)
      (buffer-string))))
  ;; Slurp new line as space.
  (should
   (string=
    "\[\[https://orgmode.org/\]\[Org's website\]\] is"
    (org-test-with-temp-text
        "\[\[https://orgmode.org/\]\[Org's\]\]
website is"
      (org-link-edit-forward-slurp 1)
      (buffer-string))))
  ;; Collapse stretches of new lines.
  (should
   (string=
    "\[\[https://orgmode.org/\]\[Org's website is\]\]"
    (org-test-with-temp-text
        "\[\[https://orgmode.org/\]\[Org's\]\]
\n\nwebsite\n\n\nis"
      (org-link-edit-forward-slurp 2)
      (buffer-string))))
  ;; Slurp blob that has no whitespace.
  (should
   (string=
    "\[\[https://orgmode.org/\]\[website\]\]"
    (org-test-with-temp-text
        "\[\[https://orgmode.org/\]\]website"
      (org-link-edit-forward-slurp 1)
      (buffer-string))))
  ;; Slurp blob that isn't separated from link by whitespace.
  (should
   (string=
    "\[\[https://orgmode.org/\]\[-website\]\]"
    (org-test-with-temp-text
        "\[\[https://orgmode.org/\]\]-website"
      (org-link-edit-forward-slurp 1)
      (buffer-string))))
  ;; Slurp beyond the number of present blobs.
  (should-error
   (org-test-with-temp-text
       "\[\[https://orgmode.org/\]\[Org's\]\] website is"
     (org-link-edit-forward-slurp 3))
   :type 'user-error))

(ert-deftest test-org-link-edit/backward-slurp ()
  "Test `org-link-edit-backward-slurp'."
  ;; Slurp one blob into plain link.
  (should
   (string=
    "Here \[\[https://orgmode.org/\]\[is\]\] Org's website"
    (org-test-with-temp-text
        "Here is <point>https://orgmode.org/ Org's website"
      (org-link-edit-backward-slurp)
      (buffer-string))))
  ;; Slurp one blob into empty bracket link.
  (should
   (string=
    "Here \[\[https://orgmode.org/\]\[is\]\] Org's website"
    (org-test-with-temp-text
        "Here is <point>\[\[https://orgmode.org/\]\] Org's website"
      (org-link-edit-backward-slurp)
      (buffer-string))))
  ;; Slurp one blob into bracket link.
  (should
   (string=
    "Here \[\[https://orgmode.org/\]\[is Org's\]\] website"
    (org-test-with-temp-text
        "Here is <point>\[\[https://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-slurp)
      (buffer-string))))
  ;; Slurp one blob with trailing punctuation into bracket link.
  (should
   (string=
    "Here \[\[https://orgmode.org/\]\[is: Org's\]\] website."
    (org-test-with-temp-text
        "Here is: <point>\[\[https://orgmode.org/\]\[Org's\]\] website."
      (org-link-edit-backward-slurp)
      (buffer-string))))
  ;; Slurp all-punctuation blob into bracket link.
  (should
   (string=
    "Here \[\[https://orgmode.org/\]\[... Org's\]\] website."
    (org-test-with-temp-text
        "Here ... <point>\[\[https://orgmode.org/\]\[Org's\]\] website."
      (org-link-edit-backward-slurp)
      (buffer-string))))
  ;; Slurping blob with point beyond link, but technically still
  ;; within link element.
  (should
   (string=
    "\[\[https://orgmode.org/\]\[Org's website\]\]  is"
    (org-test-with-temp-text
        "Org's \[\[https://orgmode.org/\]\[website\]\] <point> is"
      (org-link-edit-backward-slurp)
      (buffer-string))))
  ;; Slurp two blobs into plain link.
  (should
   (string=
    "\[\[https://orgmode.org/\]\[Here is\]\] Org's website"
    (org-test-with-temp-text
        "Here is <point>https://orgmode.org/ Org's website"
      (org-link-edit-backward-slurp 2)
      (buffer-string))))
  ;; Slurp two blobs into bracket link.
  (should
   (string=
    "\[\[https://orgmode.org/\]\[Here is Org's\]\] website"
    (org-test-with-temp-text
        "Here is <point>\[\[https://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-slurp 2)
      (buffer-string))))
  ;; Slurp new line as space.
  (should
   (string=
    "Here \[\[https://orgmode.org/\]\[is Org's website\]\]"
    (org-test-with-temp-text
        "Here is
<point>\[\[https://orgmode.org/\]\[Org's website\]\]"
      (org-link-edit-backward-slurp 1)
      (buffer-string))))
  ;; Collapse stretches of new lines.
  (should
   (string=
    "\[\[https://orgmode.org/\]\[Here is Org's website\]\]"
    (org-test-with-temp-text
        "Here\n\nis\n\n\n
<point>\[\[https://orgmode.org/\]\[Org's website\]\]"
      (org-link-edit-backward-slurp 2)
      (buffer-string))))
  ;; Slurp blob that has no whitespace.
  (should
   (string=
    "Here \[\[https://orgmode.org/\]\[is\]\] Org's website"
    (org-test-with-temp-text
        "Here is<point>\[\[https://orgmode.org/\]\] Org's website"
      (org-link-edit-backward-slurp 1)
      (buffer-string))))
  ;; Slurp blob that isn't separated from link by whitespace.
  (should
   (string=
    "Here \[\[https://orgmode.org/\]\[is-\]\] Org's website"
    (org-test-with-temp-text
        "Here is-<point>\[\[https://orgmode.org/\]\] Org's website"
      (org-link-edit-backward-slurp 1)
      (buffer-string))))
  ;; Slurp beyond the number of present blobs.
  (should-error
   (org-test-with-temp-text
       "Here is <point>\[\[https://orgmode.org/\]\[Org's\]\] website"
     (org-link-edit-backward-slurp 3))
   :type 'user-error))

(ert-deftest test-org-link-edit/slurp-negative-argument ()
  "Test `org-link-edit-forward-slurp' and
`org-link-edit-backward-slurp' with negative arguments."
  (should
   (string=
    (org-test-with-temp-text
        "Here is <point>\[\[https://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-forward-slurp 1)
      (buffer-string))
    (org-test-with-temp-text
        "Here is <point>\[\[https://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-slurp -1)
      (buffer-string))))
  (should
   (string=
    (org-test-with-temp-text
        "Here is <point>\[\[https://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-forward-slurp -1)
      (buffer-string))
    (org-test-with-temp-text
        "Here is <point>\[\[https://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-slurp)
      (buffer-string)))))


;;; Barfing

(ert-deftest test-org-link-edit/forward-barf ()
  "Test `org-link-edit-forward-barf'."
  ;; Barf last blob.
  (should
   (string=
    "Org's \[\[https://orgmode.org/\]\] website is"
    (org-test-with-temp-text
        "Org's <point>\[\[https://orgmode.org/\]\[website\]\] is"
      (org-link-edit-forward-barf)
      (buffer-string))))
  ;; Barfing last blob with point beyond link, but technically still
  ;; within link element.
  (should
   (string=
    "Org's \[\[https://orgmode.org/\]\] website  is"
    (org-test-with-temp-text
        "Org's \[\[https://orgmode.org/\]\[website\]\] <point> is"
      (org-link-edit-forward-barf)
      (buffer-string))))
  ;; Barf last blob with puctuation.
  (should
   (string=
    "Org's \[\[https://orgmode.org/\]\] website,"
    (org-test-with-temp-text
        "Org's <point>\[\[https://orgmode.org/\]\[website,\]\]"
      (org-link-edit-forward-barf)
      (buffer-string))))
  ;; Barf last blob, all punctuation.
  (should
   (string=
    "Org's \[\[https://orgmode.org/\]\] ..."
    (org-test-with-temp-text
        "Org's <point>\[\[https://orgmode.org/\]\[...\]\]"
      (org-link-edit-forward-barf)
      (buffer-string))))
  ;; Barf two last blobs.
  (should
   (string=
    "Org's \[\[https://orgmode.org/\]\] website is"
    (org-test-with-temp-text
        "Org's <point>\[\[https://orgmode.org/\]\[website is\]\]"
      (org-link-edit-forward-barf 2)
      (buffer-string))))
  ;; Barf one blob, not last.
  (should
   (string=
    "Org's \[\[https://orgmode.org/\]\[website\]\] is"
    (org-test-with-temp-text
        "Org's <point>\[\[https://orgmode.org/\]\[website is\]\]"
      (org-link-edit-forward-barf 1)
      (buffer-string))))
  ;; Barf beyond the number of present blobs.
  (should-error
   (org-test-with-temp-text
       "Org's <point>\[\[https://orgmode.org/\]\[website is\]\]"
     (org-link-edit-forward-barf 3))
   :type 'user-error))

(ert-deftest test-org-link-edit/backward-barf ()
  "Test `org-link-edit-backward-barf'."
  ;; Barf last blob.
  (should
   (string=
    "Org's website \[\[https://orgmode.org/\]\] is"
    (org-test-with-temp-text
        "Org's <point>\[\[https://orgmode.org/\]\[website\]\] is"
      (org-link-edit-backward-barf)
      (buffer-string))))
  ;; Barfing last blob with point beyond link, but technically still
  ;; within link element.
  (should
   (string=
    "Org's website \[\[https://orgmode.org/\]\]  is"
    (org-test-with-temp-text
        "Org's \[\[https://orgmode.org/\]\[website\]\] <point> is"
      (org-link-edit-backward-barf)
      (buffer-string))))
  ;; Barf last blob with puctuation.
  (should
   (string=
    "Org's website: \[\[https://orgmode.org/\]\]"
    (org-test-with-temp-text
        "Org's <point>\[\[https://orgmode.org/\]\[website:\]\]"
      (org-link-edit-backward-barf)
      (buffer-string))))
  ;; Barf last all-puctuation blob.
  (should
   (string=
    "Org's ... \[\[https://orgmode.org/\]\]"
    (org-test-with-temp-text
        "Org's <point>\[\[https://orgmode.org/\]\[...\]\]"
      (org-link-edit-backward-barf)
      (buffer-string))))
  ;; Barf two last blobs.
  (should
   (string=
    "Org's website is \[\[https://orgmode.org/\]\]"
    (org-test-with-temp-text
        "Org's <point>\[\[https://orgmode.org/\]\[website is\]\]"
      (org-link-edit-backward-barf 2)
      (buffer-string))))
  ;; Barf one blob, not last.
  (should
   (string=
    "Org's website \[\[https://orgmode.org/\]\[is\]\]"
    (org-test-with-temp-text
        "Org's <point>\[\[https://orgmode.org/\]\[website is\]\]"
      (org-link-edit-backward-barf 1)
      (buffer-string))))
  ;; Barf one blob with punctuation, not last.
  (should
   (string=
    "Org's website. \[\[https://orgmode.org/\]\[is\]\]"
    (org-test-with-temp-text
        "Org's <point>\[\[https://orgmode.org/\]\[website. is\]\]"
      (org-link-edit-backward-barf 1)
      (buffer-string))))
  ;; Barf beyond the number of present blobs.
  (should-error
   (org-test-with-temp-text
       "Org's <point>\[\[https://orgmode.org/\]\[website is\]\]"
     (org-link-edit-backward-barf 3))
   :type 'user-error))

(ert-deftest test-org-link-edit/barf-negative-argument ()
  "Test `org-link-edit-forward-barf' and
`org-link-edit-backward-barf' with negative arguments."
  (should
   (string=
    (org-test-with-temp-text
        "Here is <point>\[\[https://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-forward-barf 1)
      (buffer-string))
    (org-test-with-temp-text
        "Here is <point>\[\[https://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-barf -1)
      (buffer-string))))
  (should
   (string=
    (org-test-with-temp-text
        "Here is <point>\[\[https://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-forward-barf -1)
      (buffer-string))
    (org-test-with-temp-text
        "Here is <point>\[\[https://orgmode.org/\]\[Org's\]\] website"
      (org-link-edit-backward-barf)
      (buffer-string)))))


;;; Slurp and Barf round trip
;;
;; Slurping and then barfing in the same direction, and vice versa,
;; usually result in the original link stage.  This is not true in the
;; following cases.
;; - The slurped string contains one or more newlines.
;; - When slurping into a link with an empty description, the slurped
;;   string is separated from a link by whitespace other than a single
;;   space.

(ert-deftest test-org-link-edit/slurp-barf-round-trip ()
  "Test `org-link-edit-forward-barf' and
`org-link-edit-backward-barf' reversibility."
  (should
   (string= "Here is \[\[https://orgmode.org/\]\[Org's\]\] website"
            (org-test-with-temp-text
                "Here is <point>\[\[https://orgmode.org/\]\[Org's\]\] website"
              (org-link-edit-forward-barf 1)
              (org-link-edit-forward-slurp 1)
              (buffer-string))))
  (should
   (string= "Here is \[\[https://orgmode.org/\]\] Org's website"
            (org-test-with-temp-text
                "Here is <point>\[\[https://orgmode.org/\]\] Org's website"
              (org-link-edit-forward-slurp 1)
              (org-link-edit-forward-barf 1)
              (buffer-string))))
  (should
   (string= "Here is \[\[https://orgmode.org/\]\[Org's\]\] website"
            (org-test-with-temp-text
                "Here is <point>\[\[https://orgmode.org/\]\[Org's\]\] website"
              (org-link-edit-backward-barf 1)
              (org-link-edit-backward-slurp 1)
              (buffer-string))))
  (should
   (string= "Here is \[\[https://orgmode.org/\]\[Org's\]\] website"
            (org-test-with-temp-text
                "Here is <point>\[\[https://orgmode.org/\]\[Org's\]\] website"
              (org-link-edit-backward-slurp 1)
              (org-link-edit-backward-barf 1)
              (buffer-string))))
  ;; Handle escaped link components.
  (should
   (string= "Here is \[\[file:t.org::some%20text\]\[Org\]\] file"
            (org-test-with-temp-text
                "Here is <point>\[\[file:t.org::some%20text\]\[Org\]\] file"
              (org-link-edit-forward-slurp 1)
              (org-link-edit-forward-barf 1)
              (buffer-string))))
  ;; Failed round trip because of newline.
  (should
   (string= "Here is \[\[https://orgmode.org/\]\[Org's\]\] website"
            (org-test-with-temp-text
                "Here is <point>\[\[https://orgmode.org/\]\[Org's\]\]
website"
              (org-link-edit-forward-slurp 1)
              (org-link-edit-forward-barf 1)
              (buffer-string))))
  ;; Failed round trip because of empty description and more than one
  ;; whitespace.
  (should
   (string= "Here is \[\[https://orgmode.org/\]\] website"
            (org-test-with-temp-text
                "Here is <point>\[\[https://orgmode.org/\]\]    website"
              (org-link-edit-forward-slurp 1)
              (org-link-edit-forward-barf 1)
              (buffer-string)))))


;;; Transport

(ert-deftest test-org-link-edit/transport-next-link ()
  "Test `org-link-edit-transport-next-link'."
  ;; Transport next link to word at point.
  (should
   (string= "Here is \[\[https://orgmode.org/\]\[Org's\]\] website "
            (org-test-with-temp-text
                "Here is <point>Org's website https://orgmode.org/"
              (org-link-edit-transport-next-link)
              (buffer-string))))
  ;; Transport previous link to word at point.
  (should
   (string= " Here is \[\[https://orgmode.org/\]\[Org's\]\] website"
            (org-test-with-temp-text
                "https://orgmode.org/ Here is <point>Org's website"
              (org-link-edit-transport-next-link 'previous)
              (buffer-string))))
  ;; Transport next link to the active region.
  (should
   (string= "\[\[https://orgmode.org/\]\[Here is Org's\]\] website "
            (org-test-with-temp-text
                "Here is Org's<point> website https://orgmode.org/"
              (org-link-edit-transport-next-link
               nil (point-min) (point))
              (buffer-string))))
  ;; When a lisp caller gives BEG and END explicitly, they take
  ;; precedence over point.
  (should
   (string= "Here is \[\[https://orgmode.org/\]\[Org's\]\] website "
            (org-test-with-temp-text
                "<point>Here is Org's website https://orgmode.org/"
              (org-link-edit-transport-next-link
               nil 9 14)
              (buffer-string))))
  ;; Transport previous link to the active region.
  (should
   (string= " Here is \[\[https://orgmode.org/\]\[Org's website\]\]"
            (org-test-with-temp-text
                "https://orgmode.org/ Here is <point>Org's website"
              (org-link-edit-transport-next-link
               'previous (point) (point-max))
              (buffer-string))))
  ;; Transport next link with point on whitespace.
  (should
   (string= "Here is\[\[https://orgmode.org/\]\] Org's website "
            (org-test-with-temp-text
                "Here is<point> Org's website https://orgmode.org/"
              (org-link-edit-transport-next-link)
              (buffer-string))))
  ;; Transported links are allow to have an existing description when
  ;; point is on whitespace.
  (should
   (string=
    "Here is\[\[https://orgmode.org/\]\[description\]\] Org's website "
    (org-test-with-temp-text
        "Here is<point> Org's website \[\[https://orgmode.org/\]\[description\]\]"
      (org-link-edit-transport-next-link)
      (buffer-string))))
  ;; Fail if point is on a link.
  (should-error
   (org-test-with-temp-text
       "Here is Org's website https://orgmode.org/<point>"
     (org-link-edit-transport-next-link))
   :type 'user-error)
  (should-error
   (org-test-with-temp-text
       "Here is Org's website <point>https://orgmode.org/"
     (org-link-edit-transport-next-link
      nil (point-min) (point)))
   :type 'user-error)
  ;; Fail if link already has a description, unless caller confirms
  ;; the overwrite.
  (should-error
   (org-test-with-temp-text
       "Here is <point>Org's website \[\[https://orgmode.org/\]\[description\]\]"
     (cl-letf (((symbol-function 'y-or-n-p) (lambda (_) nil)))
       (call-interactively #'org-link-edit-transport-next-link)))
   :type 'user-error)
  (should-error
   (org-test-with-temp-text
       "Here is <point>Org's website \[\[https://orgmode.org/\]\[description\]\]"
     (org-link-edit-transport-next-link))
   :type 'user-error)
  (should
   (string=
    "Here is \[\[https://orgmode.org/\]\[Org's\]\] website "
    (org-test-with-temp-text
        "Here is <point>Org's website \[\[https://orgmode.org/\]\[description\]\]"
      (org-link-edit-transport-next-link nil nil nil 'overwrite)
      (buffer-string)))))


;;; Other

(ert-deftest test-org-link-edit/on-link-p ()
  "Test `org-link-edit--on-link-p'."
  ;; On plain link
  (should
   (org-test-with-temp-text "https://orgmode.org/"
     (org-link-edit--on-link-p)))
  ;; On bracket link
  (should
   (org-test-with-temp-text "\[\[https://orgmode.org/\]\[org\]\]"
     (org-link-edit--on-link-p)))
  ;; Point beyond link, but technically still within link element.
  (should
   (org-test-with-temp-text "\[\[https://orgmode.org/\]\[org\]\] <point>"
     (org-link-edit--on-link-p)))
  ;; Not on a link
  (should-not
   (org-test-with-temp-text " \[\[https://orgmode.org/\]\[org\]\]"
     (org-link-edit--on-link-p)))
  (should-not
   (org-test-with-temp-text "not a link"
     (org-link-edit--on-link-p))))

(ert-deftest test-org-link-edit/get-link-data ()
  "Test `org-link-edit--link-data'."
  ;; Plain link
  (cl-multiple-value-bind (_beg _end link desc)
      (org-test-with-temp-text "https://orgmode.org/"
        (org-link-edit--link-data))
    (should (string= link "https://orgmode.org/"))
    (should-not desc))
  ;; Bracket link
  (cl-multiple-value-bind (_beg _end link desc)
      (org-test-with-temp-text "\[\[https://orgmode.org/\]\[org\]\]"
        (org-link-edit--link-data))
    (should (string= link "https://orgmode.org/"))
    (should (string= desc "org"))))

(ert-deftest test-org-link-edit/forward-blob ()
  "Test `org-link-edit--forward-blob'."
  ;; Move forward one blob.
  (should
   (string=
    "one"
    (org-test-with-temp-text "one two"
      (org-link-edit--forward-blob 1)
      (buffer-substring (point-min) (point)))))
  ;; Move forward one blob with point mid.
  (should
   (string=
    "one"
    (org-test-with-temp-text "o<point>ne two"
      (org-link-edit--forward-blob 1)
      (buffer-substring (point-min) (point)))))
  ;; Move forward two blobs.
  (should
   (string=
    "one two"
    (org-test-with-temp-text "one two"
      (org-link-edit--forward-blob 2)
      (buffer-substring (point-min) (point)))))
  ;; Move forward blob, including punctuation.
  (should
   (string=
    "one."
    (org-test-with-temp-text "one."
      (org-link-edit--forward-blob 1)
      (buffer-substring (point-min) (point)))))
  ;; Move forward blob, adjusting for punctuation.
  (should
   (string=
    "one"
    (org-test-with-temp-text "one."
      (org-link-edit--forward-blob 1 t)
      (buffer-substring (point-min) (point)))))
  ;; Move forward blob consisting of only punctuation characters.
  (should
   (string=
    "...."
    (org-test-with-temp-text "...."
      (org-link-edit--forward-blob 1 t)
      (buffer-substring (point-min) (point)))))
  ;; Move backward one blob.
  (should
   (string=
    "two"
    (org-test-with-temp-text "one two<point>"
      (org-link-edit--forward-blob -1)
      (buffer-substring (point) (point-max)))))
  ;; Move backward two blobs.
  (should
   (string=
    "one two"
    (org-test-with-temp-text "one two<point>"
      (org-link-edit--forward-blob -2)
      (buffer-substring (point) (point-max)))))
  ;; Move backward one blobs, including punctuation.
  (should
   (string=
    ".two."
    (org-test-with-temp-text "one .two.<point>"
      (org-link-edit--forward-blob -1)
      (buffer-substring (point) (point-max)))))
  ;; Move beyond last blob.
  (org-test-with-temp-text "one two"
    (should (org-link-edit--forward-blob 1))
    (should-not (org-link-edit--forward-blob 2))
    (should (string= "one two"
                     (buffer-substring (point-min) (point))))))

(ert-deftest test-org-link-edit/split-firsts ()
  "Test `org-link-edit--split-first-blobs'."
  ;; Single blob, n = 1
  (should (equal '("one" . "")
                 (org-link-edit--split-first-blobs "one" 1)))
  ;; Single blob, out-of-bounds
  (should (equal '("one" . nil)
                 (org-link-edit--split-first-blobs "one" 2)))
  ;; Multiple blobs, n = 1
  (should (equal '("one " . "two three")
                 (org-link-edit--split-first-blobs "one two three" 1)))
  ;; Multiple blobs, n > 1
  (should (equal '("one two " . "three")
                 (org-link-edit--split-first-blobs "one two three" 2))))

(ert-deftest test-org-link-edit/split-lasts ()
  "Test `org-link-edit--split-last-blobs'."
  ;; Single blob, n = 1
  (should (equal '("" . "one")
                 (org-link-edit--split-last-blobs "one" 1)))
  ;; Single blob, out-of-bounds
  (should (equal '(nil . "one")
                 (org-link-edit--split-last-blobs "one" 2)))
  ;; Multiple blobs, n = 1
  (should (equal '("one two" . " three")
                 (org-link-edit--split-last-blobs "one two three" 1)))
  ;; Multiple blobs, n > 1
  (should (equal '("one" . " two three")
                 (org-link-edit--split-last-blobs "one two three" 2))))

(provide 'test-org-link-edit)
;;; test-org-link-edit.el ends here
