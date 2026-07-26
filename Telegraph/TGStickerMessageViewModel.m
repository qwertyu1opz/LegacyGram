#import "TGStickerMessageViewModel.h"

#ifndef IOS6_NOOP_LOG
#define IOS6_NOOP_LOG(...) do { } while (0)
#endif

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGMessageImageViewModel.h"

#import "TGModernConversationItem.h"

#import "TGTelegraphConversationMessageAssetsSource.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGDoubleTapGestureRecognizer.h"

#import "TGModernViewContext.h"

#import "TGMessageImageView.h"

#import "TGModernImageViewModel.h"
#import "TGModernButtonViewModel.h"
#import "TGModernButtonView.h"

#import "TGContentBubbleViewModel.h"

#import "TGReplyHeaderModel.h"
#import "TGModernFlatteningViewModel.h"
#import "TGModernImageViewModel.h"

#import "TGMessageReplyButtonsModel.h"

#import "TGModernTextViewModel.h"

#import "TGPresentation.h"

#import "TGAppDelegate.h"

static NSString *TGIOS6StickerReactionSummary(TGMessage *message)
{
    id value = [message.contentProperties objectForKey:@"ios6ReactionSummary"];
    if ([value isKindOfClass:[TGMessageReactionSummaryContentProperty class]])
        return ((TGMessageReactionSummaryContentProperty *)value).summary;
    if ([value isKindOfClass:[NSString class]])
        return value;
    return nil;
}

static NSString *TGIOS6StickerChosenReaction(TGMessage *message)
{
    id value = [message.contentProperties objectForKey:@"ios6ReactionSummary"];
    if ([value isKindOfClass:[TGMessageReactionSummaryContentProperty class]])
        return ((TGMessageReactionSummaryContentProperty *)value).chosenReaction;
    return nil;
}

static NSString *TGIOS6StickerReactionKey(NSString *emoji)
{
    return [[emoji stringByReplacingOccurrencesOfString:@"\uFE0F" withString:@""] stringByReplacingOccurrencesOfString:@"\uFE0E" withString:@""];
}

static NSArray *TGIOS6StickerReactionItems(NSString *summary)
{
    NSMutableArray *orderedKeys = [[NSMutableArray alloc] init];
    NSMutableDictionary *emojiByKey = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *countByKey = [[NSMutableDictionary alloc] init];
    for (NSString *part in [summary componentsSeparatedByString:@"  "])
    {
        NSRange separator = [part rangeOfString:@" " options:NSBackwardsSearch];
        NSString *emoji = separator.location == NSNotFound ? part : [part substringToIndex:separator.location];
        NSInteger count = separator.location == NSNotFound ? 1 : MAX(1, [[part substringFromIndex:separator.location + 1] integerValue]);
        NSString *key = [[emoji stringByReplacingOccurrencesOfString:@"\uFE0F" withString:@""] stringByReplacingOccurrencesOfString:@"\uFE0E" withString:@""];
        if (key.length == 0)
            continue;
        if ([countByKey objectForKey:key] == nil)
        {
            [orderedKeys addObject:key];
            [emojiByKey setObject:emoji forKey:key];
            [countByKey setObject:[NSNumber numberWithInteger:count] forKey:key];
        }
        else
            [countByKey setObject:[NSNumber numberWithInteger:MAX([[countByKey objectForKey:key] integerValue], count)] forKey:key];
    }
    NSMutableArray *items = [[NSMutableArray alloc] init];
    for (NSString *key in orderedKeys)
    {
        NSString *emoji = [emojiByKey objectForKey:key];
        NSInteger count = [[countByKey objectForKey:key] integerValue];
        [items addObject:@{ @"emoji": emoji, @"count": @(count) }];
    }
    return items;
}

