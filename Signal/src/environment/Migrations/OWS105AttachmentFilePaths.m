//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWS105AttachmentFilePaths.h"
#import <SignalServiceKit/TSAttachmentStream.h>
#import <YapDatabase/YapDatabaseTransaction.h>

NS_ASSUME_NONNULL_BEGIN

// Increment a similar constant for every future DBMigration
static NSString *const OWS105AttachmentFilePathsMigrationId = @"105";

@implementation OWS105AttachmentFilePaths

+ (NSString *)migrationId
{
    return OWS105AttachmentFilePathsMigrationId;
}

- (void)runUpWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    OWSAssert(transaction);

    NSMutableArray<TSAttachmentStream *> *attachmentStreams = [NSMutableArray new];
    [transaction enumerateKeysAndObjectsInCollection:TSAttachmentStream.collection
                                          usingBlock:^(NSString *key, TSAttachment *attachment, BOOL *stop) {
                                              if (![attachment isKindOfClass:[TSAttachmentStream class]]) {
                                                  return;
                                              }
                                              TSAttachmentStream *attachmentStream = (TSAttachmentStream *)attachment;
                                              [attachmentStreams addObject:attachmentStream];
                                          }];

    DDLogInfo(@"Saving %zd attachment streams.", attachmentStreams.count);

    // Persist the new localRelativeFilePath property of TSAttachmentStream.
    // For performance, we want to upgrade all existing attachment streams in
    // a single transaction.
    for (TSAttachmentStream *attachmentStream in attachmentStreams) {
        [attachmentStream saveWithTransaction:transaction];
    }
}

#pragma mark - Logging

+ (NSString *)tag
{
    return [NSString stringWithFormat:@"[%@]", self.class];
}

- (NSString *)tag
{
    return self.class.tag;
}

@end

NS_ASSUME_NONNULL_END
