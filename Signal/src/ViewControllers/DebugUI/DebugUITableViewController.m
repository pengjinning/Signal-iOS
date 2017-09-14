//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "DebugUITableViewController.h"
#import "DebugUIContacts.h"
#import "DebugUIDiskUsage.h"
#import "DebugUIMessages.h"
#import "DebugUIMisc.h"
#import "DebugUISessionState.h"
#import "Signal-Swift.h"
#import <SignalServiceKit/TSContactThread.h>
#import <SignalServiceKit/TSThread.h>

NS_ASSUME_NONNULL_BEGIN

@implementation DebugUITableViewController

#pragma mark - Logging

+ (NSString *)tag
{
    return [NSString stringWithFormat:@"[%@]", self.class];
}

- (NSString *)tag
{
    return self.class.tag;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Block device from sleeping while in the Debug UI.
    //
    // This is useful if you're using long-running actions in the
    // Debug UI, like "send 1k messages", etc.
    [DeviceSleepManager.sharedInstance addBlockWithBlockObject:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [DeviceSleepManager.sharedInstance removeBlockWithBlockObject:self];
}

#pragma mark - Factory Methods

- (void)pushPageWithSection:(OWSTableSection *)section
{
    DebugUITableViewController *viewController = [DebugUITableViewController new];
    OWSTableContents *contents = [OWSTableContents new];
    contents.title = section.headerTitle;
    [contents addSection:section];
    viewController.contents = contents;
    [self.navigationController pushViewController:viewController animated:YES];
}

+ (OWSTableItem *)itemForSubsection:(DebugUIPage *)page
                     viewController:(DebugUITableViewController *)viewController
                             thread:(nullable TSThread *)thread
{
    OWSAssert(page);
    OWSAssert(viewController);

    __weak DebugUITableViewController *weakSelf = viewController;
    return [OWSTableItem disclosureItemWithText:page.name
                                    actionBlock:^{
                                        [weakSelf pushPageWithSection:[page sectionForThread:thread]];
                                    }];
}

+ (void)presentDebugUIForThread:(TSThread *)thread fromViewController:(UIViewController *)fromViewController
{
    OWSAssert(thread);
    OWSAssert(fromViewController);

    DebugUITableViewController *viewController = [DebugUITableViewController new];

    OWSTableContents *contents = [OWSTableContents new];
    contents.title = @"Debug: Conversation";

    NSMutableArray<OWSTableItem *> *subsectionItems = [NSMutableArray new];
    [subsectionItems
        addObject:[self itemForSubsection:[DebugUIMessages new] viewController:viewController thread:thread]];
    [subsectionItems
        addObject:[self itemForSubsection:[DebugUIContacts new] viewController:viewController thread:thread]];
    [subsectionItems
        addObject:[self itemForSubsection:[DebugUIDiskUsage new] viewController:viewController thread:thread]];
    if ([thread isKindOfClass:[TSContactThread class]]) {
        [subsectionItems
            addObject:[self itemForSubsection:[DebugUISessionState new] viewController:viewController thread:thread]];
        [subsectionItems
            addObject:[self itemForSubsection:[DebugUICalling new] viewController:viewController thread:thread]];
    }
    [subsectionItems addObject:[self itemForSubsection:[DebugUIProfile new] viewController:viewController thread:thread]];
    [subsectionItems addObject:[self itemForSubsection:[DebugUIMisc new] viewController:viewController thread:thread]];

    [contents addSection:[OWSTableSection sectionWithTitle:@"Sections" items:subsectionItems]];

    viewController.contents = contents;
    [viewController presentFromViewController:fromViewController];
}

+ (void)presentDebugUIFromViewController:(UIViewController *)fromViewController
{
    OWSAssert(fromViewController);

    DebugUITableViewController *viewController = [DebugUITableViewController new];

    OWSTableContents *contents = [OWSTableContents new];
    contents.title = @"Debug UI";

    NSMutableArray<OWSTableItem *> *subsectionItems = [NSMutableArray new];
    [subsectionItems addObject:[self itemForSubsection:[DebugUIContacts new] viewController:viewController thread:nil]];
    [subsectionItems
        addObject:[self itemForSubsection:[DebugUIDiskUsage new] viewController:viewController thread:nil]];
    [subsectionItems addObject:[self itemForSubsection:[DebugUIMisc new] viewController:viewController thread:nil]];
    [contents addSection:[OWSTableSection sectionWithTitle:@"Sections" items:subsectionItems]];

    viewController.contents = contents;
    [viewController presentFromViewController:fromViewController];
}

@end

NS_ASSUME_NONNULL_END
