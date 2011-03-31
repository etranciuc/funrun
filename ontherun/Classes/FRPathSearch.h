//
//  FRPathSearch.h
//  ontherun
//
//  Created by Matt Donahoe on 2/1/11.
//  Copyright 2011 MIT Media Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FREdgePos.h"
#import "FRMap.h"

//this object is about storing the shortest paths over a graph. it is generated by the FRMap class.
@interface FRPathSearch : NSObject {
	NSDictionary * previous;
	NSDictionary * distance;
	FRMap * map;
	FREdgePos * root;
}
@property (nonatomic,retain) FREdgePos * root;

- (FRMap *)getMap;
- (id) initWithRoot:(FREdgePos *)r previous:(NSDictionary *)p distance:(NSDictionary *)d map:(FRMap *)m;
- (FREdgePos *) move:(FREdgePos*)ep towardRootWithDelta:(float)dx;
- (FREdgePos *) move:(FREdgePos*)ep awayFromRootWithDelta:(float)dx;
- (BOOL) isFacingRoot:(FREdgePos*)ep;
- (BOOL) containsPoint:(FREdgePos*)ep;
- (float) distanceFromRoot:(FREdgePos*)ep;
- (NSString *) directionFromRoot:(FREdgePos*)ep;
- (NSString *) directionToRoot:(FREdgePos*)ep;
- (FREdgePos *) edgePosThatIsDistance:(float)d fromRootAndOther:(FRPathSearch*)p;
@end
