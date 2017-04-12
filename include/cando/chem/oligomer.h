/*
    File: oligomer.h
*/
/*
Open Source License
Copyright (c) 2016, Christian E. Schafmeister
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
 
This is an open source license for the CANDO software from Temple University, but it is not the only one. Contact Temple University at mailto:techtransfer@temple.edu if you would like a different license.
*/
/* -^- */
       
       
//
// (C) 2004 Christian E. Schafmeister
//


/*
 	oligomer.h

	Store an Oligomer of Monomers connected by Couplings
 */

#ifndef	OLIGOMER_H
#define OLIGOMER_H
#include <stdio.h>
#include <string>
#include <iostream>
#include <vector>
#include <clasp/core/common.h>
#include <cando/adapt/stringSet.fwd.h>
#include <cando/geom/vector2.h>
#include <cando/geom/vector3.h>
#include <clasp/core/smallMap.h>
#include <cando/adapt/symbolSet.h>
#include <cando/adapt/objectSet.h>

//#include "bond.h"
//#include "conformation.h"
//#include "atom.h"
//#include "residue.h"
//#include "coupling.h"
//#include "monomer.h"

#include <cando/chem/chemPackage.h>


namespace chem {

SMART(CandoDatabase);
SMART(Oligomer);
SMART(Monomer);
SMART(MultiMonomer);
SMART(Coupling);
SMART(SpecificContextSet);
SMART(DirectionalCoupling);
SMART(RingCoupling);
SMART(Atom);
SMART(Residue);
SMART(Molecule);
SMART(ObjectSet);
SMART(CandoDatabase);
SMART(Oligomer);


SMART(Oligomer);
class Oligomer_O : public core::CxxObject_O
{
    LISP_CLASS(chem,ChemPkg,Oligomer_O,"Oligomer",core::CxxObject_O);
 public:
    static Oligomer_sp make(core::List_sp parts);
    friend class Coupling_O;
    friend class DirectionalCoupling_O;
    friend class RingCoupling_O;
public:
    void initialize();
    friend class AlchemistState_O;
public:
    typedef core::Symbol_O			NameType;
    friend core::T_sp chem__set_oligomer(Oligomer_O::NameType::smart_ptr_type oligomerName, core::List_sp parts);
    friend core::T_sp chem__oligomer_sequence(Oligomer_sp olig);
protected:
    NameType::smart_ptr_type			_Name;
    gctools::Vec0<Monomer_sp>			_Monomers;
    gctools::Vec0<Coupling_sp>		_Couplings;

private:	// Do not archive
		/*! When one of my MultiMonomers experiences a UserGroupChange
		 * we will store it here for others to access.
		 */
    MultiMonomer_wp	_WeakLastMultiMonomerChanged;


#ifdef	USEBOOSTPYTHON
    boost::python::object			pythonObject;
#endif

    void	sequenceOutMonomers( Monomer_sp sub );
    void	sequenceAllMonomers();
    string	stateAsString(uint state);

protected:
    void _gatherMultiMonomers(gctools::Vec0<Monomer_sp>&multiMonomer);
    void _fillSequenceAsStringForChildren(Monomer_sp mon, stringstream& seq);
    void _fillMonomerAsString(Monomer_sp mon, stringstream& seq);
    void _fillSequenceAsFileNameForChildren(Monomer_sp rootMonomer, stringstream& seq);
    void _assembleFromParts(core::List_sp parts,CandoDatabase_sp bdb);
public:
public:
    typedef	gctools::Vec0<Monomer_sp>::iterator	monomerIterator;
    typedef	gctools::Vec0<Coupling_sp>::iterator	couplingIterator;

public:	// /////////////////////////////////////////////////////////////////

    bool	hasLastMultiMonomerChanged();
    MultiMonomer_sp getLastMultiMonomerChanged();

    core::List_sp monomersAsList();

    monomerIterator begin_Monomers() { return this->_Monomers.begin(); };
    monomerIterator end_Monomers() { return this->_Monomers.end(); };

