#import "TGMessage+Telegraph.h"

#ifndef IOS6_NOOP_LOG
#define IOS6_NOOP_LOG(...) do { } while (0)
#endif

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGSchema.h"
#import "TLUser$modernUser.h"

#import "TGTelegraph.h"

#import "TGImageMediaAttachment+Telegraph.h"
#import "TGActionMediaAttachment+Telegraph.h"
#import "TGContactMediaAttachment+Telegraph.h"
#import "TGDocumentMediaAttachment+Telegraph.h"
#import "TGAudioMediaAttachment+Telegraph.h"
#import "TGWebPageMediaAttachment+Telegraph.h"
#import "TGImageInfo+Telegraph.h"
#import "TGWebDocument+Telegraph.h"
#import "TGMediaOriginInfo+Telegraph.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGRemoteImageView.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGMessageViewCountContentProperty.h"

#import "TLMessage$modernMessage.h"
#import "TLMessage$modernMessageService.h"

#import "TGDatabase.h"

#import "TGMessageViewedContentProperty.h"

#import "TGBotSignals.h"

#import <float.h>

#import "TLMessageFwdHeader$messageFwdHeader.h"
#import "TLMessageMedia$messageMediaPhoto.h"
#import "TLMessageMedia$messageMediaDocument.h"

@implementation TLMessage$modernMessage (IOS6PtsCompat)

- (int32_t)pts
{
    return 0;
}

- (void)setPts:(int32_t)__unused pts
{
}

- (int32_t)pts_count
{
    return 0;
}

- (void)setPts_count:(int32_t)__unused pts_count
{
}

- (int32_t)seq
{
    return 0;
}

- (void)setSeq:(int32_t)__unused seq
{
}

- (int32_t)qts
{
    return 0;
}

- (void)setQts:(int32_t)__unused qts
{
}

@end

@implementation TLMessage$modernMessageService (IOS6PtsCompat)

- (int32_t)pts
{
    return 0;
}

- (void)setPts:(int32_t)__unused pts
{
}

- (int32_t)pts_count
{
    return 0;
}

- (void)setPts_count:(int32_t)__unused pts_count
{
}

- (int32_t)seq
{
    return 0;
}

- (void)setSeq:(int32_t)__unused seq
{
}

- (int32_t)qts
{
    return 0;
}

- (void)setQts:(int32_t)__unused qts
{
}

@end

static bool TGIOS6ShouldRepairRoundVideoDocument(int32_t duration, CGSize dimensions, NSString *caption, bool hasStickers, NSString *mimeType)
{
    if (![mimeType hasPrefix:@"video/"] || hasStickers || caption.length != 0)
        return false;
    
    if (duration < 0 || duration > 60)
        return false;
    
    if (dimensions.width < 120.0f || dimensions.height < 120.0f)
        return false;
    
    CGFloat diff = dimensions.width > dimensions.height ? dimensions.width - dimensions.height : dimensions.height - dimensions.width;
    CGFloat maxSide = MAX(dimensions.width, dimensions.height);
    return maxSide > FLT_EPSILON && diff / maxSide < 0.08f;
}

static bool TGIOS6ShouldTreatVideoDocumentAsGifLike(int32_t duration, CGSize dimensions, NSString *caption, bool hasStickers, NSString *mimeType, NSString *fileName)
{
    NSString *lowerFileName = [fileName lowercaseString];
    if ([mimeType isEqualToString:@"image/gif"] || [lowerFileName.pathExtension isEqualToString:@"gif"] || ([mimeType isEqualToString:@"video/mp4"] && [lowerFileName isEqualToString:@"animation.mp4"]))
        return true;
    
    if (![mimeType isEqualToString:@"video/mp4"] || hasStickers || caption.length != 0)
        return false;
    
    if (duration <= 0 || duration > 15)
        return false;
    
    CGFloat maxSide = MAX(dimensions.width, dimensions.height);
    return maxSide <= 640.0f;
}

static bool TGIOS6ShouldTreatSmallMp4DocumentAsGifLike(TGDocumentMediaAttachment *documentAttachment, TGAudioMediaAttachment *audioMedia, bool isSticker)
{
    if (![documentAttachment.mimeType isEqualToString:@"video/mp4"] || audioMedia != nil || isSticker)
        return false;
    
    return documentAttachment.size > 0 && documentAttachment.size <= 512 * 1024;
}

@implementation TGMessage (Telegraph)

+ (NSArray *)parseTelegraphMedia:(id)media mediaLifetime:(int32_t *)mediaLifetime cid:(int64_t)cid mid:(int32_t)mid
{
    NSMutableArray *mediaAttachments = [[NSMutableArray alloc] init];
    
    if ([media isKindOfClass:[TLMessageMedia$messageMediaPhoto class]])
    {
        TLMessageMedia$messageMediaPhoto *mediaPhoto = (TLMessageMedia$messageMediaPhoto *)media;
    
        TGMediaOriginInfo *origin = [TGMediaOriginInfo mediaOriginInfoForPhoto:mediaPhoto.photo cid:cid mid:mid];
        
        TGImageMediaAttachment *imageMediaAttachment = [[TGImageMediaAttachment alloc] initWithTelegraphDesc:mediaPhoto.photo];
        imageMediaAttachment.originInfo = origin;
        [mediaAttachments addObject:imageMediaAttachment];
        IOS6_NOOP_LOG(@"IOS6TRACE media photo cid=%lld mid=%d imageId=%lld hasOrigin=%d", cid, mid, imageMediaAttachment.imageId, origin != nil ? 1 : 0);
        
        if (mediaLifetime != nil) {
           *mediaLifetime = mediaPhoto.ttl_seconds;
        }
    }
    else if ([media isKindOfClass:[TLMessageMedia$messageMediaContact class]])
    {
        TLMessageMedia$messageMediaContact *mediaContact = (TLMessageMedia$messageMediaContact *)media;
        
        TGContactMediaAttachment *contactAttachment = [[TGContactMediaAttachment alloc] initWithTelegraphContactDesc:mediaContact];
        
        [mediaAttachments addObject:contactAttachment];
    }
    else if ([media isKindOfClass:[TLMessageMedia$messageMediaGeo class]])
    {
        TLMessageMedia$messageMediaGeo *mediaGeo = (TLMessageMedia$messageMediaGeo *)media;
        
        if ([mediaGeo.geo isKindOfClass:[TLGeoPoint$geoPoint class]])
        {
            TLGeoPoint$geoPoint *concreteGeo = (TLGeoPoint$geoPoint *)mediaGeo.geo;
            
            TGLocationMediaAttachment *locationMediaAttachment = [[TGLocationMediaAttachment alloc] init];
            locationMediaAttachment.latitude = concreteGeo.lat;
            locationMediaAttachment.longitude = concreteGeo.n_long;
            
            [mediaAttachments addObject:locationMediaAttachment];
        }
        else if ([mediaGeo.geo isKindOfClass:[TLGeoPoint$geoPlace class]])
        {
            TLGeoPoint$geoPlace *concreteGeo = (TLGeoPoint$geoPlace *)mediaGeo.geo;
            
            TGLocationMediaAttachment *locationMediaAttachment = [[TGLocationMediaAttachment alloc] init];
            locationMediaAttachment.latitude = concreteGeo.lat;
            locationMediaAttachment.longitude = concreteGeo.n_long;
            
            [mediaAttachments addObject:locationMediaAttachment];
        }
    }
    else if ([media isKindOfClass:[TLMessageMedia$messageMediaGeoLive class]])
    {
        TLMessageMedia$messageMediaGeoLive *mediaGeoLive = (TLMessageMedia$messageMediaGeoLive *)media;
        TGLocationMediaAttachment *locationMediaAttachment = [[TGLocationMediaAttachment alloc] init];
        [mediaAttachments addObject:locationMediaAttachment];
        
        if ([mediaGeoLive.geo isKindOfClass:[TLGeoPoint$geoPoint class]])
        {
            TLGeoPoint$geoPoint *concreteGeo = (TLGeoPoint$geoPoint *)mediaGeoLive.geo;
            
            locationMediaAttachment.latitude = concreteGeo.lat;
            locationMediaAttachment.longitude = concreteGeo.n_long;
        }
        else if ([mediaGeoLive.geo isKindOfClass:[TLGeoPoint$geoPlace class]])
        {
            TLGeoPoint$geoPlace *concreteGeo = (TLGeoPoint$geoPlace *)mediaGeoLive.geo;
            
            locationMediaAttachment.latitude = concreteGeo.lat;
            locationMediaAttachment.longitude = concreteGeo.n_long;
        }
        
        locationMediaAttachment.period = mediaGeoLive.period;
    }
    else if ([media isKindOfClass:[TLMessageMedia$messageMediaVenue class]])
    {
        TLMessageMedia$messageMediaVenue *mediaVenue = (TLMessageMedia$messageMediaVenue *)media;
        TGLocationMediaAttachment *locationMediaAttachment = [[TGLocationMediaAttachment alloc] init];
        [mediaAttachments addObject:locationMediaAttachment];
        
        if ([mediaVenue.geo isKindOfClass:[TLGeoPoint$geoPoint class]])
        {
            TLGeoPoint$geoPoint *concreteGeo = (TLGeoPoint$geoPoint *)mediaVenue.geo;
            
            locationMediaAttachment.latitude = concreteGeo.lat;
            locationMediaAttachment.longitude = concreteGeo.n_long;
        }
        else if ([mediaVenue.geo isKindOfClass:[TLGeoPoint$geoPlace class]])
        {
            TLGeoPoint$geoPlace *concreteGeo = (TLGeoPoint$geoPlace *)mediaVenue.geo;
            
            locationMediaAttachment.latitude = concreteGeo.lat;
            locationMediaAttachment.longitude = concreteGeo.n_long;
        }
        
        locationMediaAttachment.venue = [[TGVenueAttachment alloc] initWithTitle:mediaVenue.title address:mediaVenue.address provider:mediaVenue.provider venueId:mediaVenue.venue_id type:mediaVenue.venue_type];
    }
    else if ([media isKindOfClass:[TLMessageMedia$messageMediaUnsupported class]])
    {
        TGUnsupportedMediaAttachment *unsupportedAttachment = [[TGUnsupportedMediaAttachment alloc] init];
        [mediaAttachments addObject:unsupportedAttachment];
        IOS6_NOOP_LOG(@"IOS6TRACE media unsupported cid=%lld mid=%d class=%@", cid, mid, NSStringFromClass([media class]));
    }
    else if ([media isKindOfClass:[TLMessageMedia$messageMediaDocument class]])
    {
        TLMessageMedia$messageMediaDocument *documentMedia = (TLMessageMedia$messageMediaDocument *)media;
        TGDocumentMediaAttachment *documentAttachment = [[TGDocumentMediaAttachment alloc] initWithTelegraphDocumentDesc:documentMedia.document];
        
        TGMediaOriginInfo *origin = [TGMediaOriginInfo mediaOriginInfoForDocument:documentMedia.document cid:cid mid:mid];
        documentAttachment.originInfo = origin;
        
        int32_t videoTTLSeconds = documentMedia.ttl_seconds;
        
        bool isAnimated = false;
        bool isSticker = false;
        TGAudioMediaAttachment *audioMedia = nil;
        TGVideoMediaAttachment *videoMedia = nil;
        for (id attribute in documentAttachment.attributes) {
            if ([attribute isKindOfClass:[TGDocumentAttributeVideo class]]) {
                TGDocumentAttributeVideo *video = attribute;
                
                videoMedia = [[TGVideoMediaAttachment alloc] init];
                videoMedia.videoId = documentAttachment.documentId;
                videoMedia.accessHash = documentAttachment.accessHash;
                videoMedia.duration = video.duration;
                videoMedia.dimensions = video.size;
                videoMedia.thumbnailInfo = documentAttachment.thumbnailInfo;
                videoMedia.roundMessage = video.isRoundMessage;
                videoMedia.originInfo = origin;
                
                for (id additionalAttribute in documentAttachment.attributes) {
                    if ([additionalAttribute isKindOfClass:[TLDocumentAttribute$documentAttributeHasStickers class]]) {
                        videoMedia.hasStickers = true;
                        break;
                    }
                }
                if (!videoMedia.roundMessage && TGIOS6ShouldRepairRoundVideoDocument(videoMedia.duration, videoMedia.dimensions, videoMedia.caption, videoMedia.hasStickers, documentAttachment.mimeType))
                {
                    videoMedia.roundMessage = true;
                    IOS6_NOOP_LOG(@"IOS6MEDIA roundRepair document cid=%lld mid=%d id=%lld duration=%d dims=%.0fx%.0f mime=%@", cid, mid, videoMedia.videoId, videoMedia.duration, videoMedia.dimensions.width, videoMedia.dimensions.height, documentAttachment.mimeType);
                }
                
                TGVideoInfo *videoInfo = [[TGVideoInfo alloc] init];
                [videoInfo addVideoWithQuality:1 url:[[NSString alloc] initWithFormat:@"video:%lld:%lld:%d:%d", videoMedia.videoId, videoMedia.accessHash, documentAttachment.datacenterId, documentAttachment.size] size:documentAttachment.size];
                videoMedia.videoInfo = videoInfo;
                IOS6_NOOP_LOG(@"IOS6MEDIA document promoted to video id=%lld dc=%d size=%d duration=%d dims=%.0fx%.0f round=%d mime=%@", videoMedia.videoId, documentAttachment.datacenterId, documentAttachment.size, videoMedia.duration, videoMedia.dimensions.width, videoMedia.dimensions.height, videoMedia.roundMessage ? 1 : 0, documentAttachment.mimeType);
            } else if ([attribute isKindOfClass:[TGDocumentAttributeAudio class]]) {
                TGDocumentAttributeAudio *audio = (TGDocumentAttributeAudio *)attribute;
                
                if (audio.isVoice) {
                    audioMedia = [[TGAudioMediaAttachment alloc] init];
                    audioMedia.audioId = documentAttachment.documentId;
                    audioMedia.accessHash = documentAttachment.accessHash;
                    audioMedia.datacenterId = documentAttachment.datacenterId;
                    audioMedia.duration = audio.duration;
                    audioMedia.fileSize = documentAttachment.size;
                    audioMedia.ios6OriginInfo = origin;
                    IOS6_NOOP_LOG(@"IOS6MEDIA document promoted to voice audio id=%lld dc=%d size=%d duration=%d mime=%@", audioMedia.audioId, audioMedia.datacenterId, audioMedia.fileSize, audioMedia.duration, documentAttachment.mimeType);
                } else {
                    IOS6_NOOP_LOG(@"IOS6MEDIA document kept as music id=%lld dc=%d size=%d duration=%d mime=%@", documentAttachment.documentId, documentAttachment.datacenterId, documentAttachment.size, audio.duration, documentAttachment.mimeType);
                }
            } else if ([attribute isKindOfClass:[TGDocumentAttributeAnimated class]]) {
                isAnimated = true;
            } else if ([attribute isKindOfClass:[TGDocumentAttributeSticker class]]) {
                isSticker = true;
            }
        }
        
        if (isSticker) {
            [mediaAttachments addObject:documentAttachment];
            IOS6_NOOP_LOG(@"IOS6STICKER document kept as sticker cid=%lld mid=%d id=%lld mime=%@ animated=%d attrs=%d", cid, mid, documentAttachment.documentId, documentAttachment.mimeType, isAnimated ? 1 : 0, (int)documentAttachment.attributes.count);
            if (mediaLifetime != nil)
                *mediaLifetime = videoTTLSeconds;
            return mediaAttachments;
        }
        
        if (videoMedia == nil && TGIOS6ShouldTreatSmallMp4DocumentAsGifLike(documentAttachment, audioMedia, isSticker)) {
            CGSize fallbackDimensions = CGSizeZero;
            if (documentAttachment.thumbnailInfo != nil)
                [documentAttachment.thumbnailInfo closestImageUrlWithSize:CGSizeZero resultingSize:&fallbackDimensions];
            if (fallbackDimensions.width < 1.0f || fallbackDimensions.height < 1.0f)
                fallbackDimensions = CGSizeMake(320.0f, 240.0f);
            
            videoMedia = [[TGVideoMediaAttachment alloc] init];
            videoMedia.videoId = documentAttachment.documentId;
            videoMedia.accessHash = documentAttachment.accessHash;
            videoMedia.duration = 0;
            videoMedia.dimensions = fallbackDimensions;
            videoMedia.thumbnailInfo = documentAttachment.thumbnailInfo;
            videoMedia.roundMessage = false;
            videoMedia.originInfo = origin;
            
            TGVideoInfo *videoInfo = [[TGVideoInfo alloc] init];
            [videoInfo addVideoWithQuality:1 url:[[NSString alloc] initWithFormat:@"video:%lld:%lld:%d:%d", videoMedia.videoId, videoMedia.accessHash, documentAttachment.datacenterId, documentAttachment.size] size:documentAttachment.size];
            videoMedia.videoInfo = videoInfo;
            IOS6_NOOP_LOG(@"IOS6MEDIA smallMp4GifLike document cid=%lld mid=%d id=%lld size=%d dims=%.0fx%.0f mime=%@", cid, mid, videoMedia.videoId, documentAttachment.size, videoMedia.dimensions.width, videoMedia.dimensions.height, documentAttachment.mimeType);
        }
        
        NSString *safeFileName = [documentAttachment safeFileName];
        NSString *lowerSafeFileName = [safeFileName lowercaseString];
        bool isGifFile = [documentAttachment.mimeType isEqualToString:@"image/gif"] || [lowerSafeFileName.pathExtension isEqualToString:@"gif"];
        bool isSmallGifLikeMp4 = TGIOS6ShouldTreatSmallMp4DocumentAsGifLike(documentAttachment, audioMedia, isSticker);
        bool isGifLikeMp4 = [documentAttachment.mimeType isEqualToString:@"video/mp4"] && (isSmallGifLikeMp4 || isAnimated || [lowerSafeFileName isEqualToString:@"animation.mp4"] || (videoMedia != nil && TGIOS6ShouldTreatVideoDocumentAsGifLike(videoMedia.duration, videoMedia.dimensions, nil, videoMedia.hasStickers, documentAttachment.mimeType, safeFileName)));
        if (isGifFile)
        {
            isAnimated = true;
        }
        else if (videoMedia != nil && isGifLikeMp4)
        {
            if (!videoMedia.roundMessage)
            {
                videoMedia.roundMessage = true;
                IOS6_NOOP_LOG(@"IOS6MEDIA gifLikeRound document cid=%lld mid=%d id=%lld duration=%d dims=%.0fx%.0f mime=%@ file=%@", cid, mid, videoMedia.videoId, videoMedia.duration, videoMedia.dimensions.width, videoMedia.dimensions.height, documentAttachment.mimeType, safeFileName);
            }
            isAnimated = false;
        }
        
        if (videoTTLSeconds > 0 && videoTTLSeconds <= 60) {
            isAnimated = false;
        }

        if (videoMedia == nil && [documentAttachment.mimeType hasPrefix:@"video/"]) {
            CGSize fallbackDimensions = CGSizeZero;
            if (documentAttachment.thumbnailInfo != nil)
                [documentAttachment.thumbnailInfo closestImageUrlWithSize:CGSizeZero resultingSize:&fallbackDimensions];
            if (fallbackDimensions.width < 1.0f || fallbackDimensions.height < 1.0f)
                fallbackDimensions = CGSizeMake(320.0f, 240.0f);
            
            videoMedia = [[TGVideoMediaAttachment alloc] init];
            videoMedia.videoId = documentAttachment.documentId;
            videoMedia.accessHash = documentAttachment.accessHash;
            videoMedia.duration = 0;
            videoMedia.dimensions = fallbackDimensions;
            videoMedia.thumbnailInfo = documentAttachment.thumbnailInfo;
            videoMedia.roundMessage = false;
            videoMedia.originInfo = origin;
            
            TGVideoInfo *videoInfo = [[TGVideoInfo alloc] init];
            [videoInfo addVideoWithQuality:1 url:[[NSString alloc] initWithFormat:@"video:%lld:%lld:%d:%d", videoMedia.videoId, videoMedia.accessHash, documentAttachment.datacenterId, documentAttachment.size] size:documentAttachment.size];
            videoMedia.videoInfo = videoInfo;
            IOS6_NOOP_LOG(@"IOS6MEDIA document mime promoted to video id=%lld dc=%d size=%d dims=%.0fx%.0f mime=%@", videoMedia.videoId, documentAttachment.datacenterId, documentAttachment.size, videoMedia.dimensions.width, videoMedia.dimensions.height, documentAttachment.mimeType);
        }
        
        if (videoMedia != nil && !isAnimated) {
            [mediaAttachments addObject:videoMedia];
            IOS6_NOOP_LOG(@"IOS6TRACE media result cid=%lld mid=%d type=video videoId=%lld size=%d mime=%@ animated=%d", cid, mid, videoMedia.videoId, documentAttachment.size, documentAttachment.mimeType, isAnimated ? 1 : 0);
        } else if (audioMedia != nil && !isAnimated && !isSticker) {
            [mediaAttachments addObject:audioMedia];
            IOS6_NOOP_LOG(@"IOS6TRACE media result cid=%lld mid=%d type=audio audioId=%lld size=%d mime=%@", cid, mid, audioMedia.audioId, audioMedia.fileSize, documentAttachment.mimeType);
        } else {
            if (videoMedia != nil && isAnimated)
                IOS6_NOOP_LOG(@"IOS6MEDIA document kept as animated document id=%lld mime=%@", documentAttachment.documentId, documentAttachment.mimeType);
            else
                IOS6_NOOP_LOG(@"IOS6MEDIA document kept as file id=%lld dc=%d size=%d attrs=%d mime=%@", documentAttachment.documentId, documentAttachment.datacenterId, documentAttachment.size, (int)documentAttachment.attributes.count, documentAttachment.mimeType);
            [mediaAttachments addObject:documentAttachment];
            IOS6_NOOP_LOG(@"IOS6TRACE media result cid=%lld mid=%d type=document docId=%lld size=%d mime=%@ animated=%d", cid, mid, documentAttachment.documentId, documentAttachment.size, documentAttachment.mimeType, isAnimated ? 1 : 0);
        }
        
        if (mediaLifetime != nil) {
           *mediaLifetime = videoTTLSeconds;
        }
    }
    else if ([media isKindOfClass:[TLMessageMedia$messageMediaWebPage class]])
    {
        TGWebPageMediaAttachment *webPage = [[TGWebPageMediaAttachment alloc] initWithTelegraphWebPageDesc:((TLMessageMedia$messageMediaWebPage *)media).webpage];        
        [mediaAttachments addObject:webPage];
        IOS6_NOOP_LOG(@"IOS6TRACE media webpage cid=%lld mid=%d class=%@", cid, mid, NSStringFromClass([media class]));
    } else if ([media isKindOfClass:[TLMessageMedia$messageMediaGame class]]) {
        TLMessageMedia$messageMediaGame *gameDesc = ((TLMessageMedia$messageMediaGame *)media);
        
        TGImageMediaAttachment *image = nil;
        if (gameDesc.game.photo != nil) {
            image = [[TGImageMediaAttachment alloc] initWithTelegraphDesc:gameDesc.game.photo];
            image.originInfo = [TGMediaOriginInfo mediaOriginInfoForPhoto:gameDesc.game.photo cid:cid mid:mid];
        }
        
        TGDocumentMediaAttachment *document = nil;
        if (gameDesc.game.document != nil) {
            document = [[TGDocumentMediaAttachment alloc] initWithTelegraphDocumentDesc:gameDesc.game.document];
            document.originInfo = [TGMediaOriginInfo mediaOriginInfoForDocument:gameDesc.game.document cid:cid mid:mid];
        }
        
        TGGameMediaAttachment *gameMedia = [[TGGameMediaAttachment alloc] initWithGameId:gameDesc.game.n_id accessHash:gameDesc.game.access_hash shortName:gameDesc.game.short_name title:gameDesc.game.title gameDescription:gameDesc.game.n_description photo:image document:document];
        [mediaAttachments addObject:gameMedia];
    } else if ([media isKindOfClass:[TLMessageMedia$messageMediaInvoiceMeta class]]) {
        TLMessageMedia$messageMediaInvoiceMeta *invoiceDesc = (TLMessageMedia$messageMediaInvoiceMeta *)media;
        
        TGWebDocument *photo = nil;
        if (invoiceDesc.photo != nil) {
            photo = [[TGWebDocument alloc] initWithTL:invoiceDesc.photo];
        }
        
        TGInvoiceMediaAttachment *invoice = [[TGInvoiceMediaAttachment alloc] initWithTitle:invoiceDesc.title text:invoiceDesc.n_description photo:photo currency:invoiceDesc.currency totalAmount:invoiceDesc.total_amount receiptMessageId:invoiceDesc.receipt_msg_id invoiceStartParam:invoiceDesc.start_param shippingAddressRequested:invoiceDesc.flags & (1 << 1) isTest:invoiceDesc.flags & (1 << 3)];
        [mediaAttachments addObject:invoice];
    }
    
    return mediaAttachments;
}

