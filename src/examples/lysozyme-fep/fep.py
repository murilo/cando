import cl4py
lisp = cl4py.Lisp(["/Users/meister/Development/cando/build/boehm/icando-boehm","-N","--load"])
cl = lisp.find_package('CL')
chem = lisp.find_package('CHEM')
leap = lisp.find_package('LEAP')
fep = lisp.find_package("FEP")
cu = lisp.find_package('CANDO-USER')
cu.setup_default_paths()
cu.load_atom_type_rules("ATOMTYPE_GFF.DEF")
leap.source("leaprc.ff14SB.redq")
leap.source("leaprc.gaff")
feps = fep.make_fep()
sk = leap.load_sketch("ligands.cdxml")
fep.setup_ligands(feps,sk)
print("Done")
