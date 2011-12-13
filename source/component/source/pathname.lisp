;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.presentation)

;;;;;;
;;; pathname/alternator/inspector

(def (component e) pathname/alternator/inspector (t/alternator/inspector)
  ())

(def subtype-mapper *inspector-type-mapping* (or null pathname iolib.pathnames:file-path) pathname/alternator/inspector)

(def layered-method make-alternatives ((component pathname/alternator/inspector) class (prototype pathname) value)
  (make-alternatives/pathname value #'call-next-layered-method))

(def layered-method make-alternatives ((component pathname/alternator/inspector) class (prototype iolib.pathnames:file-path) value)
  (make-alternatives/pathname value #'call-next-layered-method))

(def function make-alternatives/pathname (value next-method)
  (bind (((:values file? file-type) (etypecase value
                                      (pathname
                                       (values (pathname-name value)
                                               (%guess-file-type (namestring value)
                                                                 (pathname-type value))))
                                      (iolib.pathnames:file-path
                                       (values (iolib.pathnames:file-path-file-name value)
                                               (%guess-file-type (iolib.pathnames:file-path-namestring value)
                                                                 (iolib.pathnames:file-path-file-type value))))
                                      (null (values)))))
    (optional-list* (when (and value
                               (not file?))
                      (make-instance 'pathname/directory/tree/inspector :component-value value))
                    (when (eq file-type :text)
                      (make-instance 'pathname/text-file/inspector :component-value value))
                    (when (member file-type '(:asd :lisp))
                      (make-instance 'pathname/lisp-file/inspector :component-value value))
                    (when (eq file-type :binary)
                      (make-instance 'pathname/binary-file/inspector :component-value value))
                    (funcall next-method))))

(def (function e) %guess-file-type (file-path-namestring file-type)
  ;; TODO: KLUDGE: not portable, etc.
  (switch (file-type :test #'string=)
    ("asd" :asd)
    ("lisp" :lisp)
    ("txt" :text)
    ("text" :text)
    (t
     ;; TODO the runtime consequences of this are a bit heavy...
     #*((:sbcl
         (bind ((result (with-output-to-string (output)
                          (sb-ext:run-program "/usr/bin/file" (list (namestring file-path-namestring)) :output output))))
           (cond ((search "text" result) :text)
                 (t :binary))))
        (t :binary)))))

;;;;;;
;;; pathname/text-file/inspector

(def (component e) pathname/text-file/inspector (t/detail/inspector content/widget)
  ())

(def refresh-component pathname/text-file/inspector
  (bind (((:slots component-value content) -self-))
    (setf content (read-file-into-string (iolib.pathnames:file-path-namestring component-value)))))

(def render-xhtml pathname/text-file/inspector
  (with-render-style/mixin (-self- :element-name "pre")
    (render-content-for -self-)))

;;;;;;
;;; pathname/binary-file/inspector

(def (component e) pathname/binary-file/inspector (t/detail/inspector content/widget)
  ())

(def refresh-component pathname/binary-file/inspector
  (bind (((:slots component-value content) -self-))
    (setf content (with-output-to-string (string)
                    (iter (for index :from 1)
                          (for byte :in-vector (read-file-into-byte-vector (iolib.pathnames:file-path-namestring component-value)))
                          (format string "~2,'0',X " byte)
                          (when (zerop (mod index 40))
                            (terpri string)))))))

(def render-xhtml pathname/binary-file/inspector
  (with-render-style/mixin (-self- :element-name "pre")
    (render-content-for -self-)))

;;;;;;
;;; pathname/lisp-file/inspector

(def (component e) pathname/lisp-file/inspector (t/detail/inspector content/widget)
  ())

(def refresh-component pathname/lisp-file/inspector
  (bind (((:slots component-value content) -self-))
    (setf content (make-instance 't/lisp-form/inspector
                                 :component-value (read-file-into-string
                                                   (iolib.pathnames:file-path-namestring component-value))))))

;;;;;;
;;; pathname/directory-tree/inspector

(def (component e) pathname/directory/tree/inspector (t/tree/inspector)
  ())

(def layered-method make-node-presentation ((component pathname/directory/tree/inspector) class (prototype pathname) (value pathname))
  (make-instance 'pathname/directory/node/inspector :component-value value))

;;;;;;
;;; pathname/directory/node/inspector

(def (component e) pathname/directory/node/inspector (t/node/inspector)
  ())

(def layered-method collect-presented-children ((component pathname/directory/node/inspector) class (prototype pathname) value)
  (sort (copy-list (directory (merge-pathnames "*.*" value))) #'string< :key #'namestring))

(def layered-method make-node-presentation ((component pathname/directory/node/inspector) class (prototype pathname) value)
  (if (pathname-name value)
      (make-instance 'pathname/file/node/inspector :component-value value :expanded #f)
      (make-instance 'pathname/directory/node/inspector :component-value value :expanded #f)))

(def layered-method collect-presented-children ((component pathname/directory/node/inspector) class (prototype iolib.pathnames:file-path) value)
  (sort (iolib.os:list-directory value) #'string< :key #'iolib.pathnames:file-path-namestring))

(def layered-method make-node-presentation ((component pathname/directory/node/inspector) class (prototype iolib.pathnames:file-path) value)
  (if (iolib.os:file-exists-p value)
      (make-instance 'pathname/file/node/inspector :component-value value :expanded #f)
      (make-instance 'pathname/directory/node/inspector :component-value value :expanded #f)))

;;;;;;
;;; pathname/file/node/inspector

(def (component e) pathname/file/node/inspector (t/node/inspector)
  ())

(def layered-method collect-presented-children ((component pathname/file/node/inspector) class (prototype pathname) value)
  nil)
