//
//  FRMissionTemplate.m
//  ontherun
//
//  Created by Matt Donahoe on 3/14/11.
//  Copyright 2011 MIT Media Lab. All rights reserved.
//

#import "FRMissionTemplate.h"
#import "FRBriefingViewController.h"
#import "JSON.h"
#import "FRFileLoader.h"

@implementation FRMissionTemplate
@synthesize points,viewControl;

- (id) initWithLocation:(CLLocation*)l viewControl:(UIViewController*)vc {
	self = [super init];
	if (!self) return nil;
	
    //Voice Communication
	//link to /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS4.2.sdk/System/Library/PrivateFrameworks/VoiceServices.framework
	voicebot = [[NSClassFromString(@"VSSpeechSynthesizer") alloc] init];
	[voicebot setDelegate:self];
	toBeSpoken = [[NSMutableArray alloc] init];
	previously_said = nil;
	
	//communication with server
	
	
	
	//init the fileloader so we can skip network downloads if already cached
	NSAutoreleasePool * thepool = [[NSAutoreleasePool alloc] init];
	FRFileLoader * loader = [[FRFileLoader alloc] initWithBaseURLString:@"http://toqbot.com/otr/test1/"];
	
	//load the map
	
	//[loader deleteCacheForFile:filename];
	//might still have dead ends
	NSDictionary * mapdata = [[NSString stringWithContentsOfFile:[loader pathForFile:@"mapdata_nullfree.json"]
														encoding:NSUTF8StringEncoding
														   error:NULL] JSONValue];
	
    themap = [[FRMap alloc] initWithNodes:[mapdata objectForKey:@"nodes"] andRoads:[mapdata objectForKey:@"roads"]];
	
	[loader release];
	[thepool release];
	
	player = [[FRPoint alloc] initWithDict:[NSDictionary dictionaryWithObject:@"player" forKey:@"name"] onMap:themap];
	[self newPlayerLocation:l];
	player.pos = [themap edgePosFromPoint:l];
	[player setCoordinate:[themap coordinateFromEdgePosition:player.pos]];
	points = [[NSMutableArray alloc] initWithObjects:player,nil];
	

	[voicebot setRate:1.3];
	[voicebot setPitch:0.25];
	
	FRBriefingViewController * brief = 
	[[[FRBriefingViewController alloc] initWithNibName:@"FRBriefingViewController"
												bundle:nil] autorelease];
	[brief setText:@"nothing to see here"];
	brief.mission = self;
	[vc.navigationController pushViewController:brief animated:YES];
	self.viewControl = brief;
	return self;
}

- (void) speak:(NSString *)text {
	if ([voicebot isSpeaking] || [toBeSpoken count]){
		[toBeSpoken addObject:text];
	} else {
		if ([text isEqualToString:previously_said]) return;
		[self speakNow:text];
	}
}
- (void) speakNow:(NSString *)text{
	[voicebot startSpeakingString:text];
	[text retain];
	[previously_said release];
	previously_said = text;
}
- (void) speakIfEmpty:(NSString *) text {
	if (![voicebot isSpeaking] && [toBeSpoken count]==0 && [text isEqualToString:previously_said]==NO)
		[self speakNow:text];
}
- (void) speechSynthesizer:(NSObject *) synth didFinishSpeaking:(BOOL)didFinish withError:(NSError *) error { 
	// Handle the end of speech here
	
	while ([toBeSpoken count]){
		NSString * text = [toBeSpoken objectAtIndex:0];
		[text retain];
		[toBeSpoken removeObjectAtIndex:0];
		if (![text isEqualToString:previously_said]){
			[self speakNow:text];
			[text release];
			break;
		} else {
			[text release];
		}
	}
}
- (void) ticktock {
	/*
	 This method is called once a second
	 
	 todo: it could be possible to call this more than once a second, dual threading. that would be bad
	 */
	
	//update map positions
	for (FRPoint * pt in points){
		[pt setCoordinate:[themap coordinateFromEdgePosition:pt.pos]];
	}
	//[viewControl missionTick];
	[self performSelector:@selector(ticktock) withObject:nil afterDelay:1.0];
};
- (void) newPlayerLocation:(CLLocation *)location {
	/*
	 This method is called whenever a new player location
	 update is available.
	 
	 a new point comes from the network
	 or the gps
	 */
	
	
	NSLog(@"newPlayerLocation: %@",location);
	//convert to map coordinates
	FREdgePos * ep = [themap edgePosFromPoint:location];
	
	//speak the current road, if it changed
	NSString * roadname = [themap roadNameFromEdgePos:ep];
	if ([roadname isEqualToString:current_road]==NO && roadname){
		[roadname retain];
		[current_road release];
		current_road = roadname;
		[self speak:current_road];
	}
	
	if (latestsearch) {
		player.pos = [latestsearch move:ep awayFromRootWithDelta:0];
	} else {
		player.pos = ep;
	}
	
	[latestsearch release];
	latestsearch = [themap createPathSearchAt:player.pos withMaxDistance:[NSNumber numberWithFloat:1000.0]]; //this number needs to be adjustable i think.
}

/*
- (void) playsounds {
	 
	//Be able to play random sound effects.
	//Initially used to prevent deep sleep
	 
	//Code from this blog:
	//http://blog.marcopeluso.com/2009/08/23/how-to-prevent-iphone-from-deep-sleeping/
	 
	 
	// Activate audio session
	AudioSessionSetActive(true);
	// Set up audio session, to prevent iPhone from deep sleeping, while playing sounds
	UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
	AudioSessionSetProperty (
							 kAudioSessionProperty_AudioCategory,
							 sizeof (sessionCategory),
							 &sessionCategory
							 );
	
	// Set up sound file
	NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"lion1"
															  ofType:@"wav"];
	NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:soundFilePath];
	NSError *audioerror = nil;
	// Set up audio player with sound file
	audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&audioerror];
	[audioPlayer prepareToPlay];
	
	// You may want to set this to 0.0 even if your sound file is silent.
	[audioPlayer setVolume:1.0];
	
}
*/
- (void) abort {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[toBeSpoken removeAllObjects];
	[self speak:@"Mission Aborted"];
}
- (void) playSong:(NSString *)name {
    [backgroundMusicPlayer release];
    NSString * path = [[NSBundle mainBundle] pathForResource:name ofType:@"mp3"];
    NSURL * url = [NSURL fileURLWithPath:path];
    NSError * error;
    backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    [backgroundMusicPlayer prepareToPlay];
    [backgroundMusicPlayer play];
}
- (void) dealloc {
	[player release];
	[points release];
	[themap release];
    [voicebot release];
	[toBeSpoken release];
	[latestsearch release];
    [current_road release];
    [previously_said release];
	[backgroundMusicPlayer release];
	self.viewControl = nil;
    [super dealloc];
	NSLog(@"mission is dead");
}
@end
