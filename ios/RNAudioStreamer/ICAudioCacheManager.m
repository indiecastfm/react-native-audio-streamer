//
//  LocalCacheManager.m
//  IndieplayerTest
//
//  Created by Victor Chan on 30/11/14.
//  Copyright (c) 2014 Victor Chan. All rights reserved.
//

#import "ICAudioCacheManager.h"

@interface ICAudioCacheManager ()
@property(strong, nonatomic) NSFileManager *fm;
@end

@implementation ICAudioCacheManager

@synthesize cacheSize = _cacheSize;
@synthesize cacheDirectory = _cacheDirectory;

+ (ICAudioCacheManager *)sharedManager {
  static ICAudioCacheManager *_sharedManager = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    _sharedManager = [[ICAudioCacheManager alloc] init];
  });
  return _sharedManager;
}

- (id)init {
  if (self = [super init]) {
    _cacheFileLimit = 50; // Default
    _fm = [NSFileManager defaultManager];
  }
  return self;
}

- (NSString *)cacheDirectory {

  NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [documentsPaths objectAtIndex:0];
  NSString *cacheDirectory =
      [documentsDirectory stringByAppendingPathComponent:@"/ic-audio-cache"];

  if (![_fm fileExistsAtPath:cacheDirectory]) {
    [_fm createDirectoryAtPath:cacheDirectory
        withIntermediateDirectories:NO
                         attributes:nil
                              error:nil]; // Create folder
  }

  _cacheDirectory = cacheDirectory;

  return _cacheDirectory;
}

- (BOOL)isFileCached:(NSString *)fileName {
  return [_fm fileExistsAtPath:[self.cacheDirectory
                                   stringByAppendingPathComponent:fileName]
                   isDirectory:FALSE];
}

- (void)CopyAudioCachedOriginalPath:(NSString *)originalPath
                         ToFileName:(NSString *)fileName {

  // If file exist don't do anything
  if ([self isFileCached:fileName])
    return;

  // Define file name path
  NSString *fileNamePath =
      [self.cacheDirectory stringByAppendingPathComponent:fileName];

  // Copy file from tmp path to store location with filename
  NSError *error = nil;
  [_fm copyItemAtPath:originalPath toPath:fileNamePath error:&error];

  // Skip file from back up in iCloud
  [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:fileNamePath]];

  if (error) {
    NSLog(@"[ICAudioCacheManager] Save Audio Cache Error: %@",
          error.localizedDescription);

  } else {
    NSLog(@"[ICAudioCacheManager] Audio Cache %@ Saved", fileName);
  }

  [self RemoveExceededAudioCache];
}

- (void)RemoveExceededAudioCache {

  NSMutableArray *cacheFiles = [[NSMutableArray alloc] init];

  // Get cache file names & dates
  NSDirectoryEnumerator *en = [_fm enumeratorAtPath:self.cacheDirectory];
  NSString *file;
  while (file = [en nextObject]) {

    // This full path is just for date retrieving
    NSString *fullPath =
        [NSString stringWithFormat:@"file:///%@",
                                   [self.cacheDirectory
                                       stringByAppendingPathComponent:file]];

    // Get file creation date
    NSURL *fileUrl = [NSURL URLWithString:fullPath];
    NSDate *fileDate;
    [fileUrl getResourceValue:&fileDate
                       forKey:NSURLContentModificationDateKey
                        error:nil];

    [cacheFiles addObject:@{
      @"path" : [self.cacheDirectory stringByAppendingPathComponent:file],
      @"date" : fileDate
    }];
  }

  // Delete oldest caches when exceeds the cache limit
  NSSortDescriptor *sortDescriptor =
      [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
  NSArray *sortedCachedFiles = [cacheFiles
      sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];

  NSInteger diff = [sortedCachedFiles count] - _cacheFileLimit;

  if (diff > 0) {
    for (int i = 0; i < diff; i++) {

      NSDictionary *cachedFile = sortedCachedFiles[i];

      NSError *error = nil;
      [_fm removeItemAtPath:cachedFile[@"path"] error:&error];

      if (error) {
        NSLog(
            @"[ICAudioCacheManager] Exceeded Cache %@ failed to be deleted: %@",
            [cachedFile[@"path"] lastPathComponent],
            error.localizedDescription);
      } else {
        NSLog(@"[ICAudioCacheManager] Exceeded Cache %@ deleted",
              [cachedFile[@"path"] lastPathComponent]);
      }
    }
  }
}

- (void)ClearCache {
  NSDirectoryEnumerator *en = [_fm enumeratorAtPath:self.cacheDirectory];
  NSString *file;
  while (file = [en nextObject]) {
    [[NSFileManager defaultManager]
        removeItemAtPath:[self.cacheDirectory
                             stringByAppendingPathComponent:file]
                   error:nil];
  }
}

- (unsigned long long int)cacheSize {

  unsigned long long int size = 0;

  NSDirectoryEnumerator *en = [_fm enumeratorAtPath:self.cacheDirectory];
  NSString *file;
  while (file = [en nextObject]) {
    NSDictionary *fileDict = [[NSFileManager defaultManager]
        attributesOfItemAtPath:[self.cacheDirectory
                                   stringByAppendingPathComponent:file]
                         error:nil];
    size += [fileDict[NSFileSize] longLongValue];
  }

  _cacheSize = size;

  return _cacheSize;
}

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL {
  assert([[NSFileManager defaultManager] fileExistsAtPath:[URL path]]);

  NSError *error = nil;
  BOOL success = [URL setResourceValue:[NSNumber numberWithBool:YES]
                                forKey:NSURLIsExcludedFromBackupKey
                                 error:&error];
  if (!success) {
    NSLog(@"[ICAudioCacheManager] Error excluding %@ from backup %@",
          [URL lastPathComponent], error);
  } else {
    NSLog(@"[ICAudioCacheManager] Exclude back up in iCloud success");
  }
  return success;
}

@end
