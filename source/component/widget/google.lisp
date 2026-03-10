;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.presentation)

;;;;;;
;;; google-analytics/widget

(def (component e) google-analytics/widget (standard/widget)
  ((analytics-account :type string)))

(def (macro e) google-analytics/widget (&rest args &key &allow-other-keys)
  `(make-instance 'google-analytics/widget ,@args))

(def render-xhtml google-analytics/widget
  (bind (((:read-only-slots analytics-account) -self-))
    `js(hdws.io.eval-js-at-url (+ (if (== "https:" document.location.protocol)
                                      "https://ssl."
                                      "http://www.")
                                  "google-analytics.com/ga.js")
                               :on-success (lambda (type data event)
                                             (try
                                                  (let ((pageTracker (_gat._getTracker ,analytics-account)))
                                                    (pageTracker._trackPageview))
                                               (catch (e)
                                                 nil)))
                               :on-error (lambda ()
                                           (log.warn "Failed to load google-analytics.com/ga.js"))
                               :sync false)))