+ (NSArray *)parseTelegraphEntities:(NSArray *)entities {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    for (id entity in entities)
    {
        if ([entity isKindOfClass:[TLMessageEntity$messageEntityMention class]]) {
            TLMessageEntity$messageEntityMention *mentionEntity = entity;
            [result addObject:[[TGMessageEntityMention alloc] initWithRange:NSMakeRange(mentionEntity.offset, mentionEntity.length)]];
        } else if ([entity isKindOfClass:[TLMessageEntity$messageEntityHashtag class]]) {
            TLMessageEntity$messageEntityHashtag *hashtagEntity = entity;
            [result addObject:[[TGMessageEntityHashtag alloc] initWithRange:NSMakeRange(hashtagEntity.offset, hashtagEntity.length)]];
        } else if ([entity isKindOfClass:[TLMessageEntity$messageEntityBotCommand class]]) {
            TLMessageEntity$messageEntityBotCommand *botCommandEntity = entity;
            [result addObject:[[TGMessageEntityBotCommand alloc] initWithRange:NSMakeRange(botCommandEntity.offset, botCommandEntity.length)]];
        } else if ([entity isKindOfClass:[TLMessageEntity$messageEntityUrl class]]) {
            TLMessageEntity$messageEntityUrl *urlEntity = entity;
            [result addObject:[[TGMessageEntityUrl alloc] initWithRange:NSMakeRange(urlEntity.offset, urlEntity.length)]];
        } else if ([entity isKindOfClass:[TLMessageEntity$messageEntityTextUrl class]]) {
            TLMessageEntity$messageEntityTextUrl *urlEntity = entity;
            [result addObject:[[TGMessageEntityTextUrl alloc] initWithRange:NSMakeRange(urlEntity.offset, urlEntity.length) url:urlEntity.url]];
        } else if ([entity isKindOfClass:[TLMessageEntity$messageEntityEmail class]]) {
            TLMessageEntity$messageEntityEmail *emailEntity = entity;
            [result addObject:[[TGMessageEntityEmail alloc] initWithRange:NSMakeRange(emailEntity.offset, emailEntity.length)]];
        } else if ([entity isKindOfClass:[TLMessageEntity$messageEntityBold class]]) {
            TLMessageEntity$messageEntityBold *boldEntity = entity;
            [result addObject:[[TGMessageEntityBold alloc] initWithRange:NSMakeRange(boldEntity.offset, boldEntity.length)]];
        } else if ([entity isKindOfClass:[TLMessageEntity$messageEntityItalic class]]) {
            TLMessageEntity$messageEntityItalic *italicEntity = entity;
            [result addObject:[[TGMessageEntityItalic alloc] initWithRange:NSMakeRange(italicEntity.offset, italicEntity.length)]];
        } else if ([entity isKindOfClass:[TLMessageEntity$messageEntityCode class]]) {
            TLMessageEntity$messageEntityCode *codeEntity = entity;
            [result addObject:[[TGMessageEntityCode alloc] initWithRange:NSMakeRange(codeEntity.offset, codeEntity.length)]];
        } else if ([entity isKindOfClass:[TLMessageEntity$messageEntityPre class]]) {
            TLMessageEntity$messageEntityPre *preEntity = entity;
            [result addObject:[[TGMessageEntityPre alloc] initWithRange:NSMakeRange(preEntity.offset, preEntity.length)]];
        } else if ([entity isKindOfClass:[TLMessageEntity$messageEntityMentionName class]]) {
            TLMessageEntity$messageEntityMentionName *mentionNameEntity = entity;
            [result addObject:[[TGMessageEntityMentionName alloc] initWithRange:NSMakeRange(mentionNameEntity.offset, mentionNameEntity.length) userId:mentionNameEntity.user_id]];
        } else if ([entity isKindOfClass:[TLMessageEntity$messageEntityPhone class]]) {
            TLMessageEntity$messageEntityPhone *messageEntityPhone = entity;
            [result addObject:[[TGMessageEntityPhone alloc] initWithRange:NSMakeRange(messageEntityPhone.offset, messageEntityPhone.length)]];
        } else if ([entity isKindOfClass:[TLMessageEntity$messageEntityCashtag class]]) {
            TLMessageEntity$messageEntityCashtag *messageEntityCashtag = entity;
            [result addObject:[[TGMessageEntityCashtag alloc] initWithRange:NSMakeRange(messageEntityCashtag.offset, messageEntityCashtag.length)]];
        }
    }
    
    return result;
}

- (id)initWithTelegraphMessageDesc:(TLMessage *)desc
{
    self = [super init];
    if (self != nil)
    {
        NSArray *mediaAttachments = nil;
        TGReplyMarkupAttachment *replyMarkupAttachment = nil;
        TGMessageEntitiesAttachment *entitiesAttachment = nil;
        TGAuthorSignatureMediaAttachment *signatureAttachment = nil;
        
        if ([desc isKindOfClass:[TLMessage$message class]] || [desc isKindOfClass:[TLMessage$modernMessage class]])
        {
            TLMessage$message *concreteMessage = (TLMessage$message *)desc;
            
            self.containsMention = concreteMessage.flags & (1 << 4);
            if (self.containsMention) {
                self.containsUnseenMention = concreteMessage.flags & (1 << 5);
            }
            
            self.mid = concreteMessage.n_id;
            //self.unread = concreteMessage.flags & 1;
            self.outgoing = concreteMessage.flags & 2;
            self.fromUid = concreteMessage.from_id;
            if ([desc isKindOfClass:[TLMessage$modernMessage class]] && self.fromUid > 0)
                self.fromUid = TGModernLegacyIdForModernId(self.fromUid);
            
            self.text = concreteMessage.message;
            self.date = concreteMessage.date;
            
            self.isSilent = concreteMessage.flags & (1 << 13);
            self.isEdited = concreteMessage.flags & (1 << 15);
            
            if ([concreteMessage.to_id isKindOfClass:[TLPeer$peerUser class]])
            {
                TLPeer$peerUser *toUser = (TLPeer$peerUser *)concreteMessage.to_id;
                self.toUid = toUser.user_id;
                if ([desc isKindOfClass:[TLMessage$modernMessage class]] && self.fromUid == 0 && !self.outgoing)
                    self.fromUid = self.toUid;
                if (self.toUid == self.fromUid && !self.outgoing)
                    self.outgoing = true;
                self.cid = self.outgoing ? self.toUid : self.fromUid;
                if ([desc isKindOfClass:[TLMessage$modernMessage class]] && self.fromUid == self.toUid && !((concreteMessage.flags & 2) != 0))
                    self.outgoing = false;
            }
            else if ([concreteMessage.to_id isKindOfClass:[TLPeer$peerChat class]])
            {
                TLPeer$peerChat *toChat = (TLPeer$peerChat *)concreteMessage.to_id;
                self.toUid = -toChat.chat_id;
                self.cid = self.toUid;
            }
            else if ([concreteMessage.to_id isKindOfClass:[TLPeer$peerChannel class]])
            {
                TLPeer$peerChannel *toChannel = (TLPeer$peerChannel *)concreteMessage.to_id;
                self.toUid = TGPeerIdFromChannelId(toChannel.channel_id);
                self.cid = self.toUid;
                
                if ((concreteMessage.flags & (1 << 14)) != 0) {
                    self.sortKey = TGMessageSortKeyMake(self.cid, TGMessageSpaceImportant, concreteMessage.date, self.mid);
                } else {
                    self.sortKey = TGMessageSortKeyMake(self.cid, TGMessageSpaceUnimportant, concreteMessage.date, self.mid);
                }
                
                if (![desc isKindOfClass:[TLMessage$modernMessage class]] && (concreteMessage.flags & 256) == 0) {
                    self.fromUid = self.cid;
                }
                
                if (self.fromUid == TGTelegraphInstance.clientUserId) {
                    self.outgoing = true;
                }
            }

            if ([desc isKindOfClass:[TLMessage$modernMessage class]])
            {
                TLMessage$modernMessage *modernMessage = (TLMessage$modernMessage *)desc;
                if (modernMessage.fwd_from != nil)
                {
                    TGForwardedMessageMediaAttachment *forwardedMessageAttachment = [[TGForwardedMessageMediaAttachment alloc] init];
                    TLMessageFwdHeader$messageFwdHeader *fwd_header = ((TLMessageFwdHeader$messageFwdHeader *)modernMessage.fwd_from);
                    
                    if (fwd_header.channel_id != 0) {
                        forwardedMessageAttachment.forwardPeerId = TGPeerIdFromChannelId(fwd_header.channel_id);
                        forwardedMessageAttachment.forwardAuthorUserId = fwd_header.from_id;
                        forwardedMessageAttachment.forwardPostId = fwd_header.channel_post;
                        forwardedMessageAttachment.forwardMid = fwd_header.saved_from_msg_id;
                        
                    } else {
                        forwardedMessageAttachment.forwardPeerId = fwd_header.from_id;
                        
                        if (fwd_header.saved_from_msg_id != 0) {
                            TLPeer *forwardPeer = fwd_header.saved_from_peer;
                            if ([forwardPeer isKindOfClass:[TLPeer$peerUser class]]) {
                                forwardedMessageAttachment.forwardSourcePeerId = ((TLPeer$peerUser *)forwardPeer).user_id;
                            } else if ([forwardPeer isKindOfClass:[TLPeer$peerChat class]]) {
                                forwardedMessageAttachment.forwardSourcePeerId = TGPeerIdFromGroupId(((TLPeer$peerChat *)forwardPeer).chat_id);
                            } else if ([forwardPeer isKindOfClass:[TLPeer$peerChannel class]]) {
                                forwardedMessageAttachment.forwardSourcePeerId = TGPeerIdFromChannelId(((TLPeer$peerChannel *)forwardPeer).channel_id);
                            }
                            forwardedMessageAttachment.forwardMid = fwd_header.saved_from_msg_id;
                        }
                    }

                    forwardedMessageAttachment.forwardDate = fwd_header.date;
                    
                    forwardedMessageAttachment.forwardAuthorSignature = fwd_header.post_author;
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:forwardedMessageAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:forwardedMessageAttachment];
                        mediaAttachments = array;
                    }
                }
                
                if (modernMessage.via_bot_id != 0) {
                    TGViaUserAttachment *viaUserAttachment = [[TGViaUserAttachment alloc] initWithUserId:modernMessage.via_bot_id username:nil];
                    if (mediaAttachments == nil) {
                        mediaAttachments = [NSArray arrayWithObject:viaUserAttachment];
                    } else {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:viaUserAttachment];
                        mediaAttachments = array;
                    }
                }
                
                if (modernMessage.reply_to_msg_id != 0)
                {
                    TGMessage *replyMessage = [TGDatabaseInstance() loadMessageWithMid:modernMessage.reply_to_msg_id peerId:self.cid];

                    TGReplyMessageMediaAttachment *replyAttachment = [[TGReplyMessageMediaAttachment alloc] init];

                    replyAttachment.replyMessage = replyMessage;
                    replyAttachment.replyMessageId = modernMessage.reply_to_msg_id;
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:replyAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:replyAttachment];
                        mediaAttachments = array;
                    }
                }
                
                if (modernMessage.flags & (1 << 10)) {
                    self.viewCount = [[TGMessageViewCountContentProperty alloc] initWithViewCount:modernMessage.views];
                }

                if (modernMessage.reactionSummary.length != 0) {
                    NSMutableDictionary *contentProperties = [[NSMutableDictionary alloc] initWithDictionary:self.contentProperties];
                    contentProperties[@"ios6ReactionSummary"] = [[TGMessageReactionSummaryContentProperty alloc] initWithSummary:modernMessage.reactionSummary chosenReaction:modernMessage.chosenReaction];
                    self.contentProperties = contentProperties;
                }
                
                if (modernMessage.grouped_id != 0)
                    self.groupedId = modernMessage.grouped_id;
                
                self.editDate = modernMessage.edit_date;
            }
            
            if (concreteMessage.media != nil)
            {
                int32_t mediaLifetime = 0;
                NSArray *parsedMedia = [TGMessage parseTelegraphMedia:concreteMessage.media mediaLifetime:&mediaLifetime cid:self.cid mid:self.mid];
                if (mediaAttachments == nil)
                    mediaAttachments = parsedMedia;
                else
                {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObjectsFromArray:parsedMedia];
                    mediaAttachments = array;
                }
                
                bool hasContentToRead = false;
                for (id media in mediaAttachments)
                {
                    if ([media isKindOfClass:[TGAudioMediaAttachment class]])
                    {
                        hasContentToRead |= (concreteMessage.flags & (1 << 5)) == 0;
                        break;
                    } else if ([media isKindOfClass:[TGVideoMediaAttachment class]]) {
                        if (((TGVideoMediaAttachment *)media).roundMessage) {
                            hasContentToRead |= (concreteMessage.flags & (1 << 5)) == 0;
                        }
                        break;
                    }
                    else if ([media isKindOfClass:[TGDocumentMediaAttachment class]]) {
                        for (id attribute in ((TGDocumentMediaAttachment *)media).attributes) {
                            if ([attribute isKindOfClass:[TGDocumentAttributeAudio class]]) {
                                if (((TGDocumentAttributeAudio *)attribute).isVoice) {
                                    hasContentToRead |= (concreteMessage.flags & (1 << 5)) == 0;
                                }
                            }
                        }
                        break;
                    }
                }
                
                if (hasContentToRead)
                {
                    NSMutableDictionary *contentProperties = [[NSMutableDictionary alloc] initWithDictionary:self.contentProperties];
                    contentProperties[@"contentsRead"] = [[TGMessageViewedContentProperty alloc] init];
                    self.contentProperties = contentProperties;
                }
                
                if (mediaLifetime > 0) {
                    self.messageLifetime = mediaLifetime;
                    self.layer = 70;
                }
            }
            
            if ([desc isKindOfClass:[TLMessage$modernMessage class]] && ((TLMessage$modernMessage *)desc).reply_markup != nil)
            {
                bool hidePreviousMarkup = false;
                bool forceReply = false;
                bool onlyIfRelevantToUser = false;
                int32_t markupUserId = (int32_t)self.fromUid;
                if (markupUserId == 0 && self.cid < 0)
                    markupUserId = (int32_t)self.cid;
                TGBotReplyMarkup *replyMarkup = [TGBotSignals botReplyMarkupForMarkup:((TLMessage$modernMessage *)desc).reply_markup userId:markupUserId messageId:self.mid hidePreviousMarkup:&hidePreviousMarkup forceReply:&forceReply onlyIfRelevantToUser:&onlyIfRelevantToUser];
                
                if (!onlyIfRelevantToUser || ((TLMessage$modernMessage *)desc).flags & (1 << 4))
                {
                    self.hideReplyMarkup = hidePreviousMarkup;
                    self.forceReply = forceReply;
                    
                    if (replyMarkup != nil)
                    {
                        replyMarkupAttachment = [[TGReplyMarkupAttachment alloc] init];
                        replyMarkupAttachment.replyMarkup = replyMarkup;
                    }
                }
            }
            
            if ([desc isKindOfClass:[TLMessage$modernMessage class]] && ((TLMessage$modernMessage *)desc).entities != nil)
            {
                NSArray *entities = [TGMessage parseTelegraphEntities:((TLMessage$modernMessage *)desc).entities];
                if (entities.count != 0)
                {
                    entitiesAttachment = [[TGMessageEntitiesAttachment alloc] init];
                    entitiesAttachment.entities = entities;
                }
            }
            
            if ([desc isKindOfClass:[TLMessage$modernMessage class]] && ((TLMessage$modernMessage *)desc).post_author != nil)
            {
                signatureAttachment = [[TGAuthorSignatureMediaAttachment alloc] initWithSignature:((TLMessage$modernMessage *)desc).post_author];
            }
        }
        else if ([desc isKindOfClass:[TLMessage$modernMessageService class]])
        {
            TLMessage$modernMessageService *concreteMessage = (TLMessage$modernMessageService *)desc;
            
            self.mid = concreteMessage.n_id;
            //self.unread = concreteMessage.flags & 1;
            self.outgoing = concreteMessage.flags & 2;
            self.fromUid = concreteMessage.from_id;
            if (self.fromUid > 0)
                self.fromUid = TGModernLegacyIdForModernId(self.fromUid);
            
            self.text = @"";
            self.date = concreteMessage.date;
            
            if ([concreteMessage.to_id isKindOfClass:[TLPeer$peerUser class]])
            {
                TLPeer$peerUser *toUser = (TLPeer$peerUser *)concreteMessage.to_id;
                self.toUid = toUser.user_id;
                if (self.fromUid == 0 && !self.outgoing)
                    self.fromUid = self.toUid;
                if (self.toUid == self.fromUid && !self.outgoing)
                    self.outgoing = true;
                self.cid = self.outgoing ? self.toUid : self.fromUid;
                if (self.fromUid == self.toUid && !((concreteMessage.flags & 2) != 0))
                    self.outgoing = false;
            }
            else if ([concreteMessage.to_id isKindOfClass:[TLPeer$peerChat class]])
            {
                TLPeer$peerChat *toChat = (TLPeer$peerChat *)concreteMessage.to_id;
                self.toUid = -toChat.chat_id;
                self.cid = self.toUid;
            }
            else if ([concreteMessage.to_id isKindOfClass:[TLPeer$peerChannel class]])
            {
                TLPeer$peerChannel *toChannel = (TLPeer$peerChannel *)concreteMessage.to_id;
                self.toUid = TGPeerIdFromChannelId(toChannel.channel_id);
                self.cid = self.toUid;
                
                if ((concreteMessage.flags & (1 << 14)) != 0) {
                    self.sortKey = TGMessageSortKeyMake(self.cid, TGMessageSpaceImportant, concreteMessage.date, self.mid);
                } else {
                    self.sortKey = TGMessageSortKeyMake(self.cid, TGMessageSpaceUnimportant, concreteMessage.date, self.mid);
                }
                
                if (self.fromUid == 0) {
                    self.fromUid = self.cid;
                }
                
                if (self.fromUid == TGTelegraphInstance.clientUserId) {
                    self.outgoing = true;
                }
            }
            
            if (concreteMessage.reply_to_msg_id != 0)
            {
                TGMessage *replyMessage = [TGDatabaseInstance() loadMessageWithMid:concreteMessage.reply_to_msg_id peerId:self.cid];
                
                TGReplyMessageMediaAttachment *replyAttachment = [[TGReplyMessageMediaAttachment alloc] init];
                
                replyAttachment.replyMessage = replyMessage;
                replyAttachment.replyMessageId = concreteMessage.reply_to_msg_id;
                
                if (mediaAttachments == nil)
                    mediaAttachments = [NSArray arrayWithObject:replyAttachment];
                else
                {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:replyAttachment];
                    mediaAttachments = array;
                }
            }
            
            TLMessageAction *action = concreteMessage.action;
            if (action != nil && ![action isKindOfClass:[TLMessageAction$messageActionEmpty class]])
            {
                TGActionMediaAttachment *actionMediaAttachment = [[TGActionMediaAttachment alloc] initWithTelegraphActionDesc:action];
                if (actionMediaAttachment != nil && actionMediaAttachment.actionType != TGMessageActionNone)
                {
                    if (mediaAttachments == nil)
                    {
                        mediaAttachments = [NSArray arrayWithObject:actionMediaAttachment];
                    }
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:actionMediaAttachment];
                        mediaAttachments = array;
                    }
                }
            }
        }
        
        if (replyMarkupAttachment != nil)
        {
            if (mediaAttachments == nil)
            {
                mediaAttachments = [NSArray arrayWithObject:replyMarkupAttachment];
            }
            else
            {
                NSMutableArray *array = [[NSMutableArray alloc] init];
                [array addObjectsFromArray:mediaAttachments];
                [array addObject:replyMarkupAttachment];
                mediaAttachments = array;
            }
        }
        
        if (entitiesAttachment != nil)
        {
            if (mediaAttachments == nil)
            {
                mediaAttachments = [NSArray arrayWithObject:entitiesAttachment];
            }
            else
            {
                NSMutableArray *array = [[NSMutableArray alloc] init];
                [array addObjectsFromArray:mediaAttachments];
                [array addObject:entitiesAttachment];
                mediaAttachments = array;
            }
        }
        
        if (signatureAttachment != nil) {
            if (mediaAttachments == nil) {
                mediaAttachments = [NSArray arrayWithObject:signatureAttachment];
            } else {
                NSMutableArray *array = [[NSMutableArray alloc] init];
                [array addObjectsFromArray:mediaAttachments];
                [array addObject:signatureAttachment];
                mediaAttachments = array;
            }
        }
        
        self.mediaAttachments = mediaAttachments;
    }
    return self;
}

