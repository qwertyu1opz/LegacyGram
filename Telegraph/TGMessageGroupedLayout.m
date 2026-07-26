#import "TGMessageGroupedLayout.h"

#import "TGImageMessageViewModel.h"
#import "TGPresentation.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGMessageViewCountContentProperty.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGMessage.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGImageUtils.h"

@interface TGMessagePhotoInfo : NSObject

@property (nonatomic, readonly) int32_t mid;
@property (nonatomic, readonly) CGSize imageSize;
@property (nonatomic, readonly) CGFloat aspectRatio;

@property (nonatomic, assign) CGRect layoutFrame;
@property (nonatomic, assign) TGMessageGroupPositionFlags positionFlags;

- (instancetype)initWithMessage:(TGMessage *)message;

@end

@interface TGMessageGroupedLayoutAttempt : NSObject

@property (nonatomic, readonly) NSArray *lineCounts;
@property (nonatomic, readonly) NSArray *heights;

- (instancetype)initWithLineCounts:(NSArray *)lineCounts heights:(NSArray *)heights;

@end

@interface TGMessageGroupedLayout ()
{
    NSMutableDictionary *_layouts;
    int32_t _mainMessageId;
    NSString *_caption;
    NSArray *_captionTextCheckingResults;
    int32_t _captionMessageId;
    NSString *_reactionSummary;
    NSString *_chosenReaction;
}
@end

@implementation TGMessageGroupedLayout

