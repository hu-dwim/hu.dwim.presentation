;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(defsystem :hu.dwim.presentation+hu.dwim.reader
  :defsystem-depends-on (:hu.dwim.asdf)
  :class "hu.dwim.asdf:hu.dwim.system"
  :depends-on (:hu.dwim.reader+hu.dwim.syntax-sugar
               :hu.dwim.presentation)
  :components ((:module "integration"
                :components ((:file "reader")))))
