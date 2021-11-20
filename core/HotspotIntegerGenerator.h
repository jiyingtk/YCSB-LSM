//
//  zipfian_generator.h
//  YCSB-C
//
//  Created by Jinglei Ren on 12/7/14.
//  Copyright (c) 2014 Jinglei Ren <jinglei@ren.systems>.
//

#ifndef YCSB_C_HOTSPOTINTEGER_GENERATOR_H
#define YCSB_C_HOTSPOTINTEGER_GENERATOR_H

#include <cstdint>
#include <cmath>
#include <cassert>
#include "utils.h"

namespace ycsbc {

class HotspotIntegerGenerator : public Generator<uint64_t> {
 uint64_t lowerBound;
 uint64_t upperBound;
 uint64_t interval;
 uint64_t hotInterval;
 uint64_t coldInterval;
 double hotsetFraction;
 double hotOpnFraction;
 uint64_t last_value_;
 uint64_t dynamicShiftOps;
 uint64_t opCounter;
 public:

  
  HotspotIntegerGenerator(uint64_t lowerBound, uint64_t upperBound,
                   double hotsetFraction, double hotOpnFraction)  {
	if (hotsetFraction < 0.0 || hotsetFraction > 1.0) {
		fprintf(stderr,"Hotset fraction out of range. Setting to 0.0");
		hotsetFraction = 0.0;
	 }
	 if (hotOpnFraction < 0.0 || hotOpnFraction > 1.0) {
		fprintf(stderr,"Hot operation fraction out of range. Setting to 0.0");
		hotOpnFraction = 0.0;
	 }
	 if (lowerBound > upperBound) {
		fprintf(stderr,"Upper bound of Hotspot generator smaller than the lower bound.Swapping the values.");
		uint64_t temp = lowerBound;
		lowerBound = upperBound;
		upperBound = temp;
	}
	this->lowerBound = lowerBound;
	this->upperBound = upperBound;
	this->hotsetFraction = hotsetFraction;
	this->interval = upperBound - lowerBound + 1;
	this->hotInterval = (this->interval * hotsetFraction);
	this->coldInterval = this->interval - hotInterval;
	this->hotOpnFraction = hotOpnFraction;
	
	this->dynamicShiftOps = 1000000;
	if (this->dynamicShiftOps != 0) {
		fprintf(stderr, "[Hotspot] enable dynamic shift hotspot, every %lu ops", this->dynamicShiftOps);
	}
	this->opCounter = 0;
  }
  
  uint64_t Next() { 
	uint64_t value = 0;
	if(utils::RandomDouble() < hotOpnFraction){
		value = utils::RandomULL() % hotInterval;
	}else{
		value = hotInterval + utils::RandomULL()%coldInterval;
	}
	if (dynamicShiftOps != 0) {
		uint64_t shift = (opCounter / dynamicShiftOps) * hotInterval;	
		value = (value + shift) % interval;
	}
	value += lowerBound;
	last_value_ = value;
	opCounter++;
	return value;
  }

  uint64_t Last() { return last_value_; }
  
  uint64_t getLowerBound(){
	return lowerBound;
  }
  
  uint64_t getUpperBound(){
	return upperBound;
  }
  
  double getHotsetFraction(){
	    return hotsetFraction;
   }
   
   double getHotOpnFraction(){
	return hotOpnFraction;
   }
  
};


}

#endif // YCSB_C_ZIPFIAN_GENERATOR_H_