static UIImage *TGIOS6StickerReactionButtonImage(NSString *emoji, NSInteger count, bool selected)
{
    if (emoji.length == 0)
        return nil;
    static NSCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        cache = [[NSCache alloc] init];
        cache.countLimit = 64;
    });
    NSString *countText = count <= 1 ? nil : (count >= 1000 ? [NSString stringWithFormat:@"%dK", (int)MAX(1, count / 1000)] : [NSString stringWithFormat:@"%d", (int)count]);
    NSString *displayText = countText.length == 0 ? emoji : [NSString stringWithFormat:@"%@ %@", emoji, countText];
    NSString *cacheKey = [NSString stringWithFormat:@"%@/%d", displayText, selected ? 1 : 0];
    UIImage *image = [cache objectForKey:cacheKey];
    if (image != nil)
        return image;
    UIFont *font = TGSystemFontOfSize(12.0f);
    CGSize textSize = [displayText sizeWithFont:font];
    CGSize size = CGSizeMake(MAX(30.0f, MIN(160.0f, ceil(textSize.width) + 14.0f)), 22.0f);
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor *backgroundColor = selected ? [UIColor colorWithRed:0.0f green:0.48f blue:0.92f alpha:0.34f] : [UIColor colorWithWhite:0.0f alpha:0.10f];
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.0f, 0.0f, size.width, size.height) cornerRadius:11.0f];
    CGContextAddPath(context, path.CGPath);
    CGContextFillPath(context);
    [[UIColor colorWithWhite:0.55f alpha:1.0f] set];
    if (countText.length == 0)
    {
        CGRect emojiRect = CGRectMake(7.0f, roundf((size.height - textSize.height) / 2.0f) + 1.0f, size.width - 14.0f, textSize.height);
        [emoji drawInRect:emojiRect withFont:font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
    }
    else
    {
        CGSize emojiSize = [emoji sizeWithFont:font];
        CGSize countSize = [countText sizeWithFont:font];
        CGFloat contentWidth = ceilf(emojiSize.width) + 3.0f + ceilf(countSize.width);
        CGFloat contentX = roundf((size.width - contentWidth) / 2.0f);
        [emoji drawInRect:CGRectMake(contentX, roundf((size.height - emojiSize.height) / 2.0f) + 1.0f, ceilf(emojiSize.width), emojiSize.height) withFont:font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
        [countText drawInRect:CGRectMake(contentX + ceilf(emojiSize.width) + 3.0f, roundf((size.height - countSize.height) / 2.0f), ceilf(countSize.width), countSize.height) withFont:font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentLeft];
    }
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [cache setObject:image forKey:cacheKey];
    return image;
}

@interface TGStickerMessageViewModel () <TGDoubleTapGestureRecognizerDelegate, UIGestureRecognizerDelegate>
{
    bool _incoming;
    bool _read;
    TGMessageDeliveryState _deliveryState;
    bool _hasAvatar;
    CGSize _size;
    bool _savedMessage;
    
    float _progress;
    bool _progressVisible;
    
    TGDocumentMediaAttachment *_document;
    TGMessageImageViewModel *_imageModel;
    NSString *_emojiFallbackText;
    UILabel *_emojiFallbackLabel;
    bool _emojiFallbackUntilImageLoaded;
    
    UITapGestureRecognizer *_tapGestureRecognizer;
    TGDoubleTapGestureRecognizer *_boundDoubleTapRecognizer;
    UITapGestureRecognizer *_replyTapRecognizer;
    
    TGModernImageViewModel *_unsentButtonModel;
    UITapGestureRecognizer *_unsentButtonTapRecognizer;
    
    UIImageView *_temporaryHighlightView;
    
    TGModernFlatteningViewModel *_contentModel;
    TGModernImageViewModel *_replyBackgroundModel;
    TGReplyHeaderModel *_replyHeaderModel;
    TGModernTextViewModel *_replyHeaderViaUserModel;
    
    TGModernButtonViewModel *_actionButtonModel;
    
    int32_t _replyMessageId;
    TGMessageViewCountContentProperty *_messageViews;
    
    TGMessage *_message;
    NSString *_authorSignature;
    
    TGMessageReplyButtonsModel *_replyButtonsModel;
    TGBotReplyMarkup *_replyMarkup;
    SMetaDisposable *_callbackButtonInProgressDisposable;
    
    TGUser *_viaUser;

    NSString *_ios6ReactionSummary;
    NSString *_ios6ChosenReaction;
    NSArray *_ios6ReactionButtonModels;
}

@end

@implementation TGStickerMessageViewModel

- (void)_ios6RebuildReactionButtons:(TGModernViewStorage *)viewStorage
{
    for (TGModernButtonViewModel *button in _ios6ReactionButtonModels)
        if ([self containsSubmodel:button])
            [self removeSubmodel:button viewStorage:viewStorage];

    NSMutableArray *buttons = [[NSMutableArray alloc] init];
    NSString *chosenKey = TGIOS6StickerReactionKey(_ios6ChosenReaction);
    __weak TGStickerMessageViewModel *weakSelf = self;
    for (NSDictionary *item in TGIOS6StickerReactionItems(_ios6ReactionSummary))
    {
        NSString *emoji = [item[@"emoji"] copy];
        NSInteger count = [item[@"count"] integerValue];
        bool selected = chosenKey.length != 0 && [chosenKey isEqualToString:TGIOS6StickerReactionKey(emoji)];
        TGModernButtonViewModel *button = [[TGModernButtonViewModel alloc] init];
        button.image = TGIOS6StickerReactionButtonImage(emoji, count, selected);
        button.frame = (CGRect){CGPointZero, button.image.size};
        button.modernHighlight = true;
        button.pressed = ^
        {
            __strong TGStickerMessageViewModel *strongSelf = weakSelf;
            if (strongSelf == nil)
                return;
            bool remove = [TGIOS6StickerReactionKey(strongSelf->_ios6ChosenReaction) isEqualToString:TGIOS6StickerReactionKey(emoji)];
            [strongSelf->_context.companionHandle requestAction:@"ios6ReactionTapped" options:@{ @"mid": @(strongSelf->_mid), @"reaction": emoji, @"remove": @(remove) }];
        };
        [self addSubmodel:button];
        [buttons addObject:button];
    }
    _ios6ReactionButtonModels = buttons;
    UIView *container = [_imageModel boundView].superview;
    if (container != nil)
        for (TGModernButtonViewModel *button in buttons)
        {
            if ([button boundView] == nil)
                [button bindViewToContainer:container viewStorage:viewStorage];
            [container bringSubviewToFront:[button boundView]];
        }
}

- (NSString *)stickerAltText:(TGDocumentMediaAttachment *)document
{
    for (id attribute in document.attributes)
    {
        if ([attribute isKindOfClass:[TGDocumentAttributeSticker class]])
            return ((TGDocumentAttributeSticker *)attribute).alt;
    }
    
    return nil;
}

- (bool)needsEmojiFallbackForDocument:(TGDocumentMediaAttachment *)document
{
    NSString *mimeType = [document.mimeType lowercaseString];
    NSString *extension = [[document.fileName pathExtension] lowercaseString];
    return [mimeType isEqualToString:@"video/webm"] || [mimeType isEqualToString:@"application/x-tgsticker"] || [extension isEqualToString:@"webm"] || [extension isEqualToString:@"tgs"];
}

- (bool)shouldKeepEmojiFallbackForDocument:(TGDocumentMediaAttachment *)document
{
    return [self needsEmojiFallbackForDocument:document];
}

- (bool)stickerImageIsLocallyAvailable:(TGDocumentMediaAttachment *)document
{
    static NSString *filesDirectory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        filesDirectory = [[TGAppDelegate documentsPath] stringByAppendingPathComponent:@"files"];
    });
    
    NSString *fileDirectoryName = nil;
    if (document.documentId != 0)
        fileDirectoryName = [[NSString alloc] initWithFormat:@"%" PRIx64 "", document.documentId];
    else if (document.localDocumentId != 0)
        fileDirectoryName = [[NSString alloc] initWithFormat:@"local%" PRIx64 "", document.localDocumentId];
    
    if (fileDirectoryName.length == 0)
        return false;
    
    NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
    NSString *filePath = [fileDirectory stringByAppendingPathComponent:document.fileName ?: @""];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:filePath] ||
        [fileManager fileExistsAtPath:[fileDirectory stringByAppendingPathComponent:@"cached.bin"]] ||
        [fileManager fileExistsAtPath:[fileDirectory stringByAppendingPathComponent:@"thumbnail.cached.bin"]];
}

- (bool)boundImageViewHasImage
{
    UIView *boundView = [_imageModel boundView];
    if ([boundView isKindOfClass:[TGMessageImageViewContainer class]])
        return ((TGMessageImageViewContainer *)boundView).imageView.currentImage != nil;
    
    return false;
}

- (void)updateEmojiFallbackLabel
{
    UIView *containerView = [_imageModel boundView];
    if (_emojiFallbackUntilImageLoaded && [self boundImageViewHasImage])
    {
        _emojiFallbackUntilImageLoaded = false;
        _emojiFallbackText = nil;
    }
    
    if (_emojiFallbackText.length == 0 || containerView == nil)
    {
        [_emojiFallbackLabel removeFromSuperview];
        _emojiFallbackLabel = nil;
        return;
    }
    
    if (_emojiFallbackLabel == nil)
    {
        _emojiFallbackLabel = [[UILabel alloc] initWithFrame:containerView.bounds];
        _emojiFallbackLabel.backgroundColor = [UIColor clearColor];
        _emojiFallbackLabel.textAlignment = NSTextAlignmentCenter;
        _emojiFallbackLabel.userInteractionEnabled = false;
        _emojiFallbackLabel.adjustsFontSizeToFitWidth = true;
        _emojiFallbackLabel.minimumScaleFactor = 0.5f;
        _emojiFallbackLabel.shadowColor = UIColorRGBA(0xffffff, 0.65f);
        _emojiFallbackLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    }
    
    UIFont *emojiFont = [UIFont fontWithName:@"AppleColorEmoji" size:68.0f];
    if (emojiFont == nil)
        emojiFont = TGSystemFontOfSize(68.0f);
    _emojiFallbackLabel.font = emojiFont;
    _emojiFallbackLabel.text = _emojiFallbackText;
    _emojiFallbackLabel.frame = containerView.bounds;
    
    if (_emojiFallbackLabel.superview != containerView)
    {
        [_emojiFallbackLabel removeFromSuperview];
        [containerView addSubview:_emojiFallbackLabel];
    }
    [containerView bringSubviewToFront:_emojiFallbackLabel];
}

- (CGSize)displaySizeForSize:(CGSize)size
{
    CGSize maxSize = CGSizeMake(160, 170);
    return TGFitSize(CGSizeMake(size.width / 2.0f, size.height / 2.0f), maxSize);
}

