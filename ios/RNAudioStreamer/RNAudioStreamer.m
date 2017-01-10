//
//  RNAudioStreamer.m
//  RNAudioStreamer
//
//  Created by Victor Chan on 29/11/2016.
//  Copyright © 2016 Victor Chan. All rights reserved.
//

#import "RNAudioStreamer.h"
#import "ICAudioPlayer.h"
#import "ICAudioCacheManager.h"
#import <AVFoundation/AVFoundation.h>
#import "RCTEventDispatcher.h"

// Player status
static NSString *PLAYING = @"PLAYING";
static NSString *PAUSED = @"PAUSED";
static NSString *STOPPED = @"STOPPED";
static NSString *FINISHED = @"FINISHED";
static NSString *BUFFERING = @"BUFFERING";
static NSString *ERROR = @"ERROR";


@implementation RNAudioStreamer

static void *kStatusKVOKey = &kStatusKVOKey;

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(setUrl:(NSString *)urlString){
    
    // Remove previous observer
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kICAudioPlayerStatusUpdateNotification object:nil];
    
    //Audio session
    NSError *err;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&err];
    if (!err){
        [[AVAudioSession sharedInstance] setActive:YES error:&err];
        if(err) NSLog(@"Audio session error");
    }else{
        NSLog(@"Audio session error");
    }
    
    [[ICAudioPlayer sharedPlayer] preparePlayerWithUrl:urlString];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(statusChanged:) name:kICAudioPlayerStatusUpdateNotification object:nil];
}

RCT_EXPORT_METHOD(play) {
    [[ICAudioPlayer sharedPlayer] play];
}

RCT_EXPORT_METHOD(pause) {
    [[ICAudioPlayer sharedPlayer] pause];
}

RCT_EXPORT_METHOD(seekToTime: (double)time) {
    [[ICAudioPlayer sharedPlayer] setCurrentTime:time];
}

RCT_EXPORT_METHOD(duration:(RCTResponseSenderBlock)callback){
    callback(@[[NSNull null], @([[ICAudioPlayer sharedPlayer] duration])]);
}

RCT_EXPORT_METHOD(currentTime:(RCTResponseSenderBlock)callback){
    callback(@[[NSNull null], @([[ICAudioPlayer sharedPlayer] currentTime])]);
}

RCT_EXPORT_METHOD(status:(RCTResponseSenderBlock)callback){
    callback(@[[NSNull null], [self rnStatusFromICStatus]]);
}

RCT_EXPORT_METHOD(setCacheFileLimit: (int) limit){
    [[ICAudioPlayer sharedPlayer] setCacheFileLimit:limit];
}

RCT_EXPORT_METHOD(clearCache){
    [[ICAudioCacheManager sharedManager] clearCache];
}

RCT_EXPORT_METHOD(cacheSize:(RCTResponseSenderBlock)callback){
    callback(@[[NSNull null], [[ICAudioCacheManager sharedManager] humanReadableCacheSize]]);
}

- (void)statusChanged:(NSNotification *)notification {
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"RNAudioStreamerStatusChanged"
                                                    body: [self rnStatusFromICStatus]];
}

- (NSString *)rnStatusFromICStatus {
    NSString *statusString = STOPPED;
    switch([ICAudioPlayer sharedPlayer].status){
        case ICAudioPlayerStatusPlaying:
            statusString = PLAYING;
            break;
        case ICAudioPlayerStatusPaused:
            statusString = PAUSED;
            break;
        case ICAudioPlayerStatusStopped:
            statusString = STOPPED;
            break;
        case ICAudioPlayerStatusFinished:
            statusString = FINISHED;
            break;
        case ICAudioPlayerStatusBuffering:
            statusString = BUFFERING;
            break;
        case ICAudioPlayerStatusError:
            statusString = ERROR;
            break;
    }
    return statusString;
}

@end