- (instancetype)initWithDecryptedMessageDesc1:(Secret1_DecryptedMessage *)desc encryptedFile:(TGStoredIncomingMessageFileInfo *)encryptedFile conversationId:(int64_t)conversationId fromUid:(int)fromUid date:(int)date
{
    self = [super init];
    if (self != nil)
    {
        self.randomId = (int64_t)[desc.randomId longLongValue];
        self.fromUid = fromUid;
        self.toUid = TGTelegraphInstance.clientUserId;
        self.date = date;
        //self.unread = true;
        self.outgoing = false;
        self.cid = conversationId;
        
        NSArray *mediaAttachments = nil;
        
        if ([desc isKindOfClass:[Secret1_DecryptedMessage_decryptedMessage class]])
        {
            Secret1_DecryptedMessage_decryptedMessage *concreteMessage = (Secret1_DecryptedMessage_decryptedMessage *)desc;
            
            self.text = concreteMessage.message;
            
            if (![concreteMessage.media isKindOfClass:[Secret1_DecryptedMessageMedia_decryptedMessageMediaEmpty class]])
            {
                if ([concreteMessage.media isKindOfClass:[Secret1_DecryptedMessageMedia_decryptedMessageMediaPhoto class]])
                {
                    if (encryptedFile != nil)
                    {
                        Secret1_DecryptedMessageMedia_decryptedMessageMediaPhoto *decryptedPhoto = (Secret1_DecryptedMessageMedia_decryptedMessageMediaPhoto *)concreteMessage.media;
                        
                        TGImageMediaAttachment *imageAttachment = [[TGImageMediaAttachment alloc] init];
                        
                        imageAttachment.imageId = encryptedFile.n_id;
                        imageAttachment.accessHash = encryptedFile.accessHash;
                        
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedPhoto.thumbW intValue], [decryptedPhoto.thumbH intValue]) url:thumbnailUrl];
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                        {
                            if (!containsFirst)
                            {
                                if (decryptedPhoto.thumb.length < 128 * 1024)
                                {
                                    if (TGEnableBlur() && cpuCoreCount() > 1)
                                    {
                                        NSData *data = nil;
                                        TGScaleAndBlurImage(decryptedPhoto.thumb, CGSizeZero, &data);
                                        if (data != nil)
                                            [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                        else
                                            [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedPhoto.thumb url:thumbnailUrl availability:TGCacheDisk];
                                    }
                                    else
                                        [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedPhoto.thumb url:thumbnailUrl availability:TGCacheDisk];
                                }
                            }
                        }];
                        
                        NSString *fileUrl = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedPhoto.size intValue], encryptedFile.keyFingerprint, [decryptedPhoto.key stringByEncodingInHex], [decryptedPhoto.iv stringByEncodingInHex]];
                        
                        [imageInfo addImageWithSize:CGSizeMake([decryptedPhoto.w intValue], [decryptedPhoto.h intValue]) url:fileUrl fileSize:encryptedFile.size];
                        
                        imageAttachment.imageInfo = imageInfo;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:imageAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:imageAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret1_DecryptedMessageMedia_decryptedMessageMediaVideo class]])
                {
                    if (encryptedFile != nil)
                    {
                        Secret1_DecryptedMessageMedia_decryptedMessageMediaVideo *decryptedVideo = (Secret1_DecryptedMessageMedia_decryptedMessageMediaVideo *)concreteMessage.media;
                        
                        TGVideoMediaAttachment *videoAttachment = [[TGVideoMediaAttachment alloc] init];
                        
                        videoAttachment.videoId = encryptedFile.n_id;
                        videoAttachment.accessHash = encryptedFile.accessHash;
                        
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedVideo.thumbW intValue], [decryptedVideo.thumbH intValue]) url:thumbnailUrl];
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                        {
                            if (!containsFirst)
                            {
                                if (decryptedVideo.thumb.length < 128 * 1024)
                                {
                                    if (TGEnableBlur() && cpuCoreCount() > 1)
                                    {
                                        NSData *data = nil;
                                        TGScaleAndBlurImage(decryptedVideo.thumb, CGSizeZero, &data);
                                        if (data != nil)
                                            [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                        else
                                            [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedVideo.thumb url:thumbnailUrl availability:TGCacheDisk];
                                    }
                                    else
                                        [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedVideo.thumb url:thumbnailUrl availability:TGCacheDisk];
                                }
                            }
                        }];
                        
                        videoAttachment.thumbnailInfo = imageInfo;
                        
                        videoAttachment.duration = [decryptedVideo.duration intValue];
                        videoAttachment.dimensions = CGSizeMake([decryptedVideo.w intValue], [decryptedVideo.h intValue]);
                        
                        TGVideoInfo *videoInfo = [[TGVideoInfo alloc] init];
                        
                        NSString *fileUrl = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedVideo.size intValue], encryptedFile.keyFingerprint, [decryptedVideo.key stringByEncodingInHex], [decryptedVideo.iv stringByEncodingInHex]];
                        
                        [videoInfo addVideoWithQuality:1 url:fileUrl size:[decryptedVideo.size intValue]];
                        videoAttachment.videoInfo = videoInfo;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:videoAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:videoAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret1_DecryptedMessageMedia_decryptedMessageMediaDocument class]])
                {
                    Secret1_DecryptedMessageMedia_decryptedMessageMediaDocument *decryptedDocument = (Secret1_DecryptedMessageMedia_decryptedMessageMediaDocument *)concreteMessage.media;
                    
                    TGDocumentMediaAttachment *documentAttachment = [[TGDocumentMediaAttachment alloc] init];
                    
                    int64_t localId = 0;
                    arc4random_buf(&localId, sizeof(localId));
                    
                    NSMutableArray *attributes = [[NSMutableArray alloc] init];
                    [attributes addObject:[[TGDocumentAttributeFilename alloc] initWithFilename:decryptedDocument.fileName]];
                    
                    documentAttachment.localDocumentId = localId;
                    documentAttachment.mimeType = decryptedDocument.mimeType;
                    documentAttachment.size = [decryptedDocument.size intValue];
                    documentAttachment.attributes = attributes;
                    
                    documentAttachment.documentUri = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedDocument.size intValue], encryptedFile.keyFingerprint, [decryptedDocument.key stringByEncodingInHex], [decryptedDocument.iv stringByEncodingInHex]];
                    
                    if (decryptedDocument.thumb != nil && [decryptedDocument.thumbW intValue] > 0 && [decryptedDocument.thumbH intValue] > 0)
                    {
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedDocument.thumbW intValue], [decryptedDocument.thumbH intValue]) url:thumbnailUrl];
                        documentAttachment.thumbnailInfo = imageInfo;
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                        {
                            if (!containsFirst)
                            {
                                if (decryptedDocument.thumb.length < 128 * 1024)
                                {
                                    if (TGEnableBlur() && cpuCoreCount() > 1)
                                    {
                                        NSData *data = nil;
                                        TGScaleAndBlurImage(decryptedDocument.thumb, CGSizeZero, &data);
                                        if (data != nil)
                                            [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                        else
                                            [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedDocument.thumb url:thumbnailUrl availability:TGCacheDisk];
                                    }
                                    else
                                        [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedDocument.thumb url:thumbnailUrl availability:TGCacheDisk];
                                }
                            }
                        }];
                    }
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:documentAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:documentAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret1_DecryptedMessageMedia_decryptedMessageMediaAudio class]])
                {
                    Secret1_DecryptedMessageMedia_decryptedMessageMediaAudio *decryptedAudio = (Secret1_DecryptedMessageMedia_decryptedMessageMediaAudio *)concreteMessage.media;
                    
                    TGAudioMediaAttachment *audioAttachment = [[TGAudioMediaAttachment alloc] init];
                    
                    int64_t localId = 0;
                    arc4random_buf(&localId, sizeof(localId));
                    
                    audioAttachment.localAudioId = localId;
                    audioAttachment.duration = [decryptedAudio.duration intValue];
                    audioAttachment.fileSize = [decryptedAudio.size intValue];
                    
                    audioAttachment.audioUri = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedAudio.size intValue], encryptedFile.keyFingerprint, [decryptedAudio.key stringByEncodingInHex], [decryptedAudio.iv stringByEncodingInHex]];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:audioAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:audioAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret1_DecryptedMessageMedia_decryptedMessageMediaGeoPoint class]])
                {
                    Secret1_DecryptedMessageMedia_decryptedMessageMediaGeoPoint *concreteGeo = (Secret1_DecryptedMessageMedia_decryptedMessageMediaGeoPoint *)concreteMessage.media;
                    
                    TGLocationMediaAttachment *locationMediaAttachment = [[TGLocationMediaAttachment alloc] init];
                    locationMediaAttachment.latitude = [concreteGeo.lat doubleValue];
                    locationMediaAttachment.longitude = [concreteGeo.plong doubleValue];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:locationMediaAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:locationMediaAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret1_DecryptedMessageMedia_decryptedMessageMediaContact class]])
                {
                    Secret1_DecryptedMessageMedia_decryptedMessageMediaContact *mediaContact = (Secret1_DecryptedMessageMedia_decryptedMessageMediaContact *)concreteMessage.media;
                    
                    TLMessageMedia$messageMediaContact *convertedContact = [[TLMessageMedia$messageMediaContact alloc] init];
                    convertedContact.phone_number = mediaContact.phoneNumber;
                    convertedContact.first_name = mediaContact.firstName;
                    convertedContact.last_name = mediaContact.lastName;
                    convertedContact.user_id = [mediaContact.userId intValue];
                    
                    TGContactMediaAttachment *contactAttachment = [[TGContactMediaAttachment alloc] initWithTelegraphContactDesc:convertedContact];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:contactAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:contactAttachment];
                        mediaAttachments = array;
                    }
                }
            }
        }
        else if ([desc isKindOfClass:[Secret1_DecryptedMessage_decryptedMessageService class]])
        {
            Secret1_DecryptedMessage_decryptedMessageService *concreteMessage = (Secret1_DecryptedMessage_decryptedMessageService *)desc;
            //self.unread = false;
            
            if ([concreteMessage.action isKindOfClass:[Secret1_DecryptedMessageAction_decryptedMessageActionSetMessageTTL class]])
            {
                Secret1_DecryptedMessageAction_decryptedMessageActionSetMessageTTL *concreteAction = (Secret1_DecryptedMessageAction_decryptedMessageActionSetMessageTTL *)concreteMessage.action;
                
                TGActionMediaAttachment *actionAttachment = [[TGActionMediaAttachment alloc] init];
                actionAttachment.actionType = TGMessageActionEncryptedChatMessageLifetime;
                actionAttachment.actionData = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithInt:[concreteAction.ttlSeconds intValue]], @"messageLifetime", nil];
                
                if (mediaAttachments == nil)
                    mediaAttachments = [NSArray arrayWithObject:actionAttachment];
                else
                {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:actionAttachment];
                    mediaAttachments = array;
                }
            }
        }
        
        if (mediaAttachments != nil)
            self.mediaAttachments = mediaAttachments;
    }
    return self;
}