- (instancetype)initWithMessage:(TGMessage *)message document:(TGDocumentMediaAttachment *)document size:(CGSize)size authorPeer:(id)authorPeer context:(TGModernViewContext *)context replyHeader:(TGMessage *)replyHeader replyPeer:(id)replyPeer viaUser:(TGUser *)viaUser
{
    self = [super initWithAuthorPeer:authorPeer context:context];
    if (self != nil)
    {
        _callbackButtonInProgressDisposable = [[SMetaDisposable alloc] init];
        
        _mid = message.mid;
        _authorPeerId = message.fromUid;
        _incoming = !message.outgoing;
        _read = ![_context isMessageUnread:message];
        _deliveryState = message.deliveryState;
        _hasAvatar = authorPeer != nil && [authorPeer isKindOfClass:[TGUser class]];
        if ([authorPeer isKindOfClass:[TGConversation class]]) {
            TGConversation *conversationAuthor = (TGConversation *)authorPeer;
            if (!conversationAuthor.isChannel || conversationAuthor.isChannelGroup || context.isAdminLog || context.isSavedMessages || context.isFeed) {
                _hasAvatar = true;
            }
        }
        _messageViews = message.viewCount;
        _message = message;
        
        _needsEditingCheckButton = true;
        
        _document = document;
        
        _size = size;
        
        TGForwardedMessageMediaAttachment *forwardAttachment = nil;
        for (TGMediaAttachment *attachment in message.mediaAttachments)
        {
            if (attachment.type == TGForwardedMessageMediaAttachmentType)
            {
                forwardAttachment = (TGForwardedMessageMediaAttachment *)attachment;
                break;
            }
        }
        _savedMessage = forwardAttachment != nil && context.isSavedMessages && forwardAttachment.forwardSourcePeerId != message.cid;
        bool hasForwardPostId = forwardAttachment.forwardPostId != 0 || forwardAttachment.forwardMid != 0;
        
        _incomingAppearance = _incoming || [authorPeer isKindOfClass:[TGConversation class]] || _savedMessage;
        
        _imageModel = [[TGMessageImageViewModel alloc] init];
        [_imageModel setPresentation:_context.presentation];
        _imageModel.expectExtendedEdges = true;
        
        UIColor *overlayBackgroundColor = context.presentation.pallete.chatSystemBackgroundColor ?: [[TGTelegraphConversationMessageAssetsSource instance] systemMessageBackgroundColor];
        _imageModel.overlayBackgroundColorHint = UIColorRGBA(0x000000, 0.4f);
        _imageModel.timestampTextColor = context.presentation.pallete.chatSystemTextColor;
        _imageModel.timestampColor = overlayBackgroundColor;
        _imageModel.serviceTimestampStyle = true;
        
        CGSize displaySize = [self displaySizeForSize:_size];
        
        NSMutableString *imageUri = [[NSMutableString alloc] init];
        [imageUri appendString:@"sticker://?"];
        if (_document.documentId != 0)
        {
            [imageUri appendFormat:@"&documentId=%" PRId64, _document.documentId];
            
            TGMediaOriginInfo *originInfo = _document.originInfo ?: [TGMediaOriginInfo mediaOriginInfoForDocumentAttachment:_document];
            if (originInfo != nil)
                [imageUri appendFormat:@"&origin_info=%@", [originInfo stringRepresentation]];
        }
        else
        {
            [imageUri appendFormat:@"&localDocumentId=%" PRId64, _document.localDocumentId];
        }
        [imageUri appendFormat:@"&accessHash=%" PRId64, _document.accessHash];
        [imageUri appendFormat:@"&datacenterId=%d", (int)_document.datacenterId];
        [imageUri appendFormat:@"&fileName=%@", [TGStringUtils stringByEscapingForURL:_document.fileName]];
        [imageUri appendFormat:@"&size=%d", (int)_document.size];
        [imageUri appendFormat:@"&width=%d&height=%d", (int)displaySize.width, (int)displaySize.height];
        [imageUri appendFormat:@"&mime-type=%@", [TGStringUtils stringByEscapingForURL:_document.mimeType]];
        if (_document.documentUri.length != 0) {
            [imageUri appendFormat:@"&documentUri=%@", [TGStringUtils stringByEscapingForURL:_document.documentUri]];
        }
        
        [_imageModel setUri:imageUri];
        
        _imageModel.frame = CGRectMake(0.0f, 0.0f, displaySize.width, displaySize.height);
        _imageModel.skipDrawInContext = true;
        [self addSubmodel:_imageModel];
        
        NSString *alt = [self stickerAltText:_document];
        if (alt.length != 0)
        {
            bool keepFallback = [self shouldKeepEmojiFallbackForDocument:_document];
            if (keepFallback || ![self stickerImageIsLocallyAvailable:_document])
            {
                _emojiFallbackText = alt;
                _emojiFallbackUntilImageLoaded = !keepFallback;
                IOS6_NOOP_LOG(@"IOS6STICKER emojiFallback mid=%d docId=%lld mime=%@ alt=%@", (int)_mid, _document.documentId, _document.mimeType, alt);
            }
        }
        
        _imageModel.flexibleTimestamp = true;
        [_imageModel setTimestampString:[TGDateUtils stringForShortTime:(int)message.date] signatureString:nil displayCheckmarks:!_incoming && !(_incomingAppearance && _context.isSavedMessages) && _deliveryState != TGMessageDeliveryStateFailed checkmarkValue:(_incoming ? 0 : ((_deliveryState == TGMessageDeliveryStateDelivered ? 1 : 0) + (_read ? 1 : 0))) displayViews:_messageViews != nil viewsValue:_messageViews.viewCount animated:false];
        [_imageModel setDisplayTimestampProgress:_deliveryState == TGMessageDeliveryStatePending];
        [_imageModel setIsBroadcast:message.isBroadcast];
        
        __weak TGStickerMessageViewModel *weakSelf = self;
        _imageModel.completionBlock = ^(__unused TGImageView *imageView)
        {
            __strong TGStickerMessageViewModel *strongSelf = weakSelf;
            if (strongSelf != nil)
            {
                if (strongSelf->_progressVisible)
                    [strongSelf updateProgressInternal:false progress:1.0f animated:true];
                
                if (strongSelf->_emojiFallbackUntilImageLoaded)
                {
                    strongSelf->_emojiFallbackUntilImageLoaded = false;
                    strongSelf->_emojiFallbackText = nil;
                    [strongSelf updateEmojiFallbackLabel];
                }
            }
        };
        
        if (!_incoming)
        {
            if (_deliveryState == TGMessageDeliveryStatePending)
            {
            }
            else if (_deliveryState == TGMessageDeliveryStateFailed)
            {
                [self addSubmodel:[self unsentButtonModel]];
            }
            else if (_deliveryState == TGMessageDeliveryStateDelivered)
            {
            }
        }
        
        _viaUser = viaUser;
        
        if (replyHeader != nil)
        {
            _replyMessageId = replyHeader.mid;
            
            _replyBackgroundModel = [[TGModernImageViewModel alloc] initWithImage:context.presentation.images.chatReplyBackground];
            _replyBackgroundModel.skipDrawInContext = true;
            [self addSubmodel:_replyBackgroundModel];
            
            _contentModel = [[TGModernFlatteningViewModel alloc] init];
            [self addSubmodel:_contentModel];
            
            _replyHeaderModel = [TGContentBubbleViewModel replyHeaderModelFromMessage:replyHeader peer:replyPeer incoming:_incomingAppearance system:true presentation:context.presentation];
            [_contentModel addSubmodel:_replyHeaderModel];
            
            if (viaUser != nil && viaUser.userName.length != 0) {
                NSString *formatString = TGLocalized(@"Conversation.MessageViaUser");
                NSString *viaUserName = [@"@" stringByAppendingString:viaUser.userName];
                NSRange range = [formatString rangeOfString:@"%@"];
                
                _replyHeaderViaUserModel = [[TGModernTextViewModel alloc] initWithText:[[NSString alloc] initWithFormat:formatString, viaUserName] font:[[TGTelegraphConversationMessageAssetsSource instance] messageAuthorNameFont]];
                if (range.location != NSNotFound) {
                    _replyHeaderViaUserModel.textCheckingResults = @[[[TGTextCheckingResult alloc] initWithRange:NSMakeRange(range.location, viaUserName.length) type:TGTextCheckingResultTypeBold contents:nil]];
                }
                _replyHeaderViaUserModel.textColor = [UIColor whiteColor];
                [_contentModel addSubmodel:_replyHeaderViaUserModel];
                
                _viaUser = viaUser;
            }
        } else if (viaUser != nil && viaUser.userName.length != 0) {
            _replyBackgroundModel = [[TGModernImageViewModel alloc] initWithImage:[[TGTelegraphConversationMessageAssetsSource instance] systemReplyBackground]];
            _replyBackgroundModel.skipDrawInContext = true;
            [self addSubmodel:_replyBackgroundModel];
            
            _contentModel = [[TGModernFlatteningViewModel alloc] init];
            [self addSubmodel:_contentModel];
            
            NSString *formatString = TGLocalized(@"Conversation.MessageViaUser");
            NSString *viaUserName = [@"@" stringByAppendingString:viaUser.userName];
            NSRange range = [formatString rangeOfString:@"%@"];
            
            _replyHeaderViaUserModel = [[TGModernTextViewModel alloc] initWithText:[[NSString alloc] initWithFormat:formatString, viaUserName] font:[[TGTelegraphConversationMessageAssetsSource instance] messageAuthorNameFont]];
            if (range.location != NSNotFound) {
                _replyHeaderViaUserModel.textCheckingResults = @[[[TGTextCheckingResult alloc] initWithRange:NSMakeRange(range.location, viaUserName.length) type:TGTextCheckingResultTypeBold contents:nil]];
            }
            _replyHeaderViaUserModel.textColor = [UIColor whiteColor];
            [_contentModel addSubmodel:_replyHeaderViaUserModel];
            
            _viaUser = viaUser;
        }
        
        if (_incomingAppearance && _savedMessage && hasForwardPostId) {
            _actionButtonModel = [[TGModernButtonViewModel alloc] init];
            _actionButtonModel.image = [[TGTelegraphConversationMessageAssetsSource instance] systemGoToButton];
            _actionButtonModel.modernHighlight = true;
            _actionButtonModel.frame = CGRectMake(0.0f, 0.0f, 29.0f, 29.0f);
            [self addSubmodel:_actionButtonModel];
        }
        
        TGBotReplyMarkup *replyMarkup = message.replyMarkup;
        if (replyMarkup != nil && replyMarkup.isInline) {
            _replyMarkup = replyMarkup;
            _replyButtonsModel = [[TGMessageReplyButtonsModel alloc] initWithContext:context];
            __weak TGStickerMessageViewModel *weakSelf = self;
            _replyButtonsModel.buttonActivated = ^(TGBotReplyMarkupButton *button, NSInteger index) {
                __strong TGStickerMessageViewModel *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:@{@"mid": @(strongSelf->_mid), @"command": button.text}];
                    if (button.action != nil) {
                        dict[@"action"] = button.action;
                    }
                    dict[@"index"] = @(index);
                    [strongSelf->_context.companionHandle requestAction:@"activateCommand" options:dict];
                }
            };
            [_replyButtonsModel setReplyMarkup:replyMarkup hasReceipt:false];
            [self addSubmodel:_replyButtonsModel];
        }

        _ios6ReactionSummary = [TGIOS6StickerReactionSummary(message) copy];
        _ios6ChosenReaction = [TGIOS6StickerChosenReaction(message) copy];
        if (_ios6ReactionSummary.length != 0)
            [self _ios6RebuildReactionButtons:nil];
    }
    return self;
}

