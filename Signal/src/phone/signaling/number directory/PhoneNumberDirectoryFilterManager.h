#import <Foundation/Foundation.h>
#import "CollapsingFutures.h"

/**
 *
 * PhoneNumberDirectoryFilterManager is responsible for periodically downloading the latest
 * bloom filter containing phone numbers considered to have RedPhone support.
 *
 */
@interface PhoneNumberDirectoryFilterManager : NSObject {
@private TOCCancelToken* lifetimeToken;
}

-(void) forceUpdate;
-(void) startUntilCancelled:(TOCCancelToken*)cancelToken;

@property BOOL isRefreshing;

@end