- (instancetype)initWithDecryptedMessageDesc17:(Secret17_DecryptedMessage *)desc encryptedFile:(TGStoredIncomingMessageFileInfo *)encryptedFile conversationId:(int64_t)conversationId fromUid:(int)fromUid date:(int)date
{
    self = [super init];
    if (self != nil)
    {
        self.randomId = (int64_t)[desc.randomId longLongValue];
        self.fromUid = fromUid;
        self.toUid = TGTelegraphInstance.clientUserId;
        self.date = date;
        //self.unread = true;
        self.outgoing = false;
        self.cid = conversationId;
        
        NSArray *mediaAttachments = nil;
        
        if ([desc isKindOfClass:[Secret17_DecryptedMessage_decryptedMessage class]])
        {
            Secret17_DecryptedMessage_decryptedMessage *concreteMessage = (Secret17_DecryptedMessage_decryptedMessage *)desc;
            
            self.text = concreteMessage.message;
            self.messageLifetime = [concreteMessage.ttl intValue];
            
            if (![concreteMessage.media isKindOfClass:[Secret17_DecryptedMessageMedia_decryptedMessageMediaEmpty class]])
            {
                if ([concreteMessage.media isKindOfClass:[Secret17_DecryptedMessageMedia_decryptedMessageMediaPhoto class]])
                {
                    if (encryptedFile != nil)
                    {
                        Secret17_DecryptedMessageMedia_decryptedMessageMediaPhoto *decryptedPhoto = (Secret17_DecryptedMessageMedia_decryptedMessageMediaPhoto *)concreteMessage.media;
                        
                        TGImageMediaAttachment *imageAttachment = [[TGImageMediaAttachment alloc] init];
                        
                        imageAttachment.imageId = encryptedFile.n_id;
                        imageAttachment.accessHash = encryptedFile.accessHash;
                        
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedPhoto.thumbW intValue], [decryptedPhoto.thumbH intValue]) url:thumbnailUrl];
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                        {
                            if (!containsFirst)
                            {
                                if (decryptedPhoto.thumb.length < 128 * 1024)
                                {
                                    if (TGEnableBlur() && cpuCoreCount() > 1)
                                    {
                                        NSData *data = nil;
                                        TGScaleAndBlurImage(decryptedPhoto.thumb, CGSizeZero, &data);
                                        if (data != nil)
                                            [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                        else
                                            [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedPhoto.thumb url:thumbnailUrl availability:TGCacheDisk];
                                    }
                                    else
                                        [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedPhoto.thumb url:thumbnailUrl availability:TGCacheDisk];
                                }
                            }
                        }];
                        
                        NSString *fileUrl = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedPhoto.size intValue], encryptedFile.keyFingerprint, [decryptedPhoto.key stringByEncodingInHex], [decryptedPhoto.iv stringByEncodingInHex]];
                        
                        [imageInfo addImageWithSize:CGSizeMake([decryptedPhoto.w intValue], [decryptedPhoto.h intValue]) url:fileUrl fileSize:encryptedFile.size];
                        
                        imageAttachment.imageInfo = imageInfo;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:imageAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:imageAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret17_DecryptedMessageMedia_decryptedMessageMediaVideo class]])
                {
                    if (encryptedFile != nil)
                    {
                        Secret17_DecryptedMessageMedia_decryptedMessageMediaVideo *decryptedVideo = (Secret17_DecryptedMessageMedia_decryptedMessageMediaVideo *)concreteMessage.media;
                        
                        TGVideoMediaAttachment *videoAttachment = [[TGVideoMediaAttachment alloc] init];
                        
                        videoAttachment.videoId = encryptedFile.n_id;
                        videoAttachment.accessHash = encryptedFile.accessHash;
                        
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedVideo.thumbW intValue], [decryptedVideo.thumbH intValue]) url:thumbnailUrl];
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                        {
                            if (!containsFirst)
                            {
                                if (decryptedVideo.thumb.length < 128 * 1024)
                                {
                                    if (TGEnableBlur() && cpuCoreCount() > 1)
                                    {
                                        NSData *data = nil;
                                        TGScaleAndBlurImage(decryptedVideo.thumb, CGSizeZero, &data);
                                        if (data != nil)
                                            [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                        else
                                            [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedVideo.thumb url:thumbnailUrl availability:TGCacheDisk];
                                    }
                                    else
                                        [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedVideo.thumb url:thumbnailUrl availability:TGCacheDisk];
                                }
                            }
                        }];
                        
                        videoAttachment.thumbnailInfo = imageInfo;
                        
                        videoAttachment.duration = [decryptedVideo.duration intValue];
                        videoAttachment.dimensions = CGSizeMake([decryptedVideo.w intValue], [decryptedVideo.h intValue]);
                        
                        TGVideoInfo *videoInfo = [[TGVideoInfo alloc] init];
                        
                        NSString *fileUrl = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedVideo.size intValue], encryptedFile.keyFingerprint, [decryptedVideo.key stringByEncodingInHex], [decryptedVideo.iv stringByEncodingInHex]];
                        
                        [videoInfo addVideoWithQuality:1 url:fileUrl size:[decryptedVideo.size intValue]];
                        videoAttachment.videoInfo = videoInfo;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:videoAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:videoAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret17_DecryptedMessageMedia_decryptedMessageMediaDocument class]])
                {
                    Secret17_DecryptedMessageMedia_decryptedMessageMediaDocument *decryptedDocument = (Secret17_DecryptedMessageMedia_decryptedMessageMediaDocument *)concreteMessage.media;
                    
                    TGDocumentMediaAttachment *documentAttachment = [[TGDocumentMediaAttachment alloc] init];
                    
                    int64_t localId = 0;
                    arc4random_buf(&localId, sizeof(localId));
                    
                    NSMutableArray *attributes = [[NSMutableArray alloc] init];
                    [attributes addObject:[[TGDocumentAttributeFilename alloc] initWithFilename:decryptedDocument.fileName]];
                    
                    documentAttachment.localDocumentId = localId;
                    documentAttachment.attributes = attributes;
                    documentAttachment.mimeType = decryptedDocument.mimeType;
                    documentAttachment.size = [decryptedDocument.size intValue];
                    
                    documentAttachment.documentUri = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedDocument.size intValue], encryptedFile.keyFingerprint, [decryptedDocument.key stringByEncodingInHex], [decryptedDocument.iv stringByEncodingInHex]];
                    
                    if (decryptedDocument.thumb != nil && [decryptedDocument.thumbW intValue] > 0 && [decryptedDocument.thumbH intValue] > 0)
                    {
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedDocument.thumbW intValue], [decryptedDocument.thumbH intValue]) url:thumbnailUrl];
                        documentAttachment.thumbnailInfo = imageInfo;
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                        {
                            if (!containsFirst)
                            {
                                if (decryptedDocument.thumb.length < 128 * 1024)
                                {
                                    if (TGEnableBlur() && cpuCoreCount() > 1)
                                    {
                                        NSData *data = nil;
                                        TGScaleAndBlurImage(decryptedDocument.thumb, CGSizeZero, &data);
                                        if (data != nil)
                                            [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                        else
                                            [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedDocument.thumb url:thumbnailUrl availability:TGCacheDisk];
                                    }
                                    else
                                        [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedDocument.thumb url:thumbnailUrl availability:TGCacheDisk];
                                }
                            }
                        }];
                    }
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:documentAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:documentAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret17_DecryptedMessageMedia_decryptedMessageMediaAudio class]])
                {
                    Secret17_DecryptedMessageMedia_decryptedMessageMediaAudio *decryptedAudio = (Secret17_DecryptedMessageMedia_decryptedMessageMediaAudio *)concreteMessage.media;
                    
                    TGAudioMediaAttachment *audioAttachment = [[TGAudioMediaAttachment alloc] init];
                    
                    int64_t localId = 0;
                    arc4random_buf(&localId, sizeof(localId));
                    
                    audioAttachment.localAudioId = localId;
                    audioAttachment.duration = [decryptedAudio.duration intValue];
                    audioAttachment.fileSize = [decryptedAudio.size intValue];
                    
                    audioAttachment.audioUri = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedAudio.size intValue], encryptedFile.keyFingerprint, [decryptedAudio.key stringByEncodingInHex], [decryptedAudio.iv stringByEncodingInHex]];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:audioAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:audioAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret17_DecryptedMessageMedia_decryptedMessageMediaGeoPoint class]])
                {
                    Secret17_DecryptedMessageMedia_decryptedMessageMediaGeoPoint *concreteGeo = (Secret17_DecryptedMessageMedia_decryptedMessageMediaGeoPoint *)concreteMessage.media;
                    
                    TGLocationMediaAttachment *locationMediaAttachment = [[TGLocationMediaAttachment alloc] init];
                    locationMediaAttachment.latitude = [concreteGeo.lat doubleValue];
                    locationMediaAttachment.longitude = [concreteGeo.plong doubleValue];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:locationMediaAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:locationMediaAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret17_DecryptedMessageMedia_decryptedMessageMediaContact class]])
                {
                    Secret17_DecryptedMessageMedia_decryptedMessageMediaContact *mediaContact = (Secret17_DecryptedMessageMedia_decryptedMessageMediaContact *)concreteMessage.media;
                    
                    TLMessageMedia$messageMediaContact *convertedContact = [[TLMessageMedia$messageMediaContact alloc] init];
                    convertedContact.phone_number = mediaContact.phoneNumber;
                    convertedContact.first_name = mediaContact.firstName;
                    convertedContact.last_name = mediaContact.lastName;
                    convertedContact.user_id = [mediaContact.userId intValue];
                    
                    TGContactMediaAttachment *contactAttachment = [[TGContactMediaAttachment alloc] initWithTelegraphContactDesc:convertedContact];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:contactAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:contactAttachment];
                        mediaAttachments = array;
                    }
                }
            }
        }
        else if ([desc isKindOfClass:[Secret17_DecryptedMessage_decryptedMessageService class]])
        {
            Secret17_DecryptedMessage_decryptedMessageService *concreteMessage = (Secret17_DecryptedMessage_decryptedMessageService *)desc;
            //self.unread = false;
            
            if ([concreteMessage.action isKindOfClass:[Secret17_DecryptedMessageAction_decryptedMessageActionSetMessageTTL class]])
            {
                Secret17_DecryptedMessageAction_decryptedMessageActionSetMessageTTL *concreteAction = (Secret17_DecryptedMessageAction_decryptedMessageActionSetMessageTTL *)concreteMessage.action;
                
                TGActionMediaAttachment *actionAttachment = [[TGActionMediaAttachment alloc] init];
                actionAttachment.actionType = TGMessageActionEncryptedChatMessageLifetime;
                actionAttachment.actionData = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithInt:[concreteAction.ttlSeconds intValue]], @"messageLifetime", nil];
                
                if (mediaAttachments == nil)
                    mediaAttachments = [NSArray arrayWithObject:actionAttachment];
                else
                {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:actionAttachment];
                    mediaAttachments = array;
                }
            }
            else if ([concreteMessage.action isKindOfClass:[Secret17_DecryptedMessageAction_decryptedMessageActionScreenshotMessages class]])
            {
                Secret17_DecryptedMessageAction_decryptedMessageActionScreenshotMessages *concreteAction = (Secret17_DecryptedMessageAction_decryptedMessageActionScreenshotMessages *)concreteMessage.action;
                TGActionMediaAttachment *actionAttachment = [[TGActionMediaAttachment alloc] init];
                actionAttachment.actionType = TGMessageActionEncryptedChatMessageScreenshot;
                actionAttachment.actionData = @{@"randomIds": concreteAction.randomIds};
                
                if (mediaAttachments == nil)
                    mediaAttachments = [NSArray arrayWithObject:actionAttachment];
                else
                {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:actionAttachment];
                    mediaAttachments = array;
                }
            }
        }
        else
            return nil;
        
        if (mediaAttachments != nil)
            self.mediaAttachments = mediaAttachments;
    }
    return self;
}

- (instancetype)initWithDecryptedMessageDesc20:(Secret20_DecryptedMessage *)desc encryptedFile:(TGStoredIncomingMessageFileInfo *)encryptedFile conversationId:(int64_t)conversationId fromUid:(int)fromUid date:(int)date
{
    self = [super init];
    if (self != nil)
    {
        self.randomId = (int64_t)[desc.randomId longLongValue];
        self.fromUid = fromUid;
        self.toUid = TGTelegraphInstance.clientUserId;
        self.date = date;
        //self.unread = true;
        self.outgoing = false;
        self.cid = conversationId;
        
        NSArray *mediaAttachments = nil;
        
        if ([desc isKindOfClass:[Secret20_DecryptedMessage_decryptedMessage class]])
        {
            Secret20_DecryptedMessage_decryptedMessage *concreteMessage = (Secret20_DecryptedMessage_decryptedMessage *)desc;
            
            self.text = concreteMessage.message;
            self.messageLifetime = [concreteMessage.ttl intValue];
            
            if (![concreteMessage.media isKindOfClass:[Secret20_DecryptedMessageMedia_decryptedMessageMediaEmpty class]])
            {
                if ([concreteMessage.media isKindOfClass:[Secret20_DecryptedMessageMedia_decryptedMessageMediaPhoto class]])
                {
                    if (encryptedFile != nil)
                    {
                        Secret20_DecryptedMessageMedia_decryptedMessageMediaPhoto *decryptedPhoto = (Secret20_DecryptedMessageMedia_decryptedMessageMediaPhoto *)concreteMessage.media;
                        
                        TGImageMediaAttachment *imageAttachment = [[TGImageMediaAttachment alloc] init];
                        
                        imageAttachment.imageId = encryptedFile.n_id;
                        imageAttachment.accessHash = encryptedFile.accessHash;
                        
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedPhoto.thumbW intValue], [decryptedPhoto.thumbH intValue]) url:thumbnailUrl];
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                         {
                             if (!containsFirst)
                             {
                                 if (decryptedPhoto.thumb.length < 128 * 1024)
                                 {
                                     if (TGEnableBlur() && cpuCoreCount() > 1)
                                     {
                                         NSData *data = nil;
                                         TGScaleAndBlurImage(decryptedPhoto.thumb, CGSizeZero, &data);
                                         if (data != nil)
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                         else
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedPhoto.thumb url:thumbnailUrl availability:TGCacheDisk];
                                     }
                                     else
                                         [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedPhoto.thumb url:thumbnailUrl availability:TGCacheDisk];
                                 }
                             }
                         }];
                        
                        NSString *fileUrl = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedPhoto.size intValue], encryptedFile.keyFingerprint, [decryptedPhoto.key stringByEncodingInHex], [decryptedPhoto.iv stringByEncodingInHex]];
                        
                        [imageInfo addImageWithSize:CGSizeMake([decryptedPhoto.w intValue], [decryptedPhoto.h intValue]) url:fileUrl fileSize:encryptedFile.size];
                        
                        imageAttachment.imageInfo = imageInfo;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:imageAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:imageAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret20_DecryptedMessageMedia_decryptedMessageMediaVideo class]])
                {
                    if (encryptedFile != nil)
                    {
                        Secret20_DecryptedMessageMedia_decryptedMessageMediaVideo *decryptedVideo = (Secret20_DecryptedMessageMedia_decryptedMessageMediaVideo *)concreteMessage.media;
                        
                        TGVideoMediaAttachment *videoAttachment = [[TGVideoMediaAttachment alloc] init];
                        
                        videoAttachment.videoId = encryptedFile.n_id;
                        videoAttachment.accessHash = encryptedFile.accessHash;
                        
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedVideo.thumbW intValue], [decryptedVideo.thumbH intValue]) url:thumbnailUrl];
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                         {
                             if (!containsFirst)
                             {
                                 if (decryptedVideo.thumb.length < 128 * 1024)
                                 {
                                     if (TGEnableBlur() && cpuCoreCount() > 1)
                                     {
                                         NSData *data = nil;
                                         TGScaleAndBlurImage(decryptedVideo.thumb, CGSizeZero, &data);
                                         if (data != nil)
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                         else
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedVideo.thumb url:thumbnailUrl availability:TGCacheDisk];
                                     }
                                     else
                                         [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedVideo.thumb url:thumbnailUrl availability:TGCacheDisk];
                                 }
                             }
                         }];
                        
                        videoAttachment.thumbnailInfo = imageInfo;
                        
                        videoAttachment.duration = [decryptedVideo.duration intValue];
                        videoAttachment.dimensions = CGSizeMake([decryptedVideo.w intValue], [decryptedVideo.h intValue]);
                        
                        TGVideoInfo *videoInfo = [[TGVideoInfo alloc] init];
                        
                        NSString *fileUrl = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedVideo.size intValue], encryptedFile.keyFingerprint, [decryptedVideo.key stringByEncodingInHex], [decryptedVideo.iv stringByEncodingInHex]];
                        
                        [videoInfo addVideoWithQuality:1 url:fileUrl size:[decryptedVideo.size intValue]];
                        videoAttachment.videoInfo = videoInfo;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:videoAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:videoAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret20_DecryptedMessageMedia_decryptedMessageMediaDocument class]])
                {
                    Secret20_DecryptedMessageMedia_decryptedMessageMediaDocument *decryptedDocument = (Secret20_DecryptedMessageMedia_decryptedMessageMediaDocument *)concreteMessage.media;
                    
                    TGDocumentMediaAttachment *documentAttachment = [[TGDocumentMediaAttachment alloc] init];
                    
                    int64_t localId = 0;
                    arc4random_buf(&localId, sizeof(localId));
                    
                    NSMutableArray *attributes = [[NSMutableArray alloc] init];
                    [attributes addObject:[[TGDocumentAttributeFilename alloc] initWithFilename:decryptedDocument.fileName]];
                    
                    documentAttachment.localDocumentId = localId;
                    documentAttachment.attributes = attributes;
                    documentAttachment.mimeType = decryptedDocument.mimeType;
                    documentAttachment.size = [decryptedDocument.size intValue];
                    
                    documentAttachment.documentUri = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedDocument.size intValue], encryptedFile.keyFingerprint, [decryptedDocument.key stringByEncodingInHex], [decryptedDocument.iv stringByEncodingInHex]];
                    
                    if (decryptedDocument.thumb != nil && [decryptedDocument.thumbW intValue] > 0 && [decryptedDocument.thumbH intValue] > 0)
                    {
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedDocument.thumbW intValue], [decryptedDocument.thumbH intValue]) url:thumbnailUrl];
                        documentAttachment.thumbnailInfo = imageInfo;
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                         {
                             if (!containsFirst)
                             {
                                 if (decryptedDocument.thumb.length < 128 * 1024)
                                 {
                                     if (TGEnableBlur() && cpuCoreCount() > 1)
                                     {
                                         NSData *data = nil;
                                         TGScaleAndBlurImage(decryptedDocument.thumb, CGSizeZero, &data);
                                         if (data != nil)
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                         else
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedDocument.thumb url:thumbnailUrl availability:TGCacheDisk];
                                     }
                                     else
                                         [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedDocument.thumb url:thumbnailUrl availability:TGCacheDisk];
                                 }
                             }
                         }];
                    }
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:documentAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:documentAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret20_DecryptedMessageMedia_decryptedMessageMediaAudio class]])
                {
                    Secret20_DecryptedMessageMedia_decryptedMessageMediaAudio *decryptedAudio = (Secret20_DecryptedMessageMedia_decryptedMessageMediaAudio *)concreteMessage.media;
                    
                    TGAudioMediaAttachment *audioAttachment = [[TGAudioMediaAttachment alloc] init];
                    
                    int64_t localId = 0;
                    arc4random_buf(&localId, sizeof(localId));
                    
                    audioAttachment.localAudioId = localId;
                    audioAttachment.duration = [decryptedAudio.duration intValue];
                    audioAttachment.fileSize = [decryptedAudio.size intValue];
                    
                    audioAttachment.audioUri = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedAudio.size intValue], encryptedFile.keyFingerprint, [decryptedAudio.key stringByEncodingInHex], [decryptedAudio.iv stringByEncodingInHex]];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:audioAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:audioAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret20_DecryptedMessageMedia_decryptedMessageMediaGeoPoint class]])
                {
                    Secret20_DecryptedMessageMedia_decryptedMessageMediaGeoPoint *concreteGeo = (Secret20_DecryptedMessageMedia_decryptedMessageMediaGeoPoint *)concreteMessage.media;
                    
                    TGLocationMediaAttachment *locationMediaAttachment = [[TGLocationMediaAttachment alloc] init];
                    locationMediaAttachment.latitude = [concreteGeo.lat doubleValue];
                    locationMediaAttachment.longitude = [concreteGeo.plong doubleValue];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:locationMediaAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:locationMediaAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret20_DecryptedMessageMedia_decryptedMessageMediaContact class]])
                {
                    Secret20_DecryptedMessageMedia_decryptedMessageMediaContact *mediaContact = (Secret20_DecryptedMessageMedia_decryptedMessageMediaContact *)concreteMessage.media;
                    
                    TLMessageMedia$messageMediaContact *convertedContact = [[TLMessageMedia$messageMediaContact alloc] init];
                    convertedContact.phone_number = mediaContact.phoneNumber;
                    convertedContact.first_name = mediaContact.firstName;
                    convertedContact.last_name = mediaContact.lastName;
                    convertedContact.user_id = [mediaContact.userId intValue];
                    
                    TGContactMediaAttachment *contactAttachment = [[TGContactMediaAttachment alloc] initWithTelegraphContactDesc:convertedContact];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:contactAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:contactAttachment];
                        mediaAttachments = array;
                    }
                }
            }
        }
        else if ([desc isKindOfClass:[Secret20_DecryptedMessage_decryptedMessageService class]])
        {
            Secret20_DecryptedMessage_decryptedMessageService *concreteMessage = (Secret20_DecryptedMessage_decryptedMessageService *)desc;
            //self.unread = false;
            
            if ([concreteMessage.action isKindOfClass:[Secret20_DecryptedMessageAction_decryptedMessageActionSetMessageTTL class]])
            {
                Secret20_DecryptedMessageAction_decryptedMessageActionSetMessageTTL *concreteAction = (Secret20_DecryptedMessageAction_decryptedMessageActionSetMessageTTL *)concreteMessage.action;
                
                TGActionMediaAttachment *actionAttachment = [[TGActionMediaAttachment alloc] init];
                actionAttachment.actionType = TGMessageActionEncryptedChatMessageLifetime;
                actionAttachment.actionData = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithInt:[concreteAction.ttlSeconds intValue]], @"messageLifetime", nil];
                
                if (mediaAttachments == nil)
                    mediaAttachments = [NSArray arrayWithObject:actionAttachment];
                else
                {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:actionAttachment];
                    mediaAttachments = array;
                }
            }
            else if ([concreteMessage.action isKindOfClass:[Secret20_DecryptedMessageAction_decryptedMessageActionScreenshotMessages class]])
            {
                Secret20_DecryptedMessageAction_decryptedMessageActionScreenshotMessages *concreteAction = (Secret20_DecryptedMessageAction_decryptedMessageActionScreenshotMessages *)concreteMessage.action;
                TGActionMediaAttachment *actionAttachment = [[TGActionMediaAttachment alloc] init];
                actionAttachment.actionType = TGMessageActionEncryptedChatMessageScreenshot;
                actionAttachment.actionData = @{@"randomIds": concreteAction.randomIds};
                
                if (mediaAttachments == nil)
                    mediaAttachments = [NSArray arrayWithObject:actionAttachment];
                else
                {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:actionAttachment];
                    mediaAttachments = array;
                }
            }
        }
        else
            return nil;
        
        if (mediaAttachments != nil)
            self.mediaAttachments = mediaAttachments;
    }
    return self;
}

