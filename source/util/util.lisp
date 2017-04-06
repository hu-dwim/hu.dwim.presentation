;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.presentation)

;;;;;;
;;; Computation, delay and force

(def class* computation ()
  ()
  (:metaclass funcallable-standard-class))

(def (macro e) delay (&body forms)
  (with-unique-names (computation)
    `(delay* (:class-name computation :variable-name ,computation)
       ,@forms)))

(def (macro e) delay* ((&key class-name variable-name) &body forms)
  (if (and (length= 1 forms)
           (not (consp (first forms)))
           (constantp (first forms)))
      (first forms)
      `(bind ((,variable-name (make-instance ',class-name)))
         (set-funcallable-instance-function ,variable-name (named-lambda delay-body () ,@forms))
         ,variable-name)))

(def (function e) force (value)
  (if (typep value 'computation)
      (funcall value)
      value))

(def (function e) computation? (thing)
  (typep thing 'computation))

(def class* one-time-computation (computation)
  ((value :type t))
  (:metaclass funcallable-standard-class))

(def (macro e) one-time-delay (&body forms)
  (with-unique-names (computation)
    `(delay* (:class-name one-time-computation :variable-name ,computation)
       (if (slot-boundp ,computation 'value)
           (value-of ,computation)
           (setf (value-of ,computation)
                 (progn
                   ,@forms))))))

;;;;;;
;;; Utils

;; TODO maybe rename to js-string-to-lisp-boolean ?
(def function string-to-lisp-boolean (value)
  (eswitch (value :test #'string=)
    ("true" #t)
    ("false" #f)))

(def function string-to-lisp-integer (value)
  (eswitch (value :test #'string=)
    ("true" 1)
    ("false" 0)))

(def function instance-class-name-as-string (instance)
  (class-name-as-string (class-of instance)))

(def function class-name-as-string (class)
  (string-downcase (symbol-name (class-name class))))

(def function function-name (function)
  (etypecase function
    (generic-function (generic-function-name function))
    (function #*((:sbcl (sb-impl::%fun-name function))
                 (t #.(warn "~S is not implemented on your platform" 'function-name)
                    (not-yet-implemented))))))

(def function html-text? (thing)
  (declare (ignore thing))
  ;; TODO or not?
  #t)

;; TODO rename to xhtml-text?
(def (type e) html-text (&optional maximum-length)
  "XHTML formatted text."
  (declare (ignore maximum-length))
  `(and string
        (satisfies html-text?)))

(def function password? (instance)
  (declare (ignore instance))
  #t)

(def (type e) password ()
  `(and string
        (satisfies password?)))

;; TODO use def namespace if possible to make thread-safety portable
;; (def (namespace :test 'equal :finder-name %find-class-for-type) class-for-type)
(def special-variable *find-most-generic-subclass-for-type/cache* (make-hash-table :test #'equal #+sbcl :synchronized #+sbcl #t))

(def function find-most-generic-subclass-for-type (type &key (otherwise :error))
  (or (gethash type *find-most-generic-subclass-for-type/cache*)
      (awhen (or (when (symbolp type)
                   (find-class type nil))
                 ;; NOTE at one point this has been obsoleted by a change in the sbcl internals:
                 ;; https://github.com/sbcl/sbcl/commit/66d35ed03a2360fbcb776b66d3d55bd2bf72cb1a
                 ;; KLUDGE this feels like an ugly kludge. maybe properly parse/interpret the type?
                 (first (sort (bind ((classes (list)))
                                ;; enumerate *every* defined class, using SBCL internals
                                (sb-c::call-with-each-globaldb-name
                                 (lambda (x)
                                   (bind ((class (find-class x nil)))
                                     (when (and class
                                                (not (typep class 'built-in-class))
                                                (subtypep class type))
                                       (push class classes)))))
                                classes)
                              (lambda (class-1 class-2)
                                (subtypep class-2 class-1)))))
        (setf (gethash type *find-most-generic-subclass-for-type/cache*) it))
      (handle-otherwise/value otherwise :default-message (list "~S failed for ~S" -this-function/name- type))))

(def (function i) class-prototype (class)
  (cond
    ;; KLUDGE: SBCL's class prototypes for built in classes are wrong in some cases
    ((subtypep class 'float)
     42.0)
    ((subtypep class 'string)
     "42")
    ((subtypep class 'null)
     nil)
    ((subtypep class 'list)
     '(42))
    ((subtypep class 'array)
     #(42))
    ((subtypep class 'sequence)
     '(42))
    ((subtypep class 'function)
     (lambda ()))
    (t (aprog1 (closer-mop:class-prototype (ensure-finalized class))
         (assert (or (subtypep class 'number)
                     (not (eql it 42))))))))

(def (function i) class-slots (class)
  (closer-mop:class-slots (ensure-finalized class)))

(def (function i) class-precedence-list (class)
  (closer-mop:class-precedence-list (ensure-finalized class)))

(def function remove-undefined-class-slot-initargs (class args)
  (iter (for (arg value) :on args :by 'cddr)
        (when (find arg (class-slots class) :key 'slot-definition-initargs :test 'member)
          (collect arg)
          (collect value))))

(def function trim-suffix (suffix sequence)
  (subseq sequence 0 (- (length sequence) (length suffix))))

(def function filter-slots (names slots)
  (when names
    (collect-if (lambda (slot)
                  (member (slot-definition-name slot) names))
                slots)))

(def function remove-slots (names slots)
  (if names
      (remove-if (lambda (slot)
                   (member (slot-definition-name slot) names))
                 slots)
      slots))

(def function assert-file-exists (file)
  (assert (uiop:file-exists-p file))
  file)

(def constant +timestamp-parameter-name+ "_ts")

(def function append-timestamp-to-uri (uri timestamp)
  (labels ((to-timestamp-string (thing)
             (etypecase thing
               (integer (integer-to-string (mod thing 10000)))
               (local-time:timestamp (to-timestamp-string (local-time:sec-of thing))))))
    (setf (hu.dwim.uri:query-parameter-value uri +timestamp-parameter-name+)
          (to-timestamp-string (force timestamp))))
  uri)

(def function single-argument-layered-method-definer (name forms &key default-layer options whole)
  (when (or (getf options :in)
            (getf options :in-layer))
    (warn "Most probably there's a misplaced layer definition in a ~S; the form is ~S" name whole))
  (bind ((layer (if (member (first forms) '(:in-layer :in))
                    (progn
                      (pop forms)
                      (pop forms))
                    default-layer))
         (qualifier (when (or (keywordp (first forms))
                              (member (first forms) '(and or progn append nconc)))
                      (pop forms)))
         (type (pop forms)))
    `(def (layered-method ,@options) ,name ,@(when layer `(:in ,layer)) ,@(when qualifier (list qualifier)) ((-self- ,type))
          ,@forms)))

(def function owner-class-of-effective-slot-definition (effective-slot)
  "Returns the class to which the given slot belongs."
  #*((:sbcl (slot-value effective-slot 'sb-pcl::%class))
     (t #.(warn "~S is not implemented on your platform" 'owner-class-of-effective-slot-definition)
        (not-yet-implemented))))

;;;;;;
;;; Tree

(def (function o) find-ancestor (node parent-function predicate &key (otherwise nil otherwise?))
  (ensure-functionf parent-function predicate)
  (iter (for current-node :initially node :then (funcall parent-function current-node))
        (while current-node)
        (when (funcall predicate current-node)
          (return current-node))
        (finally (return (handle-otherwise (error "Could not find ancestor component using visitor ~A starting from ~A using parent-function ~A"
                                                  predicate node parent-function))))))

(def (function o) find-root (node parent-function)
  (ensure-functionf parent-function)
  (iter (for current-node :initially node :then (funcall parent-function current-node))
        (for previous-node :previous current-node)
        (while current-node)
        (finally (return previous-node))))

(def (function o) map-parent-chain (node parent-function map-function)
  (ensure-functionf parent-function map-function)
  (iter (for current-node :initially node :then (funcall parent-function current-node))
        (while current-node)
        (funcall map-function current-node)))

(def (function o) map-tree (node children-function map-function)
  (ensure-functionf children-function map-function)
  (map-tree* node children-function
             (lambda (node parent level)
               (declare (ignore parent level))
               (funcall map-function node))))

(def (function o) map-tree* (node children-function map-function &optional (level 0) parent)
  (declare (type fixnum level))
  (ensure-functionf children-function map-function)
  (cons (funcall map-function node parent level)
        (map 'list (lambda (child)
                     (map-tree* child children-function map-function (1+ level) node))
             (funcall children-function node))))

;;;;;;
;;; Dynamic classes

;; TODO FIXME thread safety? use (def namespace ...)?
(def special-variable *dynamic-classes* (make-hash-table :test #'equal))

(def function find-dynamic-class (class-names)
  (assert (every #'symbolp class-names))
  (gethash class-names *dynamic-classes*))

(def function (setf find-dynamic-class) (class class-names)
  (assert (every #'symbolp class-names))
  (setf (gethash class-names *dynamic-classes*) class))

(def function dynamic-class-name (class-names)
  (format-symbol *package* "~{~A~^&~}" class-names))

(def function dynamic-class-metaclass (class-names)
  (bind ((metaclasses (mapcar (lambda (class-name)
                                (class-of (find-class class-name)))
                              class-names)))
    (unless (all-the-same? metaclasses)
      (error "~S was called with classes of not the same metaclass" 'dynamic-class-metaclass))
    (first metaclasses)))

(def function ensure-dynamic-class (class-names)
  (ensure-class (dynamic-class-name class-names) :direct-superclasses class-names :metaclass (dynamic-class-metaclass class-names)))

(def method make-instance ((class-names list) &rest args)
  (bind ((class (find-dynamic-class class-names)))
    (unless class
      (setf class (ensure-dynamic-class class-names))
      (setf (find-dynamic-class class-names) class))
    (apply #'make-instance class args)))

(def macro ensure-instance (place type &rest args &key &allow-other-keys)
  `(aif ,place
        (reinitialize-instance it ,@args)
        (setf ,place (make-instance ,type ,@args))))

;;;;;
;;; Hash set

(def function make-hash-set-from-list (elements &key (test #'eq) (key #'identity))
  (ensure-functionf key test)
  (prog1-bind set
      (make-hash-table :test test)
    (dolist (element elements)
      (setf (gethash (funcall key element) set) element))))