- (void)dealloc {
    [_callbackButtonInProgressDisposable dispose];
}

- (void)setAuthorSignature:(NSString *)authorSignature {
    _authorSignature = authorSignature;
    [_imageModel setTimestampString:[TGDateUtils stringForShortTime:(int)_message.date] signatureString:authorSignature displayCheckmarks:!_incoming && _deliveryState != TGMessageDeliveryStateFailed checkmarkValue:(_incoming ? 0 : ((_deliveryState == TGMessageDeliveryStateDelivered ? 1 : 0) + (_read ? 1 : 0))) displayViews:_messageViews != nil viewsValue:_messageViews.viewCount animated:false];
}

- (void)updateAssets
{
    [super updateAssets];
    
    //[_imageModel setTimestampColor:[[TGTelegraphConversationMessageAssetsSource instance] systemMessageBackgroundColor]];
}

- (TGModernImageViewModel *)unsentButtonModel
{
    if (_unsentButtonModel == nil)
    {
        UIImage *image = _context.presentation.images.chatUnsentIcon;
        _unsentButtonModel = [[TGModernImageViewModel alloc] initWithImage:image];
        _unsentButtonModel.frame = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
        _unsentButtonModel.extendedEdges = UIEdgeInsetsMake(6, 6, 6, 6);
    }
    
    return _unsentButtonModel;
}

- (void)updateProgressInternal:(bool)progressVisible progress:(float)progress animated:(bool)animated
{
    bool progressWasVisible = _progressVisible;
    float previousProgress = _progress;
    
    _progress = progress;
    _progressVisible = progressVisible;
    
    [self updateImageOverlay:((progressWasVisible && !_progressVisible) || (_progressVisible && ABS(_progress - previousProgress) > FLT_EPSILON)) && animated];
}

- (void)updateImageOverlay:(bool)animated
{
    if (_progressVisible)
    {
        [_imageModel setOverlayType:TGMessageImageViewOverlayProgressNoCancel animated:false];
        [_imageModel setProgress:_progress animated:animated];
    }
    else
    {
        [_imageModel setOverlayType:TGMessageImageViewOverlayNone animated:animated];
    }
}

- (void)updateMessageAttributes
{
    [super updateMessageAttributes];
    
    bool previousRead = _read;
    _read = ![_context isMessageUnread:_message];
    if (previousRead != _read) {
        [_imageModel setTimestampString:[TGDateUtils stringForShortTime:(int)_message.date] signatureString:_authorSignature displayCheckmarks:!_incoming && !(_incomingAppearance && _context.isSavedMessages) && _deliveryState != TGMessageDeliveryStateFailed checkmarkValue:(_incoming ? 0 : ((_deliveryState == TGMessageDeliveryStateDelivered ? 1 : 0) + (_read ? 1 : 0))) displayViews:_messageViews != nil viewsValue:_messageViews.viewCount animated:true];
        [_imageModel setDisplayTimestampProgress:_deliveryState == TGMessageDeliveryStatePending];
    }
}

