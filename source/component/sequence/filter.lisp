;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.wui)

;;;;;;
;;; sequence/filter

(def (component e) sequence/filter (t/filter)
  ())

(def method collect-filter-predicates ((self sequence/filter))
  '(some every))

;;;;;;
;;; sequence/alternator/filter

(def (component e) sequence/alternator/filter (t/alternator/filter sequence/filter)
  ())

(def layered-method make-alternatives ((component sequence/alternator/filter) class prototype value)
  (bind (((:read-only-slots component-value-type) component))
    (optional-list (make-instance 't/reference/filter
                                  :component-value value
                                  :component-value-type component-value-type))))