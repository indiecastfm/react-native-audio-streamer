//
//  PlayerDisplayInfo.m
//  IndieplayerTest
//
//  Created by Victor Chan on 14/1/14.
//  Copyright (c) 2014 Victor Chan. All rights reserved.
//

#import "ICAudioFileURL.h"

@implementation ICAudioFileURL

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
