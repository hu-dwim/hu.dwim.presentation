;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(defsystem :hu.dwim.presentation+hu.dwim.reader
  :defsystem-depends-on (:hu.dwim.asdf)
  :class "hu.dwim.asdf:hu.dwim.system"
  :depends-on (:hu.dwim.reader+hu.dwim.syntax-sugar
               ;; this is needed because MAKE-SOURCE-READTABLE calls SOURCE-TEXT::ENABLE-SHEBANG-SYNTAX
               :hu.dwim.reader+swank
               :hu.dwim.presentation)
  :components ((:module "integration"
                :components ((:file "reader")))))
