;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.presentation)

;;;;;;
;;; t/viewer

;; FIXME clashes with t/viewer in component/presentation/viewer.lisp
(def (component e) t/viewer (t/presentation
                             cloneable/component
                             layer/mixin)
  ())