    uint	numberOfMonomers() { return this->_Monomers.size(); };

    adapt::SymbolSet_sp allMonomerAliases();
    adapt::ObjectSet_sp getAllAliases();

    couplingIterator begin_Couplings() { return this->_Couplings.begin(); };
    couplingIterator end_Couplings() { return this->_Couplings.end(); };

    //
    void		empty();

    /*! If the groups change then the multi monomers need to be updated
     */
    void		updateMultiMonomers();

CL_LISPIFY_NAME("setName");
CL_DEFMETHOD     void		setName(NameType::smart_ptr_type nm) { this->_Name = nm;};
CL_LISPIFY_NAME("getName");
CL_DEFMETHOD     NameType::smart_ptr_type getName() { return this->_Name;};

 bool	checkForErrors();
    //
    //	build piece by piece
    //
public:
    // These should be made protected once all the atomic
    // Oligomer modifying routines are completed
    uint		addMonomer(Monomer_sp s);
    void		removeMonomer(Monomer_sp s);
    void		addCoupling(Coupling_sp c);
    void		removeCoupling(Coupling_sp c);
    DirectionalCoupling_sp	couple(Monomer_sp inMon, core::Symbol_sp couplingName, Monomer_sp outMon );
    /*! Create a coupling for the two _Monomers that should already
      be in the Oligomer */
//	RingCoupling_sp	ringCouple(Monomer_sp mon1, const string& plug1, Monomer_sp mon2, const string& plug2 );
    RingCoupling_sp	ringCouple(Monomer_sp mon1, Monomer_sp mon2 );

    void	expandMonomerListToNeighbors(gctools::SmallOrderedSet<Monomer_sp>& monomers); // s e t<Monomer_sp>& monomers);
    void	checkMonomersAndNeighborsForErrors(CandoDatabase_sp bdb, gctools::SmallOrderedSet<Monomer_sp>& monomers ); // s e t<Monomer_sp> monomers);
    void	checkMonomersAndNotNeighborsForErrors(CandoDatabase_sp bdb, gctools::SmallOrderedSet<Monomer_sp>& monomers ); // s e t<Monomer_sp> monomers);
    void	signal_monomerContentsChanged();
    adapt::StringSet_sp allAliases();

public:
    // Atomic oligomer modifying routines
    Monomer_sp	addMultiMonomerAsLeaf(Monomer_sp monFrom, core::Symbol_sp couplingName,
                                      core::Symbol_sp representedEntityNameSetName, geom::Vector2 pos);
    Monomer_sp	removeLeafMonomer(Monomer_sp monomerToRemove );


public:

    //! Find and return the rootMonomer
    Monomer_sp	rootMonomer();

    Molecule_sp	getMolecule();

    gctools::Vec0<Monomer_sp>	getMonomers() {return this->_Monomers;}
    gctools::Vec0<Coupling_sp>	getCouplings() { return this->_Couplings;}
    Monomer_sp		getFirstMonomer();

    bool hasMonomerWithId(core::Symbol_sp id);
    Monomer_sp	getMonomerWithId(core::Symbol_sp id);

    //! Mutate one MultiMonomer
    void perturbMonomerSequence();

    void	firstSequence();
    bool	incrementSequence();
    void	gotoSequence(const Bignum& idx);
    Bignum currentSequenceIndex();
    Bignum numberOfSequences();

    string sequenceAsString();
    string sequenceAsFileName();

    void	throwIfBadConnections();

    void	signalConnectivityChanged();

    virtual void catchSignal(core::Symbol_sp sig, core::Model_sp source, core::List_sp data );
    virtual void propagateSignal(core::Symbol_sp signal);

    /*!
     * Return every specific monomer context that could be
     * found within this oligomer
     */
    SpecificContextSet_sp	allSpecificMonomerContexts();


    DEFAULT_CTOR_DTOR(Oligomer_O);
};

extern	Oligomer_sp create_Oligomer();

};

TRANSLATE(chem::Oligomer_O);
#endif