- (instancetype)initWithMessages:(NSArray *)messages larger:(bool)larger
{
    self = [super init];
    if (self != nil)
    {
        CGSize maxSize;
        [TGImageMessageViewModel calculateImageSizesForImageSize:CGSizeMake(720.0f, 660.0f) thumbnailSize:NULL renderSize:&maxSize squareAspect:false larger:larger];
        // The media mask keeps a tiny radius even on inner album corners.
        // A one-point overlap hides those transparent corner pixels and the
        // black backing beneath them; the normal presentation stays intact.
        CGFloat spacing = [TGPresentation classicIOS6Style] ? 0.0f : 1.0f;
        
        NSString *proportions = @"";
        CGFloat averageAspectRatio = 1.0f;
        bool forceCalc = false;
        NSMutableArray *photos = [[NSMutableArray alloc] init];
        for (TGMessage *message in messages)
        {
            if (_caption.length == 0 && message.caption.length != 0)
            {
                _caption = [message.caption copy];
                _captionTextCheckingResults = [message.textCheckingResults copy];
                _captionMessageId = message.mid;
            }

            TGMessagePhotoInfo *photo = [[TGMessagePhotoInfo alloc] initWithMessage:message];
            if (photo != nil)
            {
                [photos addObject:photo];
                
                CGFloat aspectRatio = photo.aspectRatio;
                if (aspectRatio > 1.2f)
                    proportions = [proportions stringByAppendingString:@"w"];
                else if (aspectRatio < 0.8f)
                    proportions = [proportions stringByAppendingString:@"n"];
                else
                    proportions = [proportions stringByAppendingString:@"q"];
                
                averageAspectRatio += photo.aspectRatio;
                
                if (photo.aspectRatio > 2.0f)
                    forceCalc = true;
            }
        }
        
        const CGFloat minWidth = 68.0f;
        CGFloat maxAspectRatio = maxSize.width / maxSize.height;
        if (photos.count > 0)
            averageAspectRatio = averageAspectRatio / photos.count;
        
        if (!forceCalc)
        {
            if (photos.count == 2)
            {
                if ([proportions isEqualToString:@"ww"] && averageAspectRatio > 1.4 * maxAspectRatio && ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).aspectRatio - ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).aspectRatio < 0.2)
                {
                    CGFloat width = maxSize.width;
                    CGFloat height = TGScreenPixelFloor(MIN(width / ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).aspectRatio, MIN(width / ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).aspectRatio, (maxSize.height - spacing) / 2.0f)));
                    
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).layoutFrame = CGRectMake(0.0f, 0.0f, width, height);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).positionFlags = TGMessageGroupPositionTop | TGMessageGroupPositionLeft | TGMessageGroupPositionRight;
                    
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).layoutFrame = CGRectMake(0.0f, height + spacing, width, height);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).positionFlags = TGMessageGroupPositionBottom | TGMessageGroupPositionLeft | TGMessageGroupPositionRight;
                }
                else if ([proportions isEqualToString:@"ww"] || [proportions isEqualToString:@"qq"])
                {
                    CGFloat width = (maxSize.width - spacing) / 2.0f;
                    CGFloat height = TGScreenPixelFloor(MIN(width / ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).aspectRatio, MIN(width / ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).aspectRatio, maxSize.height)));
                    
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).layoutFrame = CGRectMake(0.0f, 0.0f, width, height);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).positionFlags = TGMessageGroupPositionTop | TGMessageGroupPositionLeft | TGMessageGroupPositionBottom;
                    
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).layoutFrame = CGRectMake(width + spacing, 0.0f, width, height);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).positionFlags = TGMessageGroupPositionTop | TGMessageGroupPositionRight | TGMessageGroupPositionBottom;
                }
                else
                {
                    CGFloat minimalWidth = TGScreenPixelFloor(minWidth * 1.5f);
                    CGFloat secondWidth = TGScreenPixelFloor(MAX(0.4 * (maxSize.width - spacing), round((maxSize.width - spacing) / ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).aspectRatio / (1.0f / ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).aspectRatio + 1.0f / ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).aspectRatio))));
                    CGFloat firstWidth = maxSize.width - secondWidth - spacing;
                    if (firstWidth < minimalWidth)
                    {
                        CGFloat diff = minimalWidth - firstWidth;
                        firstWidth = minimalWidth;
                        secondWidth -= diff;
                    }
                    
                    CGFloat height = TGScreenPixelFloor(MIN(maxSize.height, round(MIN(firstWidth / ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).aspectRatio, secondWidth / ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).aspectRatio))));
                    
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).layoutFrame = CGRectMake(0.0f, 0.0f, firstWidth, height);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).positionFlags = TGMessageGroupPositionTop | TGMessageGroupPositionLeft | TGMessageGroupPositionBottom;
                    
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).layoutFrame = CGRectMake(firstWidth + spacing, 0.0f, secondWidth, height);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).positionFlags = TGMessageGroupPositionTop | TGMessageGroupPositionRight | TGMessageGroupPositionBottom;
                }
            }
            else if (photos.count == 3)
            {
                if ([proportions hasPrefix:@"n"])
                {
                    CGFloat firstHeight = maxSize.height;
                    
                    CGFloat thirdHeight = MIN((maxSize.height - spacing) * 0.5f, round(((TGMessagePhotoInfo *)[photos objectAtIndex:1]).aspectRatio * (maxSize.width - spacing) / (((TGMessagePhotoInfo *)[photos objectAtIndex:2]).aspectRatio + ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).aspectRatio)));
                    CGFloat secondHeight = maxSize.height - thirdHeight - spacing;
                    CGFloat rightWidth = MAX(minWidth, MIN((maxSize.width - spacing) * 0.5f, round(MIN(thirdHeight * ((TGMessagePhotoInfo *)[photos objectAtIndex:2]).aspectRatio, secondHeight * ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).aspectRatio))));
                    
                    CGFloat leftWidth = round(MIN(firstHeight * ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).aspectRatio, (maxSize.width - spacing - rightWidth)));
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).layoutFrame = CGRectMake(0.0f, 0.0f, leftWidth, firstHeight);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).positionFlags = TGMessageGroupPositionTop | TGMessageGroupPositionLeft | TGMessageGroupPositionBottom;
                    
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).layoutFrame = CGRectMake(leftWidth + spacing, 0.0f, rightWidth, secondHeight);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).positionFlags = TGMessageGroupPositionRight | TGMessageGroupPositionTop;
                    
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:2]).layoutFrame = CGRectMake(leftWidth + spacing, secondHeight + spacing, rightWidth, thirdHeight);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:2]).positionFlags = TGMessageGroupPositionRight | TGMessageGroupPositionBottom;
                }
                else
                {
                    CGFloat width = maxSize.width;
                    CGFloat firstHeight = TGScreenPixelFloor(MIN(width / ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).aspectRatio, (maxSize.height - spacing) * 0.66f));
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).layoutFrame = CGRectMake(0.0f, 0.0f, width, firstHeight);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).positionFlags = TGMessageGroupPositionTop | TGMessageGroupPositionLeft | TGMessageGroupPositionRight;
                    
                    width = (maxSize.width - spacing) / 2.0f;
                    CGFloat secondHeight = MIN(maxSize.height - firstHeight - spacing, round(MIN(width / ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).aspectRatio, width / ((TGMessagePhotoInfo *)[photos objectAtIndex:2]).aspectRatio)));
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).layoutFrame = CGRectMake(0.0f, firstHeight + spacing, width, secondHeight);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).positionFlags = TGMessageGroupPositionLeft | TGMessageGroupPositionBottom;
                    
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:2]).layoutFrame = CGRectMake(width + spacing, firstHeight + spacing, width, secondHeight);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:2]).positionFlags = TGMessageGroupPositionRight | TGMessageGroupPositionBottom;
                }
            }
            else if (photos.count == 4)
            {
                if ([proportions isEqualToString:@"wwww"] || [proportions hasPrefix:@"w"])
                {
                    CGFloat w = maxSize.width;
                    CGFloat h0 = round(MIN(w / ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).aspectRatio, (maxSize.height - spacing) * 0.66f));
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).layoutFrame = CGRectMake(0.0f, 0.0f, w, h0);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).positionFlags = TGMessageGroupPositionTop | TGMessageGroupPositionLeft | TGMessageGroupPositionRight;
                    
                    CGFloat h = round((maxSize.width - 2 * spacing) / (((TGMessagePhotoInfo *)[photos objectAtIndex:1]).aspectRatio + ((TGMessagePhotoInfo *)[photos objectAtIndex:2]).aspectRatio + ((TGMessagePhotoInfo *)[photos objectAtIndex:3]).aspectRatio));
                    CGFloat w0 = MAX(minWidth, MIN((maxSize.width - 2 * spacing) * 0.4f, h * ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).aspectRatio));
                    CGFloat w2 = MAX(MAX(minWidth, (maxSize.width - 2 * spacing) * 0.33f), h * ((TGMessagePhotoInfo *)[photos objectAtIndex:3]).aspectRatio);
                    CGFloat w1 = w - w0 - w2 - 2 * spacing;
                    h = MIN(maxSize.height - h0 - spacing, h);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).layoutFrame = CGRectMake(0.0f, h0 + spacing, w0, h);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).positionFlags = TGMessageGroupPositionLeft | TGMessageGroupPositionBottom;
                    
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:2]).layoutFrame = CGRectMake(w0 + spacing, h0 + spacing, w1, h);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:2]).positionFlags = TGMessageGroupPositionBottom;
                    
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:3]).layoutFrame = CGRectMake(w0 + w1 + 2 * spacing, h0 + spacing, w2, h);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:3]).positionFlags = TGMessageGroupPositionRight | TGMessageGroupPositionBottom;
                }
                else
                {
                    CGFloat h = maxSize.height;
                    CGFloat w0 = round(MIN(h * ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).aspectRatio, (maxSize.width - spacing) * 0.6f));
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).layoutFrame = CGRectMake(0.0f, 0.0f, w0, h);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:0]).positionFlags = TGMessageGroupPositionTop | TGMessageGroupPositionLeft | TGMessageGroupPositionBottom;
                    
                    CGFloat w = round((maxSize.height - 2 * spacing) / (1.0f / ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).aspectRatio + 1.0f /  ((TGMessagePhotoInfo *)[photos objectAtIndex:2]).aspectRatio + 1.0f / ((TGMessagePhotoInfo *)[photos objectAtIndex:3]).aspectRatio));
                    CGFloat h0 = TGScreenPixelFloor(w / ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).aspectRatio);
                    CGFloat h1 = TGScreenPixelFloor(w / ((TGMessagePhotoInfo *)[photos objectAtIndex:2]).aspectRatio);
                    CGFloat h2 = h - h0 - h1 - 2 * spacing;
                    w = MAX(minWidth, MIN(maxSize.width - w0 - spacing, w));
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).layoutFrame = CGRectMake(w0 + spacing, 0.0f, w, h0);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:1]).positionFlags = TGMessageGroupPositionRight | TGMessageGroupPositionTop;
                    
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:2]).layoutFrame = CGRectMake(w0 + spacing, h0 + spacing, w, h1);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:2]).positionFlags = TGMessageGroupPositionRight;
                    
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:3]).layoutFrame = CGRectMake(w0 + spacing, h0 + h1 + 2 * spacing, w, h2);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:3]).positionFlags = TGMessageGroupPositionRight | TGMessageGroupPositionBottom;
                }
            }
        }
        
        if (forceCalc || photos.count >= 5)
        {
            NSMutableArray *croppedRatios = [[NSMutableArray alloc] init];
            for (TGMessagePhotoInfo *photo in photos)
            {
                CGFloat aspectRatio = photo.aspectRatio;
                CGFloat croppedRatio = aspectRatio;
                if (averageAspectRatio > 1.1f)
                    croppedRatio = MAX(1.0f, aspectRatio);
                else
                    croppedRatio = MIN(1.0f, aspectRatio);
                
                croppedRatio = MAX(0.66667f, MIN(2.75f, croppedRatio));
                [croppedRatios addObject:@(croppedRatio)];
            }
            
            NSNumber *(^multiHeight)(NSArray *) = ^NSNumber *(NSArray *ratios)
            {
                CGFloat ratioSum = 0.0f;
                for (NSNumber *ratio in ratios)
                    ratioSum += ratio.floatValue;
                if (ratioSum < FLT_EPSILON)
                    ratioSum = 1.0f;
                return @((maxSize.width - (ratios.count - 1) * spacing) / ratioSum);
            };
 
            NSMutableArray *attempts = [[NSMutableArray alloc] init];
            void (^addAttempt)(NSArray *, NSArray *) = ^(NSArray *lineCounts, NSArray *heights)
            {
                [attempts addObject:[[TGMessageGroupedLayoutAttempt alloc] initWithLineCounts:lineCounts heights:heights]];
            };
            
            NSUInteger firstLine = 0;
            NSUInteger secondLine = 0;
            NSUInteger thirdLine = 0;
            NSUInteger fourthLine = 0;
            
            for (firstLine = 1; firstLine < croppedRatios.count; firstLine++)
            {
                secondLine = croppedRatios.count - firstLine;
                if (firstLine > 3 || secondLine > 3)
                    continue;

                addAttempt(@[@(firstLine), @(croppedRatios.count - firstLine)], @[multiHeight([croppedRatios subarrayWithRange:NSMakeRange(0, firstLine)]), multiHeight([croppedRatios subarrayWithRange:NSMakeRange(firstLine, croppedRatios.count - firstLine)])]);
            }

            for (firstLine = 1; firstLine < croppedRatios.count - 1; firstLine++)
            {
                for (secondLine = 1; secondLine < croppedRatios.count - firstLine; secondLine++)
                {
                    thirdLine = croppedRatios.count - firstLine - secondLine;
                    if (firstLine > 3 || secondLine > (averageAspectRatio < 0.85f ? 4 : 3) || thirdLine > 3)
                        continue;
                    
                    addAttempt(@[@(firstLine), @(secondLine), @(thirdLine)], @[multiHeight([croppedRatios subarrayWithRange:NSMakeRange(0, firstLine)]), multiHeight([croppedRatios subarrayWithRange:NSMakeRange(firstLine, croppedRatios.count - firstLine - thirdLine)]), multiHeight([croppedRatios subarrayWithRange:NSMakeRange(firstLine + secondLine, croppedRatios.count - firstLine - secondLine)])]);
                }
            }
            
            for (firstLine = 1; firstLine < croppedRatios.count - 2; firstLine++)
            {
                for (secondLine = 1; secondLine < croppedRatios.count - firstLine; secondLine++)
                {
                    for (thirdLine = 1; thirdLine < croppedRatios.count - firstLine - secondLine; thirdLine++)
                    {
                        fourthLine = croppedRatios.count - firstLine - secondLine - thirdLine;
                        if (firstLine > 3 || secondLine > 3 || thirdLine > 3 || fourthLine > 3)
                            continue;
                        
                        addAttempt(@[@(firstLine), @(secondLine), @(thirdLine), @(fourthLine)], @[multiHeight([croppedRatios subarrayWithRange:NSMakeRange(0, firstLine)]), multiHeight([croppedRatios subarrayWithRange:NSMakeRange(firstLine, croppedRatios.count - firstLine - thirdLine - fourthLine)]), multiHeight([croppedRatios subarrayWithRange:NSMakeRange(firstLine + secondLine, croppedRatios.count - firstLine - secondLine - fourthLine)]), multiHeight([croppedRatios subarrayWithRange:NSMakeRange(firstLine + secondLine + thirdLine, croppedRatios.count - firstLine - secondLine - thirdLine)])]);
                    }
                }
            }

            CGFloat maxHeight = maxSize.width / 3 * 4;
            TGMessageGroupedLayoutAttempt *optimal = nil;
            CGFloat optimalDiff = 0.0f;
            for (TGMessageGroupedLayoutAttempt *attempt in attempts)
            {
                CGFloat totalHeight = spacing * (attempt.heights.count - 1);
                CGFloat minLineHeight = FLT_MAX;
                CGFloat maxLineHeight = 0.0f;
                for (NSNumber *h in attempt.heights)
                {
                    CGFloat lineHeight = h.floatValue;
                    totalHeight += lineHeight;
                    if (lineHeight < minLineHeight)
                        minLineHeight = lineHeight;
                    if (lineHeight > maxLineHeight)
                        maxLineHeight = lineHeight;
                }
                
                CGFloat diff = fabs(totalHeight - maxHeight);
                
                if (attempt.lineCounts.count > 1)
                {
                    if (([(NSNumber *)[attempt.lineCounts objectAtIndex:0] integerValue] > [(NSNumber *)[attempt.lineCounts objectAtIndex:1] integerValue]) || (attempt.lineCounts.count > 2 && [(NSNumber *)[attempt.lineCounts objectAtIndex:1] integerValue] > [(NSNumber *)[attempt.lineCounts objectAtIndex:2] integerValue]) || (attempt.lineCounts.count > 3 && [(NSNumber *)[attempt.lineCounts objectAtIndex:2] integerValue] > [(NSNumber *)[attempt.lineCounts objectAtIndex:3] integerValue]))
                    {
                        diff *= 1.5f;
                    }
                }
                
                if (minLineHeight < minWidth)
                    diff *= 1.5f;
                
                if (optimal == nil || diff < optimalDiff)
                {
                    optimal = attempt;
                    optimalDiff = diff;
                }
            }
            
            NSInteger index = 0;
            CGFloat y = 0.0f;
            for (NSUInteger i = 0; i < optimal.lineCounts.count; i++)
            {
                NSInteger count = [(NSNumber *)[optimal.lineCounts objectAtIndex:i] integerValue];
                CGFloat lineHeight = [(NSNumber *)[optimal.heights objectAtIndex:i] floatValue];
                CGFloat x = 0.0f;
                
                TGMessageGroupPositionFlags positionFlags = TGMessageGroupPositionNone;
                if (i == 0)
                    positionFlags |= TGMessageGroupPositionTop;
                if (i == optimal.lineCounts.count - 1)
                    positionFlags |= TGMessageGroupPositionBottom;
                
                for (NSInteger k = 0; k < count; k++)
                {
                    TGMessageGroupPositionFlags innerPositionFlags = positionFlags;
                    
                    if (k == 0)
                        innerPositionFlags |= TGMessageGroupPositionLeft;
                    if (k == count - 1)
                        innerPositionFlags |= TGMessageGroupPositionRight;
                    
                    if (positionFlags == TGMessageGroupPositionNone)
                        innerPositionFlags = TGMessageGroupPositionInside;
                    
                    CGFloat ratio = [(NSNumber *)[croppedRatios objectAtIndex:index] floatValue];
                    CGFloat width = ratio * lineHeight;
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:index]).layoutFrame = CGRectMake(x, y, width, lineHeight);
                    ((TGMessagePhotoInfo *)[photos objectAtIndex:index]).positionFlags = innerPositionFlags;
                    
                    x += width + spacing;
                    index++;
                }
                
                y += lineHeight + spacing;
            }
        }
        
        CGSize dimensions = CGSizeZero;
        _layouts = [[NSMutableDictionary alloc] init];
        for (TGMessagePhotoInfo *photo in photos)
        {
            _layouts[@(photo.mid)] = photo;

            if ((photo.positionFlags & TGMessageGroupPositionTop) && (photo.positionFlags & TGMessageGroupPositionLeft))
                _mainMessageId = photo.mid;
            
            if (CGRectGetMaxX(photo.layoutFrame) > dimensions.width)
                dimensions.width = CGRectGetMaxX(photo.layoutFrame);
            if (CGRectGetMaxY(photo.layoutFrame) > dimensions.height)
                dimensions.height = CGRectGetMaxY(photo.layoutFrame);
        }
        _dimensions = dimensions;

        TGMessage *reactionMessage = nil;
        for (TGMessage *message in messages)
        {
            id value = [message.contentProperties objectForKey:@"ios6ReactionSummary"];
            NSString *summary = nil;
            if ([value isKindOfClass:[TGMessageReactionSummaryContentProperty class]])
                summary = ((TGMessageReactionSummaryContentProperty *)value).summary;
            else if ([value isKindOfClass:[NSString class]])
                summary = value;

            if (summary.length != 0 && (reactionMessage == nil || message.mid == _mainMessageId))
                reactionMessage = message;
            if (message.mid == _mainMessageId && summary.length != 0)
                break;
        }

        id reactionValue = [reactionMessage.contentProperties objectForKey:@"ios6ReactionSummary"];
        if ([reactionValue isKindOfClass:[TGMessageReactionSummaryContentProperty class]])
        {
            _reactionSummary = [((TGMessageReactionSummaryContentProperty *)reactionValue).summary copy];
            _chosenReaction = [((TGMessageReactionSummaryContentProperty *)reactionValue).chosenReaction copy];
        }
        else if ([reactionValue isKindOfClass:[NSString class]])
        {
            _reactionSummary = [reactionValue copy];
        }
    }
    return self;
}

