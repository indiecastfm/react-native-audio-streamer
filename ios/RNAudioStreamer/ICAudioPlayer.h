//
//  AudioPlayer.h
//  IndieplayerTest
//
//  Created by Victor Chan on 12/1/14.
//  Copyright (c) 2014 Victor Chan. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

/**
 *  Notifications
 */
static NSString *kICAudioPlayerBufferingRatioUpdateNotification =
    @"kICAudioPlayerBufferingRatioUpdateNotification";
static NSString *kICAudioPlayerStatusUpdateNotification =
    @"kICAudioPlayerStatusUpdateNotification";
static NSString *kICAudioPlayerTimerUpdateNotification =
    @"kICAudioPlayerTimerUpdateNotification";

/**
 ICAudioPlayerStatus
 */
typedef enum {
  ICAudioPlayerStatusPlaying,
  ICAudioPlayerStatusPaused,
  ICAudioPlayerStatusStopped,
  ICAudioPlayerStatusFinished,
  ICAudioPlayerStatusBuffering,
  ICAudioPlayerStatusError
} ICAudioPlayerStatus;

@interface ICAudioPlayer : NSObject <AVAudioPlayerDelegate>

/**
 *  Current status of ICAudioPlayer
 */
@property(nonatomic, readonly) NSUInteger status;

/**
 *  Check if audio is loaded from local or remote
 */
@property(nonatomic, readonly) BOOL isLocal;

/**
 *  Get duration of audio source (sec)
 */
@property(nonatomic, readonly) NSTimeInterval duration;

/**
 *  Get current time of audio player
 */
@property(nonatomic, assign) NSTimeInterval currentTime;

/**
 *  Cache file limit
 */
@property(nonatomic, assign) NSUInteger cacheFileLimit;

/**
 *  ICAudioPlayer Singleton Instance
 *
 *  @return ICAudioPlayer Singleton Instance
 */
+ (ICAudioPlayer *)sharedPlayer;

/**
 *  Input source URL. Check cache existence to load local player or stream
 * player
 *
 *  @param urlString Source URL
 */
- (void)preparePlayerWithUrl:(NSString *)urlString;

/**
 *  Play audio
 */
- (void)play;

/**
 *  Pause audio
 */
- (void)pause;

/**
 *  Stop audio
 */
- (void)stop;

/**
 *  Set current time of audio player
 *
 *  @param currentTime Current Time (sec)
 */
- (void)setCurrentTime:(NSTimeInterval)currentTime;

@end
