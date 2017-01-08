//
//  AudioPlayer.m
//  IndieplayerTest
//
//  Created by Victor Chan on 12/1/14.
//  Copyright (c) 2014 Victor Chan. All rights reserved.
//

#import "DOUAudioStreamer.h"
#import "ICAudioCacheManager.h"
#import "ICAudioFileURL.h"
#import "ICAudioPlayer.h"

@interface ICAudioPlayer ()
@property(strong, nonatomic) DOUAudioStreamer *player;
@property(strong, nonatomic) ICAudioFileURL *douUrl;
@property(strong, nonatomic) AVAudioPlayer *localPlayer;
@property(strong, nonatomic) ICAudioCacheManager *audioCacheManager;
@end

@implementation ICAudioPlayer

static void *kStatusKVOKey = &kStatusKVOKey;
static void *kBufferingRatioKVOKey = &kBufferingRatioKVOKey;

@synthesize duration = _duration;
@synthesize currentTime = _currentTime;
@synthesize cacheFileLimit = _cacheFileLimit;

+ (ICAudioPlayer *)sharedPlayer {
  static ICAudioPlayer *_sharedPlayer = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    _sharedPlayer = [[ICAudioPlayer alloc] init];
  });
  return _sharedPlayer;
}

- (id)init {
  self = [super init];
  if (self) {
    // initial status
    _status = ICAudioPlayerStatusStopped;
    // Init Local cache manager
    _audioCacheManager = [ICAudioCacheManager sharedManager];
    _audioCacheManager.cacheFileLimit = 50; // Default
  }
  return self;
}

- (NSUInteger)cacheFileLimit {
  _cacheFileLimit = _audioCacheManager.cacheFileLimit;
  return _cacheFileLimit;
}

- (void)setCacheFileLimit:(NSUInteger)cacheFileLimit {
  _cacheFileLimit = cacheFileLimit;
  _audioCacheManager.cacheFileLimit = _cacheFileLimit;
}

- (void)preparePlayerWithUrl:(NSString *)urlString {

  // Stop any previous state
  [self stop];

  _isLocal = [_audioCacheManager isFileCached:[urlString lastPathComponent]];

  if (_isLocal) {
    NSLog(@"[ICAudioPlayer] Local Cache is found, load local cache");
    [self PrepareLocalPlayerWithFileName:[urlString lastPathComponent]];
  } else {
    NSLog(@"[ICAudioPlayer] Local Cache is not found, prepare streamer");
    [self PrepareStreamPlayerWithURL:urlString];
  }
}

- (void)PrepareLocalPlayerWithFileName:(NSString *)fileName {

  NSError *error = nil;

  _localPlayer = [[AVAudioPlayer alloc]
      initWithContentsOfURL:
          [NSURL URLWithString:[_audioCacheManager.cacheDirectory
                                   stringByAppendingPathComponent:fileName]]
                      error:&error];
  [_localPlayer setDelegate:self];

  if (error) {
    NSLog(@"[ICAudioPlayer] Local player preparation error: %@",
          error.localizedDescription);
    _status = ICAudioPlayerStatusError;
    [self SendStatusNotif:_status];
  } else {
    // Set fully buffered
    [self SendBufferingRatioNotif:1];
  }
}

- (void)PrepareStreamPlayerWithURL:(NSString *)urlString {
  NSURL *url = [[NSURL alloc] initWithString:urlString];
  _douUrl = nil;
  _douUrl = [[ICAudioFileURL alloc] init];
  _douUrl.url = url;
  _player = [[DOUAudioStreamer alloc] initWithAudioFile:_douUrl];
  [_player addObserver:self
            forKeyPath:@"status"
               options:NSKeyValueObservingOptionNew
               context:kStatusKVOKey];
  [_player addObserver:self
            forKeyPath:@"bufferingRatio"
               options:NSKeyValueObservingOptionNew
               context:kBufferingRatioKVOKey];
}

- (void)play {

  if (_isLocal) {
    if ([_localPlayer prepareToPlay]) {
      [_localPlayer play];
      _status = ICAudioPlayerStatusPlaying;
      [self SendStatusNotif:_status];
    }
    return;
  }

  [_player play];
}

- (void)pause {

  if (_isLocal) {
    [_localPlayer pause];
    _status = ICAudioPlayerStatusPaused;
    [self SendStatusNotif:_status];
    return;
  }

  [_player pause];
}

- (void)stop {

  if (_localPlayer) {
    [_localPlayer stop];
    _localPlayer = nil;
  }

  if (_player) {
    [_player stop];
    [_player removeObserver:self forKeyPath:@"status"];
    [_player removeObserver:self forKeyPath:@"bufferingRatio"];
    _player = nil;
  }

  // Reset status
  _status = ICAudioPlayerStatusStopped;
  [self SendStatusNotif:_status];
}

- (NSTimeInterval)duration {

  if (_isLocal) {
    _duration = [_localPlayer duration];
  } else {
    _duration = [_player duration];
  }

  return _duration;
}

- (NSTimeInterval)currentTime {

  if (_isLocal) {
    _currentTime = [_localPlayer currentTime];
  } else {

    _currentTime = [_player currentTime];
  }

  return _currentTime;
}

- (void)setCurrentTime:(NSTimeInterval)currentTime {

  if (_isLocal) {
    [_localPlayer setCurrentTime:currentTime];
    return;
  }

  [_player setCurrentTime:currentTime];

  _currentTime = currentTime;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (context == kStatusKVOKey) {
    [self performSelector:@selector(statusChanged)
                 onThread:[NSThread mainThread]
               withObject:nil
            waitUntilDone:NO];
  } else if (context == kBufferingRatioKVOKey) {
    [self performSelector:@selector(updateBufferingStatus)
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

- (void)updateBufferingStatus {

  if ([_player duration] > 2) {

    [self SendBufferingRatioNotif:[_player bufferingRatio]];

    // Save audio cache if download complete
    if ([_player bufferingRatio] == 1) {
      [_audioCacheManager
          CopyAudioCachedOriginalPath:_player.cachedPath
                           ToFileName:[_player.url lastPathComponent]];
    }
  }
}

- (void)statusChanged {

  switch ([_player status]) {
  case DOUAudioStreamerPlaying:
    _status = ICAudioPlayerStatusPlaying;
    break;

  case DOUAudioStreamerPaused:
    _status = ICAudioPlayerStatusPaused;
    break;

  case DOUAudioStreamerIdle:
    _status = ICAudioPlayerStatusStopped;
    break;

  case DOUAudioStreamerFinished:
    _status = ICAudioPlayerStatusFinished;
    break;

  case DOUAudioStreamerBuffering:
    _status = ICAudioPlayerStatusBuffering;
    break;
  case DOUAudioStreamerError:
    _status = ICAudioPlayerStatusError;
    NSLog(@"[ICAudioPlayer] Error: %@", _player.error.localizedDescription);
    break;
  }

  [self SendStatusNotif:_status];
}

- (void)SendBufferingRatioNotif:(float)bufferingRatio {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:kICAudioPlayerBufferingRatioUpdateNotification
                    object:nil
                  userInfo:@{
                    @"bufferingRatio" : @(bufferingRatio)
                  }];
}

- (void)SendStatusNotif:(NSUInteger)status {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:kICAudioPlayerStatusUpdateNotification
                    object:nil
                  userInfo:@{
                    @"status" : @(status)
                  }];
}

#pragma mark AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
                       successfully:(BOOL)flag {
  _status = ICAudioPlayerStatusFinished;
  [self SendStatusNotif:_status];
}

@end
