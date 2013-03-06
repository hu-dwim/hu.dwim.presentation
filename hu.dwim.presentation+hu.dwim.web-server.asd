;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2011 by the authors.
;;;
;;; See LICENCE for details.

;; for now it's pretty much a dummy. later this will be the system for the html backend for hdp
(defsystem :hu.dwim.presentation+hu.dwim.web-server
  :defsystem-depends-on (:hu.dwim.asdf)
  :class "hu.dwim.asdf:hu.dwim.system"
  :depends-on (:hu.dwim.presentation
               :hu.dwim.web-server)
  :components ())