- (instancetype)initWithDecryptedMessageDesc23:(Secret23_DecryptedMessage *)desc encryptedFile:(TGStoredIncomingMessageFileInfo *)encryptedFile conversationId:(int64_t)conversationId fromUid:(int)fromUid date:(int)date
{
    self = [super init];
    if (self != nil)
    {
        self.randomId = (int64_t)[desc.randomId longLongValue];
        self.fromUid = fromUid;
        self.toUid = TGTelegraphInstance.clientUserId;
        self.date = date;
        //self.unread = true;
        self.outgoing = false;
        self.cid = conversationId;
        
        NSArray *mediaAttachments = nil;
        
        if ([desc isKindOfClass:[Secret23_DecryptedMessage_decryptedMessage class]])
        {
            Secret23_DecryptedMessage_decryptedMessage *concreteMessage = (Secret23_DecryptedMessage_decryptedMessage *)desc;
            
            self.text = concreteMessage.message;
            self.messageLifetime = [concreteMessage.ttl intValue];
            
            if (![concreteMessage.media isKindOfClass:[Secret23_DecryptedMessageMedia_decryptedMessageMediaEmpty class]])
            {
                if ([concreteMessage.media isKindOfClass:[Secret23_DecryptedMessageMedia_decryptedMessageMediaPhoto class]])
                {
                    if (encryptedFile != nil)
                    {
                        Secret23_DecryptedMessageMedia_decryptedMessageMediaPhoto *decryptedPhoto = (Secret23_DecryptedMessageMedia_decryptedMessageMediaPhoto *)concreteMessage.media;
                        
                        TGImageMediaAttachment *imageAttachment = [[TGImageMediaAttachment alloc] init];
                        
                        imageAttachment.imageId = encryptedFile.n_id;
                        imageAttachment.accessHash = encryptedFile.accessHash;
                        
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedPhoto.thumbW intValue], [decryptedPhoto.thumbH intValue]) url:thumbnailUrl];
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                         {
                             if (!containsFirst)
                             {
                                 if (decryptedPhoto.thumb.length < 128 * 1024)
                                 {
                                     if (TGEnableBlur() && cpuCoreCount() > 1)
                                     {
                                         NSData *data = nil;
                                         TGScaleAndBlurImage(decryptedPhoto.thumb, CGSizeZero, &data);
                                         if (data != nil)
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                         else
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedPhoto.thumb url:thumbnailUrl availability:TGCacheDisk];
                                     }
                                     else
                                         [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedPhoto.thumb url:thumbnailUrl availability:TGCacheDisk];
                                 }
                             }
                         }];
                        
                        NSString *fileUrl = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedPhoto.size intValue], encryptedFile.keyFingerprint, [decryptedPhoto.key stringByEncodingInHex], [decryptedPhoto.iv stringByEncodingInHex]];
                        
                        [imageInfo addImageWithSize:CGSizeMake([decryptedPhoto.w intValue], [decryptedPhoto.h intValue]) url:fileUrl fileSize:encryptedFile.size];
                        
                        imageAttachment.imageInfo = imageInfo;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:imageAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:imageAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret23_DecryptedMessageMedia_decryptedMessageMediaVideo class]])
                {
                    if (encryptedFile != nil)
                    {
                        Secret23_DecryptedMessageMedia_decryptedMessageMediaVideo *decryptedVideo = (Secret23_DecryptedMessageMedia_decryptedMessageMediaVideo *)concreteMessage.media;
                        
                        TGVideoMediaAttachment *videoAttachment = [[TGVideoMediaAttachment alloc] init];
                        
                        videoAttachment.videoId = encryptedFile.n_id;
                        videoAttachment.accessHash = encryptedFile.accessHash;
                        
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedVideo.thumbW intValue], [decryptedVideo.thumbH intValue]) url:thumbnailUrl];
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                         {
                             if (!containsFirst)
                             {
                                 if (decryptedVideo.thumb.length < 128 * 1024)
                                 {
                                     if (TGEnableBlur() && cpuCoreCount() > 1)
                                     {
                                         NSData *data = nil;
                                         TGScaleAndBlurImage(decryptedVideo.thumb, CGSizeZero, &data);
                                         if (data != nil)
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                         else
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedVideo.thumb url:thumbnailUrl availability:TGCacheDisk];
                                     }
                                     else
                                         [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedVideo.thumb url:thumbnailUrl availability:TGCacheDisk];
                                 }
                             }
                         }];
                        
                        videoAttachment.thumbnailInfo = imageInfo;
                        
                        videoAttachment.duration = [decryptedVideo.duration intValue];
                        videoAttachment.dimensions = CGSizeMake([decryptedVideo.w intValue], [decryptedVideo.h intValue]);
                        
                        TGVideoInfo *videoInfo = [[TGVideoInfo alloc] init];
                        
                        NSString *fileUrl = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedVideo.size intValue], encryptedFile.keyFingerprint, [decryptedVideo.key stringByEncodingInHex], [decryptedVideo.iv stringByEncodingInHex]];
                        
                        [videoInfo addVideoWithQuality:1 url:fileUrl size:[decryptedVideo.size intValue]];
                        videoAttachment.videoInfo = videoInfo;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:videoAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:videoAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret23_DecryptedMessageMedia_decryptedMessageMediaDocument class]])
                {
                    Secret23_DecryptedMessageMedia_decryptedMessageMediaDocument *decryptedDocument = (Secret23_DecryptedMessageMedia_decryptedMessageMediaDocument *)concreteMessage.media;
                    
                    TGDocumentMediaAttachment *documentAttachment = [[TGDocumentMediaAttachment alloc] init];
                    
                    int64_t localId = 0;
                    arc4random_buf(&localId, sizeof(localId));
                    
                    NSMutableArray *attributes = [[NSMutableArray alloc] init];
                    [attributes addObject:[[TGDocumentAttributeFilename alloc] initWithFilename:decryptedDocument.fileName]];
                    
                    documentAttachment.localDocumentId = localId;
                    documentAttachment.attributes = attributes;
                    documentAttachment.mimeType = decryptedDocument.mimeType;
                    documentAttachment.size = [decryptedDocument.size intValue];
                    
                    documentAttachment.documentUri = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedDocument.size intValue], encryptedFile.keyFingerprint, [decryptedDocument.key stringByEncodingInHex], [decryptedDocument.iv stringByEncodingInHex]];
                    
                    if (decryptedDocument.thumb != nil && [decryptedDocument.thumbW intValue] > 0 && [decryptedDocument.thumbH intValue] > 0)
                    {
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedDocument.thumbW intValue], [decryptedDocument.thumbH intValue]) url:thumbnailUrl];
                        documentAttachment.thumbnailInfo = imageInfo;
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                         {
                             if (!containsFirst)
                             {
                                 if (decryptedDocument.thumb.length < 128 * 1024)
                                 {
                                     if (TGEnableBlur() && cpuCoreCount() > 1)
                                     {
                                         NSData *data = nil;
                                         TGScaleAndBlurImage(decryptedDocument.thumb, CGSizeZero, &data);
                                         if (data != nil)
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                         else
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedDocument.thumb url:thumbnailUrl availability:TGCacheDisk];
                                     }
                                     else
                                         [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedDocument.thumb url:thumbnailUrl availability:TGCacheDisk];
                                 }
                             }
                         }];
                    }
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:documentAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:documentAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret23_DecryptedMessageMedia_decryptedMessageMediaAudio class]])
                {
                    Secret23_DecryptedMessageMedia_decryptedMessageMediaAudio *decryptedAudio = (Secret23_DecryptedMessageMedia_decryptedMessageMediaAudio *)concreteMessage.media;
                    
                    TGAudioMediaAttachment *audioAttachment = [[TGAudioMediaAttachment alloc] init];
                    
                    int64_t localId = 0;
                    arc4random_buf(&localId, sizeof(localId));
                    
                    audioAttachment.localAudioId = localId;
                    audioAttachment.duration = [decryptedAudio.duration intValue];
                    audioAttachment.fileSize = [decryptedAudio.size intValue];
                    
                    audioAttachment.audioUri = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedAudio.size intValue], encryptedFile.keyFingerprint, [decryptedAudio.key stringByEncodingInHex], [decryptedAudio.iv stringByEncodingInHex]];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:audioAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:audioAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret23_DecryptedMessageMedia_decryptedMessageMediaGeoPoint class]])
                {
                    Secret23_DecryptedMessageMedia_decryptedMessageMediaGeoPoint *concreteGeo = (Secret23_DecryptedMessageMedia_decryptedMessageMediaGeoPoint *)concreteMessage.media;
                    
                    TGLocationMediaAttachment *locationMediaAttachment = [[TGLocationMediaAttachment alloc] init];
                    locationMediaAttachment.latitude = [concreteGeo.lat doubleValue];
                    locationMediaAttachment.longitude = [concreteGeo.plong doubleValue];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:locationMediaAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:locationMediaAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret23_DecryptedMessageMedia_decryptedMessageMediaContact class]])
                {
                    Secret23_DecryptedMessageMedia_decryptedMessageMediaContact *mediaContact = (Secret23_DecryptedMessageMedia_decryptedMessageMediaContact *)concreteMessage.media;
                    
                    TLMessageMedia$messageMediaContact *convertedContact = [[TLMessageMedia$messageMediaContact alloc] init];
                    convertedContact.phone_number = mediaContact.phoneNumber;
                    convertedContact.first_name = mediaContact.firstName;
                    convertedContact.last_name = mediaContact.lastName;
                    convertedContact.user_id = [mediaContact.userId intValue];
                    
                    TGContactMediaAttachment *contactAttachment = [[TGContactMediaAttachment alloc] initWithTelegraphContactDesc:convertedContact];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:contactAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:contactAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret23_DecryptedMessageMedia_decryptedMessageMediaExternalDocument class]])
                {
                    Secret23_DecryptedMessageMedia_decryptedMessageMediaExternalDocument *mediaDocument = (Secret23_DecryptedMessageMedia_decryptedMessageMediaExternalDocument *)concreteMessage.media;
                    
                    TGDocumentMediaAttachment *documentAttachment = [[TGDocumentMediaAttachment alloc] initWithSecret23Desc:mediaDocument];
                    if (documentAttachment != nil)
                    {
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:documentAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:documentAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
            }
        }
        else if ([desc isKindOfClass:[Secret23_DecryptedMessage_decryptedMessageService class]])
        {
            Secret23_DecryptedMessage_decryptedMessageService *concreteMessage = (Secret23_DecryptedMessage_decryptedMessageService *)desc;
            //self.unread = false;
            
            if ([concreteMessage.action isKindOfClass:[Secret23_DecryptedMessageAction_decryptedMessageActionSetMessageTTL class]])
            {
                Secret23_DecryptedMessageAction_decryptedMessageActionSetMessageTTL *concreteAction = (Secret23_DecryptedMessageAction_decryptedMessageActionSetMessageTTL *)concreteMessage.action;
                
                TGActionMediaAttachment *actionAttachment = [[TGActionMediaAttachment alloc] init];
                actionAttachment.actionType = TGMessageActionEncryptedChatMessageLifetime;
                actionAttachment.actionData = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithInt:[concreteAction.ttlSeconds intValue]], @"messageLifetime", nil];
                
                if (mediaAttachments == nil)
                    mediaAttachments = [NSArray arrayWithObject:actionAttachment];
                else
                {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:actionAttachment];
                    mediaAttachments = array;
                }
            }
            else if ([concreteMessage.action isKindOfClass:[Secret23_DecryptedMessageAction_decryptedMessageActionScreenshotMessages class]])
            {
                Secret23_DecryptedMessageAction_decryptedMessageActionScreenshotMessages *concreteAction = (Secret23_DecryptedMessageAction_decryptedMessageActionScreenshotMessages *)concreteMessage.action;
                TGActionMediaAttachment *actionAttachment = [[TGActionMediaAttachment alloc] init];
                actionAttachment.actionType = TGMessageActionEncryptedChatMessageScreenshot;
                actionAttachment.actionData = @{@"randomIds": concreteAction.randomIds};
                
                if (mediaAttachments == nil)
                    mediaAttachments = [NSArray arrayWithObject:actionAttachment];
                else
                {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:actionAttachment];
                    mediaAttachments = array;
                }
            }
        }
        else
            return nil;
        
        if (mediaAttachments != nil)
            self.mediaAttachments = mediaAttachments;
    }
    return self;
}

