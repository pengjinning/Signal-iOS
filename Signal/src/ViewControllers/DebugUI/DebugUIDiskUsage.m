//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "DebugUIDiskUsage.h"
#import "OWSTableViewController.h"
#import "Signal-Swift.h"
#import <SignalServiceKit/NSDate+OWS.h>
#import <SignalServiceKit/OWSOrphanedDataCleaner.h>
#import <SignalServiceKit/TSDatabaseView.h>
#import <SignalServiceKit/TSInteraction.h>
#import <SignalServiceKit/TSStorageManager.h>

NS_ASSUME_NONNULL_BEGIN

@implementation DebugUIDiskUsage

#pragma mark - Logging

+ (NSString *)tag
{
    return [NSString stringWithFormat:@"[%@]", self.class];
}

- (NSString *)tag
{
    return self.class.tag;
}

#pragma mark - Factory Methods

- (NSString *)name
{
    return @"Orphans & Disk Usage";
}

- (nullable OWSTableSection *)sectionForThread:(nullable TSThread *)thread
{
    return [OWSTableSection sectionWithTitle:self.name
                                       items:@[
                                           [OWSTableItem itemWithTitle:@"Audit & Log"
                                                           actionBlock:^{
                                                               [OWSOrphanedDataCleaner auditAsync];
                                                           }],
                                           [OWSTableItem itemWithTitle:@"Audit & Clean Up"
                                                           actionBlock:^{
                                                               [OWSOrphanedDataCleaner auditAndCleanupAsync:nil];
                                                           }],
                                           [OWSTableItem itemWithTitle:@"Save All Attachments"
                                                           actionBlock:^{
                                                               [DebugUIDiskUsage saveAllAttachments];
                                                           }],
                                           [OWSTableItem itemWithTitle:@"Delete Messages older than 3 Months"
                                                           actionBlock:^{
                                                               [DebugUIDiskUsage deleteOldMessages_3Months];
                                                           }],
                                       ]];
}

+ (void)saveAllAttachments
{
    TSStorageManager *storageManager = [TSStorageManager sharedManager];
    [storageManager.newDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {

        NSMutableArray<TSAttachmentStream *> *attachmentStreams = [NSMutableArray new];
        [transaction enumerateKeysAndObjectsInCollection:TSAttachmentStream.collection
                                              usingBlock:^(NSString *key, TSAttachment *attachment, BOOL *stop) {
                                                  if (![attachment isKindOfClass:[TSAttachmentStream class]]) {
                                                      return;
                                                  }
                                                  TSAttachmentStream *attachmentStream
                                                      = (TSAttachmentStream *)attachment;
                                                  [attachmentStreams addObject:attachmentStream];
                                              }];

        DDLogInfo(@"Saving %zd attachment streams.", attachmentStreams.count);

        // Persist the new localRelativeFilePath property of TSAttachmentStream.
        // For performance, we want to upgrade all existing attachment streams in
        // a single transaction.
        for (TSAttachmentStream *attachmentStream in attachmentStreams) {
            [attachmentStream saveWithTransaction:transaction];
        }
    }];
}

+ (void)deleteOldMessages_3Months
{
    [self deleteOldMessages:kMonthInterval * 3];
}

+ (void)deleteOldMessages:(NSTimeInterval)maxAgeSeconds
{
    TSStorageManager *storageManager = [TSStorageManager sharedManager];
    [storageManager.newDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {

        NSMutableArray<NSString *> *threadIds = [NSMutableArray new];
        YapDatabaseViewTransaction *interactionsByThread = [transaction ext:TSMessageDatabaseViewExtensionName];
        [interactionsByThread enumerateGroupsUsingBlock:^(NSString *group, BOOL *stop) {
            [threadIds addObject:group];
        }];
        NSMutableArray<TSInteraction *> *interactionsToDelete = [NSMutableArray new];
        for (NSString *threadId in threadIds) {
            [interactionsByThread enumerateKeysAndObjectsInGroup:threadId
                                                      usingBlock:^(NSString *collection,
                                                          NSString *key,
                                                          TSInteraction *interaction,
                                                          NSUInteger index,
                                                          BOOL *stop) {
                                                          NSTimeInterval ageSeconds
                                                              = fabs(interaction.dateForSorting.timeIntervalSinceNow);
                                                          if (ageSeconds < maxAgeSeconds) {
                                                              *stop = YES;
                                                              return;
                                                          }
                                                          [interactionsToDelete addObject:interaction];
                                                      }];
        }

        DDLogInfo(@"Deleting %zd interactions.", interactionsToDelete.count);

        for (TSInteraction *interaction in interactionsToDelete) {
            [interaction removeWithTransaction:transaction];
        }
    }];
}

@end

NS_ASSUME_NONNULL_END