- (void)updateMessage:(TGMessage *)message viewStorage:(TGModernViewStorage *)viewStorage sizeUpdated:(bool *)sizeUpdated
{
    [super updateMessage:message viewStorage:viewStorage sizeUpdated:sizeUpdated];

    NSString *updatedReactionSummary = TGIOS6StickerReactionSummary(message);
    NSString *updatedChosenReaction = TGIOS6StickerChosenReaction(message);
    if (!TGObjectCompare(_ios6ReactionSummary, updatedReactionSummary) || !TGObjectCompare(_ios6ChosenReaction, updatedChosenReaction))
    {
        _ios6ReactionSummary = [updatedReactionSummary copy];
        _ios6ChosenReaction = [updatedChosenReaction copy];
        [self _ios6RebuildReactionButtons:viewStorage];
    }
    
    _mid = message.mid;
    _message = message;
    
    bool messageUnread = [_context isMessageUnread:message];
    
    if (_deliveryState != message.deliveryState || (!_incoming && _read != !messageUnread) || (_messageViews != nil && _messageViews.viewCount != message.viewCount.viewCount))
    {
        _messageViews = message.viewCount;
        _deliveryState = message.deliveryState;
        _read = !messageUnread;
        
        [_imageModel setTimestampString:[TGDateUtils stringForShortTime:(int)message.date] signatureString:_authorSignature displayCheckmarks:!_incoming && !(_incomingAppearance && _context.isSavedMessages) && _deliveryState != TGMessageDeliveryStateFailed checkmarkValue:(_incoming ? 0 : ((_deliveryState == TGMessageDeliveryStateDelivered ? 1 : 0) + (_read ? 1 : 0))) displayViews:_messageViews != nil viewsValue:_messageViews.viewCount animated:true];
        [_imageModel setDisplayTimestampProgress:_deliveryState == TGMessageDeliveryStatePending];
        
        if (_deliveryState == TGMessageDeliveryStateDelivered)
        {
            if (_unsentButtonModel != nil)
            {
                [self removeSubmodel:_unsentButtonModel viewStorage:viewStorage];
                _unsentButtonModel = nil;
            }
        }
        else if (_deliveryState == TGMessageDeliveryStateFailed)
        {
            if (_unsentButtonModel == nil)
            {
                [self addSubmodel:[self unsentButtonModel]];
                if ([_imageModel boundView] != nil)
                    [_unsentButtonModel bindViewToContainer:[_imageModel boundView].superview viewStorage:viewStorage];
                _unsentButtonModel.frame = CGRectOffset(_unsentButtonModel.frame, self.frame.size.width + _unsentButtonModel.frame.size.width, self.frame.size.height - _unsentButtonModel.frame.size.height - ((_collapseFlags & TGModernConversationItemCollapseBottom) ? 5 : 6));
                
                _unsentButtonTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(unsentButtonTapGesture:)];
                [[_unsentButtonModel boundView] addGestureRecognizer:_unsentButtonTapRecognizer];
            }
            
            if (self.frame.size.width > FLT_EPSILON)
            {
                if ([_imageModel boundView] != nil)
                {
                    [UIView animateWithDuration:0.2 animations:^
                    {
                        [self layoutForContainerSize:CGSizeMake(self.frame.size.width, 0.0f)];
                    }];
                }
                else
                    [self layoutForContainerSize:CGSizeMake(self.frame.size.width, 0.0f)];
            }
        }
        else if (_deliveryState == TGMessageDeliveryStatePending)
        {
            if (_unsentButtonModel != nil)
            {
                UIView<TGModernView> *unsentView = [_unsentButtonModel boundView];
                if (unsentView != nil)
                {
                    [unsentView removeGestureRecognizer:_unsentButtonTapRecognizer];
                    _unsentButtonTapRecognizer = nil;
                }
                
                if (unsentView != nil)
                {
                    [viewStorage allowResurrectionForOperations:^
                    {
                        [self removeSubmodel:_unsentButtonModel viewStorage:viewStorage];
                        
                        UIView *restoredView = [viewStorage dequeueViewWithIdentifier:[unsentView viewIdentifier] viewStateIdentifier:[unsentView viewStateIdentifier]];
                        
                        if (restoredView != nil)
                        {
                            [[_imageModel boundView].superview addSubview:restoredView];
                            
                            [UIView animateWithDuration:0.2 animations:^
                            {
                                restoredView.frame = CGRectOffset(restoredView.frame, restoredView.frame.size.width + 9, 0.0f);
                                restoredView.alpha = 0.0f;
                            } completion:^(__unused BOOL finished)
                            {
                                [viewStorage enqueueView:restoredView];
                            }];
                        }
                    }];
                }
                else
                    [self removeSubmodel:_unsentButtonModel viewStorage:viewStorage];
                
                _unsentButtonModel = nil;
            }
            
            if (self.frame.size.width > FLT_EPSILON)
            {
                if ([_imageModel boundView] != nil)
                {
                    [UIView animateWithDuration:0.2 animations:^
                    {
                        [self layoutForContainerSize:CGSizeMake(self.frame.size.width, 0.0f)];
                    }];
                }
                else
                    [self layoutForContainerSize:CGSizeMake(self.frame.size.width, 0.0f)];
            }
        }
    }
    
    for (id attachment in message.mediaAttachments)
    {
        if ([attachment isKindOfClass:[TGDocumentMediaAttachment class]])
        {
            _document = attachment;
        }
    }
    
    CGSize displaySize = [self displaySizeForSize:_size];
    
    NSMutableString *imageUri = [[NSMutableString alloc] init];
    [imageUri appendString:@"sticker://?"];
    if (_document.documentId != 0)
    {
        [imageUri appendFormat:@"&documentId=%" PRId64, _document.documentId];
        
        TGMediaOriginInfo *originInfo = _document.originInfo ?: [TGMediaOriginInfo mediaOriginInfoForDocumentAttachment:_document];
        if (originInfo != nil)
            [imageUri appendFormat:@"&origin_info=%@", [originInfo stringRepresentation]];
    }
    else
    {
        [imageUri appendFormat:@"&localDocumentId=%" PRId64, _document.localDocumentId];
    }
    [imageUri appendFormat:@"&accessHash=%" PRId64, _document.accessHash];
    [imageUri appendFormat:@"&datacenterId=%d", (int)_document.datacenterId];
    [imageUri appendFormat:@"&fileName=%@", [TGStringUtils stringByEscapingForURL:_document.fileName]];
    [imageUri appendFormat:@"&size=%d", (int)_document.size];
    [imageUri appendFormat:@"&width=%d&height=%d", (int)displaySize.width, (int)displaySize.height];
    [imageUri appendFormat:@"&mime-type=%@", [TGStringUtils stringByEscapingForURL:_document.mimeType]];
    if (_document.documentUri.length != 0) {
        [imageUri appendFormat:@"&documentUri=%@", [TGStringUtils stringByEscapingForURL:_document.documentUri]];
    }
    
    [_imageModel setUri:imageUri];
    
    NSString *alt = [self stickerAltText:_document];
    if (alt.length != 0)
    {
        bool keepFallback = [self shouldKeepEmojiFallbackForDocument:_document];
        if (keepFallback || ![self stickerImageIsLocallyAvailable:_document])
        {
            _emojiFallbackText = alt;
            _emojiFallbackUntilImageLoaded = !keepFallback;
            [self updateEmojiFallbackLabel];
            IOS6_NOOP_LOG(@"IOS6STICKER emojiFallback mid=%d docId=%lld mime=%@ alt=%@", (int)_mid, _document.documentId, _document.mimeType, alt);
        }
        else if (_emojiFallbackText.length != 0 || _emojiFallbackLabel != nil)
        {
            _emojiFallbackText = nil;
            _emojiFallbackUntilImageLoaded = false;
            [self updateEmojiFallbackLabel];
        }
    }
    else if (_emojiFallbackText.length != 0 || _emojiFallbackLabel != nil)
    {
        _emojiFallbackText = nil;
        _emojiFallbackUntilImageLoaded = false;
        [self updateEmojiFallbackLabel];
    }
    
    TGBotReplyMarkup *replyMarkup = message.replyMarkup != nil && message.replyMarkup.isInline ? message.replyMarkup : nil;
    if (!TGObjectCompare(_replyMarkup, replyMarkup)) {
        _replyMarkup = replyMarkup;
        
        if (_replyButtonsModel == nil) {
            _replyButtonsModel = [[TGMessageReplyButtonsModel alloc] initWithContext:_context];
            __weak TGStickerMessageViewModel *weakSelf = self;
            _replyButtonsModel.buttonActivated = ^(TGBotReplyMarkupButton *button, NSInteger index) {
                __strong TGStickerMessageViewModel *strongSelf = weakSelf;
                if (strongSelf != nil) {
                    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:@{@"mid": @(strongSelf->_mid), @"command": button.text}];
                    if (button.action != nil) {
                        dict[@"action"] = button.action;
                    }
                    dict[@"index"] = @(index);
                    [strongSelf->_context.companionHandle requestAction:@"activateCommand" options:dict];
                }
            };
            
            [self addSubmodel:_replyButtonsModel];
        }
        if (_imageModel.boundView != nil) {
            [_replyButtonsModel unbindView:viewStorage];
            [_replyButtonsModel setReplyMarkup:replyMarkup hasReceipt:false];
            [_replyButtonsModel bindViewToContainer:_imageModel.boundView.superview viewStorage:viewStorage];
        } else {
            [_replyButtonsModel setReplyMarkup:replyMarkup hasReceipt:false];
        }
        if (sizeUpdated) {
            *sizeUpdated = true;
        }
    }
}

