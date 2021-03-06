//
//  TheKeyMission.h
//  ontherun
//
//  Created by Matt Donahoe on 5/13/11.
//  Copyright 2011 MIT Media Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FRMissionTemplate.h"
#import "FRRandomSound.h"

@interface TheKeyMission : FRMissionTemplate {
    FRPoint * pointA;
    FRPoint * pointB;
    FRPoint * pointC;
    FRPoint * dude;
    FRPoint * safehouse;
    int main_state;
    int sub_state;
    float xdist;
    float dude_speed;
    int chase_ticks;
    FRProgress * prog;
    
    FRRandomSound * badguy_taunts;
    FRRandomSound * losing_him;
    FRRandomSound * gaining_you;
    FRRandomSound * capture_warning;
}
- (void) the_first;
- (void) the_second;
- (void) the_third;
- (void) the_chase;
@end