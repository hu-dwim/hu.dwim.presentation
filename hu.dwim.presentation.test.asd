;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(defsystem :hu.dwim.presentation.test
  :defsystem-depends-on (:hu.dwim.asdf)
  :class "hu.dwim.asdf:hu.dwim.test-system"
  :package-name :hu.dwim.presentation.test
  :depends-on (:hu.dwim.graphviz
               :hu.dwim.web-server.application.test
               :hu.dwim.presentation
               :hu.dwim.presentation+cl-graph+cl-typesetting
               :hu.dwim.presentation+hu.dwim.reader
               :hu.dwim.presentation+hu.dwim.stefil)
  :components ((:module "test"
                :components ((:file "component" :depends-on ("environment" "package"))
                             (:file "environment" :depends-on ("package"))
                             (:file "human-readable" :depends-on ("environment" "package"))
                             (:file "package")))))
