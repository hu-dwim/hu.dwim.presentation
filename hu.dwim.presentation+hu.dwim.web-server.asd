;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2011 by the authors.
;;;
;;; See LICENCE for details.

(load-system :hu.dwim.asdf)

(in-package :hu.dwim.asdf)

;; for now it's pretty much a dummy. later this will be the system for the html backend for hdp
(defsystem :hu.dwim.presentation+hu.dwim.web-server
  :class hu.dwim.system
  :depends-on (:hu.dwim.presentation
               :hu.dwim.web-server)
  :components ())
