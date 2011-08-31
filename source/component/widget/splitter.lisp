;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.presentation)

;;;;;;
;;; splitter/widget

(def (component e) splitter/widget (standard/widget list/layout)
  ())

(def (macro e) splitter/widget ((&rest args &key &allow-other-keys) &body contents)
  `(make-instance 'splitter/widget ,@args :contents (list ,@contents)))

(def render-xhtml splitter/widget
  (bind (((:read-only-slots id style-class custom-style orientation contents) -self-))
    (render-dojo-widget (+dijit/split-container+ `(:orientation ,(string-downcase orientation) :sizerWidth 7) :id id)
      <div (:id ,-id-
            :class ,style-class
            :style ,custom-style)
        ,(foreach (lambda (content)
                    (render-dojo-widget (+dijit/content-pane+ `(:sizeMin 10 :sizeShare 50))
                      <div (:id ,-id-)
                        ,(render-component content)>))
                  contents)>)))
