;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(load-system :hu.dwim.asdf)

(in-package :hu.dwim.asdf)

(defsystem :hu.dwim.presentation+hu.dwim.reader
  :class hu.dwim.system
  :depends-on (:hu.dwim.reader+hu.dwim.syntax-sugar
               :hu.dwim.presentation)
  :components ((:module "integration"
                :components ((:file "reader")))))