- (NSUInteger)count
{
    return _layouts.count;
}

- (CGRect)frameForMessageId:(int32_t)messageId
{
    TGMessagePhotoInfo *info = _layouts[@(messageId)];
    if (info != nil)
        return info.layoutFrame;
    
    return CGRectNull;
}

- (TGMessageGroupPositionFlags)positionForMessageId:(int32_t)messageId
{
    TGMessagePhotoInfo *info = _layouts[@(messageId)];
    if (info != nil)
        return info.positionFlags;
    
    return 0;
}

- (int32_t)messageIdForPosition:(TGMessageGroupPositionFlags)position
{
    for (TGMessagePhotoInfo *info in [_layouts allValues])
    {
        if (info.positionFlags == position)
            return info.mid;
    }
    return 0;
}

- (void)enumerateMessageFrames:(void (^)(int32_t, CGRect))enumerationBlock
{
    if (enumerationBlock == nil)
        return;
    
    for (TGMessagePhotoInfo *info in [_layouts allValues])
    {
        enumerationBlock(info.mid, info.layoutFrame);
    }
}

- (TGMessageGroupedLayout *)groupedLayoutAfterMessageUpdate:(TGMessage *)message previousMessage:(TGMessage *)previousMessage
{
    TGMessageGroupedLayout *groupedLayout = [[TGMessageGroupedLayout alloc] init];
    NSMutableDictionary *newLayouts = [_layouts mutableCopy];
    groupedLayout->_layouts = newLayouts;
    groupedLayout->_dimensions = _dimensions;
    groupedLayout->_mainMessageId = _mainMessageId;
    groupedLayout->_caption = [_caption copy];
    groupedLayout->_captionTextCheckingResults = [_captionTextCheckingResults copy];
    groupedLayout->_captionMessageId = _captionMessageId;
    groupedLayout->_reactionSummary = [_reactionSummary copy];
    groupedLayout->_chosenReaction = [_chosenReaction copy];
    
    TGMessagePhotoInfo *info = newLayouts[@(previousMessage.mid)];
    if (info != nil)
    {
        newLayouts[@(message.mid)] = info;
        [newLayouts removeObjectForKey:@(previousMessage.mid)];
        if (groupedLayout->_mainMessageId == previousMessage.mid)
            groupedLayout->_mainMessageId = message.mid;
    }

    if (previousMessage.mid == _captionMessageId || message.caption.length != 0)
    {
        groupedLayout->_caption = [message.caption copy];
        groupedLayout->_captionTextCheckingResults = [message.textCheckingResults copy];
        groupedLayout->_captionMessageId = message.caption.length == 0 ? 0 : message.mid;
    }

    return groupedLayout;
}

