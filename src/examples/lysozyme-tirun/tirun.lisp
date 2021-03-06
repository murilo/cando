(setup-default-paths)
(load-atom-type-rules "ATOMTYPE_GFF.DEF")
(source "leaprc.ff14SB.redq")
(source "leaprc.gaff")
(defparameter tiruns (tirun:make-tirun))
(defparameter sk (load-chem-draw "ligands.cdxml"))
(tirun:setup-ligands tiruns sk)
(defparameter tests (list (cons :c1 (lambda (a) (eq (chem:get-name a) :c1))) (cons :c3 (lambda (a) (eq (chem:get-name a) :c3))) (cons :c5 (lambda (a) (eq (chem:get-name a) :c5)))))
(defparameter pick (chem:compile-smarts "[C:6]1~[C<c1>:1]~[C:2]~[C<c3>:3]~[C:4]~[C<c5>:5]1" :tests tests))
(defparameter lysozyme (load-pdb "181L_mod.pdb"))
(cando:build-unbuilt-hydrogens lysozyme)
(simple-build-unbuilt-atoms lysozyme)
(tirun:add-receptor tiruns lysozyme)
(load-off "phen.lib")
(load-off "benz.lib")
(defparameter ligs (load-pdb "bnz_phn.pdb"))
(simple-build-unbuilt-atoms ligs)
(build-unbuilt-hydrogens ligs)
(tirun:pose-ligands-using-pattern tiruns pick ligs)
(tirun:build-job-nodes tiruns)
(tirun:connect-job-nodes tiruns :simple :connections 2 :stages 3 :windows 11)
(defparameter worklist (tirun:generate-jobs tiruns))
(with-open-file (sout "/tmp/graph.dot" :direction :output) (tirundot:draw-graph-stream (list worklist) sout))
(ext:system "dot -Tpdf -O /tmp/graph.dot")
(ext:system "open -n /tmp/graph.dot.pdf")
(core:exit)
