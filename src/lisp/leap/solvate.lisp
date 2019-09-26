(in-package :leap.solvate)


(defun tool-build-solute-array (matter)
  (let ((x-vec (make-array 10 :element-type 'double-float :fill-pointer 0 :adjustable t))
        (y-vec (make-array 10 :element-type 'double-float :fill-pointer 0 :adjustable t))
        (z-vec (make-array 10 :element-type 'double-float :fill-pointer 0 :adjustable t))
        (dx 0)
        (dy 0)
        (dz 0)
        (dxmax -1000000)
        (dymax -1000000)
        (dzmax -1000000)
        (dxmin 1000000)
        (dymin 1000000)
        (dzmin 1000000))
    (chem:map-atoms
     'nil
     (lambda (atom)
       (let ((pos (chem:get-position atom)))
         (setf dx (geom:vx pos)
               dy (geom:vy pos)
               dz (geom:vz pos))
         (vector-push-extend dx x-vec)
         (vector-push-extend dy y-vec)
         (vector-push-extend dz z-vec)
         (when (> dx dxmax)
           (setf dxmax dx))
         (when (> dy dymax)
           (setf dymax dy))
         (when (> dz dzmax)
           (setf dzmax dz))
         (when (< dx dxmin)
           (setf dxmin dx))
         (when (< dy dymin)
           (setf dymin dy))
         (when (< dz dzmin)
           (setf dzmin dz))))
     matter)
    (if (chem:bounding-box-bound-p matter)
        (let ((bounding-box (chem:bounding-box matter)))
          (values x-vec y-vec z-vec
                  (chem:get-x-width bounding-box)
                  (chem:get-y-width bounding-box)
                  (chem:get-z-width bounding-box)))
        (values (copy-seq x-vec)
                (copy-seq y-vec)
                (copy-seq z-vec)
                (- dxmax dxmin)
                (- dymax dymin)
                (- dzmax  dzmin)))))
         
;;; xstart,ystart,zstart is the CENTER of the first solvent box that goes at the max XYZ corner.
;;; ix,iy,iz is the number of solvent boxes
(defun tool-add-all-boxes (solute test-function solvent ix iy iz xstart ystart zstart xsolvent ysolvent zsolvent &key verbose)
  (let* ((solvent-count (* (chem:content-size solvent) ix iy iz))
         (progress-bar (cando:make-progress-bar :style :bar
                                                :divisions 100
                                                :total solvent-count
                                                :bar-character #\*))
         (counter 0))
    (format t "There are ~d solvent molecules and ~d solute atoms~%" solvent-count (chem:number-of-atoms solute))
    (finish-output)
    (loop for i from 0 below ix
          for dx = xstart then (- dx xsolvent)
          do (loop for j from 0 below iy
                   for dy = ystart then (- dy ysolvent)
                   do (loop for k from 0 below iz
                            for dz = zstart then (- dz zsolvent)
                            for translate-solvent = (geom:vec dx dy dz)
                            for solvent-copy = (chem:matter-copy solvent)
                            for solvent-transform = (geom:make-m4-translate translate-solvent)
                            do (chem:apply-transform-to-atoms solvent-copy solvent-transform)
                               ;; Copy only solvent molecules that fit criteria
                            do (chem:map-molecules
                                nil
                                (lambda (solvent-mol)
                                  ;; Check if solvent-mol satisfies criterion - if it does - add it to the solute
                                  #+(or)(when (= (floor (mod counter 100)) 0)
                                          (format t "Counter = ~d~%" counter)
                                          (finish-output))
                                  (incf counter)
                                  (cando:progress-advance progress-bar counter)
                                  (when (funcall test-function solvent-mol)
                                    (chem:set-name solvent-mol (intern (format nil "WAT_~a" counter) :keyword))
                                    (chem:setf-molecule-type solvent-mol :solvent)
                                    (chem:add-matter solute solvent-mol)))
                                solvent-copy))))
    (cando:progress-done progress-bar)))


;;Closeness controls how close solvent can get to solute before they are considered to be overlapping.
;;Farness defines shell's range.
(defun tool-solvate-and-shell (solute solvent width-list &key (closeness 0.0) (farness 10.0) shell oct isotropic (verbose t))
  (check-type width-list list)
  (let* ((solvent-box (chem:bounding-box solvent))
         (solvent-x-width (chem:get-x-width solvent-box))
         (solvent-y-width (chem:get-y-width solvent-box))
         (solvent-z-width (chem:get-z-width solvent-box))
         (atom-max-r (+ 1.5 closeness))
         (2xatom-max-r (* atom-max-r 2.0))
         (2xatom-max-r-squared (* 2xatom-max-r 2xatom-max-r))
         solute-xvec solute-yvec solute-zvec
         solute-x-width solute-y-width solute-z-width
         xwidth ywidth zwidth
         ix iy iz
         xstart ystart zstart
         ;;Make a copy of original solute just in case.
         (original-solute (chem:matter-copy solute)))
    (let* ((solute-center (chem:geometric-center solute))
           (transform-to-origin (geom:make-m4-translate (geom:v* solute-center -1.0))))
      (chem:apply-transform-to-atoms solute transform-to-origin))
    (multiple-value-setq (solute-xvec solute-yvec solute-zvec solute-x-width solute-y-width solute-z-width)
      (tool-build-solute-array solute))   
    (setf xwidth (+ solute-x-width (* (first width-list) 2))
          ywidth (+ solute-y-width (* (second width-list) 2))
          zwidth (+ solute-z-width (* (third width-list) 2)))
    (if (or isotropic
            oct)
        (let ((widthtemp (* xwidth ywidth zwidth))
              (widthmax (max xwidth ywidth zwidth)))
          (setf xwidth widthmax
                ywidth widthmax
                zwidth widthmax
                widthtemp (/ (- (* widthmax widthmax widthmax) widthtemp) widthtemp))
          (format t "Total bounding box for atom centers:  ~6,2f ~6,2f ~6,2f~%" xwidth ywidth zwidth)
          (format t "(box expansion for 'iso' is ~a )~%" (* 100.0 widthtemp))
          (setf widthtemp (max solute-x-width solute-y-width solute-z-width)
                solute-x-width widthtemp
                solute-y-width widthtemp
                solute-z-width widthtemp))
        (format t "Total bounding box for atom centers:  ~6,2f ~6,2f ~6,2f~%" xwidth ywidth zwidth))
    (setf 
     ix (+ (truncate (/ xwidth solvent-x-width)) 1)
     iy (+ (truncate (/ ywidth solvent-y-width)) 1)
     iz (+ (truncate (/ zwidth solvent-z-width)) 1)
     xstart (* 0.5 solvent-x-width (- ix 1))
     ystart (* 0.5 solvent-y-width (- iy 1))
     zstart (* 0.5 solvent-z-width (- iz 1)))
    (let ((test-function (lambda (solvent-molecule)
                           (and (overlap-solvent solute-xvec solute-yvec solute-zvec solvent-molecule 2xatom-max-r-squared)
                                (if oct
                                    (invalid-solvent-octahedron xwidth ywidth zwidth solvent-molecule)
                                    (if shell
                                        (invalid-solvent-shell solute-xvec solute-yvec solute-zvec solvent-molecule farness)
                                        (invalid-solvent-rectangular xwidth ywidth zwidth solvent-molecule)))))))
      (tool-add-all-boxes solute test-function solvent ix iy iz xstart ystart zstart solvent-x-width solvent-y-width solvent-z-width :verbose verbose)
      solute)
    (unless shell
      (chem:set-property solute :bounding-box (list xwidth ywidth zwidth)))))

(defun tool-solvate-in-sphare (solute solvent center radius &key (closeness 0.0) (verbose t))
  (let* ((solvent-box (chem:bounding-box solvent))
         (solvent-x-width (chem:get-x-width solvent-box))
         (solvent-y-width (chem:get-y-width solvent-box))
         (solvent-z-width (chem:get-z-width solvent-box))
         (diam (* radius 2.0))
         (buffer 0.0)
         (atom-max-r (+ 1.5 closeness))
         (2xatom-max-r (* atom-max-r 2.0))
         (2xatom-max-r-squared (* 2xatom-max-r 2xatom-max-r))
         solute-xvec solute-yvec solute-zvec
         solute-x-width solute-y-width solute-z-width
         ;;xwidth ywidth zwidth
         ix iy iz
         xstart ystart zstart)
    (multiple-value-setq (solute-xvec solute-yvec solute-zvec solute-x-width solute-y-width solute-z-width)
      (tool-build-solute-array solute))   
    (setf 
     ix (+ (truncate (/ diam solvent-x-width)) 1)
     iy (+ (truncate (/ diam solvent-y-width)) 1)
     iz (+ (truncate (/ diam solvent-z-width)) 1)
     xstart (+ (* 0.5 solvent-x-width (- ix 1)) (geom:vx center))
     ystart (+ (* 0.5 solvent-y-width (- iy 1)) (geom:vy center))
     zstart (+ (* 0.5 solvent-z-width (- iz 1)) (geom:vz center)))
    (let ((test-function (lambda (solvent-molecule)
                           (and (overlap-solvent solute-xvec solute-yvec solute-zvec solvent-molecule 2xatom-max-r-squared)
                                (invalid-solvent-sphere radius center solvent-molecule)))))
      (tool-add-all-boxes solute test-function solvent ix iy iz xstart ystart zstart solvent-x-width solvent-y-width solvent-z-width :verbose verbose)
      solute)))

(defun overlap-solvent (solute-xvec solute-yvec solute-zvec mol 2xatom-max-r-squared)
;;  #+(or)
  (chem:overlap-solvent solute-xvec solute-yvec solute-zvec mol 2xatom-max-r-squared)
  #+(or)
  (progn
    (chem:map-atoms
     nil
     (lambda (a)
       (let ((solvent-pos (chem:get-position a)))
         (let ((x-solvent (geom:vx solvent-pos))
               (y-solvent (geom:vy solvent-pos))
               (z-solvent (geom:vz solvent-pos)))
           (loop for i from 0 below (length solute-xvec)
                 do (let* ((x-solute (aref solute-xvec i))
                           (x-delta (- x-solute x-solvent))
                           (x-delta-squared (* x-delta x-delta)))
                      (when (< x-delta-squared 2xatom-max-r-squared)
                        (let* ((y-solute (aref solute-yvec i))
                               (y-delta (- y-solute y-solvent))
                               (y-delta-squared (* y-delta y-delta)))
                          (when (< y-delta-squared 2xatom-max-r-squared)
                            (let* ((z-solute (aref solute-zvec i))
                                   (z-delta (- z-solute z-solvent))
                                   (z-delta-squared (* z-delta z-delta)))
                              (when (< z-delta-squared 2xatom-max-r-squared)
                                (let ((delta-squared (+ x-delta-squared y-delta-squared z-delta-squared)))
                                  (when (< delta-squared 2xatom-max-r-squared)
                                    (return-from overlap-solvent nil)))))))))))))
     mol)
    t))

(defun invalid-solvent-rectangular (xwidth ywidth zwidth mol)
  (chem:map-atoms
   nil
   (lambda (a)
     (let ((solvent-pos (chem:get-position a)))
       (unless (and (> (/ xwidth 2.0) (abs (geom:vx solvent-pos)))
                    (> (/ ywidth 2.0) (abs (geom:vy solvent-pos)))
                    (> (/ zwidth 2.0) (abs (geom:vz solvent-pos))))
         (return-from invalid-solvent-rectangular nil))))
   mol)
  t)

(defun invalid-solvent-octahedron (xwidth ywidth zwidth mol)
  (let* ((width-avr (/ (+ xwidth ywidth zwidth) 3.0))
         (half-width-avr (/ width-avr 2.0))
         (2sqrt (sqrt 2.0))
         (2by3 (/ 2.0 3.0))
         (4by3 (/ 4.0 3.0))
         x-solvent y-solvent z-solvent)
    (chem:map-atoms
     nil
     (lambda (a)
       (let ((solvent-pos (chem:get-position a)))
         (setf x-solvent (geom:vx solvent-pos)
               y-solvent (geom:vy solvent-pos)
               z-solvent (geom:vz solvent-pos))
         (if (and (<= (- (* (* 2sqrt half-width-avr) 2by3)) z-solvent)
                  (>=  (* (* 2sqrt half-width-avr) 2by3) z-solvent))
             (progn                                 
               (when (>= x-solvent 0.0)
                 (if (and (<= (- (* 2sqrt x-solvent) (* 2sqrt half-width-avr)) z-solvent)
                          (>= (+ (* (- 2sqrt) x-solvent) (* 2sqrt half-width-avr)) z-solvent))
                     (progn
                       (when (>= y-solvent 0.0)
                         (if (and (<= (- (* 2sqrt y-solvent) (* 2sqrt half-width-avr)) z-solvent)
                                  (>= (+ (* (- 2sqrt) y-solvent) (* 2sqrt half-width-avr)) z-solvent)
                                  (>= (+ (- x-solvent) (* 4by3 half-width-avr)) y-solvent))
                             (return-from invalid-solvent-octahedron t)))
                       (when (< y-solvent 0.0)
                         (if (and (<= (- (* (- 2sqrt) y-solvent) (* 2sqrt half-width-avr)) z-solvent)
                                  (>= (+ (* 2sqrt y-solvent) (* 2sqrt half-width-avr)) z-solvent)
                                  (<= (- x-solvent (* 4by3 half-width-avr)) y-solvent))
                             (return-from invalid-solvent-octahedron t))))))
               (when (< x-solvent 0.0)
                 (if (and (<= (- (* (- 2sqrt) x-solvent) (* 2sqrt half-width-avr)) z-solvent)
                          (>= (+ (* 2sqrt x-solvent) (* 2sqrt half-width-avr)) z-solvent))
                     (progn
                       (when (>= y-solvent 0.0)
                         (if (and (<= (- (* 2sqrt y-solvent) (* 2sqrt half-width-avr)) z-solvent)
                                  (>= (+ (* (- 2sqrt) y-solvent) (* 2sqrt half-width-avr)) z-solvent)
                                  (>= (+ x-solvent (* 4by3 half-width-avr)) y-solvent))
                             (return-from invalid-solvent-octahedron t)))
                       (when (< y-solvent 0.0)
                         (if (and (<= (- (* (- 2sqrt) y-solvent) (* 2sqrt half-width-avr)) z-solvent)
                                  (>= (+ (* 2sqrt y-solvent) (* 2sqrt half-width-avr)) z-solvent)
                                  (<= (- (- x-solvent) (* 4by3 half-width-avr)) y-solvent))
                             (return-from invalid-solvent-octahedron t))))))))))
     mol))
  nil)

(defun invalid-solvent-shell (solute-xvec solute-yvec solute-zvec mol farness)
  (let* ((shell-radius farness)
         (2xshell-radius (* shell-radius shell-radius)))
    (chem:map-atoms
     nil
     (lambda (a)
       (let ((solvent-pos (chem:get-position a)))
         (loop for i from 0 below (length solute-xvec)
            for x-solute = (aref solute-xvec i)
            for y-solute = (aref solute-yvec i)
            for z-solute = (aref solute-zvec i)
            for x-solvent = (geom:vx solvent-pos)
            for y-solvent = (geom:vy solvent-pos)
            for z-solvent = (geom:vz solvent-pos)
            for x-delta = (- x-solute x-solvent)
            for x-delta-squared = (* x-delta x-delta)
            for y-delta = (- y-solute y-solvent)
            for y-delta-squared = (* y-delta y-delta)
            for z-delta = (- z-solute z-solvent)
            for z-delta-squared = (* z-delta z-delta)
            do (when (< x-delta-squared 2xshell-radius)
                 (when (< y-delta-squared 2xshell-radius)
                   (when (< z-delta-squared 2xshell-radius)
                     (let ((delta-squared (+ x-delta-squared y-delta-squared z-delta-squared)))
                       (when (< delta-squared 2xshell-radius)
                         (return-from invalid-solvent-shell t)))))))))
     mol))
  nil)

(defun invalid-solvent-sphere (radius center mol)
  (chem:map-atoms
   nil
   (lambda (a)
     (let* ((solvent-pos (chem:get-position a))
            (center-to-pos (+ (* (- (geom:vx center) (geom:vx solvent-pos))
                                 (- (geom:vx center) (geom:vx solvent-pos)))
                              (* (- (geom:vy center) (geom:vy solvent-pos))
                                 (- (geom:vy center) (geom:vy solvent-pos)))
                              (* (- (geom:vz center) (geom:vz solvent-pos))
                                 (- (geom:vz center) (geom:vz solvent-pos))))))
       (unless (> (* radius radius) center-to-pos)
         (return-from invalid-solvent-sphere nil))))
   mol)
  t)
