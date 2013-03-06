;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(defsystem :hu.dwim.presentation+cl-typesetting
  :defsystem-depends-on (:hu.dwim.asdf)
  :class "hu.dwim.asdf:hu.dwim.system"
  :depends-on (:cl-typesetting
               :hu.dwim.presentation)
  :components ((:module "integration"
                :components ((:file "cl-typesetting")))))
