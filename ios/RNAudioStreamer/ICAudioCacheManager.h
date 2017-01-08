//
//  LocalCacheManager.h
//  IndieplayerTest
//
//  Created by Victor Chan on 30/11/14.
//  Copyright (c) 2014 Victor Chan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ICAudioCacheManager : NSObject

/**
 *  Cache file limit
 */
@property(nonatomic, assign) NSUInteger cacheFileLimit;

/**
 *  Current cache size
 */
@property(nonatomic, readonly) unsigned long long int cacheSize;

/**
 *  Cache directory
 */
@property(nonatomic, readonly) NSString *cacheDirectory;

/**
 *  ICAudioCacheManager Singleton Instance
 *
 *  @return ICAudioCacheManager Singleton Instance
 */
+ (ICAudioCacheManager *)sharedManager;

/**
 *  Check if certain file name is cached
 *
 *  @param fileName
 *
 *  @return Boolean
 */
- (BOOL)isFileCached:(NSString *)fileName;

/**
 *  Copy from original path to cache directory
 *
 *  @param cachedPath
 *  @param fileName
 */
- (void)CopyAudioCachedOriginalPath:(NSString *)originalPath
                         ToFileName:(NSString *)fileName;

/**
 *  Remove all files in cache directory
 */
- (void)clearCache;

@end
