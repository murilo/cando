(in-package :leap.commands)


(defun leap.setup-amber-paths ()
  (leap:setup-amber-paths))

(defun leap.setup-default-paths ()
  (leap:setup-default-paths))

(defun leap.show-paths ()
  (leap:show-paths))



;;; ----------------------------------------------------------------------
;;;
;;; Quick and dirty setup-gaff
;;;

(defun setup-gaff ()
  (let ((*default-pathname-defaults*
          (translate-logical-pathname #P"source-dir:extensions;cando;src;data;force-field;"))
        (parms (chem:make-read-amber-parameters)))
    (with-open-file (fin "ATOMTYPE_GFF.DEF" :direction :input)
      (chem:read-types parms fin))
    (with-open-file (fin "gaff.dat" :direction :input)
      (chem:read-parameters parms fin (symbol-value (find-symbol "*AMBER-SYSTEM*" :leap))))
    (setf energy:*ff* (chem:get-force-field parms))
    energy:*ff*))

;;; ----------------------------------------------------------------------
;;;
;;; LEaP commands
;;;
(defvar *out* t)

(defun set-variable (entry)
  (let ((variable (first entry))
        (value (third entry)))
    (leap.core:register-variable variable value)))


(defun log-file (filename)
  (let* ((log-stream (open filename :direction :output :if-exists :supersede))
         (broadcast (make-broadcast-stream ext:+process-standard-output+ log-stream)))
    (setf cl:*standard-output* broadcast)))
  
(defun leap.log-file (entry)
  (valid-arguments entry 1)
  (let ((filename (pathname (ensure-string (second entry)))))
    (log-file filename)))

(defun desc (&optional (name nil namep))
  "    desc variable
      object                       _variable_

Print a description of the object.
"
  (if namep
      (let ((val (leap.core:lookup-variable name)))
        (format *out* "~S~%" val)
        val)
      (format t "~a" (leap.core:all-variables))))

(defun leap.load-smirnoff-params (filename)
  (leap:load-smirnoff-params filename))

(defun leap.set-force-field (matter force-field-name)
  (leap:set-force-field-name matter force-field-name))

(defun object (name)
  "Return the object with name."
  (leap.core:lookup-variable name))

(defun leap.desc (entry)
  (valid-arguments entry 1)
  (let ((var (second entry)))
    (format *out* "~a~%" var)))

(defun leap.add-pdb-res-map (entry)
  "    addPdbAtomMap list
      LIST                         _list_

The atom Name Map is used to try to map atom names read from PDB files
to atoms within residue UNITs when the atom name in the PDB file does
not match an atom in the residue.  This enables PDB files to be read
in without extensive editing of atom names.  The LIST is a LIST of LISTs:
      { {sublist} {sublist} ... }
where each sublist is of the form
      { \"OddAtomName\" \"LibAtomName\" }
Many `odd' atom names can map to one `standard' atom name, but any single
odd atom name maps only to the last standard atom name it was mapped to.
"
  (valid-arguments entry 1)
  (let ((map (second entry)))
    (leap.pdb:add-pdb-res-map map)))

(defun add-atom-types (info)
  (warn "add-atom-types doesn't do anything"))

(defun leap.add-atom-types (entry)
  (valid-arguments entry 1)
  (let ((info (second entry)))
    (add-atom-types info)))

(defun create-atom (name &optional type (charge 0.0))
  "    variable = createAtom name type charge

      ATOM                         _variable_
      STRING                       _name_
      STRING                       _type_
      NUMBER                       _charge_

Return a new ATOM with _name_, _type_, and _charge_.
"
  (let* ((name-sym (intern (string name) :keyword))
         (element (chem:element-from-atom-name-string (string name-sym)))
         (atom (chem:make-atom name-sym element)))
    (chem:set-type atom type)
    (chem:set-charge atom charge)
    atom))

(defun load-off (filename)
"    loadOff filename
      STRING                       _filename_

This command loads the Object File Format library within the file named
_filename_.  All UNITs and PARMSETs within the library will be loaded.
The objects are loaded into LEaP under the variable names the objects
had when they were saved.  Variables already in existence that have the
same names as the objects being loaded will be overwritten.  PARMSETs
loaded using this command are included in LEaP's library of PARMSETs
that is searched whenever parameters are required.
"
  (leap.off:load-off filename))

(defun leap.list-force-fields ()
  (leap:list-force-fields))



(defun leap.source (entry)
  (valid-arguments entry 1)
  (let* ((filename (leap.core:ensure-path (second entry))))
    (leap:source filename)))


(defun leap.save-amber-parm (aggregate-name topology-file-name &optional (crd-pathname nil crd-pathname-p) (force-field-name nil))
  (let ((aggregate (leap.core:lookup-variable aggregate-name))
        (crd-pathname (if crd-pathname-p
                          crd-pathname
                          (namestring (make-pathname :type "crd" :defaults topology-file-name)))))
    (funcall 'save-amber-parm aggregate topology-file-name crd-pathname force-field-name)))

(defun ensure-string (obj)
  (cond
    ((stringp obj) obj)
    ((symbolp obj)
     (let ((val (leap.core:lookup-variable obj nil :not-found)))
       (if (eq val :not-found)
           (string val)
           val)))))

(defun valid-arguments (entry num)
  (unless (= (length entry) (1+ num))
    (error "Bad arguments for ~a" (car entry))))



(defun process-iso-closeness (iso-closeness)
  (let ((iso nil)
        (closeness 1.0))
    (flet ((error-iso-closeness ()
             (error "You must provide either :iso or a number for closeness - you provided ~s" iso-closeness)))
      (cond
        ((= (length iso-closeness) 0))
        ((= (length iso-closeness) 1)
         (cond
           ((eq (first iso-closeness) :iso)
            (setf iso t))
           ((string-equal (first iso-closeness) "iso")
            (setf iso t))
           ((numberp (first iso-closeness))
            (setf closeness (first iso-closeness)))
           (t (error-iso-closeness))))
        ((and (= (length iso-closeness) 2)
              (or (find :iso iso-closeness)
                  (find "iso" iso-closeness :test #'string-equal))
              (find-if #'numberp iso-closeness))
         (setf iso t
               closeness (find-if #'numberp iso-closeness)))
        (t (error-iso-closeness))))
    (list :isotropic iso :closeness closeness)))

(defun leap.solvate-box (solute-name solvent-name buffer &rest iso-closeness)
  "    solvateBox solute solvent buffer [ \"iso\" ] [ closeness ]

      UNIT                         _solute_
      UNIT                         _solvent_
      object                       _buffer_
      NUMBER                       _closeness_

The solvateBox command creates a solvent box around the _solute_ UNIT.
The _solute_ UNIT is modified by the addition of _solvent_ RESIDUEs.

The user may want to first align long solutes that are not expected
to tumble using alignAxes, in order to minimize box volume.

The normal choice for a TIP3 _solvent_ UNIT is WATBOX216. Note that
constant pressure equilibration is required to bring the artificial box
to reasonable density, since Van der Waals voids remain due to the
impossibility of natural packing of solvent around the solute and at
the edges of the box.

The solvent box UNIT is copied and repeated in all three spatial directions
to create a box containing the entire solute and a buffer zone defined
by the _buffer_ argument. The _buffer_ argument defines the distance,
in angstroms, between the wall of the box and the closest ATOM in the
solute.

If the buffer argument is a single NUMBER, then the buffer distance is
the same for the x, y, and z directions, unless the \"iso\" option is used
to make the box isometric, with the shortest box clearance = buffer. If
\"iso\" is used, the solute is rotated to orient the principal axes,
otherwise it is just centered on the origin.

If the buffer argument is a LIST of three NUMBERS, then the NUMBERs are
applied to the x, y, and z axes respectively. As the larger box is created
and superimposed on the solute, solvent molecules overlapping the solute
are removed.

The optional _closeness_ parameter can be used to control the extent to
which _solvent_ ATOMs overlap _solute_ ATOMs.  The default value of
the _closeness_ argument is 1.0, which allows no overlap.  Smaller
values allow solvent ATOMs to overlap _solute_ ATOMs by (1 - closeness) *
R*ij, where R*ij is the sum of the Van der Waals radii of solute and
solvent atoms.  Values greater than 1 enforce a minimum gap between
solvent and solute of (closeness - 1) * R*ij.

This command modifies the _solute_ UNIT in several ways.  First, the
coordinates of the ATOMs are modified to move the center of a box
enclosing the Van der Waals radii of the atoms to the origin.  Secondly,
the UNIT is modified by the addition of _solvent_ RESIDUEs copied from
the _solvent_ UNIT. Finally, the box parameter of the new system (still
named for the _solute_) is modified to reflect the fact that a periodic,
rectilinear solvent box has been created around it.
"
  (let ((solute (leap.core:lookup-variable solute-name))
        (solvent (leap.core:lookup-variable solvent-name))
        (iso-closeness-args (process-iso-closeness iso-closeness)))
    (apply #'leap:solvate-box solute solvent buffer iso-closeness-args)))

(defun leap.solvate-oct (solute solvent farness &rest iso-closeness)
  "    solvateOct solute solvent buffer [ \"iso\" ] [ closeness ]

      UNIT                         _solute_
      UNIT                         _solvent_
      object                       _buffer_
      NUMBER                       _closeness_

The solvateOct command is the same as solvateBox, except the corners
of the box are sliced off, resulting in a truncated octahedron, which
typically gives a more uniform distribution of solvent around the
solute.

In solvateOct, when a LIST is given for the buffer argument, four
numbers are given instead of three, where the fourth is the diagonal
clearance. If 0.0 is given as the fourth number, the diagonal clearance
resulting from the application of the x,y,z clearances is reported. If
a non-0 value is given, this may require scaling up the other clearances,
which is also reported. Similarly, if a single number is given, any
scaleup of the x,y,z buffer to accommodate the diagonal clip is reported.

If the \"iso\" option is used, the isometric truncated octahedron is
rotated to an orientation used by the PME code, and the box and angle
dimensions output by the saveAmberParm* commands are adjusted for PME
code imaging.
"
  (let ((buffer (list farness farness farness))
        (iso-closeness-args (process-iso-closeness iso-closeness)))
    (apply #'leap:solvate-shell solute solvent buffer :farness farness :oct t iso-closeness-args)))

(defun leap.solvate-shell (solute solvent farness &rest iso-closeness)
  "    solvateShell solute solvent thickness [ closeness ]

      UNIT                         _solute_
      UNIT                         _solvent_
      NUMBER                       _thickness_
      NUMBER                       _closeness_

The solvateShell command creates a solvent shell around the _solute_ UNIT.
The _solute_ UNIT is modified by the addition of _solvent_ RESIDUEs.

The normal choice for a TIP3 _solvent_ UNIT is WATBOX216. The _solvent_ box
is repeated in all three spatial directions and _solvent_ RESIDUEs selected
to create a solvent shell with a radius of _thickness_ Angstroms around the
_solute_.

The _thickness_ argument defines the maximum distance a _solvent_ ATOM may
be from the closest _solute_ ATOM.

The optional _closeness_ parameter can be used to control overlap of _solvent_
with _solute_ ATOMs.   The default value of the _closeness_ argument is
1.0, which allows contact but no overlap.  Please see the solvateBox
command for more details on the _closeness_ parameter.
"
  (let ((buffer (list farness farness farness))
        (iso-closeness-args (process-iso-closeness iso-closeness)))
    (apply #'leap:solvate-shell solute solvent buffer :farness farness :shell t iso-closeness-args)))

(defun leap-quit ()
  (throw 'repl-done nil))

(defun leap-cando ()
  "
This command brings up a cando command line. 
Leap can be reentered by evaluating (leap).
"
  (throw 'repl-done :cando))


(defun leap-start-swank ()
  (funcall (find-symbol "START-SWANK" :cando-user)))

(defun leap-help (&optional arg)
  "    help [string]

      STRING                       _string_

This command prints a description of the command in _string_.  If
the STRING is not given then a list of legal STRINGs is provided.
"
  (if arg
      (progn
        (let ((found (assoc arg leap.parser:*function-names/alist* :test #'string=)))
          (if found
              (let ((cmd (cdr found)))
                (format t "~%~a~%" (documentation cmd 'function)))
              (format t "No help available for ~a~%" arg))))
      (progn
        (format t "Help is available on the following subjects: ~%")
        (let* ((commands (copy-seq leap.parser:*function-names/alist*))
               (sorted-commands (sort commands #'string< :key #'car)))
          (loop for cmd in sorted-commands
                for col from 1
                do (format t "~20a" (car cmd))
                when (and (> col 0) (= (rem col 4) 0))
                  do (terpri)
                finally (when (/= (rem col 4) 0)
                          (terpri)))))))

(eval-when (:load-toplevel :execute)
  (setf leap.parser:*function-names/alist*
    '(("logFile" . log-file)
      ("desc" . desc)
      ("listForceFields" . leap.list-force-fields)
      ("loadOff" . load-off)
      ("loadMol2" . cando:load-mol2)
      ("loadPdb" . leap.pdb:load-pdb)
      ("source" . leap.source)
      ("setForceField" . leap.set-force-field)
      ("loadSmirnoffParams" . leap.load-smirnoff-params)
      ("loadAmberParams" . leap:load-amber-params)
      ("addPdbResMap" . leap.pdb:add-pdb-res-map)
      ("addPdbAtomMap" . leap.pdb:add-pdb-atom-map)
      ("addAtomTypes" . add-atom-types)
      ("saveAmberParms" . leap.save-amber-parm)
      ("solvateBox" . leap.solvate-box)
      ("solvateOct" . leap.solvate-oct)
      ("solvateShell" . leap.solvate-shell)
      ("setupDefaultPaths" . leap.setup-default-paths )
      ("addIons" . leap.add-ions:add-ions)
      ("setBox" . leap.set-box:set-box)
      ("showPaths" . leap.show-paths)
      ("createAtom" . create-atom )
      ("help" . leap-help)
      ("cando" . leap-cando )
      ("startSwank" . leap-start-swank)
      ("quit" . leap-quit)
      ))
  (dolist (command leap.parser:*function-names/alist*)
    (if (fboundp (cdr command))
        (setf (leap.core:function-lookup (car command) leap.core:*leap-env*) (cdr command))
        (error "~a is not a function" (cdr command)))))


(defun parse-leap-code (code)
  (let ((ast (architecture.builder-protocol:with-builder ('list)
               (esrap:parse 'leap.parser:leap code))))
    ast))

(defun process-command-line-options ()
  (let ((includes (core:leap-command-line-includes))
        (scripts (core:leap-command-line-scripts)))
    (loop for include-path in includes
          do (format t "Adding include path: ~s~%" include-path)
          do (leap.core:add-path include-path))
    (loop for script in scripts
          do (format t "Sourcing script: ~s~%" script)
          do (leap:source script))
    ))
    
(defun leap-repl ()
  (process-command-line-options)
  (format t "Welcome to Cando-LEaP!~%")
  (clear-input)
  (catch 'repl-done
    (loop for x below 10
          for code = (progn
                       (format t "> ") (finish-output)
                       (read-line *standard-input* nil :eof))
          do (handler-case
                 (if (eq code :eof)
                     (progn
                       (clear-input *standard-input*)
                       (format t "Clearing input~%"))
                     (let ((ast (architecture.builder-protocol:with-builder
                                    ('list)
                                  (handler-bind ((esrap:esrap-parse-error
                                                   (lambda (c)
                                                     (format t "Encountered error ~s while parsing ~s~%" c code)
                                                     (break "Encountered error ~s while parsing ~s" c code))))
                                    (esrap:parse 'leap.parser:leap code)))))
                       (core:call-with-stack-top-hint
                        (lambda ()
                          (leap.core:evaluate 'list ast leap.core:*leap-env*)))))
               (error (var) (format t "Error ~a - while evaluating: ~a~%" var code))))))


(defun leap ()
  (leap-repl)
  (format t "Entering cando repl - use (leap) to re-enter leap.~%"))

(defun leap-repl-then-exit ()
  (if (leap-repl)
      (progn
        (format t "Entering cando repl - use (leap) to re-enter leap.~%"))
      (progn
        (format t "Leaving leap~%")
        (core:exit 0))))



;;(defun solvate-box (solute solvent width-list 
;;
;;)
;;; ----------------------------------------------------------------------
;;;
;;; Implement a simple leap script parser
;;;
;;; This uses the Common Lisp reader and it would probably be better
;;; to develop a proper parser
;;;
#++
(progn
  (defun leap-list-reader (stream char)
    "Read a Leap list delimited by #\} and return it."
    (let ((*readtable* (copy-readtable)))
      (set-syntax-from-char #\newline #\space)
      (read-delimited-list #\} stream t)))

  (defun leap-parse-entry (stream &optional (eof-error-p t) eof)
    "Parse a leap command from the stream and return it.
A leap command can have the form:
[command] [arg1] [arg2] [arg3] ... #\NEWLINE  - execute command
[variable] = [expression] #\NEWLINE           - set variable
[variable] = #\NEWLINE                        - clear variable
# ... #\NEWLINE                               - comment
An [expression] is either a command or a number or variable."
    (if (eq (peek-char nil stream eof-error-p eof) eof)
        eof
        (let ((*readtable* (copy-readtable))
              (*package* (find-package :keyword)))
          (setf (readtable-case *readtable*) :preserve)
          (set-macro-character #\{ #'leap-list-reader nil)
          (set-syntax-from-char #\# #\;)
          (set-syntax-from-char #\newline #\))
          (read-delimited-list #\newline stream nil))))

  (defun interpret-leap-entry (entry)
    "Interpret a leap command or variable assignment. 
Nothing is returned, it's all side effects."
    (cond
      ((eq (second entry) :=)
       (set-variable entry))
      (t (let* ((cmd (intern (string-upcase (string (first entry))) :keyword))
                (cmd-assoc (assoc cmd leap.parser:*function-names/alist*))
                (cmd-func (cdr cmd-assoc)))
           (format *out* "cmd cmd-assoc cmd-func: ~a ~a ~a~%" cmd cmd-assoc cmd-func)
           (if (null cmd-func)
               (error "Illegal function ~a cmd-assoc: ~a  cmd-func: ~a" cmd cmd-assoc cmd-func)
               (progn
                 (funcall cmd-func entry)))))))

  (defun leap-interpreter (fin &optional eof-error-p eof)
    "Load the file of leap commands and execute them one by one.
Nothing is returned."
    (loop for entry = (leap-parse-entry fin eof-error-p eof)
       do (format *out* "entry = ~a~%" entry)
       unless (or (null entry) (eq entry eof))
       do (interpret-leap-entry entry)
       until (eq entry eof)))

  )
