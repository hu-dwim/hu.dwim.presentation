;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(load-system :hu.dwim.asdf)

(in-package :hu.dwim.asdf)

(defsystem :hu.dwim.presentation+hu.dwim.serializer
  :class hu.dwim.system
  :depends-on (:hu.dwim.presentation
               :hu.dwim.serializer)
  :components ((:module "integration"
                :components ((:file "serializer")))))
