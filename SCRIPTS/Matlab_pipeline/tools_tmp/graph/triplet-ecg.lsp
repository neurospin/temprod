;;
;; A triplet display
;;
;; A display with three display areas.
;;
;;
;; $Revision: 1.1 $
;;
;; $Log: triplet.lsp,v $
;; Revision 1.1  2007/07/25 12:43:57  mjk
;; Initial revision
;;
;;
;;

(require "std-selections-vv")
(require "channel-selection")

(provide "triplet-ecg")

(defvar triplet-form          nil "Main window form")
(defvar triplet-pane          nil "paned window for displays")
(defvar triplet-menu          nil "Menu for triplet commands")
(defvar triplet-print-button  nil "Button to print the triplet")
(defvar triplet-print-button1 nil "Button to print the triplet display 1.")
(defvar triplet-print-button2 nil "Button to print the triplet display 2.")
(defvar triplet-print-button3 nil "Button to print the triplet display 3.")
(defvar triplet-dump-button   nil "Button to dump the triplet as tiff file")
(defvar triplet-meg-menu      nil "Menu to control MEG  selections")
(defvar triplet-eeg-menu      nil "Menu to control EEG  selections")
(defvar triplet-misc-menu     nil "Menu to control MISC selections")

(defvar message-line-in-main nil "Message line (X-widget) in the main window.")

;; Lists describing the different sets of displays that are displayd 
;; simultaneously.

(defparameter triplet-list0 nil "Static part")
(defparameter triplet-list1 nil "Dynamic triplet 1")


(defparameter triplet-displays nil "List of all display G-widgets")

(define-parameter-group 'displays "Parameters of the triplet display.")

(defuserparameters displays
  (scroll-delay    1     "Scroll delay in sec."   'integer)
  (default-ecg-amp 1E-3  "Default ECG amplitude." 'number)
  (default-eog-amp 1E-4  "Default EOG amplitude." 'number)
  (default-eeg-amp 1E-6  "Default EEG amplitude." 'number)
  (default-meg-amp 3E-11 "Default MEG amplityde"  'number)
  )


(defun add-to-triplet (triplet def)
  "Add new subdisplay to the display set.
   Usage: (add-to-triplet <display-set> <definition>)
   Description:
   This adds a new display to given display-set (a symbol containing
   list of displays).
   The structure of a definition is a list of following elements:
   1) name 
   2) top position       (percent of the display display height)
   3) bottom position    (percent of the display display height)
   4) left edge position (percent of the display display width)
   5) display on the right side, if any.
   6) Do we display the scroll bar of this display?
   7) Name of the display
"
  (let* ((name (car def))
	 (dform (or (get (G-widget name :quiet) :display-form)
		    (make-form triplet-pane "displayForm")))
	 (disp (or (G-widget name :quiet)
		   (if (sixth def)
		       (GtMakeObject 'plotter :name name
				     :display-parent dform
				     :scroll-parent  triplet-form)
		     (GtMakeObject 'plotter :name name
				   :display-parent dform))))
	 (y0 (second def))
	 (y1 (third def))
	 (x0 (fourth def))
	 (rw (if (fifth def)
		 (resource (G-widget (fifth def)) :display-widget)
	       nil))
	 (title (seventh def))
	 (label (or (get disp :label)
		    (if title (put disp :label (XmCreateLabel dform "label" (X-arglist) 0)))))
	 dispw)

    (put disp :display-form dform)
    (set-resource disp :scroll-visible -1 :no-controls t)
    (set-resource disp :move-hook   '(eval (append '(sync-view *this*) triplet-displays)))
    (set-resource disp :select-hook '(eval (append '(sync-selection *this*) triplet-displays)))
    (GtPopupEditor disp)
    (setq dispw (resource disp :display-widget))
    (set triplet (append (symbol-value triplet) (list dispw)))
    (setq triplet-displays (append triplet-displays (list disp)))
    (put dispw :label label)
    (set-values dispw
		"resizable"        0
		"leftAttachment"   XmATTACH_FORM
		"leftOffset"       110
		"rightAttachment"  (if rw XmATTACH_WIDGET XmATTACH_FORM)
		(if rw "rightWidget" "rigthPosition")
		(if rw rw 110)
		"topAttachment"    XmATTACH_FORM
		"topOffset"	   (if label 0 0) ;;20 0)
;;		"bottomAttachment" XmATTACH_POSITION
		"bottomAttachment" XmATTACH_FORM
		"bottomPosition"   y1
		"bottomOffset"     -3
		)
    (if label
	(set-values label
		    "resizable"        0
		    "leftAttachment"   XmATTACH_FORM
		    "rightAttachment"  XmATTACH_WIDGET
		    "rightWidget"      dispw
		    "rightOffset"      0 ;(if rw -80 -120)
		    "topAttachment"    XmATTACH_FORM
		    "bottomAttachment" XmATTACH_FORM
		    ))

    (when title
      (setq title (XmString title))
      (set-values label "labelString" title))

    (if label (manage label))
    (manage dform)
    dispw
    )
  )
    

