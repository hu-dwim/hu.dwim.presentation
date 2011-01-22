;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(load-system :hu.dwim.asdf)

(in-package :hu.dwim.asdf)

(defsystem :hu.dwim.presentation.documentation
  :class hu.dwim.documentation-system
  :depends-on (:hu.dwim.presentation.test)
  :components ((:module "documentation"
                :components ((:file "package")
                             (:file "main" :depends-on ("package"))))))
