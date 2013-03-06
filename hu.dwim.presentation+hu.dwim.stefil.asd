;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(defsystem :hu.dwim.presentation+hu.dwim.stefil
  :defsystem-depends-on (:hu.dwim.asdf)
  :class "hu.dwim.asdf:hu.dwim.system"
  :depends-on (:hu.dwim.presentation
               :hu.dwim.stefil)
  :components ((:module "source"
                :components ((:module "component"
                              :components ((:module "source"
                                            :components ((:file "test")))))))))
