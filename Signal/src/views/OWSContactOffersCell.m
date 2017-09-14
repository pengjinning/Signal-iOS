//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "OWSContactOffersCell.h"
#import "NSBundle+JSQMessages.h"
#import "OWSContactOffersInteraction.h"
#import "UIColor+OWS.h"
#import "UIFont+OWS.h"
#import "UIView+OWS.h"
#import <JSQMessagesViewController/UIView+JSQMessages.h>

NS_ASSUME_NONNULL_BEGIN

@interface OWSContactOffersCell ()

@property (nonatomic, nullable) OWSContactOffersInteraction *interaction;

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *addToContactsButton;
@property (nonatomic) UIButton *addToProfileWhitelistButton;
@property (nonatomic) UIButton *blockButton;

@end

#pragma mark -

@implementation OWSContactOffersCell

// `[UIView init]` invokes `[self initWithFrame:...]`.
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commontInit];
    }

    return self;
}

- (void)commontInit
{
    OWSAssert(!self.titleLabel);

    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.titleLabel = [UILabel new];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.font = [self titleFont];
    self.titleLabel.text = NSLocalizedString(@"CONVERSATION_VIEW_CONTACTS_OFFER_TITLE",
        @"Title for the group of buttons show for unknown contacts offering to add them to contacts, etc.");
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.titleLabel];

    self.addToContactsButton = [self
        createButtonWithTitle:
            NSLocalizedString(@"CONVERSATION_VIEW_ADD_TO_CONTACTS_OFFER",
                @"Message shown in conversation view that offers to add an unknown user to your phone's contacts.")
                     selector:@selector(addToContacts)];
    self.addToProfileWhitelistButton = [self
        createButtonWithTitle:NSLocalizedString(@"CONVERSATION_VIEW_ADD_USER_TO_PROFILE_WHITELIST_OFFER",
                                  @"Message shown in conversation view that offers to share your profile with a user.")
                     selector:@selector(addToProfileWhitelist)];
    self.blockButton =
        [self createButtonWithTitle:NSLocalizedString(@"CONVERSATION_VIEW_UNKNOWN_CONTACT_BLOCK_OFFER",
                                        @"Message shown in conversation view that offers to block an unknown user.")
                           selector:@selector(block)];
}

- (UIButton *)createButtonWithTitle:(NSString *)title selector:(SEL)selector
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor ows_materialBlueColor] forState:UIControlStateNormal];
    button.titleLabel.font = self.buttonFont;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    [button setBackgroundColor:[UIColor colorWithRGBHex:0xf5f5f5]];
    button.layer.cornerRadius = 5.f;
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:button];
    return button;
}

+ (NSString *)cellReuseIdentifier
{
    return NSStringFromClass([self class]);
}

- (void)configureWithInteraction:(OWSContactOffersInteraction *)interaction;
{
    OWSAssert(interaction);

    _interaction = interaction;

    OWSAssert(
        interaction.hasBlockOffer || interaction.hasAddToContactsOffer || interaction.hasAddToProfileWhitelistOffer);

    [self setNeedsLayout];
}

- (UIFont *)titleFont
{
    return [UIFont ows_mediumFontWithSize:16.f];
}

- (UIFont *)buttonFont
{
    return [UIFont ows_regularFontWithSize:14.f];
}

- (CGFloat)hMargin
{
    return 10.f;
}

- (CGFloat)topVMargin
{
    return 5.f;
}

- (CGFloat)bottomVMargin
{
    return 5.f;
}

- (CGFloat)buttonVPadding
{
    return 5.f;
}

- (CGFloat)buttonVSpacing
{
    return 5.f;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    // We're using a bit of a hack to get JSQ to layout this and the unread indicator as
    // "full width" cells.  These cells will end up with an erroneous left margin that we
    // want to reverse.
    CGFloat contentWidth = self.width;
    CGFloat left = -self.left;

    CGRect titleFrame = self.contentView.bounds;
    titleFrame.origin = CGPointMake(left + self.hMargin, self.topVMargin);
    titleFrame.size.width = contentWidth - 2 * self.hMargin;
    titleFrame.size.height = ceil([self.titleLabel sizeThatFits:CGSizeZero].height);
    self.titleLabel.frame = titleFrame;

    __block CGFloat y = round(self.titleLabel.bottom + self.buttonVSpacing);
    void (^layoutButton)(UIButton *, BOOL) = ^(UIButton *button, BOOL isVisible) {
        if (isVisible) {
            button.hidden = NO;

            button.frame = CGRectMake(round(left + self.hMargin),
                round(y),
                floor(contentWidth - 2 * self.hMargin),
                ceil([button sizeThatFits:CGSizeZero].height + self.buttonVPadding));
            y = round(button.bottom + self.buttonVSpacing);
        } else {
            button.hidden = YES;
        }
    };

    layoutButton(self.addToContactsButton, self.interaction.hasAddToContactsOffer);
    layoutButton(self.addToProfileWhitelistButton, self.interaction.hasAddToProfileWhitelistOffer);
    layoutButton(self.blockButton, self.interaction.hasBlockOffer);
}

- (CGSize)bubbleSizeForInteraction:(OWSContactOffersInteraction *)interaction
               collectionViewWidth:(CGFloat)collectionViewWidth
{
    CGSize result = CGSizeMake(collectionViewWidth, 0);
    result.height += self.topVMargin;
    result.height += self.bottomVMargin;

    result.height += ceil([self.titleLabel sizeThatFits:CGSizeZero].height);

    int buttonCount = ((interaction.hasBlockOffer ? 1 : 0) + (interaction.hasAddToContactsOffer ? 1 : 0)
        + (interaction.hasAddToProfileWhitelistOffer ? 1 : 0));
    result.height += buttonCount
        * (self.buttonVPadding + self.buttonVSpacing + ceil([self.addToContactsButton sizeThatFits:CGSizeZero].height));

    return result;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.interaction = nil;
}

#pragma mark - Events

- (void)addToContacts
{
    OWSAssert(self.contactOffersCellDelegate);
    OWSAssert(self.interaction);

    [self.contactOffersCellDelegate tappedAddToContactsOfferMessage:self.interaction];
}

- (void)addToProfileWhitelist
{
    OWSAssert(self.contactOffersCellDelegate);
    OWSAssert(self.interaction);

    [self.contactOffersCellDelegate tappedAddToProfileWhitelistOfferMessage:self.interaction];
}

- (void)block
{
    OWSAssert(self.contactOffersCellDelegate);
    OWSAssert(self.interaction);

    [self.contactOffersCellDelegate tappedUnknownContactBlockOfferMessage:self.interaction];
}

#pragma mark - Logging

+ (NSString *)logTag
{
    return [NSString stringWithFormat:@"[%@]", self.class];
}

- (NSString *)logTag
{
    return self.class.logTag;
}

@end

NS_ASSUME_NONNULL_END