- (instancetype)initWithDecryptedMessageDesc45:(Secret46_DecryptedMessage *)desc encryptedFile:(TGStoredIncomingMessageFileInfo *)encryptedFile conversationId:(int64_t)conversationId fromUid:(int)fromUid date:(int)date {
    self = [super init];
    if (self != nil)
    {
        self.randomId = (int64_t)[desc.randomId longLongValue];
        self.fromUid = fromUid;
        self.toUid = TGTelegraphInstance.clientUserId;
        self.date = date;
        //self.unread = true;
        self.outgoing = false;
        self.cid = conversationId;
        
        NSArray *mediaAttachments = nil;
        TGMessageEntitiesAttachment *entitiesAttachment = nil;
        NSMutableDictionary *contentProperties = nil;
        
        if ([desc isKindOfClass:[Secret46_DecryptedMessage_decryptedMessage class]])
        {
            Secret46_DecryptedMessage_decryptedMessage *concreteMessage = (Secret46_DecryptedMessage_decryptedMessage *)desc;
            
            self.text = concreteMessage.message;
            self.messageLifetime = [concreteMessage.ttl intValue];
            
            if (concreteMessage.viaBotName.length != 0) {
                TGViaUserAttachment *viaUserAttachment = [[TGViaUserAttachment alloc] initWithUserId:0 username:concreteMessage.viaBotName];
                if (mediaAttachments == nil) {
                    mediaAttachments = [NSArray arrayWithObject:viaUserAttachment];
                } else {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:viaUserAttachment];
                    mediaAttachments = array;
                }
            }
            
            NSMutableArray *entities = [[NSMutableArray alloc] init];
            for (id entity in concreteMessage.entities) {
                if ([entity isKindOfClass:[Secret46_MessageEntity_messageEntityBold class]]) {
                    Secret46_MessageEntity_messageEntityBold *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityBold alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret46_MessageEntity_messageEntityBotCommand class]]) {
                    Secret46_MessageEntity_messageEntityBotCommand *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityBotCommand alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret46_MessageEntity_messageEntityCode class]]) {
                    Secret46_MessageEntity_messageEntityCode *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityCode alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret46_MessageEntity_messageEntityEmail class]]) {
                    Secret46_MessageEntity_messageEntityEmail *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityEmail alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret46_MessageEntity_messageEntityHashtag class]]) {
                    Secret46_MessageEntity_messageEntityHashtag *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityHashtag alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret46_MessageEntity_messageEntityItalic class]]) {
                    Secret46_MessageEntity_messageEntityItalic *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityItalic alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret46_MessageEntity_messageEntityMention class]]) {
                    Secret46_MessageEntity_messageEntityMention *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityMention alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret46_MessageEntity_messageEntityPre class]]) {
                    Secret46_MessageEntity_messageEntityPre *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityPre alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue]) language:concreteEntity.language]];
                } else if ([entity isKindOfClass:[Secret46_MessageEntity_messageEntityTextUrl class]]) {
                    Secret46_MessageEntity_messageEntityTextUrl *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityTextUrl alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue]) url:concreteEntity.url]];
                } else if ([entity isKindOfClass:[Secret46_MessageEntity_messageEntityUrl class]]) {
                    Secret46_MessageEntity_messageEntityUrl *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityUrl alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                }
            }
            
            if (entities.count != 0) {
                entitiesAttachment = [[TGMessageEntitiesAttachment alloc] init];
                entitiesAttachment.entities = entities;
            }
            
            if ([concreteMessage.replyToRandomId longLongValue] != 0) {
                int32_t replyMessageId = [TGDatabaseInstance() messageIdForRandomId:[concreteMessage.replyToRandomId longLongValue]];
                if (replyMessageId != 0) {
                    TGMessage *replyMessage = [TGDatabaseInstance() loadMessageWithMid:replyMessageId peerId:0];
                    if (replyMessage != nil) {
                        TGReplyMessageMediaAttachment *replyAttachment = [[TGReplyMessageMediaAttachment alloc] init];
                        
                        replyAttachment.replyMessage = replyMessage;
                        replyAttachment.replyMessageId = replyMessageId;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:replyAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:replyAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
            }
            
            if (![concreteMessage.media isKindOfClass:[Secret46_DecryptedMessageMedia_decryptedMessageMediaEmpty class]])
            {
                if ([concreteMessage.media isKindOfClass:[Secret46_DecryptedMessageMedia_decryptedMessageMediaPhoto class]])
                {
                    if (encryptedFile != nil)
                    {
                        Secret46_DecryptedMessageMedia_decryptedMessageMediaPhoto *decryptedPhoto = (Secret46_DecryptedMessageMedia_decryptedMessageMediaPhoto *)concreteMessage.media;
                        
                        TGImageMediaAttachment *imageAttachment = [[TGImageMediaAttachment alloc] init];
                        
                        imageAttachment.imageId = encryptedFile.n_id;
                        imageAttachment.accessHash = encryptedFile.accessHash;
                        imageAttachment.caption = decryptedPhoto.caption;
                        
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedPhoto.thumbW intValue], [decryptedPhoto.thumbH intValue]) url:thumbnailUrl];
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                         {
                             if (!containsFirst)
                             {
                                 if (decryptedPhoto.thumb.length < 128 * 1024)
                                 {
                                     if (TGEnableBlur() && cpuCoreCount() > 1)
                                     {
                                         NSData *data = nil;
                                         TGScaleAndBlurImage(decryptedPhoto.thumb, CGSizeZero, &data);
                                         if (data != nil)
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                         else
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedPhoto.thumb url:thumbnailUrl availability:TGCacheDisk];
                                     }
                                     else
                                         [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedPhoto.thumb url:thumbnailUrl availability:TGCacheDisk];
                                 }
                             }
                         }];
                        
                        NSString *fileUrl = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedPhoto.size intValue], encryptedFile.keyFingerprint, [decryptedPhoto.key stringByEncodingInHex], [decryptedPhoto.iv stringByEncodingInHex]];
                        
                        [imageInfo addImageWithSize:CGSizeMake([decryptedPhoto.w intValue], [decryptedPhoto.h intValue]) url:fileUrl fileSize:encryptedFile.size];
                        
                        imageAttachment.imageInfo = imageInfo;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:imageAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:imageAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret46_DecryptedMessageMedia_decryptedMessageMediaVideo class]])
                {
                    if (encryptedFile != nil)
                    {
                        Secret46_DecryptedMessageMedia_decryptedMessageMediaVideo *decryptedVideo = (Secret46_DecryptedMessageMedia_decryptedMessageMediaVideo *)concreteMessage.media;
                        
                        TGVideoMediaAttachment *videoAttachment = [[TGVideoMediaAttachment alloc] init];
                        
                        videoAttachment.videoId = encryptedFile.n_id;
                        videoAttachment.accessHash = encryptedFile.accessHash;
                        videoAttachment.caption = decryptedVideo.caption;
                        
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedVideo.thumbW intValue], [decryptedVideo.thumbH intValue]) url:thumbnailUrl];
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                         {
                             if (!containsFirst)
                             {
                                 if (decryptedVideo.thumb.length < 128 * 1024)
                                 {
                                     if (TGEnableBlur() && cpuCoreCount() > 1)
                                     {
                                         NSData *data = nil;
                                         TGScaleAndBlurImage(decryptedVideo.thumb, CGSizeZero, &data);
                                         if (data != nil)
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                         else
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedVideo.thumb url:thumbnailUrl availability:TGCacheDisk];
                                     }
                                     else
                                         [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedVideo.thumb url:thumbnailUrl availability:TGCacheDisk];
                                 }
                             }
                         }];
                        
                        videoAttachment.thumbnailInfo = imageInfo;
                        
                        videoAttachment.duration = [decryptedVideo.duration intValue];
                        videoAttachment.dimensions = CGSizeMake([decryptedVideo.w intValue], [decryptedVideo.h intValue]);
                        
                        TGVideoInfo *videoInfo = [[TGVideoInfo alloc] init];
                        
                        NSString *fileUrl = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedVideo.size intValue], encryptedFile.keyFingerprint, [decryptedVideo.key stringByEncodingInHex], [decryptedVideo.iv stringByEncodingInHex]];
                        
                        [videoInfo addVideoWithQuality:1 url:fileUrl size:[decryptedVideo.size intValue]];
                        videoAttachment.videoInfo = videoInfo;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:videoAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:videoAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret46_DecryptedMessageMedia_decryptedMessageMediaDocument class]])
                {
                    Secret46_DecryptedMessageMedia_decryptedMessageMediaDocument *decryptedDocument = (Secret46_DecryptedMessageMedia_decryptedMessageMediaDocument *)concreteMessage.media;
                    
                    TGDocumentMediaAttachment *documentAttachment = [[TGDocumentMediaAttachment alloc] init];
                    documentAttachment.caption = decryptedDocument.caption;
                    
                    int64_t localId = 0;
                    arc4random_buf(&localId, sizeof(localId));
                    
                    NSMutableArray *attributes = [[NSMutableArray alloc] init];
                    
                    for (id attributeDesc in decryptedDocument.attributes) {
                        if ([attributeDesc isKindOfClass:[Secret46_DocumentAttribute_documentAttributeAnimated class]]) {
                            [attributes addObject:[[TGDocumentAttributeAnimated alloc] init]];
                        } else if ([attributeDesc isKindOfClass:[Secret46_DocumentAttribute_documentAttributeAudio class]]) {
                            Secret46_DocumentAttribute_documentAttributeAudio *concreteAttribute = attributeDesc;
                            TGAudioWaveform *waveform = nil;
                            if (concreteAttribute.waveform != nil) {
                                waveform = [[TGAudioWaveform alloc] initWithBitstream:concreteAttribute.waveform bitsPerSample:5];
                            }
                            [attributes addObject:[[TGDocumentAttributeAudio alloc] initWithIsVoice:concreteAttribute.flags.intValue & (1 << 10) title:concreteAttribute.title performer:concreteAttribute.performer duration:[concreteAttribute.duration intValue] waveform:waveform]];
                        } else if ([attributeDesc isKindOfClass:[Secret46_DocumentAttribute_documentAttributeFilename class]] ) {
                            Secret46_DocumentAttribute_documentAttributeFilename *concreteAttribute = attributeDesc;
                            [attributes addObject:[[TGDocumentAttributeFilename alloc] initWithFilename:concreteAttribute.fileName]];
                        } else if ([attributeDesc isKindOfClass:[Secret46_DocumentAttribute_documentAttributeImageSize class]]) {
                            Secret46_DocumentAttribute_documentAttributeImageSize *concreteAttribute = attributeDesc;
                            [attributes addObject:[[TGDocumentAttributeImageSize alloc] initWithSize:CGSizeMake([concreteAttribute.w intValue], [concreteAttribute.h intValue])]];
                        } else if ([attributeDesc isKindOfClass:[Secret46_DocumentAttribute_documentAttributeSticker class]]) {
                            Secret46_DocumentAttribute_documentAttributeSticker *concreteAttribute = attributeDesc;
                            TGStickerPackShortnameReference *reference = nil;
                            if ([concreteAttribute.stickerset isKindOfClass:[Secret46_InputStickerSet_inputStickerSetShortName class]]) {
                                Secret46_InputStickerSet_inputStickerSetShortName *concreteStickerSet = (Secret46_InputStickerSet_inputStickerSetShortName *)concreteAttribute.stickerset;
                                reference = [[TGStickerPackShortnameReference alloc] initWithShortName:concreteStickerSet.shortName];
                            }
                            [attributes addObject:[[TGDocumentAttributeSticker alloc] initWithAlt:concreteAttribute.alt packReference:reference mask:nil]];
                        } else if ([attributeDesc isKindOfClass:[Secret46_DocumentAttribute_documentAttributeVideo class]]) {
                            Secret46_DocumentAttribute_documentAttributeVideo *concreteAttribute = attributeDesc;
                            [attributes addObject:[[TGDocumentAttributeVideo alloc] initWithRoundMessage:false size:CGSizeMake([concreteAttribute.w intValue], [concreteAttribute.h intValue]) duration:[concreteAttribute.duration intValue]]];
                        }
                    }
                    
                    documentAttachment.localDocumentId = localId;
                    documentAttachment.attributes = attributes;
                    documentAttachment.mimeType = decryptedDocument.mimeType;
                    documentAttachment.size = [decryptedDocument.size intValue];
                    
                    documentAttachment.documentUri = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedDocument.size intValue], encryptedFile.keyFingerprint, [decryptedDocument.key stringByEncodingInHex], [decryptedDocument.iv stringByEncodingInHex]];
                    
                    if (decryptedDocument.thumb != nil && [decryptedDocument.thumbW intValue] > 0 && [decryptedDocument.thumbH intValue] > 0)
                    {
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedDocument.thumbW intValue], [decryptedDocument.thumbH intValue]) url:thumbnailUrl];
                        documentAttachment.thumbnailInfo = imageInfo;
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                         {
                             if (!containsFirst)
                             {
                                 if (decryptedDocument.thumb.length < 128 * 1024)
                                 {
                                     if (TGEnableBlur() && cpuCoreCount() > 1)
                                     {
                                         NSData *data = nil;
                                         TGScaleAndBlurImage(decryptedDocument.thumb, CGSizeZero, &data);
                                         if (data != nil)
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                         else
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedDocument.thumb url:thumbnailUrl availability:TGCacheDisk];
                                     }
                                     else
                                         [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedDocument.thumb url:thumbnailUrl availability:TGCacheDisk];
                                 }
                             }
                         }];
                    }
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:documentAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:documentAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret46_DecryptedMessageMedia_decryptedMessageMediaAudio class]])
                {
                    Secret46_DecryptedMessageMedia_decryptedMessageMediaAudio *decryptedAudio = (Secret46_DecryptedMessageMedia_decryptedMessageMediaAudio *)concreteMessage.media;
                    
                    TGAudioMediaAttachment *audioAttachment = [[TGAudioMediaAttachment alloc] init];
                    
                    int64_t localId = 0;
                    arc4random_buf(&localId, sizeof(localId));
                    
                    audioAttachment.localAudioId = localId;
                    audioAttachment.duration = [decryptedAudio.duration intValue];
                    audioAttachment.fileSize = [decryptedAudio.size intValue];
                    
                    audioAttachment.audioUri = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedAudio.size intValue], encryptedFile.keyFingerprint, [decryptedAudio.key stringByEncodingInHex], [decryptedAudio.iv stringByEncodingInHex]];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:audioAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:audioAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret46_DecryptedMessageMedia_decryptedMessageMediaGeoPoint class]])
                {
                    Secret46_DecryptedMessageMedia_decryptedMessageMediaGeoPoint *concreteGeo = (Secret46_DecryptedMessageMedia_decryptedMessageMediaGeoPoint *)concreteMessage.media;
                    
                    TGLocationMediaAttachment *locationMediaAttachment = [[TGLocationMediaAttachment alloc] init];
                    locationMediaAttachment.latitude = [concreteGeo.lat doubleValue];
                    locationMediaAttachment.longitude = [concreteGeo.plong doubleValue];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:locationMediaAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:locationMediaAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret46_DecryptedMessageMedia_decryptedMessageMediaContact class]])
                {
                    Secret46_DecryptedMessageMedia_decryptedMessageMediaContact *mediaContact = (Secret46_DecryptedMessageMedia_decryptedMessageMediaContact *)concreteMessage.media;
                    
                    TLMessageMedia$messageMediaContact *convertedContact = [[TLMessageMedia$messageMediaContact alloc] init];
                    convertedContact.phone_number = mediaContact.phoneNumber;
                    convertedContact.first_name = mediaContact.firstName;
                    convertedContact.last_name = mediaContact.lastName;
                    convertedContact.user_id = [mediaContact.userId intValue];
                    
                    TGContactMediaAttachment *contactAttachment = [[TGContactMediaAttachment alloc] initWithTelegraphContactDesc:convertedContact];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:contactAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:contactAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret46_DecryptedMessageMedia_decryptedMessageMediaExternalDocument class]])
                {
                    Secret46_DecryptedMessageMedia_decryptedMessageMediaExternalDocument *mediaDocument = (Secret46_DecryptedMessageMedia_decryptedMessageMediaExternalDocument *)concreteMessage.media;
                    
                    TGDocumentMediaAttachment *documentAttachment = [[TGDocumentMediaAttachment alloc] initWithSecret46ExternalDesc:mediaDocument];
                    if (documentAttachment != nil)
                    {
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:documentAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:documentAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret46_DecryptedMessageMedia_decryptedMessageMediaVenue class]]) {
                    Secret46_DecryptedMessageMedia_decryptedMessageMediaVenue *mediaVenue = (Secret46_DecryptedMessageMedia_decryptedMessageMediaVenue *)concreteMessage.media;
                    
                    TGVenueAttachment *venue = [[TGVenueAttachment alloc] initWithTitle:mediaVenue.title address:mediaVenue.address provider:mediaVenue.provider venueId:mediaVenue.venueId type:nil];
                    TGLocationMediaAttachment *location = [[TGLocationMediaAttachment alloc] init];
                    location.latitude = [mediaVenue.lat doubleValue];
                    location.longitude = [mediaVenue.plong doubleValue];
                    location.venue = venue;
                    if (venue != nil) {
                        if (mediaAttachments == nil) {
                            mediaAttachments = [NSArray arrayWithObject:location];
                        } else {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:location];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret46_DecryptedMessageMedia_decryptedMessageMediaWebPage class]]) {
                    Secret46_DecryptedMessageMedia_decryptedMessageMediaWebPage *mediaWebpage = (Secret46_DecryptedMessageMedia_decryptedMessageMediaWebPage *)concreteMessage.media;
                    
                    TGWebPageMediaAttachment *webpage = [[TGWebPageMediaAttachment alloc] init];
                    int64_t randomId = 0;
                    arc4random_buf(&randomId, 8);
                    webpage.webPageLocalId = randomId;
                    webpage.url = mediaWebpage.url;
                    
                    if (webpage != nil) {
                        if (mediaAttachments == nil) {
                            mediaAttachments = [NSArray arrayWithObject:webpage];
                        } else {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:webpage];
                            mediaAttachments = array;
                        }
                    }
                }
            }
        }
        else if ([desc isKindOfClass:[Secret46_DecryptedMessage_decryptedMessageService class]])
        {
            Secret46_DecryptedMessage_decryptedMessageService *concreteMessage = (Secret46_DecryptedMessage_decryptedMessageService *)desc;
            //self.unread = false;
            
            if ([concreteMessage.action isKindOfClass:[Secret46_DecryptedMessageAction_decryptedMessageActionSetMessageTTL class]])
            {
                Secret46_DecryptedMessageAction_decryptedMessageActionSetMessageTTL *concreteAction = (Secret46_DecryptedMessageAction_decryptedMessageActionSetMessageTTL *)concreteMessage.action;
                
                TGActionMediaAttachment *actionAttachment = [[TGActionMediaAttachment alloc] init];
                actionAttachment.actionType = TGMessageActionEncryptedChatMessageLifetime;
                actionAttachment.actionData = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithInt:[concreteAction.ttlSeconds intValue]], @"messageLifetime", nil];
                
                if (mediaAttachments == nil)
                    mediaAttachments = [NSArray arrayWithObject:actionAttachment];
                else
                {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:actionAttachment];
                    mediaAttachments = array;
                }
            }
            else if ([concreteMessage.action isKindOfClass:[Secret46_DecryptedMessageAction_decryptedMessageActionScreenshotMessages class]])
            {
                Secret46_DecryptedMessageAction_decryptedMessageActionScreenshotMessages *concreteAction = (Secret46_DecryptedMessageAction_decryptedMessageActionScreenshotMessages *)concreteMessage.action;
                TGActionMediaAttachment *actionAttachment = [[TGActionMediaAttachment alloc] init];
                actionAttachment.actionType = TGMessageActionEncryptedChatMessageScreenshot;
                actionAttachment.actionData = @{@"randomIds": concreteAction.randomIds};
                
                if (mediaAttachments == nil)
                    mediaAttachments = [NSArray arrayWithObject:actionAttachment];
                else
                {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:actionAttachment];
                    mediaAttachments = array;
                }
            }
        }
        else
            return nil;
        
        if (entitiesAttachment != nil)
        {
            if (mediaAttachments == nil)
            {
                mediaAttachments = [NSArray arrayWithObject:entitiesAttachment];
            }
            else
            {
                NSMutableArray *array = [[NSMutableArray alloc] init];
                [array addObjectsFromArray:mediaAttachments];
                [array addObject:entitiesAttachment];
                mediaAttachments = array;
            }
        }
        
        if (mediaAttachments != nil)
            self.mediaAttachments = mediaAttachments;
        if (contentProperties != nil) {
            self.contentProperties = contentProperties;
        }
    }
    return self;
}