- (void)updateReactionSummary:(NSString *)reactionSummary chosenReaction:(NSString *)chosenReaction messageId:(int32_t)messageId
{
    if (messageId != _mainMessageId)
        return;

    _reactionSummary = [reactionSummary copy];
    _chosenReaction = [chosenReaction copy];
}

@end


@implementation TGMessagePhotoInfo

- (instancetype)initWithMessage:(TGMessage *)message
{
    self = [super init];
    if (self != nil)
    {
        _mid = message.mid;
        
        TGImageMediaAttachment *imageAttachment = nil;
        TGVideoMediaAttachment *videoAttachment = nil;
        
        for (TGMediaAttachment *attachment in message.mediaAttachments)
        {
            if (attachment.type == TGImageMediaAttachmentType)
            {
                imageAttachment = (TGImageMediaAttachment *)attachment;
                break;
            }
            else if (attachment.type == TGVideoMediaAttachmentType)
            {
                videoAttachment = (TGVideoMediaAttachment *)attachment;
                break;
            }
        }
        
        if (imageAttachment != nil)
        {
            CGSize dimensions = CGSizeZero;
            [imageAttachment.imageInfo closestImageUrlWithSize:CGSizeMake(1136, 1136) resultingSize:&dimensions pickLargest:true];
            if (dimensions.width <= 90.0f + FLT_EPSILON || dimensions.height <= 90.0f + FLT_EPSILON)
                [imageAttachment.imageInfo imageUrlForSizeLargerThanSize:CGSizeMake(1000.0f, 1000.0f) actualSize:&dimensions];
            
            _imageSize = dimensions;
            _aspectRatio = _imageSize.height > 0 ? _imageSize.width / _imageSize.height : 1.0f;
        }
        else if (videoAttachment != nil)
        {
            _imageSize = videoAttachment.dimensions;
            _aspectRatio = _imageSize.height > 0 ? _imageSize.width / _imageSize.height : 1.0f;
        }
        else
        {
            return nil;
        }
    }
    return self;
}

@end


@implementation TGMessageGroupedLayoutAttempt

- (instancetype)initWithLineCounts:(NSArray *)lineCounts heights:(NSArray *)heights
{
    self = [super init];
    if (self != nil)
    {
        _lineCounts = lineCounts;
        _heights = heights;
    }
    return self;
}

@end
