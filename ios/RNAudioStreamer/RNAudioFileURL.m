//
//  RNAudioFileURL.m
//  RNAudioStreamer
//
//  Created by Victor Chan on 29/11/2016.
//  Copyright © 2016 Victor Chan. All rights reserved.
//

#import "RNAudioFileURL.h"

@implementation RNAudioFileURL
- (id)init {
    
    if (self = [super init]) {
        self.url = nil;
    }
    return self;
}

- (NSURL *)audioFileURL {
    return [self url];
}

@end
