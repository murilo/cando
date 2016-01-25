#define	DEBUG_LEVEL_FULL

#include <clasp/core/common.h>
#include <clasp/core/environment.h>
#include <cando/chem/atom.h>
#include <cando/chem/angle.h>
#include <clasp/core/wrappers.h>
namespace chem
{

// ----------------------------------------------------------------------
//








    Angle_sp Angle_O::create(Atom_sp a1, Atom_sp a2, Atom_sp a3)
    {
	GC_ALLOCATE(Angle_O, obj );
	obj->setup(a1,a2,a3);
	return obj;
    }


    void Angle_O::setup(Atom_sp a1, Atom_sp a2, Atom_sp a3)
    {_OF();
	this->_a1 = a1;
	this->_a2 = a2;
	this->_a3 = a3;
    }


#ifdef XML_ARCHIVE
    void Angle_O::archiveBase(core::ArchiveP node)
    {
        this->Base::archiveBase(node);
	// Archive other instance variables here
    }
#endif


    void Angle_O::initialize()
    {_OF();
        this->Base::initialize();
    }


    string Angle_O::__repr__() const
    {
	stringstream ss;
	ss << this->className() << "["<<this->_a1->getName()<<"-"<<this->_a2->getName()<<"-"<<this->_a3->getName()<<"]";
	return ss.str();
    }



}; /* chem */
