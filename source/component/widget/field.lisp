;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.presentation)

;;;;;;
;;; Checkbox field

(def (function e) render-checkbox-field (value &key checked-image unchecked-image (id (unique-js-name "_chkb"))
                                               checked-tooltip unchecked-tooltip
                                               checked-class unchecked-class
                                               on-change name value-sink (preprocess-value #t) (disabled #f))
  "PREPROCESS-VALUE means that the js value is turned into a lisp value using STRING-TO-LISP-BOOLEAN."
  (check-type disabled boolean)
  (assert (or (and (null checked-image) (null unchecked-image))
              (and checked-image unchecked-image)))
  (assert (not (and name value-sink)))
  (assert (or disabled name value-sink) () "you must provide either a NAME or a VALUE-SINK argument to ~S unless it's a DISABLED one" 'render-checkbox-field)
  (when (typep name 'client-state-sink)
    (setf name (id-of name)))
  (bind ((name (unless disabled
                 (if name
                     (etypecase name
                       (client-state-sink (id-of name))
                       (string name))
                     (progn
                       (assert (functionp value-sink))
                       (id-of (if preprocess-value
                                  (client-state-sink (client-value)
                                    (funcall value-sink (string-to-lisp-boolean client-value)))
                                  (client-state-sink (client-value)
                                    (funcall value-sink client-value))))))))
         (custom (or checked-image checked-class))
         (hidden-id (string+ id "_hidden"))
         (checked (when value "")))
    (unless disabled
      <input (:id ,hidden-id
                  :name ,name
                  :value ,(if value "true" "false")
                  :type "hidden")>)
    (if custom
        ;; FIXME i think it's completely bitrotten...
        (progn
          ;; TODO :tabindex (tabindex field)
          ;; :class (style-class field)
          ;; handle :disabled
          <div (:id ,id)
            ,(if (and checked-image
                      unchecked-image)
                 ;; TODO cleanup... <img> tags are not allowed without an alt, but this is pure confusion here...
                 <img>)>
          `js-onload(hdp.field.setup-custom-checkbox ,id ,disabled ,checked-image ,unchecked-image ,checked-tooltip ,unchecked-tooltip ,checked-class ,unchecked-class))
        (progn
          ;; TODO :accesskey (accesskey field)
          ;; :title (or (tooltip field) (if value
          ;;                                (enabled-tooltip-of field)
          ;;                                (disabled-tooltip-of field)))
          ;; :tabindex (tabindex field)
          ;; :class (style-class field)
          ;; :style (style field)
          <input (:id ,id
                  :type "checkbox"
                  :checked ,checked
                  ,(when disabled
                     (make-xml-attribute "disabled" "disabled"))
                  ,(maybe-make-xml-attribute "onChange" on-change))>
          `js-onload(hdp.field.setup-simple-checkbox ,id ,disabled ,checked-tooltip ,unchecked-tooltip))))
  (values))

;;;;;;
;;; String field

(def function render-string-field (type value client-state-sink &key (id (generate-unique-component-id "_stw")) on-change on-key-down on-key-up)
  ;; TODO dojoRows 3
  (render-dojo-widget (+dijit/text-box+ () :id id)
    <input (:type     ,type
            :id       ,-id-
            :name     ,(id-of client-state-sink)
            :value    ,value
            ,(maybe-make-xml-attribute "onChange" on-change)
            ,(maybe-make-xml-attribute "onKeyDown" on-key-down)
            ,(maybe-make-xml-attribute "onKeyUp" on-key-up))>))

;;;;;;
;;; Number field

(def function render-number-field (value client-state-sink &key (id (generate-unique-component-id "_nrw")) on-change on-key-down on-key-up)
  (render-dojo-widget (+dijit/number-text-box+ () :id id)
    <input (:type     "text"
            :id       ,-id-
            :name     ,(id-of client-state-sink)
            :value    ,value
            ,(maybe-make-xml-attribute "onChange" on-change)
            ,(maybe-make-xml-attribute "onKeyDown" on-key-down)
            ,(maybe-make-xml-attribute "onKeyUp" on-key-up))>))

;;;;;;
;;; Combo box

(def function render-combo-box-field (value possible-values &key (id (generate-unique-component-id "_w")) name
                                            (key #'identity) (test #'equal) (client-name-generator #'princ-to-string))
  <select (:id ,id
           :name ,name)
    ,(iter (for index :upfrom 0)
           (for possible-value :in-sequence possible-values)
           (for actual-value = (funcall key possible-value))
           (for client-name = (funcall client-name-generator actual-value))
           (for client-value = (integer-to-string index))
           (for selected = (when (funcall test value actual-value) "yes"))
           <option (:value ,client-value :selected ,selected)
                   ,client-name>)>)

;;;;;;
;;; Select field

(def function render-select-field (value possible-values &key (id (generate-unique-component-id "_w")) name
                                         (key #'identity) (test #'equal) (client-name-generator #'princ-to-string) on-change)
  (render-dojo-widget (+dijit/filtering-select+ () :id id)
    <select (:id ,-id-
             :name ,name
             ,(maybe-make-xml-attribute "onChange" on-change))
      ;; TODO the qq patch "xml: add optimizations that collapse xml tags even when a macro and list qq is also involved" breaks this
      ;; add a qq test that triggers this
      ,(iter (for index :upfrom 0)
             (for possible-value :in-sequence possible-values)
             (for actual-value = (funcall key possible-value))
             (for client-name = (funcall client-name-generator actual-value))
             (for client-value = (integer-to-string index))
             (for selected = (when (funcall test value actual-value) "yes"))
             <option (:value ,client-value :selected ,selected) ,client-name>)>)
  (values))

;;;;;;
;;; Upload file

(def function render-upload-file-field (&key (id (generate-unique-component-id)) access-key tooltip tab-index
                                             class style client-state-sink (name (awhen client-state-sink (id-of it))))
  <input (:id ,id
          :class ,class
          :style ,style
          :name ,name
          :accesskey ,access-key
          :type "file"
          :title ,tooltip
          :tabindex ,tab-index)>)

;;;;;;
;;; Popup menu select field

(def function render-popup-menu-select-field (value possible-values &key value-sink classes (test #'equal) (key #'identity))
  (bind ((div-id (generate-unique-component-id))
         (field-id (generate-unique-component-id))
         (name (id-of (client-state-sink (client-value)
                        (funcall value-sink client-value))))
         (index (position value possible-values :key key :test test)))
    <input (:id ,field-id :type "hidden" :name ,name :value ,value)>
    <div (:id ,div-id :class ,(nth index classes))
      ,(unless classes
         value)
      ,(render-dojo-widget (+dijit/menu+ `(:left-click-to-open ,`js-piece true :target-node-ids ,`js-piece(array ,div-id)))
        <div (:id ,-id-
              :style "display: none;")
          ,(iter (for possible-value :in possible-values)
                 (for class :in classes)
                 (render-dojo-widget (+dijit/menu-item+ `(:icon-class ,class))
                   <div (:id ,-id-
                         :onClick `js-inline(hdp.field.update-popup-menu-select-field ,div-id ,field-id ,possible-value ,class))
                     ,possible-value>))>)>))
