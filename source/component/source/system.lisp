;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.presentation)

;;;;;;
;;; system/alternator/inspector

(def (component e) system/alternator/inspector (t/alternator/inspector)
  ())

(def subtype-mapper *inspector-type-mapping* (or null asdf:system) system/alternator/inspector)

(def layered-method make-alternatives ((component system/alternator/inspector) (class standard-class) (prototype asdf:system) (value asdf:system))
  (list* (make-instance 'system/depends-on-hierarchy/tree/inspector :component-value value) (call-next-layered-method)))

;;;;;;
;;; system/depends-on-hierarchy/tree/inspector

(def (component e) system/depends-on-hierarchy/tree/inspector (t/tree/inspector)
  ())

(def layered-method make-node-presentation ((component system/depends-on-hierarchy/tree/inspector) (class standard-class) (prototype asdf:system) (value asdf:system))
  (make-instance 'system/depends-on-hierarchy/node/inspector :component-value value))

;;;;;;
;;; system/depends-on-hierarchy/node/inspector

(def (component e) system/depends-on-hierarchy/node/inspector (t/node/inspector)
  ())

(def layered-method make-node-presentation ((component system/depends-on-hierarchy/node/inspector) (class standard-class) (prototype asdf:system) (value asdf:system))
  (make-instance 'system/depends-on-hierarchy/node/inspector :component-value value :expanded #f))

(def layered-method collect-presented-children ((component system/depends-on-hierarchy/node/inspector) (class standard-class) (prototype asdf:system) (value asdf:system))
  (collect-system-dependencies value))
