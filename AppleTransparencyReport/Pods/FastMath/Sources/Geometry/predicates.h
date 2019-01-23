//
//  predicates.h
//  Delaunay
//
//  Created by andrew mcknight on 4/30/12.
//  Copyright (c) 2012 old dominion university. All rights reserved.
//

#ifndef Delaunay_predicates_h
#define Delaunay_predicates_h

void exactinit();
double incircle(double *pa, double *pb, double *pc, double *pd);
double orient2d(double *pa, double *pb, double *pc);

#endif
