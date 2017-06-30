//
//  RNAudioStreamer.m
//  RNAudioStreamer
//
//  Created by Victor Chan on 29/11/2016.
//  Copyright © 2016 Victor Chan. All rights reserved.
//

#import "RNAudioStreamer.h"
#import "STKAudioPlayer.h"
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
@property(strong, nonatomic) STKAudioPlayer *player;
@property(strong, nonatomic) NSURL *url;
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

    _url = [[NSURL alloc] initWithString:urlString];
    _player = [[STKAudioPlayer alloc] init];
    _player.volume = 1;


    // Status observer
    [_player addObserver:self
              forKeyPath:@"state"
                 options:NSKeyValueObservingOptionNew
                 context:kStatusKVOKey];
}

RCT_EXPORT_METHOD(play) {
    if(_player) [_player playURL:_url];
}

RCT_EXPORT_METHOD(pause) {
    if(_player) [_player pause];
}

RCT_EXPORT_METHOD(seekToTime: (double)time) {
   if(_player) [_player seekToTime:time];
}

RCT_EXPORT_METHOD(duration:(RCTResponseSenderBlock)callback){
    callback(@[[NSNull null], @(_player && _player.duration && _player.duration > 0 ? _player.duration : 0)]);
}

RCT_EXPORT_METHOD(currentTime:(RCTResponseSenderBlock)callback){
    callback(@[[NSNull null], @(_player && _player.progress && _player.progress > 0 ? _player.progress : 0)]);
}

RCT_EXPORT_METHOD(status:(RCTResponseSenderBlock)callback){
    callback(@[[NSNull null], _player ? [self mapStatus] : STOPPED]);
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
                                                    body: _player ? [self mapStatus] : STOPPED];
}

- (NSString *)mapStatus {
    switch(_player.state){
        case STKAudioPlayerStatePlaying:
            return PLAYING;
        case STKAudioPlayerStatePaused:
            return PAUSED;
        case STKAudioPlayerStateStopped:
            return STOPPED;
        case STKAudioPlayerStateDisposed:
            return FINISHED;
        case STKAudioPlayerStateBuffering:
            return BUFFERING;
        case STKAudioPlayerStateError:
            return ERROR;
        default:
            return STOPPED;
    }
}

- (void)killPlayer{
  if (!_player) return;
  [_player stop];
  [_player removeObserver:self forKeyPath:@"state"];
  _player = nil;
}

- (void)dealloc{
    [self killPlayer];
}

@end
