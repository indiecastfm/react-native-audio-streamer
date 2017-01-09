//
//  PlayerDisplayInfo.h
//  IndieplayerTest
//
//  Created by Victor Chan on 14/1/14.
//  Copyright (c) 2014 Victor Chan. All rights reserved.
//

#import "DOUAudioStreamer+Options.h"
#import "DOUAudioStreamer.h"
#import <Foundation/Foundation.h>

@interface ICAudioFileURL : NSObject <DOUAudioFile>
@property(strong, nonatomic) NSURL *url;
- (NSURL *)audioFileURL;
@end
