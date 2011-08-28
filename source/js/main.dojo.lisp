;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :hu.dwim.presentation)

(log.debug "Started evaluating main.js of hu.dwim.presentation")

(defmacro with-new-dom-nodes (bindings &BODY body)
  (ITER (FOR binding :IN bindings)
        (BIND (((variable-name tag-name &KEY class) binding))
          (COLLECT `(,variable-name (document.createElement ,tag-name)) :INTO node-bindings)
          (WHEN class
            (COLLECT `(dojo.addClass ,variable-name ,class) :INTO forms)))
        (FINALLY (RETURN `(bind (,@node-bindings)
                            ,@forms
                            ,@body)))))

(dojo.getObject "hdp" #t)
(dojo.getObject "hdp.io" #t)
(dojo.getObject "hdp.field" #t)
(dojo.getObject "hdp.help" #t)

;;;;;;
;;; io

(defun hdp.io.lazy-context-menu-handler (event connection href id parent-id)
  ((hdws.io.make-action-event-handler
    href
    :ajax true
    :subject-dom-node parent-id
    :send-client-state false
    :sync true
    :on-success (lambda (event connection)
                  (aif (dijit.byId id)
                       ;; TODO why does it ever happen that the ajax answer is empty?
                       ;; TODO don't use dojo internals. find a way to reinvoke the same event, or make sure some other way that the context menu comes up
                       (._scheduleOpen it event.target nil (create :x event.pageX :y event.pageY))
                       (log.error "Context menu was not found after processing the ajax answer (empty ajax answer?). The id we looked for is " id))))
   event connection))

;;;;;;
;;; highlight

(defun hdp.highlight-mouse-enter-handler (event (element :by-id))
  (dojo.addClass element "highlighted")
  (let ((parent element.parent-node))
    (while (not (= parent document))
      (dojo.removeClass parent "highlighted")
      (setf parent parent.parent-node)))
  (dojo.stopEvent event))

(defun hdp.highlight-mouse-leave-handler (event (element :by-id))
  (dojo.removeClass element "highlighted"))

;;;;;
;;; fields

;; TODO rename to hdp.primitive.*? or something else...
;; TODO convert to using &key? see others, too...
(defun hdp.field.setup-simple-checkbox (checkbox-id disabled checked-tooltip unchecked-tooltip)
  (bind ((checkbox (dojo.byId checkbox-id))
         (hidden (dojo.byId (+ checkbox-id "_hidden"))))
    (log.debug "Setting up simple checkbox " checkbox ", using hidden input " hidden)
    (unless disabled
      (hdws.connect checkbox "onchange"
                    (lambda (event)
                      (let ((enabled checkbox.checked))
                        (log.debug "Propagating checkbox.checked of " checkbox " to the hidden field " hidden " named " hidden.name)
                        (setf hidden.value (if enabled
                                               "true"
                                               "false"))
                        (setf checkbox.title
                              (if enabled
                                  checked-tooltip
                                  unchecked-tooltip))))))
    (setf checkbox.hdp-set-checked (lambda (enabled)
                                     (if (= checkbox.checked enabled)
                                         (return false)
                                         (progn
                                           (setf checkbox.checked enabled)
                                           ;; we need to be in sync, so call onchange explicitly
                                           (checkbox.onchange)
                                           (return true)))))
    (setf checkbox.hdp-is-checked (lambda ()
                                    (return checkbox.checked)))))

(defun hdp.field.setup-custom-checkbox (link-id disabled checked-image unchecked-image checked-tooltip unchecked-tooltip checked-class unchecked-class)
  ;; FIXME i think it's completely bitrotten...
  (bind ((link (dojo.byId link-id))
         (hidden (dojo.byId (+ link-id "_hidden"))))
    (log.debug "Setting up custom checkbox " link ", using hidden input " hidden)
    (bind ((image (aref (.get-elements-by-tag-name link "img") 0))
           (checked (not (= hidden.value "false"))))
;; TODO:      (assert image)
      (if (and checked-image
               unchecked-image)
          (setf image.src (if checked
                              checked-image
                              unchecked-image)))
      (setf link.className (if checked
                               checked-class
                               unchecked-class))
      (setf link.title (if checked
                           checked-tooltip
                           unchecked-tooltip)))
    (setf link.hdp-set-checked (lambda (checked)
                                 (setf hidden.value (if checked
                                                        "true"
                                                        "false"))
                                 (if (and checked-image
                                          unchecked-image)
                                     (setf image.src (if checked
                                                         checked-image
                                                         unchecked-image)))
                                 (setf link.className (if checked
                                                          checked-class
                                                          unchecked-class))
                                 (setf link.title (if checked
                                                      checked-tooltip
                                                      unchecked-tooltip))))
    (setf link.hdp-is-checked (lambda ()
                                (return (not (= hidden.value "false")))))
    (setf link.name hidden.name)        ; copy name of the form input
    (setf link.onclick (lambda (event)
                         (link.hdp-set-checked (not (link.hdp-is-checked)))))))

(defun hdp.field.update-popup-menu-select-field ((node :by-id) (field :by-id) value class)
  (if class
      (setf node.className class)
      (setf node.innerHTML value))
  (setf field.value value))

(defun hdp.field.update-use-in-filter ((field :by-id) value)
  ;; TODO disable, or make transparent the other controls, too
  (field.hdp-set-checked value))

(defun hdp.field._setup-filter-field (widget-id use-in-filter-id)
  ;; for now it's shared between a few fields...
  (on-load
   (bind ((widget (dijit.byId widget-id))
          (listener (lambda ()
                      (hdp.field.update-use-in-filter use-in-filter-id (!= "" (.getValue this))))))
     (assert widget)
     ;; TODO why not hdws.connect?
     (widget.connect widget "onKeyUp" listener)
     (widget.connect widget "onChange" listener))))

(defun hdp.field.setup-string-filter (widget-id use-in-filter-id)
  (hdp.field._setup-filter-field widget-id use-in-filter-id))

(defun hdp.field.setup-number-filter (widget-id use-in-filter-id)
  (hdp.field._setup-filter-field widget-id use-in-filter-id))

;;;;;;
;;; generic function

(defun hdp.create-generic-function (name)
  (bind ((generic-function (create)))
    (setf generic-function.name name)
    (return generic-function)))

(defun hdp.register-generic-function-method (generic-function dispatch-type fn)
  (setf (slot-value generic-function dispatch-type) fn))

(defun hdp.apply-generic-function (generic-function dispatch-type args)
  (bind ((class-precedence-list (slot-value hdp.component-class-precedence-lists dispatch-type)))
    (assert class-precedence-list)
    (dolist (class class-precedence-list)
      (bind ((fn (slot-value generic-function class)))
        (when fn
          (return (fn.apply undefined args)))))))

;;;;;;
;;; setup component

(setf hdp.setup-component-generic-function (hdp.create-generic-function))

(defun hdp.register-component-setup (type fn)
  (hdp.register-generic-function-method hdp.setup-component-generic-function type fn))

(defun hdp.setup-component (id type &rest args &key &allow-other-keys)
  (hdp.apply-generic-function hdp.setup-component-generic-function type (array id args)))

;;;;;;
;;; Context sensitive help

(setf hdp.help.popup-timeout 400)
(setf hdp.help.timer nil)

(defun hdp.help.decorate-url (url id)
  (if (or (= id "")
          (= id undefined))
      (return url)
      (return (hdp.append-query-parameter url #.(escape-as-uri +context-sensitive-help-parameter-name+) id))))

(defun hdp.help.make-mouseover-handler (url)
  (return
    (lambda (event)
      (clearTimeout hdp.help.timer) ; safe to call with garbage
      (setf hdp.help.timer
            (setTimeout (lambda ()
                          (bind ((decorated-url url)
                                 (node event.target)
                                 (help hdp.help.tooltip))
                            (while (not (= node document))
                              (setf decorated-url (hdp.help.decorate-url decorated-url node.id))
                              (setf node node.parent-node))
                            (when (or (= help nil)
                                      (and help.has-loaded
                                           (not (= help.href decorated-url))))
                              (hdp.help.teardown)
                              (setf help (new dojox.widget.DynamicTooltip
                                              (create :connectId (array event.target)
                                                      :position (array "below" "right")
                                                      :href decorated-url)))
                              (setf hdp.help.tooltip help)
                              (help.open event.target))))
                        hdp.help.popup-timeout))
      (dojo.stopEvent event))))

(defun hdp.help.setup (event url)
  (bind ((handles (array))
         (aborter (lambda (event)
                    (dojo.style document.body "cursor" "default")
                    (foreach 'dojo.disconnect handles)
                    (hdp.help.teardown)
                    (dojo.stopEvent event))))
    (handles.push (hdws.connect document "mouseover" (hdp.help.make-mouseover-handler url)))
    (handles.push (hdws.connect document "click" aborter))
    (handles.push (hdws.connect document "keypress" (lambda (event)
                                                      (when (= event.charOrCode dojo.keys.ESCAPE)
                                                        (aborter event)))))
    (dojo.style document.body "cursor" "help")
    (dojo.stopEvent event)))

(defun hdp.help.teardown ()
  (when hdp.help.tooltip
    (hdp.help.tooltip.destroy)
    (setf hdp.help.tooltip nil)
    (when hdp.help.timer
      (clearTimeout hdp.help.timer)
      (setf hdp.help.timer nil))))

;;;;;;
;;; Border

(defun hdp.attach-border ((element :by-id) style-class element-name)
  (if element
      (bind ((parent-element element.parentNode)
             (next-sibling element.nextSibling)
             (table-element (make-dom-node "table")))
        (if (or (not style-class)
                (not element-name)
                (and (not (= element-name true))
                     (not (= element-name element.tagName))))
            (return element))
        (if (dojo.isArray style-class)
            (dolist (one-class style-class)
              (dojo.addClass table-element one-class))
            (dojo.addClass table-element style-class))
        (progn
          ;; KLUDGE: we copy the id on the border not to confuse ajax what should be replaced
          (setf table-element.id element.id)
          (setf element.id ""))
        (flet ((create-dummy-div ()
                 (bind ((result (document.createElement "div")))
                   (dojo.addClass result "decoration")
                   (return result)))
               (create-row (row-kind)
                 (with-new-dom-nodes ((row-kind-element (+ "t" row-kind))
                                      (row-element "tr")
                                      (left-cell-element "td" :class "border-left")
                                      (cell-element "td" :class "border-center")
                                      (right-cell-element "td" :class "border-right"))
                   (when (= row-kind "head")
                     (dojo.place (create-dummy-div) left-cell-element "only")
                     (dojo.place (create-dummy-div) right-cell-element "only"))
                   (when (= row-kind "body")
                     (dojo.place (create-dummy-div) left-cell-element "only")
                     (dojo.place (create-dummy-div) right-cell-element "only"))
                   (dojo.place row-kind-element table-element)
                   (dojo.place row-element row-kind-element)
                   (dojo.place left-cell-element row-element)
                   (dojo.place cell-element row-element)
                   (dojo.place right-cell-element row-element)
                   (return cell-element))))
          (create-row "head")
          (bind ((cell-element (create-row "body")))
            (create-row "foot")
            (dojo.place element cell-element)
            (if next-sibling
                (dojo.place table-element next-sibling "before")
                (dojo.place table-element parent-element)))))
      (log.warn "Cannot attach border to element")))

;;;;;;
;;; End of story

(log.debug "Finished evaluating main.js of hu.dwim.presentation")
