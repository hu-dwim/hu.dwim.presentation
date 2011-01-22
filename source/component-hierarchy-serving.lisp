;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.presentation)

;;;;;;
;;; js-component-hierarchy-broker

(def constant +js-component-hierarchy-serving-broker/default-path+ "/hdp/js/component-hierarchy.js")

(def special-variable *js-component-hierarchy-cache* nil)

(def special-variable *js-component-hierarchy-cache/last-modified-at* (local-time:now))

(def (class* e) js-component-hierarchy-serving-broker (broker-at-path)
  ()
  (:default-initargs :path +js-component-hierarchy-serving-broker/default-path+))

(def function clear-js-component-hierarchy-cache ()
  (setf *js-component-hierarchy-cache* nil)
  (setf *js-component-hierarchy-cache/last-modified-at* (local-time:now)))

(def method produce-response ((self js-component-hierarchy-serving-broker) request)
  (make-byte-vector-response* (or *js-component-hierarchy-cache*
                                  (setf *js-component-hierarchy-cache*
                                        (emit-into-js-stream-buffer (:external-format :utf-8)
                                          (serve-js-component-hierarchy))))
                              :last-modified-at *js-component-hierarchy-cache/last-modified-at*
                              :seconds-until-expires (* 60 60)
                              :content-type (content-type-for +javascript-mime-type+ :utf-8)))

;; FIXME: this generates a quite big list which is redundant like hell
;;        but it is cached and compressed, so we don't care about it right now
(def (function e) serve-js-component-hierarchy ()
  (bind ((component-class (find-class 'component)))
    `js(setf hdp.component-class-precedence-lists (create))
    (dolist (subclass (moptilities:subclasses component-class))
      (bind ((subclass-name (class-name-as-string subclass))
             (class-precedence-list (class-precedence-list subclass))
             (index (position component-class class-precedence-list))
             (class-name-precedence-list (mapcar #'class-name-as-string (subseq class-precedence-list 0 (1+ index)))))
        `js(setf (slot-value hdp.component-class-precedence-lists ,subclass-name) (array ,@class-name-precedence-list))))
    +void+))
