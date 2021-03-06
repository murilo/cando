(in-package :asdf-user)

(defsystem "cando"
  :description "The CANDO compiler front end"
  :version "0.0.1"
  :author "Christian Schafmeister <chris.schaf@verizon.net>"
  :licence "LGPL-3.0"
  :depends-on (:utility :inet :smarts :lparallel)
  :serial t
  :components
  ((:file "packages")
   (:file "basic")
   (:file "infix")
   (:file "chem")
   (:file "environment")
   (:file "print-read")
   (:file "conditions")
   (:file "chemistry")
   (:file "select")
   (:file "convenience")
   (:file "geom")
   (:file "build")
   (:file "progress")
   (:file "anchor")
   (:file "struct")
   (:file "fortran")
   (:file "monomers")
   (:file "dynamics")
   (:file "modelling")
   (:file "constitution")
   (:file "molecules")
   (:file "atom-tree")
   (:file "ring-builder")
   (:file "chemdraw")
   (:file "energy")
   (:file "matter-hierarchy")
   (:file "psf-files")
;;;     (:file "remove-overlaps")
;;;     (:file "matter")
;;;     (:file "antique")
;;;     (:file "antechamber")
   ))
