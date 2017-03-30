;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.presentation)

;;;;;;
;;; API

(def (generic e) application-relative-path-for-no-javascript-support-error (application)
  (:method ((application application))
    "/help/"))

;;;;;;
;;; frame/widget

(def (component e) frame/widget (top/component layer/mixin)
  ((content-mime-type +xhtml-mime-type+)
   (stylesheet-uris nil)
   (script-uris (make-default-script-uris))
   (page-icon-uri nil)
   (title nil)))

(def method parent-component-of ((self frame/widget))
  nil)

(def method supports-debug-component-hierarchy? ((self frame/widget))
  #f)

;;;;;;
;;; dojo-frame/widget

(def (component e) dojo-frame/widget (frame/widget)
  ((dojo-skin-name *dojo-skin-name*)
   (dojo-release-uri (hu.dwim.uri:parse-uri (string+ "static/hdws/libraries/" *dojo-directory-name* "dojo/")))
   (dojo-file-name *dojo-file-name*)
   (parse-dojo-widgets-on-load #f :type boolean)
   (debug-client-side :type boolean :writer (setf debug-client-side?))))

(def (macro e) frame/widget ((&rest args &key (widget-library :dojo) &allow-other-keys) &body content)
  (remove-from-plistf args :widget-library)
  (ecase widget-library
    (:dojo `(make-instance 'dojo-frame/widget ,@args :content ,(the-only-element content)))))

(def method debug-client-side? ((self dojo-frame/widget))
  (if (slot-boundp self 'debug-client-side)
      (slot-value self 'debug-client-side)
      (debug-client-side? *application*)))

(def component-environment dojo-frame/widget
  (with-active-layers (dojo-layer)
    (call-next-method)))

;; we stay with render-xhtml here, because component-environment is reinstated only after us, so the dojo layer is not active yet
(def render-xhtml dojo-frame/widget
  (bind ((application *application*)
         (application-path (path-of application))
         (encoding (or (when *response*
                         (encoding-name-of *response*))
                       +default-encoding+))
         (debug-client-side? (debug-client-side? -self-))
         (javascript-supported? (not (request-parameter-value *request* +no-javascript-error-parameter-name+))))
    (emit-xhtml-prologue encoding +xhtml-1.1-doctype+)
    <html (:xmlns     #.+xml-namespace-uri/xhtml+
           xmlns:dojo #.+xml-namespace-uri/dojo+)
      <head
        <meta (:http-equiv +header/content-type+
               :content ,(content-type-for (content-mime-type-of -self-) encoding))>
        ,(bind (((&optional icon-uri timestamp) (ensure-list (page-icon-uri-of -self-))))
           (when icon-uri
             <link (:rel "icon"
                    :type "image/x-icon"
                    :href ,(bind ((uri (hu.dwim.uri:clone-uri icon-uri)))
                             (hu.dwim.uri:prepend-path uri application-path)
                             (when timestamp
                               (append-timestamp-to-uri uri timestamp))
                             (hu.dwim.uri:print-uri-to-string uri)))>))
        <title ,(title-of -self-)>
        ,(foreach (lambda (entry)
                    (bind (((stylesheet-uri &optional timestamp) (ensure-list entry)))
                      <link (:rel "stylesheet"
                             :type "text/css"
                             :href ,(bind ((uri (hu.dwim.uri:clone-uri stylesheet-uri)))
                                      (hu.dwim.uri:prepend-path uri application-path)
                                      (when timestamp
                                        (append-timestamp-to-uri uri timestamp))
                                      (hu.dwim.uri:print-uri-to-string uri)))>))
                  (stylesheet-uris-of -self-))
        <script (:type +javascript-mime-type+)
          ,(string+ "djConfig = { baseUrl: '/static/hdws/libraries/" *dojo-directory-name* "dojo/'"
                    ", parseOnLoad: " (to-js-boolean (parse-dojo-widgets-on-load? -self-))
                    ", isDebug: " (to-js-boolean debug-client-side?)
                    ;; TODO add separate flag for debugAtAllCosts
                    ", debugAtAllCosts: " (to-js-boolean debug-client-side?)
                    ;; TODO locale should come from either the session or from frame/widget
                    ;; KLUDGE browsers do not substitute &quot; if the content-type of the response is text/html.
                    ;;    was:", locale: " (to-js-literal (locale-name (locale (first (ensure-list (default-locale-of application))))))
                    ", locale: '" (escape-as-js-string (locale-name (locale (first (ensure-list (default-locale-of application)))))) "'"
                    "}")>
        <script (:type +javascript-mime-type+
                 :src  ,(bind ((uri (hu.dwim.uri:clone-uri (dojo-release-uri-of -self-))))
                          ;; we have the dojo release version in the url, so timestamps here are not important
                          (hu.dwim.uri:prepend-path uri application-path)
                          (hu.dwim.uri:append-path uri (if debug-client-side?
                                                           (string+ (dojo-file-name-of -self-) ".uncompressed.js")
                                                           (dojo-file-name-of -self-)))
                          (hu.dwim.uri:print-uri-to-string uri)))
                 ;; it must have an empty body because browsers don't like collapsed <script ... /> in the head
                 "">
        ,(foreach (lambda (entry)
                    (bind (((script-uri &optional timestamp) (ensure-list entry)))
                      <script (:type +javascript-mime-type+
                               :src  ,(bind ((uri (hu.dwim.uri:clone-uri script-uri)))
                                        (unless (starts-with #\/ (hu.dwim.uri:path-of uri))
                                          (hu.dwim.uri:prepend-path uri application-path))
                                        (when timestamp
                                          (append-timestamp-to-uri uri timestamp))
                                        (when debug-client-side?
                                          (setf (hu.dwim.uri:query-parameter-value uri "debug") "t"))
                                        (hu.dwim.uri:print-uri-to-string uri)))
                        ;; it must have an empty body because browsers don't like collapsed <script ... /> in the head
                        "">))
                  (script-uris-of -self-))>
      <body (:class ,(dojo-skin-name-of -self-)
             :style ,(when javascript-supported? "margin-left: -10000px;"))
        ;; TODO: this causes problems when content-type is application/xhtml+xml
        ;;       should solve the no javascript issue in a different way
        ,(when javascript-supported?
           <noscript <meta (:http-equiv +header/refresh+
                            :content ,(string+ "0; URL="
                                               (application-relative-path-for-no-javascript-support-error *application*)
                                               "?"
                                               +no-javascript-error-parameter-name+
                                               "=t"))>>
           (apply-localization-function 'render-failed-to-load-page)
           ;; don't use any non-standard js stuff for the failed-to-load machinery, because if things go wrong then nothing is guaranteed to be loaded...
           `js-xml(progn
                    ;; don't use any non-standard js stuff for the failed-to-load machinery, because if things go wrong then nothing is guaranteed to be loaded...
                    (defun _wui_handleFailedToLoad ()
                      (setf document.location.href document.location.href)
                      (return false))
                    (bind ((failed-page (document.getElementById ,+page-failed-to-load-id+)))
                      (setf failed-page.style.display "none")
                      (setf document.hdp-failed-to-load-timer (setTimeout (lambda ()
                                                                            ;; if things go wrong, at least have a timer that brings stuff back in the view
                                                                            (setf document.body.style.margin "0px")
                                                                            (dolist (child document.body.childNodes)
                                                                              (when child.style
                                                                                (setf child.style.display "none")))
                                                                            (setf failed-page.style.display ""))
                                                                          ,+page-failed-to-load-grace-period-in-millisecs+)))
                    (on-load
                     (hdp.reset-scroll-position)
                     (setf hdp.session-id  ,(or (awhen *session* (id-of it)) ""))
                     (setf hdp.frame-id    ,(or (awhen *frame* (id-of it)) ""))
                     (setf hdp.frame-index ,(or (awhen *frame* (frame-index-of it)) "")))))
        ;; NOTE: if javascript is turned on in the browser, then just reload without the marker parameter (this might be true after enabling it and pressing refresh)
        ,(unless javascript-supported?
           (bind ((href (hu.dwim.uri:print-uri-to-string (clone-request-uri :strip-query-parameters (list +no-javascript-error-parameter-name+)))))
             `js-xml(setf window.location.href ,href)))
        <form (:method "post"
               :enctype #.+form-encoding/multipart-form-data+
               ;; NOTE this is needed for default actions.
               ;; Firefox calls onClick on the single :type "submit" input, so it doesn't need anything special.
               ;; Chrome on the other hand simply submits the form, so we need to store an url here that points to the next frame, and render an action-id <input > for default actions. See command rendering for that.
               ,(when *frame*
                  (make-xml-attribute "action"
                                      (bind ((frame-uri (make-uri-for-current-application)))
                                        (setf (hu.dwim.uri:query-parameter-value frame-uri +frame-index-parameter-name+) (next-frame-index-of *frame*))
                                        (hu.dwim.uri:print-uri-to-string frame-uri)))))
          <div (:style "display: none")
            <input (:id #.+scroll-x-parameter-name+ :name #.+scroll-x-parameter-name+ :type "hidden"
                    :value ,(first (ensure-list (parameter-value +scroll-x-parameter-name+))))>
            <input (:id #.+scroll-y-parameter-name+ :name #.+scroll-y-parameter-name+ :type "hidden"
                    :value ,(first (ensure-list (parameter-value +scroll-y-parameter-name+))))>>
          ,@(with-xhtml-body-environment ()
              (render-content-for -self-)
             `js-onload(progn
                         (log.debug "Loaded successfully, clearing the failed to load timer and showing the page")
                         (clearTimeout document.hdp-failed-to-load-timer)
                         (dojo.style document.body "margin" "0px")))>>>))

(def (function e) make-page-icon-uri (asdf-system-name-or-base-directory path-prefix path &key (otherwise nil otherwise?))
  (bind ((base-directory (aif (find-system asdf-system-name-or-base-directory #f)
                              (system-relative-pathname it "www/")
                              asdf-system-name-or-base-directory))
         (file (merge-pathnames path base-directory)))
    (if (uiop:file-exists-p file)
        (list (hu.dwim.uri:parse-uri (string+ path-prefix path))
              (delay (file-write-date file)))
        (handle-otherwise
          (error "~S: the specified page icon (favicon) does not exist, (~S, ~S, ~S)"
                 'make-page-icon-uri asdf-system-name-or-base-directory path-prefix path)))))

(def (function e) make-default-script-uris ()
  (load-time-value
   (list (list (hu.dwim.uri:parse-uri "/hdws/js/main.dojo.js")
               (bind ((file (system-relative-pathname :hu.dwim.web-server "source/js/main.dojo.lisp")))
                 (delay (file-write-date file))))
         (list (hu.dwim.uri:parse-uri "/hdp/js/main.dojo.js")
               (bind ((file (system-relative-pathname :hu.dwim.presentation "source/js/main.dojo.lisp")))
                 (delay (file-write-date file))))
         (list (hu.dwim.uri:parse-uri +js-i18n-broker/default-path+)
               (delay hu.dwim.web-server::*js-i18n-resource-registry/last-modified-at*))
         (list (hu.dwim.uri:parse-uri +js-component-hierarchy-serving-broker/default-path+)
               (delay *js-component-hierarchy-cache/last-modified-at*)))))

(def function %make-stylesheet-uris (asdf-system-name-or-base-directory path-prefix &rest relative-paths)
  (bind ((base-directory (aif (find-system asdf-system-name-or-base-directory #f)
                              (system-relative-pathname it "www/")
                              asdf-system-name-or-base-directory)))
    (iter (for path :in relative-paths)
          (collect (list (hu.dwim.uri:parse-uri (string+ path-prefix path))
                         (bind ((file (assert-file-exists (merge-pathnames path base-directory))))
                           (delay (file-write-date file))))))))

(def (function e) make-default-stylesheet-uris ()
  (flet ((dojo-relative-path (path)
           (hu.dwim.uri:parse-uri (string+ "static/hdws/libraries/" *dojo-directory-name* path))))
    (append
     (mapcar #'dojo-relative-path
             '("dojo/resources/dojo.css"
               "dijit/themes/tundra/tundra.css"))
     (%make-stylesheet-uris :hu.dwim.web-server "static/hdws/"
                            "css/hdws.css")
     (%make-stylesheet-uris :hu.dwim.presentation "static/hdp/"
                            "css/icon.css"
                            "css/border.css"
                            "css/layout.css"
                            "css/widget.css"
                            "css/text.css"
                            "css/lisp-form.css"
                            "css/shell-script.css"
                            "css/presentation.css"))))

(def (function e) make-stylesheet-uris (asdf-system-name-or-base-directory path-prefix &rest relative-paths)
  (append (make-default-stylesheet-uris)
          (apply #'%make-stylesheet-uris asdf-system-name-or-base-directory path-prefix relative-paths)))
