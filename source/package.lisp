;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.def)

(def package :hu.dwim.presentation
  (:use :babel
        :babel-streams
        :bordeaux-threads
        :cl-l10n
        :cl-l10n.lang
        :contextl
        :hu.dwim.asdf
        :hu.dwim.common
        :hu.dwim.computed-class
        :hu.dwim.def
        :hu.dwim.defclass-star
        :hu.dwim.delico
        :hu.dwim.logger
        :hu.dwim.quasi-quote
        :hu.dwim.quasi-quote.js
        :hu.dwim.quasi-quote.xml
        :hu.dwim.syntax-sugar
        :hu.dwim.util
        :hu.dwim.web-server
        :hu.dwim.web-server.semi-public
        :trivial-garbage)

  (:shadow #:class-prototype
           #:class-slots
           #:class-precedence-list
           #:log)

  (:shadowing-import-from :hu.dwim.syntax-sugar
                          #:define-syntax)

  (:shadowing-import-from :hu.dwim.web-server
                          #:|defun|)

  (:shadowing-import-from :trivial-garbage
                          #:make-hash-table)
  (:readtable-setup (setup-readtable/same-as-package :hu.dwim.web-server)))