- (CGRect)effectiveContentFrame
{
    return _imageModel.frame;
}

- (void)bindSpecialViewsToContainer:(UIView *)container viewStorage:(TGModernViewStorage *)viewStorage atItemPosition:(CGPoint)itemPosition
{
    [super bindSpecialViewsToContainer:container viewStorage:viewStorage atItemPosition:itemPosition];
    
    [_imageModel bindViewToContainer:container viewStorage:viewStorage];
    [_imageModel boundView].frame = CGRectOffset([_imageModel boundView].frame, itemPosition.x, itemPosition.y);
    
    [self updateEmojiFallbackLabel];
    for (TGModernButtonViewModel *button in _ios6ReactionButtonModels)
        if ([button boundView] != nil)
            [container bringSubviewToFront:[button boundView]];

    _replyBackgroundModel.parentOffset = itemPosition;
    [_replyBackgroundModel bindViewToContainer:container viewStorage:viewStorage];
    
    _contentModel.parentOffset = itemPosition;
    [_contentModel bindViewToContainer:container viewStorage:viewStorage];
    
    [_replyHeaderModel bindSpecialViewsToContainer:container viewStorage:viewStorage atItemPosition:CGPointMake(itemPosition.x + _contentModel.frame.origin.x + _replyHeaderModel.frame.origin.x, itemPosition.y + _contentModel.frame.origin.y + _replyHeaderModel.frame.origin.y)];
    
    [_replyButtonsModel bindSpecialViewsToContainer:container viewStorage:viewStorage atItemPosition:CGPointMake(itemPosition.x, itemPosition.y)];
    
    [self subscribeToCallbackButtonInProgress];
}

- (void)subscribeToCallbackButtonInProgress {
    if (_replyButtonsModel != nil) {
        __weak TGStickerMessageViewModel *weakSelf = self;
        [_callbackButtonInProgressDisposable setDisposable:[[[_context callbackInProgress] deliverOn:[SQueue mainQueue]] startWithNext:^(NSDictionary *next) {
            __strong TGStickerMessageViewModel *strongSelf = weakSelf;
            if (strongSelf != nil) {
                if (next != nil) {
                    if ([next[@"mid"] intValue] == strongSelf->_mid) {
                        [strongSelf->_replyButtonsModel setButtonIndexInProgress:[next[@"buttonIndex"] intValue]];
                    } else {
                        [strongSelf->_replyButtonsModel setButtonIndexInProgress:NSNotFound];
                    }
                } else {
                    [strongSelf->_replyButtonsModel setButtonIndexInProgress:NSNotFound];
                }
            }
        }]];
    }
}

- (void)bindViewToContainer:(UIView *)container viewStorage:(TGModernViewStorage *)viewStorage
{
    [self updateEditingState:nil viewStorage:nil animationDelay:-1.0];
    
    _replyBackgroundModel.parentOffset = CGPointZero;
    _contentModel.parentOffset = CGPointZero;
    
    [super bindViewToContainer:container viewStorage:viewStorage];
    for (TGModernButtonViewModel *button in _ios6ReactionButtonModels)
        if ([button boundView] != nil)
            [container bringSubviewToFront:[button boundView]];
    
    [_replyHeaderModel bindSpecialViewsToContainer:_contentModel.boundView viewStorage:viewStorage atItemPosition:CGPointMake(_replyHeaderModel.frame.origin.x, _replyHeaderModel.frame.origin.y)];
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(messageTapGesture:)];
    _tapGestureRecognizer.delegate = self;
    
    _boundDoubleTapRecognizer = [[TGDoubleTapGestureRecognizer alloc] initWithTarget:self action:@selector(messageDoubleTapGesture:)];
    _boundDoubleTapRecognizer.consumeSingleTap = false;
    _boundDoubleTapRecognizer.delegate = self;
    
    if (_contentModel != nil)
    {
        _replyTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(replyHeaderTapGesture:)];
        [[_contentModel boundView] addGestureRecognizer:_replyTapRecognizer];
    }
    
    if (_unsentButtonModel != nil)
    {
        _unsentButtonTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(unsentButtonTapGesture:)];
        [[_unsentButtonModel boundView] addGestureRecognizer:_unsentButtonTapRecognizer];
    }
    
    if (_actionButtonModel != nil) {
        [(TGModernButtonView *)_actionButtonModel.boundView addTarget:self action:@selector(actionPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    
    UIView *backgroundView = [_imageModel boundView];
    if (![self needsEmojiFallbackForDocument:_document])
    {
        [backgroundView addGestureRecognizer:_tapGestureRecognizer];
        [backgroundView addGestureRecognizer:_boundDoubleTapRecognizer];
    }
    
    [self updateEmojiFallbackLabel];
    
    [self subscribeToCallbackButtonInProgress];
}

- (void)unbindView:(TGModernViewStorage *)viewStorage
{
    UIView *imageView = [_imageModel boundView];
    [imageView removeGestureRecognizer:_tapGestureRecognizer];
    _tapGestureRecognizer.delegate = nil;
    _tapGestureRecognizer = nil;
    
    [imageView removeGestureRecognizer:_boundDoubleTapRecognizer];
    _boundDoubleTapRecognizer.delegate = nil;
    _boundDoubleTapRecognizer = nil;
    
    [[_contentModel boundView] removeGestureRecognizer:_replyTapRecognizer];
    _replyTapRecognizer = nil;
    
    [_emojiFallbackLabel removeFromSuperview];
    _emojiFallbackLabel = nil;
    
    if (_temporaryHighlightView != nil)
    {
        [_temporaryHighlightView removeFromSuperview];
        _temporaryHighlightView = nil;
    }
    
    if (_unsentButtonModel != nil)
    {
        [[_unsentButtonModel boundView] removeGestureRecognizer:_unsentButtonTapRecognizer];
        _unsentButtonTapRecognizer = nil;
    }
    
    if (_actionButtonModel != nil)
    {
        [(TGModernButtonView *)_actionButtonModel.boundView removeTarget:self action:@selector(sharePressed) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [super unbindView:viewStorage];
    
    [_callbackButtonInProgressDisposable setDisposable:nil];
}

- (void)actionPressed {
    if (_savedMessage)
    {
        int64_t peerId = 0;
        int32_t messageId = 0;
        for (TGMediaAttachment *attachment in _message.mediaAttachments)
        {
            if (attachment.type == TGForwardedMessageMediaAttachmentType)
            {
                peerId = ((TGForwardedMessageMediaAttachment *)attachment).forwardSourcePeerId ? : ((TGForwardedMessageMediaAttachment *)attachment).forwardPeerId;
                messageId = ((TGForwardedMessageMediaAttachment *)attachment).forwardMid ?: ((TGForwardedMessageMediaAttachment *)attachment).forwardPostId;
                break;
            }
        }
        
        [_context.companionHandle requestAction:@"peerAvatarTapped" options:@{@"peerId": @(peerId), @"messageId": @(messageId)}];
    }
}

- (void)unsentButtonTapGesture:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        [_context.companionHandle requestAction:@"showUnsentMessageMenu" options:@{@"mid": @(_mid)}];
    }
}

- (void)replyHeaderTapGesture:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint location = [recognizer locationInView:_contentModel.boundView];
        if (_replyHeaderViaUserModel != nil && (CGRectContainsPoint(_replyHeaderViaUserModel.frame, location) || _replyHeaderModel == nil)) {
            [_context.companionHandle requestAction:@"useContextBot" options:@{@"uid": @((int32_t)_viaUser.uid), @"username": _viaUser.userName == nil ? @"" : _viaUser.userName}];
        } else if (_replyHeaderModel != nil) {
            [_context.companionHandle requestAction:@"navigateToMessage" options:@{@"mid": @(_replyMessageId), @"sourceMid": @(_mid)}];
        }
    }
}

