//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class HomeViewController;

@interface ProfileViewController : UIViewController

- (instancetype)init NS_UNAVAILABLE;

+ (BOOL)shouldDisplayProfileViewOnLaunch;

+ (void)presentForAppSettings:(UINavigationController *)navigationController;
+ (void)presentForRegistration:(UINavigationController *)navigationController;
+ (void)presentForUpgradeOrNag:(HomeViewController *)presentingController NS_SWIFT_NAME(presentForUpgradeOrNag(from:));

@end

NS_ASSUME_NONNULL_END
