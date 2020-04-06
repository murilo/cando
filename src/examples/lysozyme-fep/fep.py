import cl4py
lisp = cl4py.Lisp(["/Users/meister/Development/cando-dev/build/boehm/icando-boehm","-N","--load"])
cl = lisp.find_package('CL')
chem = lisp.find_package('CHEM')
leap = lisp.find_package('LEAP')
ti_run = lisp.find_package("TI-RUN")
cando = lisp.find_package("CANDO")
cu = lisp.find_package('CANDO-USER')
cu.setup_default_paths()
cu.load_atom_type_rules("ATOMTYPE_GFF.DEF")
leap.source("leaprc.ff14SB.redq")
leap.source("leaprc.gaff")
ti_runs = ti_run.make_ti_run()
sk = leap.load_sketch("ligands.cdxml")
ti_run.setup_ligands(ti_runs,sk)
tests_list = cl.read_from_string("""(list (cons :c1 (lambda (a) (eq (chem:get-name a) :c1))) (cons :c3 (lambda (a) (eq (chem:get-name a) :c3))) (cons :c5 (lambda (a) (eq (chem:get-name a) :c5))))""")
tests = cl.eval(cl.first(tests_list))
pick = chem.compile_smarts("[C:6]1~[C<c1>:1]~[C:2]~[C<c3>:3]~[C:4]~[C<c5>:5]1",tests=tests)
lysozyme = cu.load_pdb("181L_mod.pdb")
cando.build_unbuilt_hydrogens(cl.first(lysozyme))
cu.simple_build_unbuilt_atoms(cl.first(lysozyme))
ti_run.add_receptor(ti_runs,cl.first(lysozyme))
cu.load_off("phen.lib")
cu.load_off("benz.lib")
ligs = cu.load_pdb("bnz_phn.pdb")
cando.build_unbuilt_hydrogens(cl.first(ligs))
cu.simple_build_unbuilt_atoms(cl.first(ligs))
ti_run.pose_ligands_using_pattern(ti_runs,pick,cl.first(ligs))
ti_run.build_job_nodes(ti_runs)
ti_run.connect_job_nodes(ti_runs,connections=2,stages=3,windows=11)
worklist = ti_run.generate_jobs(ti_runs)
print("ti-run setup done")