- (instancetype)initWithDecryptedMessageDesc66:(Secret66_DecryptedMessage *)desc encryptedFile:(TGStoredIncomingMessageFileInfo *)encryptedFile conversationId:(int64_t)conversationId fromUid:(int)fromUid date:(int)date {
    self = [super init];
    if (self != nil)
    {
        self.randomId = (int64_t)[desc.randomId longLongValue];
        self.fromUid = fromUid;
        self.toUid = TGTelegraphInstance.clientUserId;
        self.date = date;
        //self.unread = true;
        self.outgoing = false;
        self.cid = conversationId;
        
        NSArray *mediaAttachments = nil;
        TGMessageEntitiesAttachment *entitiesAttachment = nil;
        NSMutableDictionary *contentProperties = nil;
        
        if ([desc isKindOfClass:[Secret66_DecryptedMessage_decryptedMessage class]])
        {
            Secret66_DecryptedMessage_decryptedMessage *concreteMessage = (Secret66_DecryptedMessage_decryptedMessage *)desc;
            
            self.text = concreteMessage.message;
            self.messageLifetime = [concreteMessage.ttl intValue];
            
            if (concreteMessage.viaBotName.length != 0) {
                TGViaUserAttachment *viaUserAttachment = [[TGViaUserAttachment alloc] initWithUserId:0 username:concreteMessage.viaBotName];
                if (mediaAttachments == nil) {
                    mediaAttachments = [NSArray arrayWithObject:viaUserAttachment];
                } else {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:viaUserAttachment];
                    mediaAttachments = array;
                }
            }
            
            NSMutableArray *entities = [[NSMutableArray alloc] init];
            for (id entity in concreteMessage.entities) {
                if ([entity isKindOfClass:[Secret66_MessageEntity_messageEntityBold class]]) {
                    Secret66_MessageEntity_messageEntityBold *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityBold alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret66_MessageEntity_messageEntityBotCommand class]]) {
                    Secret66_MessageEntity_messageEntityBotCommand *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityBotCommand alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret66_MessageEntity_messageEntityCode class]]) {
                    Secret66_MessageEntity_messageEntityCode *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityCode alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret66_MessageEntity_messageEntityEmail class]]) {
                    Secret66_MessageEntity_messageEntityEmail *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityEmail alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret66_MessageEntity_messageEntityHashtag class]]) {
                    Secret66_MessageEntity_messageEntityHashtag *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityHashtag alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret66_MessageEntity_messageEntityItalic class]]) {
                    Secret66_MessageEntity_messageEntityItalic *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityItalic alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret66_MessageEntity_messageEntityMention class]]) {
                    Secret66_MessageEntity_messageEntityMention *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityMention alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret66_MessageEntity_messageEntityPre class]]) {
                    Secret66_MessageEntity_messageEntityPre *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityPre alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue]) language:concreteEntity.language]];
                } else if ([entity isKindOfClass:[Secret66_MessageEntity_messageEntityTextUrl class]]) {
                    Secret66_MessageEntity_messageEntityTextUrl *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityTextUrl alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue]) url:concreteEntity.url]];
                } else if ([entity isKindOfClass:[Secret66_MessageEntity_messageEntityUrl class]]) {
                    Secret66_MessageEntity_messageEntityUrl *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityUrl alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                }
            }
            
            if (entities.count != 0) {
                entitiesAttachment = [[TGMessageEntitiesAttachment alloc] init];
                entitiesAttachment.entities = entities;
            }
            
            if ([concreteMessage.replyToRandomId longLongValue] != 0) {
                int32_t replyMessageId = [TGDatabaseInstance() messageIdForRandomId:[concreteMessage.replyToRandomId longLongValue]];
                if (replyMessageId != 0) {
                    TGMessage *replyMessage = [TGDatabaseInstance() loadMessageWithMid:replyMessageId peerId:0];
                    if (replyMessage != nil) {
                        TGReplyMessageMediaAttachment *replyAttachment = [[TGReplyMessageMediaAttachment alloc] init];
                        
                        replyAttachment.replyMessage = replyMessage;
                        replyAttachment.replyMessageId = replyMessageId;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:replyAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:replyAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
            }
            
            if (![concreteMessage.media isKindOfClass:[Secret66_DecryptedMessageMedia_decryptedMessageMediaEmpty class]])
            {
                if ([concreteMessage.media isKindOfClass:[Secret66_DecryptedMessageMedia_decryptedMessageMediaPhoto class]])
                {
                    if (encryptedFile != nil)
                    {
                        Secret66_DecryptedMessageMedia_decryptedMessageMediaPhoto *decryptedPhoto = (Secret66_DecryptedMessageMedia_decryptedMessageMediaPhoto *)concreteMessage.media;
                        
                        TGImageMediaAttachment *imageAttachment = [[TGImageMediaAttachment alloc] init];
                        
                        imageAttachment.imageId = encryptedFile.n_id;
                        imageAttachment.accessHash = encryptedFile.accessHash;
                        imageAttachment.caption = decryptedPhoto.caption;
                        
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedPhoto.thumbW intValue], [decryptedPhoto.thumbH intValue]) url:thumbnailUrl];
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                         {
                             if (!containsFirst)
                             {
                                 if (decryptedPhoto.thumb.length < 128 * 1024)
                                 {
                                     if (TGEnableBlur() && cpuCoreCount() > 1)
                                     {
                                         NSData *data = nil;
                                         TGScaleAndBlurImage(decryptedPhoto.thumb, CGSizeZero, &data);
                                         if (data != nil)
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                         else
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedPhoto.thumb url:thumbnailUrl availability:TGCacheDisk];
                                     }
                                     else
                                         [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedPhoto.thumb url:thumbnailUrl availability:TGCacheDisk];
                                 }
                             }
                         }];
                        
                        NSString *fileUrl = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedPhoto.size intValue], encryptedFile.keyFingerprint, [decryptedPhoto.key stringByEncodingInHex], [decryptedPhoto.iv stringByEncodingInHex]];
                        
                        [imageInfo addImageWithSize:CGSizeMake([decryptedPhoto.w intValue], [decryptedPhoto.h intValue]) url:fileUrl fileSize:encryptedFile.size];
                        
                        imageAttachment.imageInfo = imageInfo;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:imageAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:imageAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret66_DecryptedMessageMedia_decryptedMessageMediaVideo class]])
                {
                    if (encryptedFile != nil)
                    {
                        Secret66_DecryptedMessageMedia_decryptedMessageMediaVideo *decryptedVideo = (Secret66_DecryptedMessageMedia_decryptedMessageMediaVideo *)concreteMessage.media;
                        
                        TGVideoMediaAttachment *videoAttachment = [[TGVideoMediaAttachment alloc] init];
                        
                        videoAttachment.videoId = encryptedFile.n_id;
                        videoAttachment.accessHash = encryptedFile.accessHash;
                        videoAttachment.caption = decryptedVideo.caption;
                        
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedVideo.thumbW intValue], [decryptedVideo.thumbH intValue]) url:thumbnailUrl];
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                         {
                             if (!containsFirst)
                             {
                                 if (decryptedVideo.thumb.length < 128 * 1024)
                                 {
                                     if (TGEnableBlur() && cpuCoreCount() > 1)
                                     {
                                         NSData *data = nil;
                                         TGScaleAndBlurImage(decryptedVideo.thumb, CGSizeZero, &data);
                                         if (data != nil)
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                         else
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedVideo.thumb url:thumbnailUrl availability:TGCacheDisk];
                                     }
                                     else
                                         [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedVideo.thumb url:thumbnailUrl availability:TGCacheDisk];
                                 }
                             }
                         }];
                        
                        videoAttachment.thumbnailInfo = imageInfo;
                        
                        videoAttachment.duration = [decryptedVideo.duration intValue];
                        videoAttachment.dimensions = CGSizeMake([decryptedVideo.w intValue], [decryptedVideo.h intValue]);
                        
                        TGVideoInfo *videoInfo = [[TGVideoInfo alloc] init];
                        
                        NSString *fileUrl = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedVideo.size intValue], encryptedFile.keyFingerprint, [decryptedVideo.key stringByEncodingInHex], [decryptedVideo.iv stringByEncodingInHex]];
                        
                        [videoInfo addVideoWithQuality:1 url:fileUrl size:[decryptedVideo.size intValue]];
                        videoAttachment.videoInfo = videoInfo;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:videoAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:videoAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret66_DecryptedMessageMedia_decryptedMessageMediaDocument class]])
                {
                    Secret66_DecryptedMessageMedia_decryptedMessageMediaDocument *decryptedDocument = (Secret66_DecryptedMessageMedia_decryptedMessageMediaDocument *)concreteMessage.media;
                    
                    TGDocumentMediaAttachment *documentAttachment = [[TGDocumentMediaAttachment alloc] init];
                    documentAttachment.caption = decryptedDocument.caption;
                    
                    int64_t localId = 0;
                    arc4random_buf(&localId, sizeof(localId));
                    
                    NSMutableArray *attributes = [[NSMutableArray alloc] init];
                    
                    TGDocumentAttributeAnimated *animatedAttribute = nil;
                    TGDocumentAttributeVideo *videoAttribute = nil;
                    
                    for (id attributeDesc in decryptedDocument.attributes) {
                        if ([attributeDesc isKindOfClass:[Secret66_DocumentAttribute_documentAttributeAnimated class]]) {
                            animatedAttribute = [[TGDocumentAttributeAnimated alloc] init];
                            [attributes addObject:animatedAttribute];
                        } else if ([attributeDesc isKindOfClass:[Secret66_DocumentAttribute_documentAttributeAudio class]]) {
                            Secret66_DocumentAttribute_documentAttributeAudio *concreteAttribute = attributeDesc;
                            TGAudioWaveform *waveform = nil;
                            if (concreteAttribute.waveform != nil) {
                                waveform = [[TGAudioWaveform alloc] initWithBitstream:concreteAttribute.waveform bitsPerSample:5];
                            }
                            [attributes addObject:[[TGDocumentAttributeAudio alloc] initWithIsVoice:concreteAttribute.flags.intValue & (1 << 10) title:concreteAttribute.title performer:concreteAttribute.performer duration:[concreteAttribute.duration intValue] waveform:waveform]];
                        } else if ([attributeDesc isKindOfClass:[Secret66_DocumentAttribute_documentAttributeFilename class]] ) {
                            Secret66_DocumentAttribute_documentAttributeFilename *concreteAttribute = attributeDesc;
                            [attributes addObject:[[TGDocumentAttributeFilename alloc] initWithFilename:concreteAttribute.fileName]];
                        } else if ([attributeDesc isKindOfClass:[Secret66_DocumentAttribute_documentAttributeImageSize class]]) {
                            Secret66_DocumentAttribute_documentAttributeImageSize *concreteAttribute = attributeDesc;
                            [attributes addObject:[[TGDocumentAttributeImageSize alloc] initWithSize:CGSizeMake([concreteAttribute.w intValue], [concreteAttribute.h intValue])]];
                        } else if ([attributeDesc isKindOfClass:[Secret66_DocumentAttribute_documentAttributeSticker class]]) {
                            Secret66_DocumentAttribute_documentAttributeSticker *concreteAttribute = attributeDesc;
                            TGStickerPackShortnameReference *reference = nil;
                            if ([concreteAttribute.stickerset isKindOfClass:[Secret66_InputStickerSet_inputStickerSetShortName class]]) {
                                Secret66_InputStickerSet_inputStickerSetShortName *concreteStickerSet = (Secret66_InputStickerSet_inputStickerSetShortName *)concreteAttribute.stickerset;
                                reference = [[TGStickerPackShortnameReference alloc] initWithShortName:concreteStickerSet.shortName];
                            }
                            [attributes addObject:[[TGDocumentAttributeSticker alloc] initWithAlt:concreteAttribute.alt packReference:reference mask:nil]];
                        } else if ([attributeDesc isKindOfClass:[Secret66_DocumentAttribute_documentAttributeVideo class]]) {
                            Secret66_DocumentAttribute_documentAttributeVideo *concreteAttribute = attributeDesc;
                            videoAttribute = [[TGDocumentAttributeVideo alloc] initWithRoundMessage:concreteAttribute.flags.intValue & (1 << 0) size:CGSizeMake([concreteAttribute.w intValue], [concreteAttribute.h intValue]) duration:[concreteAttribute.duration intValue]];
                            [attributes addObject:videoAttribute];
                        }
                    }
                    
                    documentAttachment.localDocumentId = localId;
                    documentAttachment.attributes = attributes;
                    documentAttachment.mimeType = decryptedDocument.mimeType;
                    documentAttachment.size = [decryptedDocument.size intValue];
                    
                    documentAttachment.documentUri = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedDocument.size intValue], encryptedFile.keyFingerprint, [decryptedDocument.key stringByEncodingInHex], [decryptedDocument.iv stringByEncodingInHex]];
                    
                    if (decryptedDocument.thumb != nil && [decryptedDocument.thumbW intValue] > 0 && [decryptedDocument.thumbH intValue] > 0)
                    {
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedDocument.thumbW intValue], [decryptedDocument.thumbH intValue]) url:thumbnailUrl];
                        documentAttachment.thumbnailInfo = imageInfo;
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                         {
                             if (!containsFirst)
                             {
                                 if (decryptedDocument.thumb.length < 128 * 1024)
                                 {
                                     if (TGEnableBlur() && cpuCoreCount() > 1)
                                     {
                                         NSData *data = nil;
                                         TGScaleAndBlurImage(decryptedDocument.thumb, CGSizeZero, &data);
                                         if (data != nil)
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                         else
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedDocument.thumb url:thumbnailUrl availability:TGCacheDisk];
                                     }
                                     else
                                         [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedDocument.thumb url:thumbnailUrl availability:TGCacheDisk];
                                 }
                             }
                         }];
                    }
                    
                    if (videoAttribute != nil && animatedAttribute == nil) {
                        TGVideoMediaAttachment *videoMedia = [[TGVideoMediaAttachment alloc] init];
                        videoMedia.videoId = encryptedFile.n_id;
                        videoMedia.localVideoId = documentAttachment.localDocumentId;
                        videoMedia.accessHash = documentAttachment.accessHash;
                        videoMedia.duration = videoAttribute.duration;
                        videoMedia.dimensions = videoAttribute.size;
                        videoMedia.thumbnailInfo = documentAttachment.thumbnailInfo;
                        videoMedia.caption = documentAttachment.caption;
                        videoMedia.roundMessage = videoAttribute.isRoundMessage;
                        
                        TGVideoInfo *videoInfo = [[TGVideoInfo alloc] init];
                        [videoInfo addVideoWithQuality:1 url:documentAttachment.documentUri size:documentAttachment.size];
                        videoMedia.videoInfo = videoInfo;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:videoMedia];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:videoMedia];
                            mediaAttachments = array;
                        }
                    } else {
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:documentAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:documentAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret66_DecryptedMessageMedia_decryptedMessageMediaAudio class]])
                {
                    Secret66_DecryptedMessageMedia_decryptedMessageMediaAudio *decryptedAudio = (Secret66_DecryptedMessageMedia_decryptedMessageMediaAudio *)concreteMessage.media;
                    
                    TGAudioMediaAttachment *audioAttachment = [[TGAudioMediaAttachment alloc] init];
                    
                    int64_t localId = 0;
                    arc4random_buf(&localId, sizeof(localId));
                    
                    audioAttachment.localAudioId = localId;
                    audioAttachment.duration = [decryptedAudio.duration intValue];
                    audioAttachment.fileSize = [decryptedAudio.size intValue];
                    
                    audioAttachment.audioUri = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedAudio.size intValue], encryptedFile.keyFingerprint, [decryptedAudio.key stringByEncodingInHex], [decryptedAudio.iv stringByEncodingInHex]];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:audioAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:audioAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret66_DecryptedMessageMedia_decryptedMessageMediaGeoPoint class]])
                {
                    Secret66_DecryptedMessageMedia_decryptedMessageMediaGeoPoint *concreteGeo = (Secret66_DecryptedMessageMedia_decryptedMessageMediaGeoPoint *)concreteMessage.media;
                    
                    TGLocationMediaAttachment *locationMediaAttachment = [[TGLocationMediaAttachment alloc] init];
                    locationMediaAttachment.latitude = [concreteGeo.lat doubleValue];
                    locationMediaAttachment.longitude = [concreteGeo.plong doubleValue];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:locationMediaAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:locationMediaAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret66_DecryptedMessageMedia_decryptedMessageMediaContact class]])
                {
                    Secret66_DecryptedMessageMedia_decryptedMessageMediaContact *mediaContact = (Secret66_DecryptedMessageMedia_decryptedMessageMediaContact *)concreteMessage.media;
                    
                    TLMessageMedia$messageMediaContact *convertedContact = [[TLMessageMedia$messageMediaContact alloc] init];
                    convertedContact.phone_number = mediaContact.phoneNumber;
                    convertedContact.first_name = mediaContact.firstName;
                    convertedContact.last_name = mediaContact.lastName;
                    convertedContact.user_id = [mediaContact.userId intValue];
                    
                    TGContactMediaAttachment *contactAttachment = [[TGContactMediaAttachment alloc] initWithTelegraphContactDesc:convertedContact];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:contactAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:contactAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret66_DecryptedMessageMedia_decryptedMessageMediaExternalDocument class]])
                {
                    Secret66_DecryptedMessageMedia_decryptedMessageMediaExternalDocument *mediaDocument = (Secret66_DecryptedMessageMedia_decryptedMessageMediaExternalDocument *)concreteMessage.media;
                    
                    TGDocumentMediaAttachment *documentAttachment = [[TGDocumentMediaAttachment alloc] initWithSecret66ExternalDesc:mediaDocument];
                    if (documentAttachment != nil)
                    {
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:documentAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:documentAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret66_DecryptedMessageMedia_decryptedMessageMediaVenue class]]) {
                    Secret66_DecryptedMessageMedia_decryptedMessageMediaVenue *mediaVenue = (Secret66_DecryptedMessageMedia_decryptedMessageMediaVenue *)concreteMessage.media;
                    
                    TGVenueAttachment *venue = [[TGVenueAttachment alloc] initWithTitle:mediaVenue.title address:mediaVenue.address provider:mediaVenue.provider venueId:mediaVenue.venueId type:nil];
                    TGLocationMediaAttachment *location = [[TGLocationMediaAttachment alloc] init];
                    location.latitude = [mediaVenue.lat doubleValue];
                    location.longitude = [mediaVenue.plong doubleValue];
                    location.venue = venue;
                    if (venue != nil) {
                        if (mediaAttachments == nil) {
                            mediaAttachments = [NSArray arrayWithObject:location];
                        } else {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:location];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret66_DecryptedMessageMedia_decryptedMessageMediaWebPage class]]) {
                    Secret66_DecryptedMessageMedia_decryptedMessageMediaWebPage *mediaWebpage = (Secret66_DecryptedMessageMedia_decryptedMessageMediaWebPage *)concreteMessage.media;
                    
                    TGWebPageMediaAttachment *webpage = [[TGWebPageMediaAttachment alloc] init];
                    int64_t randomId = 0;
                    arc4random_buf(&randomId, 8);
                    webpage.webPageLocalId = randomId;
                    webpage.url = mediaWebpage.url;
                    
                    if (webpage != nil) {
                        if (mediaAttachments == nil) {
                            mediaAttachments = [NSArray arrayWithObject:webpage];
                        } else {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:webpage];
                            mediaAttachments = array;
                        }
                    }
                }
            }
        }
        else if ([desc isKindOfClass:[Secret66_DecryptedMessage_decryptedMessageService class]])
        {
            Secret66_DecryptedMessage_decryptedMessageService *concreteMessage = (Secret66_DecryptedMessage_decryptedMessageService *)desc;
            //self.unread = false;
            
            if ([concreteMessage.action isKindOfClass:[Secret66_DecryptedMessageAction_decryptedMessageActionSetMessageTTL class]])
            {
                Secret66_DecryptedMessageAction_decryptedMessageActionSetMessageTTL *concreteAction = (Secret66_DecryptedMessageAction_decryptedMessageActionSetMessageTTL *)concreteMessage.action;
                
                TGActionMediaAttachment *actionAttachment = [[TGActionMediaAttachment alloc] init];
                actionAttachment.actionType = TGMessageActionEncryptedChatMessageLifetime;
                actionAttachment.actionData = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithInt:[concreteAction.ttlSeconds intValue]], @"messageLifetime", nil];
                
                if (mediaAttachments == nil)
                    mediaAttachments = [NSArray arrayWithObject:actionAttachment];
                else
                {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:actionAttachment];
                    mediaAttachments = array;
                }
            }
            else if ([concreteMessage.action isKindOfClass:[Secret66_DecryptedMessageAction_decryptedMessageActionScreenshotMessages class]])
            {
                Secret66_DecryptedMessageAction_decryptedMessageActionScreenshotMessages *concreteAction = (Secret66_DecryptedMessageAction_decryptedMessageActionScreenshotMessages *)concreteMessage.action;
                TGActionMediaAttachment *actionAttachment = [[TGActionMediaAttachment alloc] init];
                actionAttachment.actionType = TGMessageActionEncryptedChatMessageScreenshot;
                actionAttachment.actionData = @{@"randomIds": concreteAction.randomIds};
                
                if (mediaAttachments == nil)
                    mediaAttachments = [NSArray arrayWithObject:actionAttachment];
                else
                {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:actionAttachment];
                    mediaAttachments = array;
                }
            }
        }
        else
            return nil;
        
        if (entitiesAttachment != nil)
        {
            if (mediaAttachments == nil)
            {
                mediaAttachments = [NSArray arrayWithObject:entitiesAttachment];
            }
            else
            {
                NSMutableArray *array = [[NSMutableArray alloc] init];
                [array addObjectsFromArray:mediaAttachments];
                [array addObject:entitiesAttachment];
                mediaAttachments = array;
            }
        }
        
        if (mediaAttachments != nil)
            self.mediaAttachments = mediaAttachments;
        if (contentProperties != nil) {
            self.contentProperties = contentProperties;
        }
    }
    return self;
}

