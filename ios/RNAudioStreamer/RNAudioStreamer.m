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

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(setUrl:(NSString *)urlString){
    
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

RCT_EXPORT_METHOD(stop) {
    if (_player) {
        [_player stop];
        _player = nil;
    }
}

RCT_EXPORT_METHOD(duration:(RCTResponseSenderBlock)callback){
    callback(@[[NSNull null], @(_player ? _player.duration : 0)]);
}

RCT_EXPORT_METHOD(currentTime:(RCTResponseSenderBlock)callback){
    callback(@[[NSNull null], @(_player ? _player.currentTime : 0)]);
}

RCT_EXPORT_METHOD(status:(RCTResponseSenderBlock)callback){\
    
    NSString *statusString;
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
    
    callback(@[[NSNull null], _player ? statusString : STOPPED]);
}

@end
