//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "TSRequest.h"

#import "TSConstants.h"
#import "TSStorageManager+keyingMaterial.h"

@implementation TSRequest

- (id)initWithURL:(NSURL *)URL {
    OWSAssert(URL);
    self = [super initWithURL:URL
                  cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
              timeoutInterval:textSecureHTTPTimeOut];
    self.parameters = [NSMutableDictionary dictionary];

    return self;
}

- (id)init {
    [NSException raise:NSInternalInconsistencyException format:@"You must use the initWithURL: method"];
    return nil;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"

- (id)initWithURL:(NSURL *)URL
      cachePolicy:(NSURLRequestCachePolicy)cachePolicy
  timeoutInterval:(NSTimeInterval)timeoutInterval {
    [NSException raise:NSInternalInconsistencyException format:@"You must use the initWithURL method"];
    return nil;
}

#pragma clang diagnostic pop

- (void)makeAuthenticatedRequest {
    [self.parameters addEntriesFromDictionary:@{ @"Authorization" : [TSStorageManager serverAuthToken] }];
}

@end
