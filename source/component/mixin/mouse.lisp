;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.presentation)

;;;;;;
;;; mouse/component

(def (component e) mouse/component ()
  ())

(def (layered-function e) render-onclick-handler (component button)
  (:method ((self mouse/component) button)
    (values)))
