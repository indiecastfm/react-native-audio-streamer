//
//  RNAudioFileURL.h
//  RNAudioStreamer
//
//  Created by Victor Chan on 29/11/2016.
//  Copyright © 2016 Victor Chan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DOUAudioStreamer+Options.h"
#import "DOUAudioStreamer.h"

@interface RNAudioFileURL : NSObject<DOUAudioFile>
@property(strong, nonatomic) NSURL *url;
- (NSURL *)audioFileURL;
@end
