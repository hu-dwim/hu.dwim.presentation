;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(defsystem :hu.dwim.presentation+hu.dwim.perec
  :defsystem-depends-on (:hu.dwim.asdf)
  :class "hu.dwim.asdf:hu.dwim.system"
  :depends-on (:cl-l10n
               :hu.dwim.perec+iolib
               :hu.dwim.presentation
               :hu.dwim.meta-model ; KLUDGE
               :hu.dwim.web-server.application+hu.dwim.perec
               )
  :components ((:module "integration"
                :components ((:module "perec"
                              :components ((:file "d-value")
                                           (:file "dimension")
                                           (:file "filter")
                                           (:file "inspector")
                                           (:file "kludge")
                                           (:file "l10n")
                                           (:file "presentation")
                                           (:file "process")
                                           (:file "table")))))))
