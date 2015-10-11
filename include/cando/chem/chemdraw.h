#ifndef	ChemDraw_H //[
#define ChemDraw_H



#include <stdio.h>
#include <string>
#include <vector>
#include <set>
#include <clasp/core/common.h>
#include <clasp/core/holder.h>
#include <cando/chem/bond.fwd.h>
#include <cando/chem/constitutionAtoms.fwd.h>
#include <cando/chem/chemPackage.h>
#include <cando/adapt/quickDom.fwd.h>// chemdraw.h wants QDomNode needs quickDom.fwd.h
#include <cando/chem/atom.fwd.h>
#include <cando/chem/molecule.fwd.h>
#include <cando/chem/aggregate.fwd.h>
namespace chem
{


SMART(Bond);
SMART(Matter);
SMART(Atom);
SMART(Residue);
SMART(Binder);
SMART(QDomNode);
SMART(Lisp);


typedef	enum { singleCDBond,
		doubleCDBond,
		tripleCDBond,
		dativeCDBond,
		singleDashCDBond,
		doubleDashCDBond,
		tripleDashCDBond,
		hashCDBond,
               hollowWedgeCDBond,
               wedgeHashCDBond,
               wedgeCDBond,
                 wavyCDBond,
		unknownCDBond
    } CDBondOrder;


SMART(CDNode );
class CDNode_O : public core::CxxObject_O
{	
  friend class CDFragment_O;
  LISP_BASE1(core::CxxObject_O);
  LISP_CLASS(chem,ChemPkg,CDNode_O,"CDNode");
 public:
  uint				_Id;
  std::string       		_Label;
  StereochemistryType		_StereochemistryType;
  ConfigurationEnum		_Configuration;
 private:	// generated
  gc::Nilable<Atom_sp>		_Atom;
  gc::Nilable<CDNode_sp>		_BackSpan;
  gc::Nilable<CDNode_sp>		_NextSpan;
  core::List_sp _AtomProperties;
  core::List_sp _ResidueProperties;
  core::List_sp _MoleculeProperties;
 public:
  void	initialize();
 private:
  std::string	_extractLabel(adapt::QDomNode_sp node);
 public:
  uint	getId() const { return this->_Id;};
  void    setId(uint i) { this->_Id = i; };
//        core::Symbol_sp getLabel() const { return this->_Label;};
	/*! Parse the label into a name and ionization component "name/[+-] */
  void getParsedLabel(string& name, int& ionization) const;
//	void setLabel(core::Symbol_sp l) { this->_Label = l;};
  Atom_sp	getAtom() const { return this->_Atom;};
  void setAtom(Atom_sp a) { this->_Atom = a;};
  void	parseFromXml(adapt::QDomNode_sp xml);

  void	bondTo( CDNode_sp neighbor, CDBondOrder order);

  CDNode_O( const CDNode_O& ss ); //!< Copy constructor

 CDNode_O() : _Atom(_Nil<core::T_O>())
    , _BackSpan(_Nil<core::T_O>())
    , _NextSpan(_Nil<core::T_O>())
    , _AtomProperties(_Nil<core::T_O>())
    , _ResidueProperties(_Nil<core::T_O>())
    , _MoleculeProperties(_Nil<core::T_O>())
  {};
  virtual ~CDNode_O() {};
};


SMART(CDBond );
class CDBond_O : public core::CxxObject_O
{
    LISP_BASE1(core::CxxObject_O);
    LISP_CLASS(chem,ChemPkg,CDBond_O,"CDBond");
private:
	uint		_IdBegin;
	uint		_IdEnd;
	CDNode_sp	_BeginNode;
	CDNode_sp	_EndNode;
	CDBondOrder	_Order;
public:
	void	initialize();
public:
	string	getOrderAsString();
	CDBondOrder	getOrder() { return this->_Order; };
	void setOrder(CDBondOrder o) { this->_Order = o; };
	BondOrder	getOrderAsBondOrder();
	uint		getIdBegin() { return this->_IdBegin;};
	void	setIdBegin(uint i) { this->_IdBegin = i;};
	uint		getIdEnd() { return this->_IdEnd;};
	void	setIdEnd(uint i) { this->_IdEnd = i;};
	void	setBeginNode(CDNode_sp n) { this->_BeginNode = n;};
	CDNode_sp getBeginNode() {_OF(); ANN(this->_BeginNode);return this->_BeginNode;};
	void	setEndNode(CDNode_sp n) { this->_EndNode = n;};
	CDNode_sp getEndNode() {_OF(); ANN(this->_EndNode);return this->_EndNode;};

	void	parseFromXml(adapt::QDomNode_sp xml);

	CDBond_O( const CDBond_O& ss ); //!< Copy constructor

