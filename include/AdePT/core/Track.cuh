// SPDX-FileCopyrightText: 2022 CERN
// SPDX-License-Identifier: Apache-2.0

#ifndef ADEPT_TRACK_CUH
#define ADEPT_TRACK_CUH

#include <AdePT/core/TrackData.h>
#include <AdePT/copcore/SystemOfUnits.h>
#include <AdePT/copcore/Ranluxpp.h>

#include <VecGeom/base/Vector3D.h>
#include <VecGeom/navigation/NavigationState.h>

#ifdef USE_SPLIT_KERNELS
#include <G4HepEmRandomEngine.hh>
#endif

// A data structure to represent a particle track. The particle type is implicit
// by the queue and not stored in memory.
struct Track {
  using Precision = vecgeom::Precision;

  RanluxppDouble rngState;
  double eKin;
  double numIALeft[4];
  double initialRange;
  double dynamicRangeFactor;
  double tlimitMin;

  double globalTime{0};
  double localTime{0};
  double properTime{0};

  vecgeom::Vector3D<Precision> pos;
  vecgeom::Vector3D<Precision> dir;
  vecgeom::NavigationState navState;

#ifdef USE_SPLIT_KERNELS
  // Variables used to store track info needed for scoring
  vecgeom::NavigationState nextState;
  vecgeom::NavigationState preStepNavState;
  vecgeom::Vector3D<Precision> preStepPos;
  vecgeom::Vector3D<Precision> preStepDir;
  RanluxppDouble newRNG;
  double preStepEKin{0};

  // Variables used to store navigation results
  double geometryStepLength{0};
  double safety{0};
  long hitsurfID{0};
#endif

  int parentID{0}; // Stores the track id of the initial particle given to AdePT

#ifdef USE_SPLIT_KERNELS
  bool propagated{false};

  // Variables used to store results from G4HepEM
  bool restrictedPhysicalStepLength{false};
  bool stopped{false};
#endif

  __host__ __device__ double Uniform() { return rngState.Rndm(); }

  __host__ __device__ void InitAsSecondary(const vecgeom::Vector3D<Precision> &parentPos,
                                           const vecgeom::NavigationState &parentNavState, double gTime)
  {
    // The caller is responsible to branch a new RNG state and to set the energy.
    this->numIALeft[0] = -1.0;
    this->numIALeft[1] = -1.0;
    this->numIALeft[2] = -1.0;
    this->numIALeft[3] = -1.0;

    this->initialRange       = -1.0;
    this->dynamicRangeFactor = -1.0;
    this->tlimitMin          = -1.0;

    // A secondary inherits the position of its parent; the caller is responsible
    // to update the directions.
    this->pos      = parentPos;
    this->navState = parentNavState;

    // The global time is inherited from the parent
    this->globalTime = gTime;
    this->localTime  = 0.;
    this->properTime = 0.;
  }

  __host__ __device__ void CopyTo(adeptint::TrackData &tdata, int pdg)
  {
    tdata.pdg          = pdg;
    tdata.parentID     = parentID;
    tdata.position[0]  = pos[0];
    tdata.position[1]  = pos[1];
    tdata.position[2]  = pos[2];
    tdata.direction[0] = dir[0];
    tdata.direction[1] = dir[1];
    tdata.direction[2] = dir[2];
    tdata.eKin         = eKin;
    tdata.globalTime   = globalTime;
    tdata.localTime    = localTime;
    tdata.properTime   = properTime;
  }
};
#endif