- (void)messageTapGesture:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
        [_context.companionHandle requestAction:@"stickerPackInfoRequested" options:@{@"mid": @(_mid), @"peerId": @(_authorPeerId)}];
}

- (void)messageDoubleTapGesture:(TGDoubleTapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        if (recognizer.longTapped)
            [_context.companionHandle requestAction:@"messageSelectionRequested" options:@{@"mid": @(_mid), @"peerId": @(_authorPeerId)}];
    }
}

- (bool)gestureRecognizerShouldHandleLongTap:(TGDoubleTapGestureRecognizer *)__unused recognizer
{
    return true;
}

- (void)gestureRecognizer:(TGDoubleTapGestureRecognizer *)__unused recognizer didBeginAtPoint:(CGPoint)__unused point
{
}

- (int)gestureRecognizer:(TGDoubleTapGestureRecognizer *)__unused recognizer shouldFailTap:(CGPoint)__unused point
{
    return 0;
}

- (void)doubleTapGestureRecognizerSingleTapped:(TGDoubleTapGestureRecognizer *)__unused recognizer
{
}

- (bool)gestureRecognizerShouldLetScrollViewStealTouches:(TGDoubleTapGestureRecognizer *)__unused recognizer
{
    return true;
}

- (bool)gestureRecognizerShouldFailOnMove:(TGDoubleTapGestureRecognizer *)__unused recognizer
{
    return true;
}