- (instancetype)initWithDecryptedMessageDesc73:(Secret73_DecryptedMessage *)desc encryptedFile:(TGStoredIncomingMessageFileInfo *)encryptedFile conversationId:(int64_t)conversationId fromUid:(int)fromUid date:(int)date {
    self = [super init];
    if (self != nil)
    {
        self.randomId = (int64_t)[desc.randomId longLongValue];
        self.fromUid = fromUid;
        self.toUid = TGTelegraphInstance.clientUserId;
        self.date = date;
        //self.unread = true;
        self.outgoing = false;
        self.cid = conversationId;
        
        NSArray *mediaAttachments = nil;
        TGMessageEntitiesAttachment *entitiesAttachment = nil;
        NSMutableDictionary *contentProperties = nil;
        
        if ([desc isKindOfClass:[Secret73_DecryptedMessage_decryptedMessage class]])
        {
            Secret73_DecryptedMessage_decryptedMessage *concreteMessage = (Secret73_DecryptedMessage_decryptedMessage *)desc;
            
            self.groupedId = [concreteMessage.groupedId longLongValue];
            
            self.text = concreteMessage.message;
            self.messageLifetime = [concreteMessage.ttl intValue];
            
            if (concreteMessage.viaBotName.length != 0) {
                TGViaUserAttachment *viaUserAttachment = [[TGViaUserAttachment alloc] initWithUserId:0 username:concreteMessage.viaBotName];
                if (mediaAttachments == nil) {
                    mediaAttachments = [NSArray arrayWithObject:viaUserAttachment];
                } else {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:viaUserAttachment];
                    mediaAttachments = array;
                }
            }
            
            NSMutableArray *entities = [[NSMutableArray alloc] init];
            for (id entity in concreteMessage.entities) {
                if ([entity isKindOfClass:[Secret73_MessageEntity_messageEntityBold class]]) {
                    Secret73_MessageEntity_messageEntityBold *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityBold alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret73_MessageEntity_messageEntityBotCommand class]]) {
                    Secret73_MessageEntity_messageEntityBotCommand *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityBotCommand alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret73_MessageEntity_messageEntityCode class]]) {
                    Secret73_MessageEntity_messageEntityCode *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityCode alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret73_MessageEntity_messageEntityEmail class]]) {
                    Secret73_MessageEntity_messageEntityEmail *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityEmail alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret73_MessageEntity_messageEntityHashtag class]]) {
                    Secret73_MessageEntity_messageEntityHashtag *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityHashtag alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret73_MessageEntity_messageEntityItalic class]]) {
                    Secret73_MessageEntity_messageEntityItalic *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityItalic alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret73_MessageEntity_messageEntityMention class]]) {
                    Secret73_MessageEntity_messageEntityMention *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityMention alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                } else if ([entity isKindOfClass:[Secret73_MessageEntity_messageEntityPre class]]) {
                    Secret73_MessageEntity_messageEntityPre *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityPre alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue]) language:concreteEntity.language]];
                } else if ([entity isKindOfClass:[Secret73_MessageEntity_messageEntityTextUrl class]]) {
                    Secret73_MessageEntity_messageEntityTextUrl *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityTextUrl alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue]) url:concreteEntity.url]];
                } else if ([entity isKindOfClass:[Secret73_MessageEntity_messageEntityUrl class]]) {
                    Secret73_MessageEntity_messageEntityUrl *concreteEntity = entity;
                    [entities addObject:[[TGMessageEntityUrl alloc] initWithRange:NSMakeRange([concreteEntity.offset intValue], [concreteEntity.length intValue])]];
                }
            }
            
            if (entities.count != 0) {
                entitiesAttachment = [[TGMessageEntitiesAttachment alloc] init];
                entitiesAttachment.entities = entities;
            }
            
            if ([concreteMessage.replyToRandomId longLongValue] != 0) {
                int32_t replyMessageId = [TGDatabaseInstance() messageIdForRandomId:[concreteMessage.replyToRandomId longLongValue]];
                if (replyMessageId != 0) {
                    TGMessage *replyMessage = [TGDatabaseInstance() loadMessageWithMid:replyMessageId peerId:0];
                    if (replyMessage != nil) {
                        TGReplyMessageMediaAttachment *replyAttachment = [[TGReplyMessageMediaAttachment alloc] init];
                        
                        replyAttachment.replyMessage = replyMessage;
                        replyAttachment.replyMessageId = replyMessageId;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:replyAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:replyAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
            }
            
            if (![concreteMessage.media isKindOfClass:[Secret73_DecryptedMessageMedia_decryptedMessageMediaEmpty class]])
            {
                if ([concreteMessage.media isKindOfClass:[Secret73_DecryptedMessageMedia_decryptedMessageMediaPhoto class]])
                {
                    if (encryptedFile != nil)
                    {
                        Secret73_DecryptedMessageMedia_decryptedMessageMediaPhoto *decryptedPhoto = (Secret73_DecryptedMessageMedia_decryptedMessageMediaPhoto *)concreteMessage.media;
                        
                        TGImageMediaAttachment *imageAttachment = [[TGImageMediaAttachment alloc] init];
                        
                        imageAttachment.imageId = encryptedFile.n_id;
                        imageAttachment.accessHash = encryptedFile.accessHash;
                        imageAttachment.caption = decryptedPhoto.caption;
                        
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedPhoto.thumbW intValue], [decryptedPhoto.thumbH intValue]) url:thumbnailUrl];
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                         {
                             if (!containsFirst)
                             {
                                 if (decryptedPhoto.thumb.length < 128 * 1024)
                                 {
                                     if (TGEnableBlur() && cpuCoreCount() > 1)
                                     {
                                         NSData *data = nil;
                                         TGScaleAndBlurImage(decryptedPhoto.thumb, CGSizeZero, &data);
                                         if (data != nil)
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                         else
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedPhoto.thumb url:thumbnailUrl availability:TGCacheDisk];
                                     }
                                     else
                                         [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedPhoto.thumb url:thumbnailUrl availability:TGCacheDisk];
                                 }
                             }
                         }];
                        
                        NSString *fileUrl = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedPhoto.size intValue], encryptedFile.keyFingerprint, [decryptedPhoto.key stringByEncodingInHex], [decryptedPhoto.iv stringByEncodingInHex]];
                        
                        [imageInfo addImageWithSize:CGSizeMake([decryptedPhoto.w intValue], [decryptedPhoto.h intValue]) url:fileUrl fileSize:encryptedFile.size];
                        
                        imageAttachment.imageInfo = imageInfo;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:imageAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:imageAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret73_DecryptedMessageMedia_decryptedMessageMediaVideo class]])
                {
                    if (encryptedFile != nil)
                    {
                        Secret73_DecryptedMessageMedia_decryptedMessageMediaVideo *decryptedVideo = (Secret73_DecryptedMessageMedia_decryptedMessageMediaVideo *)concreteMessage.media;
                        
                        TGVideoMediaAttachment *videoAttachment = [[TGVideoMediaAttachment alloc] init];
                        
                        videoAttachment.videoId = encryptedFile.n_id;
                        videoAttachment.accessHash = encryptedFile.accessHash;
                        videoAttachment.caption = decryptedVideo.caption;
                        
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedVideo.thumbW intValue], [decryptedVideo.thumbH intValue]) url:thumbnailUrl];
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                         {
                             if (!containsFirst)
                             {
                                 if (decryptedVideo.thumb.length < 128 * 1024)
                                 {
                                     if (TGEnableBlur() && cpuCoreCount() > 1)
                                     {
                                         NSData *data = nil;
                                         TGScaleAndBlurImage(decryptedVideo.thumb, CGSizeZero, &data);
                                         if (data != nil)
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                         else
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedVideo.thumb url:thumbnailUrl availability:TGCacheDisk];
                                     }
                                     else
                                         [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedVideo.thumb url:thumbnailUrl availability:TGCacheDisk];
                                 }
                             }
                         }];
                        
                        videoAttachment.thumbnailInfo = imageInfo;
                        
                        videoAttachment.duration = [decryptedVideo.duration intValue];
                        videoAttachment.dimensions = CGSizeMake([decryptedVideo.w intValue], [decryptedVideo.h intValue]);
                        
                        TGVideoInfo *videoInfo = [[TGVideoInfo alloc] init];
                        
                        NSString *fileUrl = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedVideo.size intValue], encryptedFile.keyFingerprint, [decryptedVideo.key stringByEncodingInHex], [decryptedVideo.iv stringByEncodingInHex]];
                        
                        [videoInfo addVideoWithQuality:1 url:fileUrl size:[decryptedVideo.size intValue]];
                        videoAttachment.videoInfo = videoInfo;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:videoAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:videoAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret73_DecryptedMessageMedia_decryptedMessageMediaDocument class]])
                {
                    Secret73_DecryptedMessageMedia_decryptedMessageMediaDocument *decryptedDocument = (Secret73_DecryptedMessageMedia_decryptedMessageMediaDocument *)concreteMessage.media;
                    
                    TGDocumentMediaAttachment *documentAttachment = [[TGDocumentMediaAttachment alloc] init];
                    documentAttachment.caption = decryptedDocument.caption;
                    
                    int64_t localId = 0;
                    arc4random_buf(&localId, sizeof(localId));
                    
                    NSMutableArray *attributes = [[NSMutableArray alloc] init];
                    
                    TGDocumentAttributeAnimated *animatedAttribute = nil;
                    TGDocumentAttributeVideo *videoAttribute = nil;
                    
                    for (id attributeDesc in decryptedDocument.attributes) {
                        if ([attributeDesc isKindOfClass:[Secret73_DocumentAttribute_documentAttributeAnimated class]]) {
                            animatedAttribute = [[TGDocumentAttributeAnimated alloc] init];
                            [attributes addObject:animatedAttribute];
                        } else if ([attributeDesc isKindOfClass:[Secret73_DocumentAttribute_documentAttributeAudio class]]) {
                            Secret73_DocumentAttribute_documentAttributeAudio *concreteAttribute = attributeDesc;
                            TGAudioWaveform *waveform = nil;
                            if (concreteAttribute.waveform != nil) {
                                waveform = [[TGAudioWaveform alloc] initWithBitstream:concreteAttribute.waveform bitsPerSample:5];
                            }
                            [attributes addObject:[[TGDocumentAttributeAudio alloc] initWithIsVoice:concreteAttribute.flags.intValue & (1 << 10) title:concreteAttribute.title performer:concreteAttribute.performer duration:[concreteAttribute.duration intValue] waveform:waveform]];
                        } else if ([attributeDesc isKindOfClass:[Secret73_DocumentAttribute_documentAttributeFilename class]] ) {
                            Secret73_DocumentAttribute_documentAttributeFilename *concreteAttribute = attributeDesc;
                            [attributes addObject:[[TGDocumentAttributeFilename alloc] initWithFilename:concreteAttribute.fileName]];
                        } else if ([attributeDesc isKindOfClass:[Secret73_DocumentAttribute_documentAttributeImageSize class]]) {
                            Secret73_DocumentAttribute_documentAttributeImageSize *concreteAttribute = attributeDesc;
                            [attributes addObject:[[TGDocumentAttributeImageSize alloc] initWithSize:CGSizeMake([concreteAttribute.w intValue], [concreteAttribute.h intValue])]];
                        } else if ([attributeDesc isKindOfClass:[Secret73_DocumentAttribute_documentAttributeSticker class]]) {
                            Secret73_DocumentAttribute_documentAttributeSticker *concreteAttribute = attributeDesc;
                            TGStickerPackShortnameReference *reference = nil;
                            if ([concreteAttribute.stickerset isKindOfClass:[Secret73_InputStickerSet_inputStickerSetShortName class]]) {
                                Secret73_InputStickerSet_inputStickerSetShortName *concreteStickerSet = (Secret73_InputStickerSet_inputStickerSetShortName *)concreteAttribute.stickerset;
                                reference = [[TGStickerPackShortnameReference alloc] initWithShortName:concreteStickerSet.shortName];
                            }
                            [attributes addObject:[[TGDocumentAttributeSticker alloc] initWithAlt:concreteAttribute.alt packReference:reference mask:nil]];
                        } else if ([attributeDesc isKindOfClass:[Secret73_DocumentAttribute_documentAttributeVideo class]]) {
                            Secret73_DocumentAttribute_documentAttributeVideo *concreteAttribute = attributeDesc;
                            videoAttribute = [[TGDocumentAttributeVideo alloc] initWithRoundMessage:concreteAttribute.flags.intValue & (1 << 0) size:CGSizeMake([concreteAttribute.w intValue], [concreteAttribute.h intValue]) duration:[concreteAttribute.duration intValue]];
                            [attributes addObject:videoAttribute];
                        }
                    }
                    
                    documentAttachment.localDocumentId = localId;
                    documentAttachment.attributes = attributes;
                    documentAttachment.mimeType = decryptedDocument.mimeType;
                    documentAttachment.size = [decryptedDocument.size intValue];
                    
                    documentAttachment.documentUri = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedDocument.size intValue], encryptedFile.keyFingerprint, [decryptedDocument.key stringByEncodingInHex], [decryptedDocument.iv stringByEncodingInHex]];
                    
                    if (decryptedDocument.thumb != nil && [decryptedDocument.thumbW intValue] > 0 && [decryptedDocument.thumbH intValue] > 0)
                    {
                        NSString *thumbnailUrl = [[NSString alloc] initWithFormat:@"encryptedThumbnail:%lld", encryptedFile.n_id];
                        
                        TGImageInfo *imageInfo = [[TGImageInfo alloc] init];
                        [imageInfo addImageWithSize:CGSizeMake([decryptedDocument.thumbW intValue], [decryptedDocument.thumbH intValue]) url:thumbnailUrl];
                        documentAttachment.thumbnailInfo = imageInfo;
                        
                        [[TGRemoteImageView sharedCache] diskCacheContains:thumbnailUrl orUrl:nil completion:^(bool containsFirst, __unused bool containsSecond)
                         {
                             if (!containsFirst)
                             {
                                 if (decryptedDocument.thumb.length < 128 * 1024)
                                 {
                                     if (TGEnableBlur() && cpuCoreCount() > 1)
                                     {
                                         NSData *data = nil;
                                         TGScaleAndBlurImage(decryptedDocument.thumb, CGSizeZero, &data);
                                         if (data != nil)
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:data url:thumbnailUrl availability:TGCacheDisk];
                                         else
                                             [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedDocument.thumb url:thumbnailUrl availability:TGCacheDisk];
                                     }
                                     else
                                         [[TGRemoteImageView sharedCache] cacheImage:nil withData:decryptedDocument.thumb url:thumbnailUrl availability:TGCacheDisk];
                                 }
                             }
                         }];
                    }
                    
                    if (videoAttribute != nil && animatedAttribute == nil) {
                        TGVideoMediaAttachment *videoMedia = [[TGVideoMediaAttachment alloc] init];
                        videoMedia.videoId = encryptedFile.n_id;
                        videoMedia.localVideoId = documentAttachment.localDocumentId;
                        videoMedia.accessHash = documentAttachment.accessHash;
                        videoMedia.duration = videoAttribute.duration;
                        videoMedia.dimensions = videoAttribute.size;
                        videoMedia.thumbnailInfo = documentAttachment.thumbnailInfo;
                        videoMedia.caption = documentAttachment.caption;
                        videoMedia.roundMessage = videoAttribute.isRoundMessage;
                        
                        TGVideoInfo *videoInfo = [[TGVideoInfo alloc] init];
                        [videoInfo addVideoWithQuality:1 url:documentAttachment.documentUri size:documentAttachment.size];
                        videoMedia.videoInfo = videoInfo;
                        
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:videoMedia];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:videoMedia];
                            mediaAttachments = array;
                        }
                    } else {
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:documentAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:documentAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret73_DecryptedMessageMedia_decryptedMessageMediaAudio class]])
                {
                    Secret73_DecryptedMessageMedia_decryptedMessageMediaAudio *decryptedAudio = (Secret73_DecryptedMessageMedia_decryptedMessageMediaAudio *)concreteMessage.media;
                    
                    TGAudioMediaAttachment *audioAttachment = [[TGAudioMediaAttachment alloc] init];
                    
                    int64_t localId = 0;
                    arc4random_buf(&localId, sizeof(localId));
                    
                    audioAttachment.localAudioId = localId;
                    audioAttachment.duration = [decryptedAudio.duration intValue];
                    audioAttachment.fileSize = [decryptedAudio.size intValue];
                    
                    audioAttachment.audioUri = [[NSString alloc] initWithFormat:@"mt-encrypted-file://?dc=%d&id=%lld&accessHash=%lld&size=%d&decryptedSize=%d&fingerprint=%d&key=%@%@", encryptedFile.datacenterId, encryptedFile.n_id, encryptedFile.accessHash, encryptedFile.size, [decryptedAudio.size intValue], encryptedFile.keyFingerprint, [decryptedAudio.key stringByEncodingInHex], [decryptedAudio.iv stringByEncodingInHex]];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:audioAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:audioAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret73_DecryptedMessageMedia_decryptedMessageMediaGeoPoint class]])
                {
                    Secret73_DecryptedMessageMedia_decryptedMessageMediaGeoPoint *concreteGeo = (Secret73_DecryptedMessageMedia_decryptedMessageMediaGeoPoint *)concreteMessage.media;
                    
                    TGLocationMediaAttachment *locationMediaAttachment = [[TGLocationMediaAttachment alloc] init];
                    locationMediaAttachment.latitude = [concreteGeo.lat doubleValue];
                    locationMediaAttachment.longitude = [concreteGeo.plong doubleValue];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:locationMediaAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:locationMediaAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret73_DecryptedMessageMedia_decryptedMessageMediaContact class]])
                {
                    Secret73_DecryptedMessageMedia_decryptedMessageMediaContact *mediaContact = (Secret73_DecryptedMessageMedia_decryptedMessageMediaContact *)concreteMessage.media;
                    
                    TLMessageMedia$messageMediaContact *convertedContact = [[TLMessageMedia$messageMediaContact alloc] init];
                    convertedContact.phone_number = mediaContact.phoneNumber;
                    convertedContact.first_name = mediaContact.firstName;
                    convertedContact.last_name = mediaContact.lastName;
                    convertedContact.user_id = [mediaContact.userId intValue];
                    
                    TGContactMediaAttachment *contactAttachment = [[TGContactMediaAttachment alloc] initWithTelegraphContactDesc:convertedContact];
                    
                    if (mediaAttachments == nil)
                        mediaAttachments = [NSArray arrayWithObject:contactAttachment];
                    else
                    {
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        [array addObjectsFromArray:mediaAttachments];
                        [array addObject:contactAttachment];
                        mediaAttachments = array;
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret73_DecryptedMessageMedia_decryptedMessageMediaExternalDocument class]])
                {
                    Secret73_DecryptedMessageMedia_decryptedMessageMediaExternalDocument *mediaDocument = (Secret73_DecryptedMessageMedia_decryptedMessageMediaExternalDocument *)concreteMessage.media;
                    
                    TGDocumentMediaAttachment *documentAttachment = [[TGDocumentMediaAttachment alloc] initWithSecret73ExternalDesc:mediaDocument];
                    if (documentAttachment != nil)
                    {
                        if (mediaAttachments == nil)
                            mediaAttachments = [NSArray arrayWithObject:documentAttachment];
                        else
                        {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:documentAttachment];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret73_DecryptedMessageMedia_decryptedMessageMediaVenue class]]) {
                    Secret73_DecryptedMessageMedia_decryptedMessageMediaVenue *mediaVenue = (Secret73_DecryptedMessageMedia_decryptedMessageMediaVenue *)concreteMessage.media;
                    
                    TGVenueAttachment *venue = [[TGVenueAttachment alloc] initWithTitle:mediaVenue.title address:mediaVenue.address provider:mediaVenue.provider venueId:mediaVenue.venueId type:nil];
                    TGLocationMediaAttachment *location = [[TGLocationMediaAttachment alloc] init];
                    location.latitude = [mediaVenue.lat doubleValue];
                    location.longitude = [mediaVenue.plong doubleValue];
                    location.venue = venue;
                    if (venue != nil) {
                        if (mediaAttachments == nil) {
                            mediaAttachments = [NSArray arrayWithObject:location];
                        } else {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:location];
                            mediaAttachments = array;
                        }
                    }
                }
                else if ([concreteMessage.media isKindOfClass:[Secret73_DecryptedMessageMedia_decryptedMessageMediaWebPage class]]) {
                    Secret73_DecryptedMessageMedia_decryptedMessageMediaWebPage *mediaWebpage = (Secret73_DecryptedMessageMedia_decryptedMessageMediaWebPage *)concreteMessage.media;
                    
                    TGWebPageMediaAttachment *webpage = [[TGWebPageMediaAttachment alloc] init];
                    int64_t randomId = 0;
                    arc4random_buf(&randomId, 8);
                    webpage.webPageLocalId = randomId;
                    webpage.url = mediaWebpage.url;
                    
                    if (webpage != nil) {
                        if (mediaAttachments == nil) {
                            mediaAttachments = [NSArray arrayWithObject:webpage];
                        } else {
                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            [array addObjectsFromArray:mediaAttachments];
                            [array addObject:webpage];
                            mediaAttachments = array;
                        }
                    }
                }
            }
        }
        else if ([desc isKindOfClass:[Secret73_DecryptedMessage_decryptedMessageService class]])
        {
            Secret73_DecryptedMessage_decryptedMessageService *concreteMessage = (Secret73_DecryptedMessage_decryptedMessageService *)desc;
            //self.unread = false;
            
            if ([concreteMessage.action isKindOfClass:[Secret73_DecryptedMessageAction_decryptedMessageActionSetMessageTTL class]])
            {
                Secret73_DecryptedMessageAction_decryptedMessageActionSetMessageTTL *concreteAction = (Secret73_DecryptedMessageAction_decryptedMessageActionSetMessageTTL *)concreteMessage.action;
                
                TGActionMediaAttachment *actionAttachment = [[TGActionMediaAttachment alloc] init];
                actionAttachment.actionType = TGMessageActionEncryptedChatMessageLifetime;
                actionAttachment.actionData = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSNumber alloc] initWithInt:[concreteAction.ttlSeconds intValue]], @"messageLifetime", nil];
                
                if (mediaAttachments == nil)
                    mediaAttachments = [NSArray arrayWithObject:actionAttachment];
                else
                {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:actionAttachment];
                    mediaAttachments = array;
                }
            }
            else if ([concreteMessage.action isKindOfClass:[Secret73_DecryptedMessageAction_decryptedMessageActionScreenshotMessages class]])
            {
                Secret73_DecryptedMessageAction_decryptedMessageActionScreenshotMessages *concreteAction = (Secret73_DecryptedMessageAction_decryptedMessageActionScreenshotMessages *)concreteMessage.action;
                TGActionMediaAttachment *actionAttachment = [[TGActionMediaAttachment alloc] init];
                actionAttachment.actionType = TGMessageActionEncryptedChatMessageScreenshot;
                actionAttachment.actionData = @{@"randomIds": concreteAction.randomIds};
                
                if (mediaAttachments == nil)
                    mediaAttachments = [NSArray arrayWithObject:actionAttachment];
                else
                {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    [array addObjectsFromArray:mediaAttachments];
                    [array addObject:actionAttachment];
                    mediaAttachments = array;
                }
            }
        }
        else
            return nil;
        
        if (entitiesAttachment != nil)
        {
            if (mediaAttachments == nil)
            {
                mediaAttachments = [NSArray arrayWithObject:entitiesAttachment];
            }
            else
            {
                NSMutableArray *array = [[NSMutableArray alloc] init];
                [array addObjectsFromArray:mediaAttachments];
                [array addObject:entitiesAttachment];
                mediaAttachments = array;
            }
        }
        
        if (mediaAttachments != nil)
            self.mediaAttachments = mediaAttachments;
        if (contentProperties != nil) {
            self.contentProperties = contentProperties;
        }
    }
    return self;
}

@end