	DEFAULT_CTOR_DTOR(CDBond_O);
};



SMART(CDFragment );
class CDFragment_O : public core::CxxObject_O
{
    LISP_BASE1(core::CxxObject_O);
    LISP_CLASS(chem,ChemPkg,CDFragment_O,"CDFragment");
public:
    typedef gctools::Vec0<CDBond_sp>	CDBonds;
    typedef gctools::SmallMap<Atom_sp,CDNode_sp> AtomsToBonds; // map<Atom_sp,CDNode_sp>	AtomsToBonds;
    typedef gctools::SmallMap<int,CDNode_sp> IntMappedCDNodes; // typedef map<int,CDNode_sp>		IntMappedCDNodes;
private:
    core::Symbol_sp		_ConstitutionName;
    IntMappedCDNodes		_Nodes;
    AtomsToBonds		_AtomsToNodes;
    CDBonds			_Bonds;
    int				_LargestId;
    gc::Nilable<Molecule_sp> _Molecule;
//    core::HashTableEq_sp		_Properties;
public:
    void	initialize();
private:
    bool _asKeyedObject(core::Symbol_sp label, core::Symbol_sp& keyword, core::T_sp& obj);
private:
//    Residue_sp _buildResidue(bool constitutionOnly);

public:
    void setConstitutionName(core::Symbol_sp n) { this->_ConstitutionName = n;};
    core::Symbol_sp getConstitutionName() { return this->_ConstitutionName;};

#if 0
    core::HashTableEq_sp getProperties() { return this->_Properties;};
    void	addProperties(core::HashTableEq_sp dict);
    //! Get the property for this ChemDraw Fragment
    core::T_sp getProperty(core::Symbol_sp key);
    core::T_sp getPropertyOrDefault(core::Symbol_sp key, core::T_sp df);
    bool hasProperty(core::Symbol_sp key);
    core::T_sp setProperty(core::Symbol_sp key, core::T_sp df);
    string describeProperties();
#endif
    Atom_sp createOneAtom(CDNode_sp n);
    void	createAtomsAndBonds();
    void	createImplicitHydrogen(CDNode_sp from, const string& name);
    void	parseFromXml(adapt::QDomNode_sp xml);
    /*! Return false if the fragment couldn't be interpreted */
    bool	interpret();

core::T_sp getMolecule() { return this->_Molecule; };


    int countNeighbors(CDNode_sp node);
    void createBonds(bool selectedAtomsOnly);
Molecule_sp createMolecule();
    void removeAllBonds();
    void clearAtomSelected();


    Residue_sp createResidueOfSelectedAtoms();

//    Residue_sp getEntireResidue();
    ConstitutionAtoms_sp asConstitutionAtoms();

    string __repr__() const;

    CDFragment_O( const CDFragment_O& ss ); //!< Copy constructor

 CDFragment_O() : _Molecule(_Nil<core::T_O>()) {};
    virtual ~CDFragment_O() {};
};



SMART(CDText );
class CDText_O : public core::CxxObject_O
{
    LISP_BASE1(core::CxxObject_O);
    LISP_CLASS(chem,ChemPkg,CDText_O,"CDText");
#if INIT_TO_FACTORIES
 public:
    static CDText_sp make(core::HashTableEq_sp kprops);
#else
    DECLARE_INIT();
#endif
private:
	string			_Text;
	core::HashTableEq_sp		_Properties;
public:
	void	initialize();
public:

	void	parseFromXml(adapt::QDomNode_sp xml);

	bool	hasProperties();
	core::HashTableEq_sp getProperties() { return this->_Properties; };

	CDText_O( const CDText_O& ss ); //!< Copy constructor

	DEFAULT_CTOR_DTOR(CDText_O);
};




SMART(ChemDraw );
class ChemDraw_O : public core::CxxObject_O
{
    LISP_BASE1(core::CxxObject_O);
    LISP_CLASS(chem,ChemPkg,ChemDraw_O,"ChemDraw");
#if INIT_TO_FACTORIES
 public:
    static ChemDraw_sp make(core::T_sp stream);
#else
    DECLARE_INIT();
#endif
    public:
	static void lisp_initGlobals(core::Lisp_sp lisp);
public:
    typedef	gctools::Vec0<CDFragment_sp>	Fragments;
	typedef adapt::SymbolMap<CDFragment_O>	NamedFragments;
private:
	Fragments	_AllFragments;
	NamedFragments	_NamedFragments;
public:
//	void	archive(core::ArchiveP node);
	void	initialize();
private:
	// instance variables
public:
private:
	string	_getAtomName(adapt::QDomNode_sp node);
public:
        void parse(core::T_sp strm);

	/*! Set the properties for the named fragment.
	  @param fragmentName The name of the fragment whose properties are being set
	  @param properties is a property list (keyword symbol/object pairs) */
        void setFragmentProperties(core::Symbol_sp name
                                       , core::T_sp comment
                                       , core::T_sp chiral_centers
                                       , core::T_sp group
                                       , core::T_sp name_template
                                       , core::T_sp pdb_template
                                       , core::T_sp restraints
                                       , core::T_sp residue_charge
                                       , core::T_sp restrained_pi_bonds
                                       , core::T_sp caps);



	core::List_sp getFragments();
	core::List_sp allFragmentsAsCons() { return this->getFragments();};
	core::List_sp getSubSetOfFragments(adapt::SymbolSet_sp subsetNames );


    /*! Return the entire ChemDraw file as an Aggregate and each structure
      is a Molecule with the name given by the hashed-bond-:name attribute
    */
    Aggregate_sp asAggregate();


	ChemDraw_O( const ChemDraw_O& ss ); //!< Copy constructor

	DEFAULT_CTOR_DTOR(ChemDraw_O);
};


};
TRANSLATE(chem::CDNode_O);
TRANSLATE(chem::CDBond_O);
TRANSLATE(chem::CDFragment_O);
TRANSLATE(chem::CDText_O);
TRANSLATE(chem::ChemDraw_O);
#endif //]