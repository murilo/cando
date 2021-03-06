/*
    File: energyPointToLineRestraint.cc
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
       
#define	DEBUG_LEVEL_NONE

#include <cando/chem/energyPointToLineRestraint.h>
#include <cando/chem/energyFunction.h>
#include <cando/chem/largeSquareMatrix.h>
#include <cando/chem/bond.h>
#include <cando/chem/matter.h>
#include <cando/chem/atom.h>
#include <cando/chem/residue.h>
#include <cando/chem/energyStretch.h>
#include <cando/chem/aggregate.h>
#include <cando/chem/nVector.h>
#include <cando/chem/ffBaseDb.h>
#include <cando/chem/ffTypesDb.h>
#include <clasp/core/wrappers.h>

namespace chem {


EnergyPointToLineRestraint_sp EnergyPointToLineRestraint_O::create(EnergySketchStretch_sp stretch) {
  GC_ALLOCATE_VARIADIC(EnergyPointToLineRestraint_O,obj,stretch);
  return obj;
}


double EnergyPointToLineRestraint_O::evaluateAllComponent( ScoringFunction_sp score,
                                                  NVector_sp 	pos,
                                                  bool 		calcForce,
                                                  gc::Nilable<NVector_sp> 	force,
                                                  bool		calcDiagonalHessian,
                                                  bool		calcOffDiagonalHessian,
                                                  gc::Nilable<AbstractLargeSquareMatrix_sp>	hessian,
                                                  gc::Nilable<NVector_sp>	hdvec,
                                                  gc::Nilable<NVector_sp> dvec)
{
  bool	hasForce = force.notnilp();
  bool	hasHessian = hessian.notnilp();
  bool	hasHdAndD = (hdvec.notnilp())&&(dvec.notnilp());
//
// Copy from implementAmberFunction::evaluateAll
//
// -----------------------

#define POINT_TO_LINE_RESTRAINT_CALC_FORCE
#define POINT_TO_LINE_RESTRAINT_CALC_DIAGONAL_HESSIAN
#define POINT_TO_LINE_RESTRAINT_CALC_OFF_DIAGONAL_HESSIAN
#undef	POINT_TO_LINE_RESTRAINT_SET_PARAMETER
#define	POINT_TO_LINE_RESTRAINT_SET_PARAMETER(x)	{x = cri->term.x;}
#undef	POINT_TO_LINE_RESTRAINT_SET_POSITION
#define	POINT_TO_LINE_RESTRAINT_SET_POSITION(x,ii,of)	{x = pos->element(ii+of);}
#undef	POINT_TO_LINE_RESTRAINT_PHI_SET
#define	POINT_TO_LINE_RESTRAINT_PHI_SET(x) {}
#undef	POINT_TO_LINE_RESTRAINT_ENERGY_ACCUMULATE
#define	POINT_TO_LINE_RESTRAINT_ENERGY_ACCUMULATE(e) this->_TotalEnergy += (e);
#undef	POINT_TO_LINE_RESTRAINT_FORCE_ACCUMULATE
#undef	POINT_TO_LINE_RESTRAINT_DIAGONAL_HESSIAN_ACCUMULATE
#undef	POINT_TO_LINE_RESTRAINT_OFF_DIAGONAL_HESSIAN_ACCUMULATE
#define	POINT_TO_LINE_RESTRAINT_FORCE_ACCUMULATE 		ForceAcc
#define	POINT_TO_LINE_RESTRAINT_DIAGONAL_HESSIAN_ACCUMULATE 	DiagHessAcc
#define	POINT_TO_LINE_RESTRAINT_OFF_DIAGONAL_HESSIAN_ACCUMULATE OffDiagHessAcc


  if ( this->isEnabled() ) {
    double bond_length = this->_Bond_div_2*2.0;
    for (size_t stretch_idx= 0; stretch_idx<this->_Stretch->_Terms.size(); stretch_idx++ ) {
      EnergySketchStretch& estretch = this->_Stretch->_Terms[stretch_idx];
      int IA = estretch.term.I1;
      int IB = estretch.term.I2;
      Vector3 vA((*pos)[IA+0],(*pos)[IA+1],(*pos)[IA+2]);
      Vector3 vB((*pos)[IB+0],(*pos)[IB+1],(*pos)[IB+2]);
      Vector3 dx21 = vB-vA;
      double x2mx1sq = dx21.dotProduct(dx21);
      for ( size_t I1 = 0; I1 < pos->length(); I1+=3 ) {
        if (I1!=IA && I1!=IB) {
          Vector3 v1((*pos)[I1+0],(*pos)[I1+1],(*pos)[I1+2]);
          if (this->_ForceConstant>0.0) {
            if (fabs(v1.getX()-vA.getX()) > bond_length) continue;
            if (fabs(v1.getY()-vA.getY()) > bond_length) continue;
            if (fabs(v1.getZ()-vA.getZ()) > bond_length) continue;
            if (fabs(v1.getX()-vB.getX()) > bond_length) continue;
            if (fabs(v1.getY()-vB.getY()) > bond_length) continue;
            if (fabs(v1.getZ()-vB.getZ()) > bond_length) continue;
          } else {
            if (fabs(v1.getX()-vA.getX()) < bond_length) continue;
            if (fabs(v1.getY()-vA.getY()) < bond_length) continue;
            if (fabs(v1.getZ()-vA.getZ()) < bond_length) continue;
            if (fabs(v1.getX()-vB.getX()) < bond_length) continue;
            if (fabs(v1.getY()-vB.getY()) < bond_length) continue;
            if (fabs(v1.getZ()-vB.getZ()) < bond_length) continue;
          }
          Vector3 dx10 = vA-v1;
          double dot = dx10.dotProduct(dx21);
          double t = dot/x2mx1sq;
          if (t<0.0 || t>1.0) continue;
          Vector3 close = (dx21*t)+vA;
          Vector3 d = v1-close;
          double dist = d.length();
          if (this->_ForceConstant > 0.0 ) {
            if (dist < this->_Bond_div_2) {
              if (dist > 0.01) {
                Vector3 fv = d*(this->_ForceConstant/dist);
                POINT_TO_LINE_RESTRAINT_FORCE_ACCUMULATE(I1,0,fv.getX());
                POINT_TO_LINE_RESTRAINT_FORCE_ACCUMULATE(I1,1,fv.getY());
                POINT_TO_LINE_RESTRAINT_FORCE_ACCUMULATE(I1,2,fv.getZ());
              } else {
                POINT_TO_LINE_RESTRAINT_FORCE_ACCUMULATE(I1,0,0.5*core::randomNumber01());
                POINT_TO_LINE_RESTRAINT_FORCE_ACCUMULATE(I1,1,0.5*core::randomNumber01());
                POINT_TO_LINE_RESTRAINT_FORCE_ACCUMULATE(I1,2,0.5*core::randomNumber01());
              }
            }
          } else {
            if (dist>this->_Bond_div_2) {
              Vector3 fv = d*(this->_ForceConstant/dist);
              POINT_TO_LINE_RESTRAINT_FORCE_ACCUMULATE(I1,0,fv.getX());
              POINT_TO_LINE_RESTRAINT_FORCE_ACCUMULATE(I1,1,fv.getY());
              POINT_TO_LINE_RESTRAINT_FORCE_ACCUMULATE(I1,2,fv.getZ());
            }
          }
        }
      }
    }
  }
  return this->_TotalEnergy;
}


void EnergyPointToLineRestraint_O::initialize()
{
    this->Base::initialize();
    this->setErrorThreshold(0.2);
}

void EnergyPointToLineRestraint_O::reset()
{
}


};