- (void)setTemporaryHighlighted:(bool)temporaryHighlighted viewStorage:(TGModernViewStorage *)__unused viewStorage
{
    if (iosMajorVersion() >= 7)
    {
        TGImageView *imageView = ((TGMessageImageViewContainer *)_imageModel.boundView).imageView;
        if (imageView.currentImage != nil)
        {
            if (temporaryHighlighted)
            {
                if (_temporaryHighlightView == nil)
                {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
                    UIImage *highlightImage = [imageView.currentImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
#else
                    UIImage *highlightImage = imageView.currentImage;
#endif
                    _temporaryHighlightView = [[UIImageView alloc] initWithImage:highlightImage];
                    _temporaryHighlightView.frame = [_imageModel boundView].frame;
                    _temporaryHighlightView.tintColor = UIColorRGBA(0x000000, 0.2f);
                    [[_imageModel boundView].superview addSubview:_temporaryHighlightView];
                }
            }
            else if (_temporaryHighlightView != nil)
            {
                UIImageView *temporaryView = _temporaryHighlightView;
                [UIView animateWithDuration:0.4 animations:^
                {
                    temporaryView.alpha = 0.0f;
                } completion:^(__unused BOOL finished)
                {
                    [temporaryView removeFromSuperview];
                }];
                _temporaryHighlightView = nil;
            }
        }
    }
}

- (void)layoutForContainerSize:(CGSize)containerSize
{
    bool isPost = _authorPeer != nil && [_authorPeer isKindOfClass:[TGConversation class]];
    TGMessageViewModelLayoutConstants const *layoutConstants = TGGetMessageViewModelLayoutConstants();
    
    CGFloat topSpacing = (_collapseFlags & TGModernConversationItemCollapseTop) ? layoutConstants->topInsetCollapsed : layoutConstants->topInset;
    CGFloat bottomSpacing = (_collapseFlags & TGModernConversationItemCollapseBottom) ? layoutConstants->bottomInsetCollapsed : layoutConstants->bottomInset;
    CGFloat reactionExtraHeight = _ios6ReactionButtonModels.count != 0 ? 25.0f : 0.0f;
    
    if (isPost) {
        topSpacing = layoutConstants->topPostInset;
        bottomSpacing = layoutConstants->bottomPostInset;
    }
    
    CGFloat avatarOffset = 0.0f;
    if (_hasAvatar)
        avatarOffset = 38.0f;
    
    CGFloat unsentOffset = 0.0f;
    if (!_incomingAppearance && _deliveryState == TGMessageDeliveryStateFailed)
        unsentOffset = 29.0f;
    
    CGRect imageFrame = CGRectMake(_incomingAppearance ? (avatarOffset + layoutConstants->leftImageInset) : (containerSize.width - _imageModel.frame.size.width - layoutConstants->rightImageInset - unsentOffset), topSpacing, _imageModel.frame.size.width, _imageModel.frame.size.height);
    if (_incomingAppearance && _editing)
        imageFrame.origin.x += 42.0f;
    
    if (!_editing && fabs(_replyPanOffset) > FLT_EPSILON)
        imageFrame.origin.x += _replyPanOffset;
    
    _imageModel.frame = imageFrame;

    if (_ios6ReactionButtonModels.count != 0)
    {
        CGFloat totalWidth = 0.0f;
        for (TGModernButtonViewModel *button in _ios6ReactionButtonModels)
            totalWidth += button.image.size.width;
        totalWidth += MAX(0, (NSInteger)_ios6ReactionButtonModels.count - 1) * 3.0f;
        CGFloat x = _incomingAppearance ? CGRectGetMinX(imageFrame) + 4.0f : MAX(8.0f, CGRectGetMaxX(imageFrame) - 4.0f - totalWidth);
        for (TGModernButtonViewModel *button in _ios6ReactionButtonModels)
        {
            CGSize buttonSize = button.image.size;
            button.hidden = x + buttonSize.width > containerSize.width - 8.0f;
            button.frame = CGRectMake(x, CGRectGetMaxY(imageFrame) + 2.0f, buttonSize.width, buttonSize.height);
            x += buttonSize.width + 3.0f;
        }
    }
    
    if (_emojiFallbackLabel != nil)
        _emojiFallbackLabel.frame = CGRectMake(0.0f, 0.0f, imageFrame.size.width, imageFrame.size.height);
    
    if (_contentModel != nil)
    {
        CGFloat availableWidth = containerSize.width - imageFrame.size.width - 40.0f - avatarOffset;
        
        bool updateContent = false;
        CGRect contentFrame = CGRectZero;
        if (_replyHeaderModel != nil) {
            [_replyHeaderModel layoutForContainerSize:CGSizeMake(availableWidth, 0.0f) updateContent:&updateContent];
            contentFrame = CGRectMake(0.0f, 0.0f, _replyHeaderModel.frame.size.width + 17.0f, _replyHeaderModel.frame.size.height + 5.0f);
            
            if (_replyHeaderViaUserModel != nil) {
                if ([_replyHeaderViaUserModel layoutNeedsUpdatingForContainerSize:CGSizeMake(availableWidth, 0.0f)]) {
                    updateContent = true;
                    [_replyHeaderViaUserModel layoutForContainerSize:CGSizeMake(availableWidth, 0.0f)];
                }
                
                _replyHeaderViaUserModel.frame = CGRectMake(5.0f, 2.0f, _replyHeaderViaUserModel.frame.size.width, _replyHeaderViaUserModel.frame.size.height);
                contentFrame.size.height += _replyHeaderViaUserModel.frame.size.height + 4.0f;
                contentFrame.size.width = MAX(contentFrame.size.width, _replyHeaderViaUserModel.frame.size.width + 14.0f);
            }
        } else {
            if (_replyHeaderViaUserModel != nil) {
                if ([_replyHeaderViaUserModel layoutNeedsUpdatingForContainerSize:CGSizeMake(availableWidth, 0.0f)]) {
                    updateContent = true;
                    [_replyHeaderViaUserModel layoutForContainerSize:CGSizeMake(availableWidth, 0.0f)];
                }
                
                _replyHeaderViaUserModel.frame = CGRectMake(5.0f, 2.0f, _replyHeaderViaUserModel.frame.size.width, _replyHeaderViaUserModel.frame.size.height);
                contentFrame.size.width = _replyHeaderViaUserModel.frame.size.width + 14.0f;
                contentFrame.size.height += _replyHeaderViaUserModel.frame.size.height + 9.0f;
            }
        }
        
        if (_incomingAppearance)
            contentFrame.origin.x = containerSize.width - contentFrame.size.width - 7.0f;
        else
            contentFrame.origin.x = 9.0f + (_editing ? 42.0f : 0.0f);
        
        contentFrame.origin.y = 0.0f; //CGRectGetMaxY(imageFrame) - contentFrame.size.height - 4.0f - 8.0f;
        
        _contentModel.frame = contentFrame;
        _replyHeaderModel.frame = CGRectMake(7.0f, _replyHeaderViaUserModel == nil ? 0.0f : (_replyHeaderViaUserModel.frame.size.height + 2.0), _replyHeaderModel.frame.size.width, _replyHeaderModel.frame.size.height);
        _replyBackgroundModel.frame = CGRectMake(contentFrame.origin.x, contentFrame.origin.y + 3.0f, contentFrame.size.width - 2.0f, contentFrame.size.height - 5.0f);
        
        if ((_incomingAppearance && _replyBackgroundModel.frame.origin.x < CGRectGetMaxX(imageFrame)) || (!_incomingAppearance && CGRectGetMaxX(_replyBackgroundModel.frame) > imageFrame.origin.x))
        {
            _contentModel.alpha = 0.0f;
            _replyBackgroundModel.alpha = 0.0f;
        }
        else
        {
            _contentModel.alpha = 1.0f;
            _replyBackgroundModel.alpha = 1.0f;
        }
        
        if (updateContent)
        {
            [_contentModel setNeedsSubmodelContentsUpdate];
            [_contentModel updateSubmodelContentsIfNeeded];
        }
    }
    
    if (_unsentButtonModel != nil)
    {
        _unsentButtonModel.frame = CGRectMake(containerSize.width - _unsentButtonModel.frame.size.width - 9, _imageModel.frame.size.height + topSpacing + bottomSpacing - _unsentButtonModel.frame.size.height - ((_collapseFlags & TGModernConversationItemCollapseBottom) ? 5 : 6), _unsentButtonModel.frame.size.width, _unsentButtonModel.frame.size.height);
    }
    
    if (_actionButtonModel != nil)
    {
        _actionButtonModel.frame = CGRectOffset(_actionButtonModel.bounds, CGRectGetMaxX(imageFrame) + 7.0f, CGRectGetMaxY(imageFrame) - 29.0f - 1.0f);
    }
    
    CGFloat replyButtonsHeight = 0.0f;
    if (_replyButtonsModel != nil) {
        CGRect backgroundFrame = _imageModel.frame;
        
        [_replyButtonsModel layoutForContainerSize:CGSizeMake(MIN(MAX([_replyButtonsModel minimumWidth], backgroundFrame.size.width + 10.0f), containerSize.width - 38.0f), containerSize.height)];
        
        _replyButtonsModel.frame = CGRectMake((_incomingAppearance ? backgroundFrame.origin.x : (CGRectGetMaxX(backgroundFrame) - _replyButtonsModel.frame.size.width)) + (_incomingAppearance ? -5.0f : 5.0f), CGRectGetMaxY(backgroundFrame) + reactionExtraHeight, _replyButtonsModel.frame.size.width, _replyButtonsModel.frame.size.height);
        replyButtonsHeight = _replyButtonsModel.frame.size.height;
        self.avatarOffset = replyButtonsHeight;
    }
    
    CGRect frame = self.frame;
    frame.size = CGSizeMake(containerSize.width, _imageModel.frame.size.height + topSpacing + bottomSpacing + reactionExtraHeight + replyButtonsHeight);
    self.frame = frame;
    
    [super layoutForContainerSize:containerSize];
}

- (void)avatarTapGesture:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        int64_t peerId = _message.fromUid;
        bool peer = !TGPeerIdIsUser(peerId);
        if (_context.isSavedMessages)
        {
            for (TGMediaAttachment *attachment in _message.mediaAttachments)
            {
                if (attachment.type == TGForwardedMessageMediaAttachmentType)
                {
                    peerId = ((TGForwardedMessageMediaAttachment *)attachment).forwardPeerId;
                    peer = true;
                    break;
                }
            }
        }
        
        if (peer)
        {
            [_context.companionHandle requestAction:@"peerAvatarTapped" options:@{@"peerId": @(peerId), @"messageId": @(_mid), @"chat": @(_context.isSavedMessages)}];
        }
        else
        {
            [_context.companionHandle requestAction:@"userAvatarTapped" options:@{@"uid": @(peerId), @"mid": @(_mid)}];
        }
    }
}

@end
