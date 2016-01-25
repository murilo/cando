       
#define	DEBUG_LEVEL_FULL

#include "trainerArchive.h"
//#include "core/archive.h"
//#include "core/xmlSaveArchive.h"
//#include "core/xmlLoadArchive.h"
#include "trainer.h"
#include "core/wrappers.h"



namespace chem {





void	TrainerArchive_O::initialize()
{
    this->Base::initialize();
    this->_CandoDatabase = _Nil<CandoDatabase_O>();
    this->_Trainers.clear();
}

#ifdef XML_ARCHIVE
    void	TrainerArchive_O::archive(core::ArchiveP node)
{
    node->attribute("CandoDatabase",this->_CandoDatabase);
    node->attributeStringMap("Trainers",this->_Trainers);
}
#endif


#if 0
void	TrainerArchive_O::setCandoDatabase(CandoDatabase_sp hold)
{
    ASSERTNOTNULL(hold);
    this->_CandoDatabase = hold;
}
#endif

void	TrainerArchive_O::addTrainer(Trainer_sp job)
{
string		key;
    key = job->getHeader()->getContextKey();
    this->_Trainers.set(key,job);
}


bool	TrainerArchive_O::hasTrainerWithKey(const string& key)
{
    return this->_Trainers.contains(key);
}

Trainer_sp	TrainerArchive_O::getTrainerWithKey(const string& key)
{
    return this->_Trainers.get(key);
}



};

