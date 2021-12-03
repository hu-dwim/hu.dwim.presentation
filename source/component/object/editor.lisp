;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.presentation)

;;;;;;
;;; t/editor

;; FIXME clashes with t/editor in component/object/editor.lisp
(def (component e) t/editor (t/presentation
                             cloneable/component
                             layer/mixin)
  ())
