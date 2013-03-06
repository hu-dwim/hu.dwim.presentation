;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(defsystem :hu.dwim.presentation+cl-graph+cl-typesetting
  :defsystem-depends-on (:hu.dwim.asdf)
  :class "hu.dwim.asdf:hu.dwim.system"
  :depends-on (:cl-graph
               :hu.dwim.presentation+cl-typesetting)
  :components ((:module "source"
                :components ((:module "component"
                              :components ((:module "widget"
                                            :components ((:file "graph")))))))))
