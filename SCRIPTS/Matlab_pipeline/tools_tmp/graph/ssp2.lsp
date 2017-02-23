;;------------------------------------------------------------------------
;;  Linear projetion utilities for analysis and interference suppression.
;;
;;  Copyright (c) 1995-2008 Neuromag Ltd 
;;  All rights reserved
;;
;; $Id: ssp.lsp,v 1.8 2008/06/13 11:38:18 mjk Exp $
;;
;; This module contains a utility to easily apply linear projection
;; operations on data. This module uses suppressor widget called ssp
;; to perform the operations. To use this package, you should also use
;; setup that contains this ssp widget in a suitable place.
;;
;;------------------------------------------------------------------------
(in-package "graph")
(provide "ssp2")
(require "simple-edit-string")

(setq ssp-symbols
      '(ssp-on
	ssp-off
	ssp-popup
	ssp-add-vectors
	ssp-dialog
	ssp-actions-menu
	ssp-edit-menu
	ssp-file-menu
	ssp-vector-directory))

(export ssp-symbols)
(shadowing-import ssp-symbols (find-package "user"))

(require-widget 'suppressor "ssp")

(defvar ssp-on nil
  "Is the SSP projection operation active?")

;;
;; Note ssp definition is currently a list (name matrix [:description <desc>])
;;

(defvar ssp-vectors nil 
  "List of vectors defining noisy signal space in SSP")

(defvar ssp-vector-pool nil
  "List of potentially useful signal space vectors with their names")

(defvar ssp-dialog nil
  "Dialog for contolling SSP operation")

(defvar ssp-popup-button
  (if *motif* (add-button *command-menu* "SSP dialog ..." '(ssp-popup)) nil)
  "Button used to popup ssp-dialog.")

(defvar ssp-vector-list  nil "List widget to show active ssp-vectors")
(defvar ssp-pool-list    nil "List widget to show ssp-vector pool")
(defvar ssp-vector-label nil "Label on top of the ssp vector list")

(defuserparameter ssp-vector-directory
  (neuromag-file "ssp/")
  "Directory template XmDirectoryList to be with load/save commands of ssp."
  'string
  'misc-defaults) ;; ssp-build.lsp:


(defun ssp-vector-dir-template()
  "Utility to get working template for ssp files"
  (if (file-exists-p ssp-vector-directory)
      (format nil "~a/*.fif" ssp-vector-directory)
    "./*.fif")
)


(defmacro ssp-add(list name data &key description)
  "Push suitable list structure to tail of a list"
  (list 'setq list
	(list 'nconc
	      list
	      (list 'list
		    (list 'list name data :description description))))
  )


(defun ssp-remove-space(&rest spaces)
  "Define space removed by SSP
   Usage: (ssp-remove-space &rest spaces)
   This function directs projection system to remove certain subspace from
   signal space. The space is defined by a set of vectors or matrices
   spanning the complement of the desired subspace. The vectors are
   normalized before setting the bad-space, so that their scale should
   not affect the results. If no arguments are given, then the removed
   space is reset to nil. This routine should be the only way used to change
   the active SSP projection vectors in ssp suppressor. Otherwise the SSP
   software will be unaware of the changes and gets out of sync with reality.
   If linear widget called timevar exists, the current space vectors are
   installed in it, so that the output reflects the time variation of
   the signal vectors. The time variations represent multipliers needed to
   multiply the original signal vectors to achieve best match to current
   signal vector. Also if  a linear widget called remove exists,
   the current orhogonalized space vectors are set as the transformation
   matrix of the widget.
"
  (with-status "Recalculating ..."
    (on-error (ssp-refresh-lists t nil)
      (if spaces 
	  (let* ((bs (apply (function mat-append) spaces))
		 (scaled (multiple-value-list (nnormalize-columns bs)))
		 (obs (orthogonalize (first scaled))))
	    (set-resource (G-widget "ssp" "ssp module needs this widget!") "bad-space" obs)
	    (if (G-widget "ssp2" :quiet)
 		(set-resource (G-widget "ssp2" "ssp2 module needs this widget!") "bad-space" obs))
	    (setq ssp-on t)
	    (if (G-widget "removed" :quiet)
		(set-resource (G-widget "removed") :transformation obs))
	    (if (G-widget "timevar" :quiet)
		(set-resource (G-widget "timevar") :transformation 
			      (ntranspose 
			       (nweight-matrix 
				(inverse (first scaled) :if-singular :accept)
				(map-matrix (second scaled) #'finverse))
			       )))
	    )
	(progn
	  (set-resource (G-widget 'ssp) "bad-space" (setq ssp-on nil))
	  (if (G-widget "removed" :quiet)
	      (set-resource (G-widget "removed") :transformation nil))
	  (if (G-widget "timevar" :quiet)
	      (set-resource (G-widget "timevar") :transformation nil))
	  )
	)
      (ssp-refresh-lists t nil)
      )
    )
  )


(defun remove-gradient-space(source)
  "Remove the gradient space of given widget
   Usage: (remove-gradient-space source)
   Utility to remove that homogneous gradient space from the signals.
   See also: ssp-remove-space"

  (ssp-remove-space (gradient-space (G-widget source "Bad source in remove-gradient-space")))
  )


(defun ssp-rebuild-space()
  "Rebuild bad-space matrix
   Usage: (ssp-rebuild-space)
   This function rebuilds SSP projection from list of vector
   definitions in ssp-vectors and activates this projection"

  (let ((vectors nil))
    (dolist (v ssp-vectors)
      (push (second v) vectors))
    (eval (cons 'ssp-remove-space (nreverse vectors))))
  )


(defun ssp-clear-vectors()
  "Clear ssp vectors
   Usage: (clear-ssp-vectors)
   This clears current SSP vectors."
  (setq ssp-vectors nil)
  (ssp-remove-space))


(defun ssp-on()
  "Activate SSP
   Usage: (ssp-on)
   This activates current SSP vectors when SSP is turned off. Note
   that this save symbol is also a variable that tells if the SSP is on."
  (unless ssp-on
    (ssp-rebuild-space))
)


(defun ssp-off()
 "Deactivate SSP
  Usage: (ssp-off)
  This turns the SSP off but does not throw away the vectors.
  Current vectors can again be activated using (ssp-on)."

 (if ssp-on (ssp-remove-space)))


(defun ssp-popup()
  "Popup SSP dialog
   Usage: (ssp-popup)"
  (if ssp-dialog (manage ssp-dialog) (ssp-create-dialog))
  )


(defun ssp-create-dialog()
  
  "Create a Motif SSP dialog
   Usage: (ssp-create-dialog)
   This routine creates the main dialog that is used to control working
   of SSP. It contains menu bar two lists in a dialog box. Lists 
   represent the active SSP vectors and a pool ov vectors that may prove
   useful. This routine is not intended to be called directly by user."
  
  (apply 'manage
	 (reverse
    (list
     (setq ssp-dialog (make-form-dialog *application-shell* "sspDialog"
					:autoUnmanage 0))

     (setq ssp-menu-bar (make-menu-bar ssp-dialog "sspMenuBar"
				       :rightAttachment XmATTACH_FORM
				       :leftAttachment XmATTACH_FORM
				       :topAttachment XmATTACH_FORM))
     
     (setq ssp-pool-frame (make-frame ssp-dialog "sspPoolFrame"
				       :topAttachment XmATTACH_WIDGET
				       :topWidget ssp-menu-bar
				       :bottomAttachment XmATTACH_FORM
				       :leftAttachment XmATTACH_FORM 
				       :rightAttachment XmATTACH_POSITION
				       :rightPosition 45))

     (setq ssp-pool-label (make-label ssp-pool-frame "sspPoolLabel"
				       :labelString (XmString "Vector pool")
				       :childType XmFRAME_TITLE_CHILD))

     (setq ssp-pool-list (XmjkLispList ssp-pool-frame "sspPoolList"
					'ssp-list-printer
					:listSizePolicy XmCONSTANT
					:selectionPolicy XmEXTENDED_SELECT))
       
     (setq ssp-vector-frame (make-frame ssp-dialog "sspVectorFrame"
					:topAttachment XmATTACH_WIDGET
					:topWidget ssp-menu-bar
					:bottomAttachment XmATTACH_FORM
					:rightAttachment XmATTACH_FORM
					:leftAttachment XmATTACH_POSITION
					:leftPosition 55))
     (setq ssp-vector-label (make-label ssp-vector-frame "sspVectorLabel"
				      :labelString (XmString "SSP vectors OFF")
				      :childType XmFRAME_TITLE_CHILD))
     
     (setq ssp-vector-list (XmjkLispList ssp-vector-frame "sspVectorList"
					 'ssp-list-printer
					 :listSizePolicy XmCONSTANT
					 :selectionPolicy XmEXTENDED_SELECT))

     (setq ssp-add-button (make-button ssp-dialog "sspAddButton"
				       :labelString (XmString "->")
				       :topAttachment XmATTACH_WIDGET
				       :topWidget ssp-menu-bar
				       :topOffset 30
				       :rightAttachment XmATTACH_WIDGET
				       :rightWidget ssp-vector-frame
				       :rightOffset 5
				       :leftAttachment XmATTACH_WIDGET
				       :leftWidget ssp-pool-frame
				       :leftOffset 5
				       ))
     
     (setq ssp-delete-button (make-button ssp-dialog "sspDeleteButton"
					  :labelString (XmString "Clr")
					  :topAttachment XmATTACH_WIDGET
					  :topWidget ssp-add-button
					  :topOffset 5
					  :rightAttachment XmATTACH_WIDGET
					  :rightWidget ssp-vector-frame
					  :rightOffset 5
					  :leftAttachment XmATTACH_WIDGET
					  :leftWidget ssp-pool-frame
					  :leftOffset 5))

     (setq ssp-on-button (make-button ssp-dialog "sspOnButton"
				      :labelString (XmString "On")
				      :topAttachment XmATTACH_WIDGET
				      :topWidget ssp-delete-button
				      :topOffset 5
				      :rightAttachment XmATTACH_WIDGET
				      :rightWidget ssp-vector-frame
				      :rightOffset 5
				      :leftAttachment XmATTACH_WIDGET
				      :leftWidget ssp-pool-frame
				      :leftOffset 5))

     (setq ssp-off-button (make-button ssp-dialog "sspOnButton"
				       :labelString (XmString "Off")
				       :topAttachment XmATTACH_WIDGET
				       :topWidget ssp-on-button
				       :topOffset 5
				       :rightAttachment XmATTACH_WIDGET
				       :rightWidget ssp-vector-frame
				       :rightOffset 5
				       :leftAttachment XmATTACH_WIDGET
				       :leftWidget ssp-pool-frame
				       :leftOffset 5))
     
     (setq ssp-file-menu
	   (make-menu ssp-menu-bar "File" nil 
		      '("Default directory" (cd-path 'ssp-vector-directory))
		      '("Save"   (ssp-save-file))
		      '("Load"   (ssp-load-file nil t))
		      '("Close"  (unmanage ssp-dialog)))
	   
	   ssp-edit-menu
	   (make-menu ssp-menu-bar "Edit" nil
		      '("Delete selected" (ssp-delete-selected))
		      :----
		      '("Add to SSP"      (ssp-add-selected))
		      '("Clear SSP"       (ssp-clear-vectors))
		      :----
		      '("Explode"         (ssp-explode-selected))
		      '("Implode"         (ssp-implode-selected))
		      :----
		      '("Edit name"        (ssp-edit-name))
		      '("Edit description" (ssp-edit-description))
		     )
	   
	   ssp-check-menu
	   (make-menu ssp-menu-bar "Check" nil
		      '("Check lengths"           (ssp-check-lengths))
		      '("Check angle"             (ssp-check-angle))
		      '("Check angle to subspace" (ssp-check-angle-to-space))
		      )
	   
	   ssp-actions-menu
	   (make-menu ssp-menu-bar "Actions" nil
		      '("Add pointed field"   (ssp-pick-vector)))
	   ))
    )
   )

  (when-module "pca"
    (make-menu ssp-actions-menu "Add PCA fields" nil
	       '(" 1 vector"   (ssp-add-pca 1))
	       '(" 2 vectors"  (ssp-add-pca 2))
	       '(" 3 vectors"  (ssp-add-pca 3))
	       '(" 5 vectors"  (ssp-add-pca 5))
	       '(" 8 vectors"  (ssp-add-pca 8))
	       '("12 vectors"  (ssp-add-pca 12))
	       '(" N vectors"  (ssp-add-pca))))
  
  (add-lisp-callback ssp-pool-list "defaultActionCallback"
		     '(ssp-show-description ssp-pool-list))
  
  (add-lisp-callback ssp-vector-list "defaultActionCallback"
		     '(ssp-show-description ssp-vector-list))

  (add-lisp-callback ssp-add-button "activateCallback" '(ssp-add-selected))

  (add-lisp-callback ssp-delete-button "activateCallback" 
		     '(ssp-delete-selected :active))
  
  (add-lisp-callback ssp-on-button "activateCallback" '(ssp-on))
  (add-lisp-callback ssp-off-button "activateCallback" '(ssp-off))

  (ssp-refresh-lists t t)
  )


(when *motif*
  (defparameter ssp-on-label (XmString "SSP vectors ON"))
  (defparameter ssp-off-label (XmString "SSP vectors OFF")))


(defun ssp-list-printer(x)
  "Lisp->Text converter
   Usage: (ssp-list-printer)
   This function is used to convert projection list items to textual form
   in XmjkLispList widgets."
  (let ((data (second x)))
    (format nil "~a [~d,~d]"
	    (string (first x))
	    (array-dimension data 0)
	    (array-dimension data 1) )
    )
  )


(defun ssp-refresh-lists(vecs pool)
  "Update SSP list widgets
   Usage: (ssp-refresh-lists vecs pool)
   Update ssp lists. The lists which should be updated are defined by
   parameters vec and pool, correrponding to active vector list and 
   vector pool list."
  
  (when (and *motif* ssp-dialog)
    (if vecs (XmjkLispListSet ssp-vector-list ssp-vectors))
    (if pool (XmjkLispListSet ssp-pool-list ssp-vector-pool))
    (if ssp-on 
	(set-values ssp-vector-label :labelString ssp-on-label)
      (set-values ssp-vector-label :labelString ssp-off-label))
    )
  )


(defun ssp-pick-vector(&optional source time name)
  
  "Pick one SSP vector from data
   Usage: (ssp-pick-vector &optional source time name)
   This routine adds an vector to the list of vectors defining the
   noisy space removed by SSP. If no arguments are given, the data
   is taken from the source of widget 'ssp' at time defined by the
   current x-selection. Vectors are normalized before being added to 
   space definition list. In addition, the vector can be tagged with name
   which is asked by default from the user."
  
  (let ((sel (x-selection))
	(help "SSP vectors have names so that it is
               easier to manipulate them later on.
               The name does not have to be unique."))
    
    (if (and sel (/= (second sel) 0))
	(error "Too long selection for pick-ssp-vector, should be one point"))
    (setq source (G-widget (or source (widget-source (G-widget "ssp")))
			   "Source for SSP data is not defined and widget~@
                            ssp has no source linked!"))
    (unless (setq time (or time (first sel)))
      (error "No time point selected to to define the vector"))

    (format t " ~s ~s ~s ~%" source time name)
    (setq data (get-data-matrix source (x-to-sample source time) 1))
    
    (when (or name (setq name (question "Give name to this vector" "Field" help)))
      (nnormalize-columns data)
      (ssp-add ssp-vectors name data)
      (ssp-add ssp-vector-pool name data)
      (ssp-refresh-lists nil t) ;; only pool, vecs go automatically.
      (ssp-rebuild-space)
      )
    )
  )


(defun ssp-add-selected()
  "Add selected vector from ssp-vector-pool
   Usage: (ssp-add-selected)
   This function allowes user to select some vectors from the
   ssp-vector-pool and add them in to the active ssp vectors."
  
  (let ((sel (XmjkLispListSelected ssp-pool-list))
	(len (length ssp-vectors)))
    
    (dolist (this sel)
      (setq ssp-vectors (reverse (adjoin this (reverse ssp-vectors)))))
    (if (/= (length ssp-vectors) len)
	(ssp-rebuild-space))
    )
  )


(defun ssp-delete-selected(&optional (which :pool))
  "Delete selected projections
   Usage: (ssp-delete-selected &optional which)
   This routine deletes selected vectors either in pool or in active vector
   list. The argument which defines which ones are deleted. Arument may have
   values :pool :active"
  
  (if (not (member which '(:pool :active)))
      (error "ssp-delete-selected: bad value for argument 'which': ~s" which))
  
  (when (and (eq which :pool) (XmjkLispListSelected ssp-pool-list)
	     (yes-or-no-p "Shall we really delete the selected pool vectors"))
    (XmjkLispListDelete ssp-pool-list)
    (setq ssp-vector-pool (XmjkLispListGet ssp-pool-list))
    )
  
  (when (eq which :active)
    (if (XmjkLispListSelected ssp-vector-list)
	(when (yes-or-no-p "Shall we really delete the selected SSP vectors")
	  (XmjkLispListDelete ssp-vector-list)
	  (setq ssp-vectors (XmjkLispListGet ssp-vector-list))
	  (ssp-rebuild-space))
      (when (yes-or-no-p "Shall we clear all active vectors")
	(ssp-clear-vectors)
	(setq ssp-vectors (XmjkLispListGet ssp-vector-list))
	(ssp-rebuild-space)))
    )
  )


(defun ssp-explode-selected()
  "Explode selected projections
   Usage: (ssp-explode-selected)
   This routine changes a projection operator defining a multidimensional
   space to individual vectors."
  
  (when (and (XmjkLispListSelected ssp-pool-list)
	     (yes-or-no-p "Shall we really explode the selected pool vectors"))
    (let ((tobeexp (XmjkLispListSelected ssp-pool-list))
	  exploaded dim)
      (XmjkLispListDelete ssp-pool-list)
      (setq ssp-vector-pool (XmjkLispListGet ssp-pool-list))
      (dolist (this tobeexp)
	(if (> (setq dim (array-dimension (second this) 1)) 1)
	    (dotimes (col dim)
	      (push (list (str-append (first this)(format nil "-v~d" (1+ col)))
			  (column col (second this)))
		    exploaded))
	  (push this exploaded))
	)
      (setq ssp-vector-pool (append ssp-vector-pool (nreverse exploaded)))
      (ssp-refresh-lists nil t)
      )
    )
  )


(defun ssp-implode-selected(&optional name)
  "Collect selected vecotrs to a matrix
   Usage: (ssp-implode-selected)"
  
  (let ((tobe (XmjkLispListSelected ssp-pool-list)) result)
    (when (> (length tobe) 1)
      (unless name
	(setq name (question "Give name to the imploded projection" "SpaceX")))
      (when name
	(XmjkLispListDelete ssp-pool-list)
	(setq ssp-vector-pool (XmjkLispListGet ssp-pool-list))
	(ssp-add ssp-vector-pool name (apply 'mat-append (mapcar 'second tobe)))
	(ssp-refresh-lists nil t)
	)
      )
    )
  )


(defun ssp-add-vectors(matrix name &optional active)
  "Add some matrix into SSP vector pool
   Usage: (ssp-add-vectors matrix name &optional active)
   This routine creates a list compatible with SSP system from given
   data and adds it into ssp vector pool. The name of the projection
   is given as the second argument. If the parameter active is not null
   (the default) the new vectors will be automatically added into the
   active vectors too."
  
  (unless name (setq name "Anonymous"))
  
  (unless (and (matrixp matrix)(stringp name))
    (error "ssp-add-vetor: Bad matrix or name was given: ~s, ~s"
	   matrix name))
  
  (ssp-add ssp-vector-pool name matrix)
  (when active
    (ssp-add ssp-vectors name matrix)
    (ssp-rebuild-space))
  
  (ssp-refresh-lists nil t)
  )


(defun ssp-add-pca(&optional n)
  "Add some PCA vectors to SSP
   Usage: (ssp-add-pca & optional n)
   This routine picks n vectors from pca-fields (defined in 
   module pca) and inserts them into the vector pool. If the number
   of components is not given, it will be asked from the user."
  
  (if (not (boundp 'pca-fields))
      (error "Variable pca-fields has no value. ~@
              Probably the pca module is not loadad."))
  
  (unless pca-fields (error "No PCA fields available"))
  
  (when (null n)
    (setq n (question "How many components?" "1"
		      "Please state how many (largest) PCA components you would
like to add to the projection."))
    (when n
      (setq n (read-from-string n))
      (if (not (integerp n))(error "The number of components must be an integer!"))
      )
    )
  (when n
    (ssp-add ssp-vector-pool "PCA" (truncate-columns pca-fields n))
    (ssp-refresh-lists nil t)
    )
)


(defun ssp-edit-name()
  "Edit ssp vector description
   Usage: (ssp-edit-vector-description)
   This starts an interactive editor on selected pool item for changing
   the description string related to a ptojection. There sould be only one
   item selected."
  
  (let ((item (XmjkLispListSelected ssp-pool-list))
	text)
    (if (> (length item) 1)
	(error "Too many projections selected!"))
    
    (when (setq item (car item))
      (if (not (stringp (car item)))
	  (error "ssp-edit-name: Can't find the name!"))
      (setq text (car item))
      (when (setq text 
		  (question "Give new name to projection" text
			    "Here you can give a new name to the selected
projection. The name should be short but
descriptive. It doesn't need to be unique.")
		  )
	(rplaca item text)
	(setq ssp-vector-pool (XmjkLispListGet ssp-pool-list))
	(ssp-refresh-lists nil t))
      )
    )
  )


(defun ssp-edit-description()
  "Edit ssp vector description
   Usage: (ssp-edit-vector-description)
   This starts an interactive editor on selected pool item for changing
   the description string related to a ptojection. There sould be only one
   item selected."
  
  (let ((item (XmjkLispListSelected ssp-pool-list))
	point text)
    (if (> (length item) 1)
	(error "Too many projections selected!"))
    
    (when (setq item (car item))
      (setq point (member :description item))
      (if point
	  (if (not (and (cdr point)
			(or (stringp (second point)) (null (second point)))))
	      (error "ssp-edit-description: Cant find the description!"))
	(rplacd (last item) (setq point (list :description nil))))
      (setq text (second point))
      (when (simple-edit-string 'text)
	(rplaca (cdr point) text)
	(setq ssp-vector-pool (XmjkLispListGet ssp-pool-list))
	(ssp-refresh-lists nil t))
      )
    )
  )


(defun ssp-show-description(list)
  "Show description of selected projection
   Usage: (ssp-show-description list)"
  
  (let ((item (car (XmjkLispListSelected list))) name description)
    (when (and item
	       (setq name (first item))
	       (setq description (second (member :description item))))
      (info "Description of Projection Item ~s~%------------------------------------~%~a"
	    name description)))
  )



(defun ssp-load-file(&optional filename concat)
  "Read graph/xfit generated signal vectors from a file
   Usage: (read-ssp-vectors &optional filename concat)
   This routine reads given file and assumes that it contains
   vectors created by Xfit or Graph. Vectors are put in variable
   ssp-vector-pool. New vectors replace the old value of ssp-vector-pool
   unless the parameter concat is set to non nil value, which causes new
   vectors to be concatenated to the old ones. Files loaded may be either
   fif files containing projection informatin or a lisp file. In lisp files
   the vectors may be either row (generated with Xfit) or column vectors
   (generated with Graph)."
  
  (let* ((file (or filename (ask-filename "Give filename to load projections from"
					  :template (ssp-vector-dir-template))))
	 (extension (filename-extension file))
	 apu)

    (if file
	(cond 
	 
	 ((equal extension "fif")
	  (setq ssp-vector-pool
		(append (if concat ssp-vector-pool nil)
			(mapcar 'GtExplodeProjection (GtFiffLoadProj file)))))
     
	 ((equal extension "lsp")
	  (setq file (open file))
	  (setq apu (read file))
	  (close file)
	  (if (and (listp apu) (listp (car apu))(matrixp (second (car apu))))
	      (progn
		(dolist (def apu)
		  (rplaca def (string (car def)))
		  (if (apply #'< (array-dimensions (second def)))
		      (ntranspose (second def))))
		(if concat
		    (setq ssp-vector-pool (nconc ssp-vector-pool apu))
		  (setq ssp-vector-pool apu)))
	    (error "Bad xfit vector file")))
	 
	 (t (error "ssp-load: Dont know how to load file with extension ~s"
		   extension))
	 ))
    (ssp-refresh-lists t t)
    )
  )


(defun ssp-some-pool-vectors()
  "Return all or selected pool vectors"
  
  (let ((item (XmjkLispListSelected ssp-pool-list)))
    (cond (item) (ssp-vector-pool)))
  )
  


(defun ssp-save-file(&optional filename)
  "Save current SSP vectors as lisp
   Usage: (ssp-save-file &optional filename)
   This function writes current SSP vectors in given file. The format
   of the file depends on the extension of the filename! If the extension
   is .lsp, the data will be saves as lisp text. If the extension is .fif,
   fif format will be used. Other extension will cause an error.
   If the filename is not defined it will be asked interactively."
  
  (if (and filename (file-exists-p filename))
      (unless (yes-or-no-p "File ~s exists, shall we replace the file?" filename)
	(setq filename nil)))
  
  (if (not filename)
      (setq filename
	    (ask-filename 
	     (format nil 
		     "Give filename for saving ~:[all~;selected~] SSP vectors"
		     (XmjkLispListSelected ssp-pool-list))
	     :new t :if-exists :ask
	     :template (ssp-vector-dir-template))))
  
  (when filename
    (cond

     ((equal (filename-extension filename) "fif")
      (GtFiffSaveProj filename (mapcar 'ssp-apply-make-projection (ssp-some-pool-vectors)))
      ;;
      ;; Use add_proj_namelist to add the channel names.
      ;;
      (let ((tmp (change-extension (tempnam nil "graph") "fif")))
	(make-evoked-file :filename tmp :source "ssp"
			  :selection (list (x-start "ssp") 0.05)) 
	(system (format nil "~a -f ~a ~a" (utility-program "add_proj_namelist") tmp filename))
	(delete-file tmp))
      )
     
     ((equal (filename-extension filename) "lsp")
      (let ((file (open filename :direction :output :if-exists :supersede)))
	(format file ";;~%;; SSP vectors generated by Graph~%;;~%")
	(print-array (ssp-some-pool-vectors) file)
	(close file)))
     
     (t (error "ssp-save-file: bad file extension, must be .fif or .lsp!"))
     )
    )
  )


(defun ssp-apply-make-projection(item)
  "Conversion utility
   Usage: (ssp-apply-make-projection item)
   This function assumes that the given items is suitable to be
   a argument list for GtMakeProjection and converts is to corresponding
   projection."
  (apply 'GtMakeProjection item))



(defun ssp-check-lengths()
  "Check SSP vector lengths
   Usage: (ssp-check-lengths)
   This routines displays the lengths of selected vectors in the
   vector pool."

  (let ((sel (XmjkLispListSelected ssp-pool-list))
	(out (make-string-output-stream)))
    (cond
     ((null sel)(info "Nothing was selected in the vector pool"))
     (t
      (dolist (vecdef sel)
	(let ((vec (second vecdef)))
	  (format out "~a :~%" (first vecdef))
	  (dotimes (col (array-dimension vec 1))
	    (format out "  length = ~e ~%" (vec-length (column col vec))))))
      (info "~a" (get-output-stream-string out))
      (close out))
     )
    )
  )


(defun ssp-check-angle-to-space()
  "Check SSP vector angle to the current subspace
   Usage: (ssp-check-angle-to-space)
   This routines displays the angles of selected vectors to the
   current projection space."
  
  (let ((sel (XmjkLispListSelected ssp-pool-list))
	(out (make-string-output-stream))
	space)
    (cond
     ((null sel)(info "Nothing was selected in the vector pool"))
     (t
      (dolist (v ssp-vectors)
	(push (second v) space))
      (unless (setq space (apply #'mat-append space))
	(error "Projection subspace is not defined"))
      
      (dolist (vecdef sel)
	(let ((vec (second vecdef)))
	  (format out "~a :~%" (first vecdef))
	  (dotimes (col (array-dimension vec 1))
	    (format out "    angle to projection space = ~f ~%" 
		    (vec-angle-to-subspace (column col vec) space)))))
      (info "~a" (get-output-stream-string out))
      (close out))
     )
    )
  )


(defun ssp-check-angle()
  "Check angle between SSP pool vectors
   Usage: (ssp-check-angle)
   This routines displays the lengths of selected vectors in the
   vector pool."

  (let ((sel (XmjkLispListSelected ssp-pool-list)))
    (cond
     ((/= (length sel) 2)(info "You should select 2 vectors from the pool!"))
     ((info "Angle = ~f deg" (vec-angle (cadar sel)(cadadr sel)))))
    )
  )



(defun vec-angle-to-subspace(vector space)
  "Check angle between vector and a subspace
   Usage: (ssp-angle-to-subspace vector space)"
  
  (vec-angle 
   (* (projection space) vector)
   vector)
  )



(defun vec-length(v1)
  "Calculate vector length
   Usage: (vector-length vec)
   This calculates the length of a vector."
  
  (sqrt (* (ata v1) 1))
)


(defun vec-angle(v1 v2)
  "Calculate angle between two vectors
   Usage: (vector-angle vec1 vec2)"

  (if (or (> (array-dimension v1 1) 1)
	  (> (array-dimension v2 1) 1))
      (error "vec-angle: Angle not yet defined for matrices, sorry"))
  
  (if (/= (length v1) (length v2))
      (error "vector-angle: vectors must have equal lengths"))
  
  (if (or (= (vec-length v1) 0) (= (vec-length v2) 0))
      0.0
    (* 180 (/ 1.0 pi)
       (acos (min (/ (* (atb v1 v2) 1)(vec-length v1)(vec-length v2)) 1))))
  )