(defun build-triplet-display()
  "Build a triplet display
   Usage: (build-triplet-display)"
  
  (when (G-widget "display" :quiet)
    (GtDeleteWidget (G-widget "display")))
  
  (unless triplet-form
    (setq triplet-form (make-form *main-window* "tripletForm"))
    (set-values *main-window* "workWindow" triplet-form))
  (unmanage triplet-form)

  (unless triplet-pane
    (setq triplet-pane (XmCreatePanedWindow triplet-form "tripletPane" (X-arglist) 0))
    (set-values triplet-pane
		"separatorOn"      0
		"sashIndent"       -1
		"topAttachment"    XmATTACH_FORM
		"bottomAttachment" XmATTACH_FORM
		"leftAttachment"   XmATTACH_FORM
		"rightAttachment"  XmATTACH_FORM
		"bottomOffset" 20 )
    )
  ;;  (unmanage triplet-pane)
  
  (add-to-triplet 'triplet-list0 '("triplet1"  0 80  0 nil t   "MEG"))
  (add-to-triplet 'triplet-list0 '("triplet2" 81 90  0 nil nil "ECG raw"))
  (add-to-triplet 'triplet-list0 '("triplet3" 91 97  0 nil nil "ECG trg"))
  
  (set-resource (G-widget "triplet1") :background "white")
  (set-resource (G-widget "triplet1") :default-color "black")
  (set-resource (G-widget "triplet1") :highlight "pink")
  (set-resource (G-widget "triplet1") :baseline-color "grey")

  (set-resource (G-widget "triplet2") :background "white")
  (set-resource (G-widget "triplet2") :default-color "black")
  (set-resource (G-widget "triplet2") :highlight "pink")
  (set-resource (G-widget "triplet2") :baseline-color "grey")

  (set-resource (G-widget "triplet3") :background "white")
  (set-resource (G-widget "triplet3") :default-color "black")
  (set-resource (G-widget "triplet3") :highlight "pink")
  (set-resource (G-widget "triplet3") :baseline-color "grey")
  
  (set-values (resource (G-widget "triplet1") :scroll-widget)
	      "bottomAttachment" XmATTACH_FORM
	      "leftAttachment"   XmATTACH_FORM
	      "rightAttachment"  XmATTACH_FORM
	      "rightOffset" 10
	      "leftOffset" 110 )
  (set-resource (G-widget "triplet1") :scroll-visible 1)
  
  (apply 'manage triplet-list0)
;;  (apply 'manage triplet-list1)

  (manage triplet-pane)
  (manage triplet-form)
  )


(defun popup-tripletlist(list)
  (dolist (this list)
    (manage this)
    (manage (get this :label)))
)

(defun popdown-tripletlist(list)
  (dolist (this list)
    (unmanage this)
    (unmanage (get this :label)))
)


;(defun select-triplet(number)
; "Select which items to show"
 
; (case number
;   (1 (popup-tripletlist triplet-list1)
;      (popdown-tripletlist triplet-list2)
;      (popdown-tripletlist triplet-list3)
;      (popdown-tripletlist triplet-list4)
;      )
;   (2 (popup-tripletlist triplet-list2)
;      (popdown-tripletlist triplet-list1)
;      (popdown-tripletlist triplet-list3)
;      (popdown-tripletlist triplet-list4)
;      )
;   (3 (popup-tripletlist triplet-list3)
;      (popdown-tripletlist triplet-list1)
;      (popdown-tripletlist triplet-list2)
;      (popdown-tripletlist triplet-list4)
;      )
;   (4 (popup-tripletlist triplet-list4)
;      (popdown-tripletlist triplet-list1)
;      (popdown-tripletlist triplet-list2)
;      (popdown-tripletlist triplet-list3)
;      )
;   )
; )


(defun page-triplet()
  "Page views ahead
   Usage: (page-triplet)"
  
  (let* ((w (G-widget "triplet1"))
	 (start (resource w :point))
	 (len (resource w :length)))
    (dolist (x triplet-displays)
      (set-resource x :point (+ start len)))
    )
  )


(defun scroll-triplet()
  "Page ahead continuously
   Usage: (scroll-triplet)"
  
  (do ()
      ((not (longworking "Scrolling ahead..." 1 2)) t)
    (page-triplet)
    (sleep scroll-delay))
  )


(defun popup-disp()
  (sync-view      "triplet1" "display")
  (sync-selection "triplet1" "display")
  (GtPopupEditor (G-widget "display"))
)


(defun triplet-default-scales()
  "Set default scales to displays
   Usage: (triplet-default-scales)
   This sets the scales of the displays according to default
   values defined in parameters menu."
  
  (let ((megs     (list (first triplet-displays)))
	(ecgrawdisp  (second triplet-displays))
	(ecgtrgdisp  (third triplet-displays))
	(exg-amps (make-matrix 50 1 10.0)))
    
    (vset exg-amps  0 default-eog-amp)
    (vset exg-amps  1 default-eog-amp)
    (vset exg-amps  3 default-ecg-amp)
    (dolist (meg megs) (set-resource (G-widget meg) :scales (make-matrix 50 1 default-meg-amp)))
    (set-resource (G-widget ecgrawdisp) :scales (make-matrix 3 1 default-ecg-amp))
    (set-resource (G-widget ecgtrgdisp) :scales (make-matrix 3 1 default-ecg-amp))
    )
  )


(defun triplet-scale(relative)
  "Change scale in selected displays
   Usage: (triplet-scale relative)
   This function scales selected channels with given factor.
   This applies to all triplet displays that have some channels selected on."

  (dolist (disp triplet-displays)
    (let ((selected (resource disp :port-selection))
	  scales)
      (when selected
	(setq scales (resource disp :scales))
	(dolist (port selected)
	  (vset scales port (* relative (vref scales port))))
	(set-resource disp :scales scales)))
    )
  )


(defparameter triplet-goto-help
  "The program asks you to give the time point where to move the view.
   Give a proper time in seconds. The default given is the
   current time.")


(defun triplet-goto()
  "Interactive time move"

  (let ((time (question "Give time to jump to"
			(format nil "~f" (resource (G-widget "triplet1") :point))
			triplet-goto-help) ))
    (when time
      (setq time (read-from-string time))
      (if (not (numberp time))
	  (error "Bad time: ~s" time))
      (dolist (x triplet-displays)
	(set-resource x :point time))
      )
    )
  )


(defparameter triplet-length-help
  "The proram asks you to give new length for the displays.
   Give a proper time in seconds. The default given is the
   current length.")


(defun triplet-length()
  "Interactive setting of length of displays"

  (let ((len (question "Give new length for displays"
			(format nil "~f" (resource (G-widget "triplet1") :length))
			triplet-length-help) ))
    (when len
      (setq len (read-from-string len))
      (if (not (numberp len))
	  (error "Bad length: ~s" len))
      (dolist (x triplet-displays)
	(set-resource x :length len))
      )
    )
  )
    

(defun remove-bad-channels()
  "Remove selected MEG channels from views"
  
  (let (these selected name some-anon)
    (dolist (disp triplet-displays)
      (when (setq these (resource disp :port-selection))
	(dolist (this these)
	  (if (setq name (get-property disp this :name))
	      (setq selected (cons name selected))
	    (setq some-anon t)))))
    (when selected
      (set-resource (G-widget "meg")
		    :ignore (append (resource (G-widget "meg") :ignore) selected))
      )
    (if some-anon
	(error "Some anonymous channels were selected!"))
    )
  )


(defun triplet-view-all()
  (set-resource (G-widget "meg") :ignore nil))


(defun print-triplet(&key header (comment " ") (display :all))
  "Print display triplet
   Usage: (print-triplet &key header display)
   This function prints the display triplet. It uses user parameters
   print-display-reverse and print-display-printer to define 
   format and printer."
  
  (print-window
   :id      (cond ((eq display :all) (window-id (XtWindow triplet-form)))
		  ((G-widget display :quiet) (resource (G-widget display) :graphics-window-id))
		  (t (error "print-triplet: Bad display argument: ~s" display)))

   :header  (or header 
	       (str-append (default-data-header (G-widget "triplet1")) " "))
   :trailer comment
   :reverse print-display-reverse
   :printer print-display-printer)
  )
)


(defun save-triplet ()
  "Save display as a tiff file."
   
  (dump-window :interactive :id  (window-id (XtWindow triplet-pane)))
)


(defun triplet-menu()
  "Create the triplet menu"

  (unless triplet-menu
    (setq triplet-menu (make-menu *display-menu* "Views" nil
				:tear-off
				'("Scroll"         (scroll-triplet))
				'("Go to..."       (triplet-goto))
				'("Length..."      (triplet-length))
				:----
				'("Default scales" (triplet-default-scales))
				'("Bigger"         (triplet-scale 0.7))
				'("Smaller"        (triplet-scale 1.4))
				:----
				'("Remove bad" (remove-bad-channels))
				'("View all"   (triplet-view-all))
				:----
				'("Chop"   (info (make-evoked-file)))
				)))
  
  (unless triplet-print-button
    (setq triplet-print-button
	  (add-button *file-menu* "Print display" '(print-triplet))))

  (unless triplet-print-button1
    (setq triplet-print-button1
	  (add-button *file-menu* "Print display1" '(print-triplet :display "triplet1"))))
  (unless triplet-print-button2
    (setq triplet-print-button2
	  (add-button *file-menu* "Print display2" '(print-triplet :display "triplet2"))))
  (unless triplet-print-button3
    (setq triplet-print-button3
	  (add-button *file-menu* "Print display3" '(print-triplet :display "triplet3" ))))
  
  (unless triplet-dump-button
    (setq triplet-dump-button
	  (add-button *file-menu* "Save display (TIFF)" '(save-triplet))))
  )


(export 'dump-window)


(defun convert-picture-file(file from output to)
  "Convert picture file format
   Usage: (convert-picture-file file from-format output output-format)
   This routine uses external programs to convert
   picture file formats."
  
  (let ((temp (tempnam nil "pic")))
    
    (cond
     
     ((eq from to)
      (system (format nil "cp ~a ~a" file output)))
     
     ((and (eq from :xwd) (eq to :tiff))
      (when (not (eql 0 (system (format nil "/neuro/bin/util/xwdtopnm ~a >~a" file temp))))
	(delete-file temp)
	(error "Conversion failed, conversion from xwd to pnm failed!"))
      (when (not (eql 0 (system (format nil "/neuro/bin/util/pnmtotiff ~a >~a" temp output))))
	(delete-file temp)
	(error "Conversion failed, conversion from pnm to tiff failed!"))
      (delete-file temp)
      )

     (t (error "convert-picture-file: Sorry, don't know how to convert from ~a to ~a" from to)) 
     )
    )
  )
  

(defun set-proper-extension(file format)
  "Add a suitable filename extension to given name
   Usage: (set-proper-extension file format)"
  
  (case format 
    (:xwd  (change-extension file "xwd"))
    (:tiff (change-extension file "tiff"))
    (:pnm  (change-extension file "pnm")))
  )


(defun dump-window(filename &key id (format :tiff))
  "Dump a window int a file.
   Syntax: (dump-window filename &key id format)
   This function dumps a window into a file using system commands.
   It writes the window pixmap to temporary file and converts it
   into requested format.
   If no window id is given, then the window is pointed by the
   cursor. Ensure that there are no dialogs etc on top of the window.
   The filename may also be :interactive to request the program to 
   prompt user for the name."


  (when (null filename)
    (error "dump-window: no filename"))
  (when (eq filename :interactive)
    (setq filename (ask-filename "Give output filename, please"
				 :new t
				 :default (set-proper-extension "windowdump" format)))
    (if (null filename)
	(error "Window dump was cancelled!"))
    (XmUpdateDisplay *main-menu-bar*)
    (sleep 1)
    (XmUpdateDisplay *main-menu-bar*)
    )
  
  (let (command 
	(result (set-proper-extension filename format))
	(temp (tempnam nil "pic")))
    
    (cond
     (id
      (system (format nil "xwd -id ~d >~a" id temp)))
     (t
      (info "After removing this, Wait until the cursor changes to a
 cross and click the window that should be printed.")
      (XmUpdateDisplay *main-menu-bar*)
      (sleep 1)
      (XmUpdateDisplay *main-menu-bar*)
      (system (format nil "xwd >~a" temp))
      )
     )

    (with-status (format nil "Saving into file ~a" result)
      (convert-picture-file temp :xwd result format)
      (delete-file temp))
    )
  )


(defun make-triplet-eeg-selection-menu(menu-bar name accelerator pick disp)
  "Make a new selection menu
   Usage: (make-selection-menu menu-bar name accelerator pick display)
   Make a selection menu into menu-bar. This menu controls pick widget 'pick'
   and display 'display'. These may be either names or widgets."
  
  (let* ((smenu (make-menu menu-bar name accelerator :tear-off))
	 (dmenu (make-menu smenu "Device" "D"))
	 menu)
        
    (add-separator smenu)
    (setq menu (list smenu (list pick disp) (list dmenu) nil nil))
    (rebuild-selection-menu selection-default-device menu)
    menu)
  )


(defun triplet-change-meg-label (defs pick plot)
  "Hook function to change meg display label."
  (set-values (get (G-widget "triplet1") :label) :labelString (XmString (car defs))))

(defun triplet-change-eeg-label (defs)
  "Hook function to change eeg display label."
  (set-values (get (G-widget "triplet2") :label) :labelString (XmString (car defs))))

;;
;; Actions on loading 
;;
;;

(with-status "Building displays..." (build-triplet-display))
(triplet-menu)
(setq triplet-meg-menu (make-selection-menu *display-menu* "MEG selection" "M" "pick" "triplet1"))
(setq search-displays triplet-displays)
(setq channel-selection-hook 'triplet-change-meg-label)
(setq derivation-change-hook 'triplet-change-eeg-label)