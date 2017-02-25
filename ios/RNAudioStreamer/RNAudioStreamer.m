//
//  RNAudioStreamer.m
//  RNAudioStreamer
//
//  Created by Victor Chan on 29/11/2016.
//  Copyright © 2016 Victor Chan. All rights reserved.
//

#import "RNAudioStreamer.h"
#import "DOUAudioStreamer.h"
#import "RNAudioFileURL.h"
#import <AVFoundation/AVFoundation.h>
#import "RCTEventDispatcher.h"

// Player status
static NSString *PLAYING = @"PLAYING";
static NSString *PAUSED = @"PAUSED";
static NSString *STOPPED = @"STOPPED";
static NSString *FINISHED = @"FINISHED";
static NSString *BUFFERING = @"BUFFERING";
static NSString *ERROR = @"ERROR";

@interface RNAudioStreamer ()
@property(strong, nonatomic) DOUAudioStreamer *player;
@property(strong, nonatomic) RNAudioFileURL *douUrl;
@end

@implementation RNAudioStreamer

static void *kStatusKVOKey = &kStatusKVOKey;

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(setUrl:(NSString *)urlString){

    [self killPlayer];

    //Audio session
    NSError *err;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&err];
    if (!err){
        [[AVAudioSession sharedInstance] setActive:YES error:&err];
        if(err) NSLog(@"Audio session error");
    }else{
        NSLog(@"Audio session error");
    }


    NSURL *url = [[NSURL alloc] initWithString:urlString];
    _douUrl = [[RNAudioFileURL alloc] init];
    _douUrl.url = url;
    _player = [[DOUAudioStreamer alloc] initWithAudioFile:_douUrl];

    // Status observer
    [_player addObserver:self
              forKeyPath:@"status"
                 options:NSKeyValueObservingOptionNew
                 context:kStatusKVOKey];
}

RCT_EXPORT_METHOD(play) {
    if(_player) [_player play];
}

RCT_EXPORT_METHOD(pause) {
    if(_player) [_player pause];
}

RCT_EXPORT_METHOD(seekToTime: (double)time) {
   if(_player) [_player setCurrentTime:time];
}

RCT_EXPORT_METHOD(duration:(RCTResponseSenderBlock)callback){
    callback(@[[NSNull null], @(_player && _player.duration && _player.duration > 0 ? _player.duration : 0)]);
}

RCT_EXPORT_METHOD(currentTime:(RCTResponseSenderBlock)callback){
    callback(@[[NSNull null], @(_player && _player.currentTime && _player.currentTime > 0 ? _player.currentTime : 0)]);
}

RCT_EXPORT_METHOD(status:(RCTResponseSenderBlock)callback){
    callback(@[[NSNull null], _player ? [self rnStatusFromDouStatus] : STOPPED]);
}

/**
 *  Status KVO
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (context == kStatusKVOKey) {
        [self performSelector:@selector(statusChanged)
                     onThread:[NSThread mainThread]
                   withObject:nil
                waitUntilDone:NO];
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

- (void)statusChanged {
    [self.bridge.eventDispatcher sendDeviceEventWithName:@"RNAudioStreamerStatusChanged"
                                                    body: _player ? [self rnStatusFromDouStatus] : STOPPED];
}

- (NSString *)rnStatusFromDouStatus {
    NSString *statusString = STOPPED;
    switch(_player.status){
        case DOUAudioStreamerPlaying:
            statusString = PLAYING;
            break;
        case DOUAudioStreamerPaused:
            statusString = PAUSED;
            break;
        case DOUAudioStreamerIdle:
            statusString = STOPPED;
            break;
        case DOUAudioStreamerFinished:
            statusString = FINISHED;
            break;
        case DOUAudioStreamerBuffering:
            statusString = BUFFERING;
            break;
        case DOUAudioStreamerError:
            statusString = ERROR;
            break;
    }
    return statusString;
}

- (void)killPlayer{
  if (!_player) return;
  [_player stop];
  [_player removeObserver:self forKeyPath:@"status"];
  _player = nil;
}

- (void)dealloc{
    [self killPlayer];
}

@end
