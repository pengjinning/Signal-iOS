//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "Contact.h"
#import <SignalServiceKit/ContactsManagerProtocol.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const OWSContactsManagerSignalAccountsDidChangeNotification;

@class UIFont;
@class SignalAccount;
@class ImageCache;

/**
 * Get latest Signal contacts, and be notified when they change.
 */
@interface OWSContactsManager : NSObject <ContactsManagerProtocol>

#pragma mark - Setup

- (void)startObserving;

#pragma mark - Accessors

@property (nonnull, readonly) ImageCache *avatarCache;

@property (atomic, readonly) NSArray<Contact *> *allContacts;

@property (atomic, readonly) NSDictionary<NSString *, Contact *> *allContactsMap;

// signalAccountMap and signalAccounts hold the same data.
// signalAccountMap is for lookup. signalAccounts contains the accounts
// ordered by display order.
@property (atomic, readonly) NSDictionary<NSString *, SignalAccount *> *signalAccountMap;
@property (atomic, readonly) NSArray<SignalAccount *> *signalAccounts;

- (nullable SignalAccount *)signalAccountForRecipientId:(NSString *)recipientId;

- (Contact *)getOrBuildContactForPhoneIdentifier:(NSString *)identifier;

#pragma mark - System Contact Fetching

// Must call `requestSystemContactsOnce` before accessing this method
@property (nonatomic, readonly) BOOL isSystemContactsAuthorized;

@property (nonatomic, readonly) BOOL supportsContactEditing;

// Request systems contacts and start syncing changes. The user will see an alert
// if they haven't previously.
- (void)requestSystemContactsOnce;
- (void)requestSystemContactsOnceWithCompletion:(void (^_Nullable)(NSError *_Nullable error))completion;

// Ensure's the app has the latest contacts, but won't prompt the user for contact
// access if they haven't granted it.
- (void)fetchSystemContactsIfAlreadyAuthorized;

#pragma mark - Util

- (BOOL)hasNameInSystemContactsForRecipientId:(NSString *)recipientId;
- (NSString *)displayNameForPhoneIdentifier:(nullable NSString *)identifier;
- (NSString *)displayNameForSignalAccount:(SignalAccount *)signalAccount;

// Generally we prefer the formattedProfileName over the raw profileName so as to
// distinguish a profile name apart from a name pulled from the system's contacts.
// This helps clarify when the remote person chooses a potentially confusing profile name.
- (nullable NSString *)formattedProfileNameForRecipientId:(NSString *)recipientId;
- (nullable NSString *)profileNameForRecipientId:(NSString *)recipientId;
- (nullable NSString *)nameFromSystemContactsForRecipientId:(NSString *)recipientId;

- (nullable UIImage *)imageForPhoneIdentifier:(nullable NSString *)identifier;
- (NSAttributedString *)formattedDisplayNameForSignalAccount:(SignalAccount *)signalAccount font:(UIFont *_Nonnull)font;
- (NSAttributedString *)formattedFullNameForRecipientId:(NSString *)recipientId font:(UIFont *)font;
- (NSAttributedString *)attributedStringForMessageFooterWithPhoneIdentifier:(NSString *)recipientId;
- (NSAttributedString *)attributedStringForConversationTitleWithPhoneIdentifier:(NSString *)recipientId
                                                                    primaryFont:(UIFont *)primaryFont
                                                                  secondaryFont:(UIFont *)secondaryFont;
@end

NS_ASSUME_NONNULL_END
