(in-package :asdf-user)

(defsystem "design"
  :description "Design related code"
  :version "0.0.1"
  :author "Christian Schafmeister <chris.schaf@verizon.net>"
  :licence "LGPL-3.0"
  :depends-on (:cando :leap :charges :smarts :amber)
  :serial t
  :components
  ((:file "packages")
   (:file "build-internal-coordinate-joint-template-tree")
   (:file "load")
   (:file "util")
   (:file "design")
   (:file "trainers")
   (:file "build-trainer-jobs")
   (:file "graphviz-draw-joint-template")
   (:file "graphviz-draw-fold-tree")
   (:file "graphviz-draw-joint-tree")
   ))
