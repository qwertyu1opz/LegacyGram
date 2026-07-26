/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGDocumentMediaAttachment+Telegraph.h"

#import "TGImageInfo+Telegraph.h"

#import "TGAppDelegate.h"

#import "TLDocumentAttribute$documentAttributeAudio.h"

static NSString *TGModernDocumentThumbnailUrl(TLDocument$document *document, TLPhotoSize *size)
{
    if (document == nil || size == nil || document.dc_id == 0 || document.n_id == 0)
        return nil;
    
    NSString *thumbSize = @"";
    int32_t fileSize = 0;
    if ([size isKindOfClass:[TLPhotoSize$photoSize class]])
    {
        TLPhotoSize$photoSize *concreteSize = (TLPhotoSize$photoSize *)size;
        thumbSize = concreteSize.type ?: @"";
        fileSize = concreteSize.size;
    }
    else if ([size isKindOfClass:[TLPhotoSize$photoCachedSize class]])
    {
        TLPhotoSize$photoCachedSize *concreteSize = (TLPhotoSize$photoCachedSize *)size;
        thumbSize = concreteSize.type ?: @"";
        fileSize = (int32_t)concreteSize.bytes.length;
    }
    
    NSString *fileReference = document.file_reference.length == 0 ? @"" : [document.file_reference stringByEncodingInHex];
    return [[NSString alloc] initWithFormat:@"documentthumb:%d:%lld:%lld:%d:%@:%@", document.dc_id, document.n_id, document.access_hash, fileSize, thumbSize, fileReference];
}

@implementation TGDocumentMediaAttachment (Telegraph)

+ (NSArray *)parseAttribtues:(NSArray *)descs {
    NSMutableArray *attributes = [[NSMutableArray alloc] init];
    for (id attribute in descs)
    {
        if ([attribute isKindOfClass:[TLDocumentAttribute$documentAttributeFilename class]])
        {
            TLDocumentAttribute$documentAttributeFilename *concreteAttribute = attribute;
            [attributes addObject:[[TGDocumentAttributeFilename alloc] initWithFilename:concreteAttribute.file_name]];
        }
        else if ([attribute isKindOfClass:[TLDocumentAttribute$documentAttributeAnimated class]])
        {
            [attributes addObject:[[TGDocumentAttributeAnimated alloc] init]];
        }
        else if ([attribute isKindOfClass:[TLDocumentAttribute$documentAttributeImageSize class]])
        {
            TLDocumentAttribute$documentAttributeImageSize *concreteAttribute = attribute;
            [attributes addObject:[[TGDocumentAttributeImageSize alloc] initWithSize:CGSizeMake(concreteAttribute.w, concreteAttribute.h)]];
        }
        else if ([attribute isKindOfClass:[TLDocumentAttribute$documentAttributeStickerMeta class]])
        {
            TLDocumentAttribute$documentAttributeStickerMeta *concreteAttribute = (TLDocumentAttribute$documentAttributeStickerMeta *)attribute;
            id<TGStickerPackReference> packReference = nil;
            if ([concreteAttribute.stickerset isKindOfClass:[TLInputStickerSet$inputStickerSetID class]])
            {
                TLInputStickerSet$inputStickerSetID *concreteStickerset = (TLInputStickerSet$inputStickerSetID *)concreteAttribute.stickerset;
                packReference = [[TGStickerPackIdReference alloc] initWithPackId:concreteStickerset.n_id packAccessHash:concreteStickerset.access_hash shortName:nil];
            }
            else if ([concreteAttribute.stickerset isKindOfClass:[TLInputStickerSet$inputStickerSetShortName class]])
            {
                TLInputStickerSet$inputStickerSetShortName *concreteStickerset = (TLInputStickerSet$inputStickerSetShortName *)concreteAttribute.stickerset;
                packReference = [[TGStickerPackShortnameReference alloc] initWithShortName:concreteStickerset.short_name];
            }
            TGStickerMaskDescription *maskDescription = nil;
            if (concreteAttribute.mask_coords != nil) {
                maskDescription = [[TGStickerMaskDescription alloc] initWithN:concreteAttribute.mask_coords.n point:CGPointMake((CGFloat)concreteAttribute.mask_coords.x, (CGFloat)concreteAttribute.mask_coords.y) zoom:concreteAttribute.mask_coords.zoom];
            }
            
            [attributes addObject:[[TGDocumentAttributeSticker alloc] initWithAlt:concreteAttribute.alt packReference:packReference mask:maskDescription]];
        }
        else if ([attribute isKindOfClass:[TLDocumentAttribute$documentAttributeVideo class]])
        {
            TLDocumentAttribute$documentAttributeVideo *concreteAttribute = (TLDocumentAttribute$documentAttributeVideo *)attribute;
            [attributes addObject:[[TGDocumentAttributeVideo alloc] initWithRoundMessage:(concreteAttribute.flags & (1 << 0)) size:CGSizeMake(concreteAttribute.w, concreteAttribute.h) duration:concreteAttribute.duration]];
        }
        else if ([attribute isKindOfClass:[TLDocumentAttribute$documentAttributeAudio class]])
        {
            TLDocumentAttribute$documentAttributeAudio *concreteAttribute = attribute;
            
            TGAudioWaveform *waveform = nil;
            if (concreteAttribute.waveform.length != 0) {
                waveform = [[TGAudioWaveform alloc] initWithBitstream:concreteAttribute.waveform bitsPerSample:5];
            }
            
            [attributes addObject:[[TGDocumentAttributeAudio alloc] initWithIsVoice:concreteAttribute.is_voice title:concreteAttribute.title performer:concreteAttribute.performer duration:concreteAttribute.duration waveform:waveform]];
        }
    }
    return attributes;
}

- (instancetype)initWithTelegraphDocumentDesc:(TLDocument *)desc
{
    self = [super init];
    if (self != nil)
    {
        self.type = TGDocumentMediaAttachmentType;
        
        self.documentId = desc.n_id;
        
        if ([desc isKindOfClass:[TLDocument$document class]])
        {
            TLDocument$document *concreteDocument = (TLDocument$document *)desc;
            
            self.accessHash = concreteDocument.access_hash;
            self.datacenterId = concreteDocument.dc_id;
            self.date = concreteDocument.date;
            self.version = concreteDocument.version;
            
            self.attributes = [TGDocumentMediaAttachment parseAttribtues:concreteDocument.attributes];
            self.mimeType = concreteDocument.mime_type;
            self.size = concreteDocument.size;
            
            bool hasAudioAttribute = false;
            for (id attribute in self.attributes)
            {
                if ([attribute isKindOfClass:[TGDocumentAttributeAudio class]])
                {
                    hasAudioAttribute = true;
                    break;
                }
            }
            if (!hasAudioAttribute && ([self.mimeType hasPrefix:@"audio/"] || [self.mimeType isEqualToString:@"application/ogg"]))
            {
                NSMutableArray *attributes = [[NSMutableArray alloc] initWithArray:self.attributes == nil ? @[] : self.attributes];
                bool isVoice = [self.mimeType isEqualToString:@"audio/ogg"] || [self.mimeType isEqualToString:@"audio/opus"] || [self.mimeType isEqualToString:@"application/ogg"];
                [attributes addObject:[[TGDocumentAttributeAudio alloc] initWithIsVoice:isVoice title:nil performer:nil duration:0 waveform:nil]];
                self.attributes = attributes;
                while (false) TGLog(@"IOS6MEDIA document audio fallback id=%lld mime=%@ voice=%d", self.documentId, self.mimeType, isVoice ? 1 : 0);
            }
            
            NSData *cachedData = nil;
            TGImageInfo *thumbmailInfo = nil;
            if (concreteDocument.thumb != nil)
            {
                thumbmailInfo = [[TGImageInfo alloc] initWithTelegraphSizesDescription:@[concreteDocument.thumb] cachedData:&cachedData];
                // Modern PhotoSize objects do not contain a legacy FileLocation.
                // TGImageInfo can still report itself as non-empty after receiving
                // an empty URL, so check the actual URL before choosing the legacy
                // thumbnail path.
                if (thumbmailInfo.empty || [thumbmailInfo imageUrlForLargestSize:NULL].length == 0)
                {
                    NSString *modernUrl = TGModernDocumentThumbnailUrl(concreteDocument, concreteDocument.thumb);
                    if (modernUrl != nil)
                    {
                        CGSize dimensions = CGSizeZero;
                        int32_t fileSize = 0;
                        if ([concreteDocument.thumb isKindOfClass:[TLPhotoSize$photoSize class]])
                        {
                            TLPhotoSize$photoSize *size = (TLPhotoSize$photoSize *)concreteDocument.thumb;
                            dimensions = CGSizeMake(size.w, size.h);
                            fileSize = size.size;
                        }
                        else if ([concreteDocument.thumb isKindOfClass:[TLPhotoSize$photoCachedSize class]])
                        {
                            TLPhotoSize$photoCachedSize *size = (TLPhotoSize$photoCachedSize *)concreteDocument.thumb;
                            dimensions = CGSizeMake(size.w, size.h);
                            fileSize = (int32_t)size.bytes.length;
                            if (cachedData == nil && size.bytes.length != 0)
                                cachedData = size.bytes;
                        }
                        
                        thumbmailInfo = [[TGImageInfo alloc] init];
                        [thumbmailInfo addImageWithSize:dimensions url:modernUrl fileSize:fileSize];
                    }
                }
            }
            if (thumbmailInfo != nil && !thumbmailInfo.empty)
            {
                self.thumbnailInfo = thumbmailInfo;
                if (cachedData != nil)
                {
                    static NSString *filesDirectory = nil;
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^
                    {
                        filesDirectory = [[TGAppDelegate documentsPath] stringByAppendingPathComponent:@"files"];
                    });
                    
                    NSString *fileDirectoryName = nil;
                    fileDirectoryName = [[NSString alloc] initWithFormat:@"%" PRIx64 "", self.documentId];
                    NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
                    
                    [[NSFileManager defaultManager] createDirectoryAtPath:fileDirectory withIntermediateDirectories:true attributes:nil error:nil];
                    
                    NSString *filePath = [fileDirectory stringByAppendingPathComponent:@"thumbnail"];
                    
                    [cachedData writeToFile:filePath atomically:true];
                }
            }
        }
    }
    return self;
}

- (instancetype)initWithSecret23Desc:(Secret23_DecryptedMessageMedia_decryptedMessageMediaExternalDocument *)desc
{
    self = [super init];
    if (self != nil)
    {
        self.type = TGDocumentMediaAttachmentType;
        
        self.documentId = [desc.pid longLongValue];
        
        self.accessHash = [desc.accessHash longLongValue];
        self.datacenterId = [desc.dcId intValue];
        self.date = [desc.date intValue];
        
        NSMutableArray *attributes = [[NSMutableArray alloc] init];
        for (id attribute in desc.attributes)
        {
            if ([attribute isKindOfClass:[Secret23_DocumentAttribute_documentAttributeFilename class]])
            {
                Secret23_DocumentAttribute_documentAttributeFilename *concreteAttribute = attribute;
                [attributes addObject:[[TGDocumentAttributeFilename alloc] initWithFilename:concreteAttribute.fileName]];
            }
            else if ([attribute isKindOfClass:[Secret23_DocumentAttribute_documentAttributeAnimated class]])
            {
                [attributes addObject:[[TGDocumentAttributeAnimated alloc] init]];
            }
            else if ([attribute isKindOfClass:[Secret23_DocumentAttribute_documentAttributeAudio class]])
            {
            }
            else if ([attribute isKindOfClass:[Secret23_DocumentAttribute_documentAttributeImageSize class]])
            {
                Secret23_DocumentAttribute_documentAttributeImageSize *concreteAttribute = attribute;
                [attributes addObject:[[TGDocumentAttributeImageSize alloc] initWithSize:CGSizeMake(concreteAttribute.w.integerValue, concreteAttribute.h.integerValue)]];
            }
            else if ([attribute isKindOfClass:[Secret23_DocumentAttribute_documentAttributeSticker class]])
            {
                [attributes addObject:[[TGDocumentAttributeSticker alloc] initWithAlt:nil packReference:nil mask:nil]];
            }
            else if ([attribute isKindOfClass:[Secret23_DocumentAttribute_documentAttributeVideo class]])
            {
            }
        }
    
        self.attributes = attributes;
        self.mimeType = desc.mimeType;
        self.size = [desc.size intValue];
        
        NSData *cachedData = nil;
        TGImageInfo *thumbmailInfo = desc.thumb == nil ? nil : [[TGImageInfo alloc] initWithSecret23SizesDescription:@[desc.thumb] cachedData:&cachedData];
        if (thumbmailInfo != nil && !thumbmailInfo.empty)
        {
            self.thumbnailInfo = thumbmailInfo;
            if (cachedData != nil)
            {
                static NSString *filesDirectory = nil;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^
                {
                    filesDirectory = [[TGAppDelegate documentsPath] stringByAppendingPathComponent:@"files"];
                });
                
                NSString *fileDirectoryName = nil;
                fileDirectoryName = [[NSString alloc] initWithFormat:@"%" PRIx64 "", self.documentId];
                NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
                
                [[NSFileManager defaultManager] createDirectoryAtPath:fileDirectory withIntermediateDirectories:true attributes:nil error:nil];
                
                NSString *filePath = [fileDirectory stringByAppendingPathComponent:@"thumbnail"];
                
                [cachedData writeToFile:filePath atomically:true];
            }
        }
    }
    return self;
}

- (instancetype)initWithSecret46ExternalDesc:(Secret46_DecryptedMessageMedia_decryptedMessageMediaExternalDocument *)desc {
    self = [super init];
    if (self != nil)
    {
        self.type = TGDocumentMediaAttachmentType;
        
        self.documentId = [desc.pid longLongValue];
        
        self.accessHash = [desc.accessHash longLongValue];
        self.datacenterId = [desc.dcId intValue];
        self.date = [desc.date intValue];
        
        NSMutableArray *attributes = [[NSMutableArray alloc] init];
        for (id attribute in desc.attributes)
        {
            if ([attribute isKindOfClass:[Secret46_DocumentAttribute_documentAttributeFilename class]])
            {
                Secret46_DocumentAttribute_documentAttributeFilename *concreteAttribute = attribute;
                [attributes addObject:[[TGDocumentAttributeFilename alloc] initWithFilename:concreteAttribute.fileName]];
            }
            else if ([attribute isKindOfClass:[Secret46_DocumentAttribute_documentAttributeAnimated class]])
            {
                [attributes addObject:[[TGDocumentAttributeAnimated alloc] init]];
            }
            else if ([attribute isKindOfClass:[Secret46_DocumentAttribute_documentAttributeAudio class]])
            {
                Secret46_DocumentAttribute_documentAttributeAudio *concreteAttribute = attribute;
                TGAudioWaveform *waveform = nil;
                if (concreteAttribute.waveform.length != 0) {
                    waveform = [[TGAudioWaveform alloc] initWithBitstream:concreteAttribute.waveform bitsPerSample:5];
                }
                [attributes addObject:[[TGDocumentAttributeAudio alloc] initWithIsVoice:[concreteAttribute.flags intValue] & (1 << 10) title:concreteAttribute.title performer:concreteAttribute.performer duration:[concreteAttribute.duration intValue] waveform:waveform]];
            }
            else if ([attribute isKindOfClass:[Secret46_DocumentAttribute_documentAttributeImageSize class]])
            {
                Secret46_DocumentAttribute_documentAttributeImageSize *concreteAttribute = attribute;
                [attributes addObject:[[TGDocumentAttributeImageSize alloc] initWithSize:CGSizeMake(concreteAttribute.w.integerValue, concreteAttribute.h.integerValue)]];
            }
            else if ([attribute isKindOfClass:[Secret46_DocumentAttribute_documentAttributeSticker class]])
            {
                Secret46_DocumentAttribute_documentAttributeSticker *concreteAttribute = attribute;
                TGStickerPackShortnameReference *reference = nil;
                if ([concreteAttribute.stickerset isKindOfClass:[Secret46_InputStickerSet_inputStickerSetShortName class]]) {
                    Secret46_InputStickerSet_inputStickerSetShortName *concreteStickerSet = (Secret46_InputStickerSet_inputStickerSetShortName *)concreteAttribute.stickerset;
                    reference = [[TGStickerPackShortnameReference alloc] initWithShortName:concreteStickerSet.shortName];
                }
                [attributes addObject:[[TGDocumentAttributeSticker alloc] initWithAlt:concreteAttribute.alt packReference:reference mask:nil]];
            }
            else if ([attribute isKindOfClass:[Secret46_DocumentAttribute_documentAttributeVideo class]])
            {
                Secret46_DocumentAttribute_documentAttributeVideo *concreteAttribute = attribute;
                [attributes addObject:[[TGDocumentAttributeVideo alloc] initWithRoundMessage:false size:CGSizeMake([concreteAttribute.w intValue], [concreteAttribute.h intValue]) duration:[concreteAttribute.duration intValue]]];
            }
        }
        
        self.attributes = attributes;
        self.mimeType = desc.mimeType;
        self.size = [desc.size intValue];
        
        NSData *cachedData = nil;
        TGImageInfo *thumbmailInfo = desc.thumb == nil ? nil : [[TGImageInfo alloc] initWithSecret46SizesDescription:@[desc.thumb] cachedData:&cachedData];
        if (thumbmailInfo != nil && !thumbmailInfo.empty)
        {
            self.thumbnailInfo = thumbmailInfo;
            if (cachedData != nil)
            {
                static NSString *filesDirectory = nil;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^
                              {
                                  filesDirectory = [[TGAppDelegate documentsPath] stringByAppendingPathComponent:@"files"];
                              });
                
                NSString *fileDirectoryName = nil;
                fileDirectoryName = [[NSString alloc] initWithFormat:@"%" PRIx64 "", self.documentId];
                NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
                
                [[NSFileManager defaultManager] createDirectoryAtPath:fileDirectory withIntermediateDirectories:true attributes:nil error:nil];
                
                NSString *filePath = [fileDirectory stringByAppendingPathComponent:@"thumbnail"];
                
                [cachedData writeToFile:filePath atomically:true];
            }
        }
    }
    return self;
}

- (instancetype)initWithSecret66ExternalDesc:(Secret66_DecryptedMessageMedia_decryptedMessageMediaExternalDocument *)desc {
    self = [super init];
    if (self != nil)
    {
        self.type = TGDocumentMediaAttachmentType;
        
        self.documentId = [desc.pid longLongValue];
        
        self.accessHash = [desc.accessHash longLongValue];
        self.datacenterId = [desc.dcId intValue];
        self.date = [desc.date intValue];
        
        NSMutableArray *attributes = [[NSMutableArray alloc] init];
        for (id attribute in desc.attributes)
        {
            if ([attribute isKindOfClass:[Secret66_DocumentAttribute_documentAttributeFilename class]])
            {
                Secret66_DocumentAttribute_documentAttributeFilename *concreteAttribute = attribute;
                [attributes addObject:[[TGDocumentAttributeFilename alloc] initWithFilename:concreteAttribute.fileName]];
            }
            else if ([attribute isKindOfClass:[Secret66_DocumentAttribute_documentAttributeAnimated class]])
            {
                [attributes addObject:[[TGDocumentAttributeAnimated alloc] init]];
            }
            else if ([attribute isKindOfClass:[Secret66_DocumentAttribute_documentAttributeAudio class]])
            {
                Secret66_DocumentAttribute_documentAttributeAudio *concreteAttribute = attribute;
                TGAudioWaveform *waveform = nil;
                if (concreteAttribute.waveform.length != 0) {
                    waveform = [[TGAudioWaveform alloc] initWithBitstream:concreteAttribute.waveform bitsPerSample:5];
                }
                [attributes addObject:[[TGDocumentAttributeAudio alloc] initWithIsVoice:[concreteAttribute.flags intValue] & (1 << 10) title:concreteAttribute.title performer:concreteAttribute.performer duration:[concreteAttribute.duration intValue] waveform:waveform]];
            }
            else if ([attribute isKindOfClass:[Secret66_DocumentAttribute_documentAttributeImageSize class]])
            {
                Secret66_DocumentAttribute_documentAttributeImageSize *concreteAttribute = attribute;
                [attributes addObject:[[TGDocumentAttributeImageSize alloc] initWithSize:CGSizeMake(concreteAttribute.w.integerValue, concreteAttribute.h.integerValue)]];
            }
            else if ([attribute isKindOfClass:[Secret66_DocumentAttribute_documentAttributeSticker class]])
            {
                Secret66_DocumentAttribute_documentAttributeSticker *concreteAttribute = attribute;
                TGStickerPackShortnameReference *reference = nil;
                if ([concreteAttribute.stickerset isKindOfClass:[Secret66_InputStickerSet_inputStickerSetShortName class]]) {
                    Secret66_InputStickerSet_inputStickerSetShortName *concreteStickerSet = (Secret66_InputStickerSet_inputStickerSetShortName *)concreteAttribute.stickerset;
                    reference = [[TGStickerPackShortnameReference alloc] initWithShortName:concreteStickerSet.shortName];
                }
                [attributes addObject:[[TGDocumentAttributeSticker alloc] initWithAlt:concreteAttribute.alt packReference:reference mask:nil]];
            }
            else if ([attribute isKindOfClass:[Secret66_DocumentAttribute_documentAttributeVideo class]])
            {
                Secret66_DocumentAttribute_documentAttributeVideo *concreteAttribute = attribute;
                [attributes addObject:[[TGDocumentAttributeVideo alloc] initWithRoundMessage:concreteAttribute.flags.intValue & (1 << 0) size:CGSizeMake([concreteAttribute.w intValue], [concreteAttribute.h intValue]) duration:[concreteAttribute.duration intValue]]];
            }
        }
        
        self.attributes = attributes;
        self.mimeType = desc.mimeType;
        self.size = [desc.size intValue];
        
        NSData *cachedData = nil;
        TGImageInfo *thumbmailInfo = desc.thumb == nil ? nil : [[TGImageInfo alloc] initWithSecret66SizesDescription:@[desc.thumb] cachedData:&cachedData];
        if (thumbmailInfo != nil && !thumbmailInfo.empty)
        {
            self.thumbnailInfo = thumbmailInfo;
            if (cachedData != nil)
            {
                static NSString *filesDirectory = nil;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^
                              {
                                  filesDirectory = [[TGAppDelegate documentsPath] stringByAppendingPathComponent:@"files"];
                              });
                
                NSString *fileDirectoryName = nil;
                fileDirectoryName = [[NSString alloc] initWithFormat:@"%" PRIx64 "", self.documentId];
                NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
                
                [[NSFileManager defaultManager] createDirectoryAtPath:fileDirectory withIntermediateDirectories:true attributes:nil error:nil];
                
                NSString *filePath = [fileDirectory stringByAppendingPathComponent:@"thumbnail"];
                
                [cachedData writeToFile:filePath atomically:true];
            }
        }
    }
    return self;
}

- (instancetype)initWithSecret73ExternalDesc:(Secret73_DecryptedMessageMedia_decryptedMessageMediaExternalDocument *)desc {
    self = [super init];
    if (self != nil)
    {
        self.type = TGDocumentMediaAttachmentType;
        
        self.documentId = [desc.pid longLongValue];
        
        self.accessHash = [desc.accessHash longLongValue];
        self.datacenterId = [desc.dcId intValue];
        self.date = [desc.date intValue];
        
        NSMutableArray *attributes = [[NSMutableArray alloc] init];
        for (id attribute in desc.attributes)
        {
            if ([attribute isKindOfClass:[Secret73_DocumentAttribute_documentAttributeFilename class]])
            {
                Secret73_DocumentAttribute_documentAttributeFilename *concreteAttribute = attribute;
                [attributes addObject:[[TGDocumentAttributeFilename alloc] initWithFilename:concreteAttribute.fileName]];
            }
            else if ([attribute isKindOfClass:[Secret73_DocumentAttribute_documentAttributeAnimated class]])
            {
                [attributes addObject:[[TGDocumentAttributeAnimated alloc] init]];
            }
            else if ([attribute isKindOfClass:[Secret73_DocumentAttribute_documentAttributeAudio class]])
            {
                Secret73_DocumentAttribute_documentAttributeAudio *concreteAttribute = attribute;
                TGAudioWaveform *waveform = nil;
                if (concreteAttribute.waveform.length != 0) {
                    waveform = [[TGAudioWaveform alloc] initWithBitstream:concreteAttribute.waveform bitsPerSample:5];
                }
                [attributes addObject:[[TGDocumentAttributeAudio alloc] initWithIsVoice:[concreteAttribute.flags intValue] & (1 << 10) title:concreteAttribute.title performer:concreteAttribute.performer duration:[concreteAttribute.duration intValue] waveform:waveform]];
            }
            else if ([attribute isKindOfClass:[Secret73_DocumentAttribute_documentAttributeImageSize class]])
            {
                Secret73_DocumentAttribute_documentAttributeImageSize *concreteAttribute = attribute;
                [attributes addObject:[[TGDocumentAttributeImageSize alloc] initWithSize:CGSizeMake(concreteAttribute.w.integerValue, concreteAttribute.h.integerValue)]];
            }
            else if ([attribute isKindOfClass:[Secret73_DocumentAttribute_documentAttributeSticker class]])
            {
                Secret73_DocumentAttribute_documentAttributeSticker *concreteAttribute = attribute;
                TGStickerPackShortnameReference *reference = nil;
                if ([concreteAttribute.stickerset isKindOfClass:[Secret73_InputStickerSet_inputStickerSetShortName class]]) {
                    Secret73_InputStickerSet_inputStickerSetShortName *concreteStickerSet = (Secret73_InputStickerSet_inputStickerSetShortName *)concreteAttribute.stickerset;
                    reference = [[TGStickerPackShortnameReference alloc] initWithShortName:concreteStickerSet.shortName];
                }
                [attributes addObject:[[TGDocumentAttributeSticker alloc] initWithAlt:concreteAttribute.alt packReference:reference mask:nil]];
            }
            else if ([attribute isKindOfClass:[Secret73_DocumentAttribute_documentAttributeVideo class]])
            {
                Secret73_DocumentAttribute_documentAttributeVideo *concreteAttribute = attribute;
                [attributes addObject:[[TGDocumentAttributeVideo alloc] initWithRoundMessage:concreteAttribute.flags.intValue & (1 << 0) size:CGSizeMake([concreteAttribute.w intValue], [concreteAttribute.h intValue]) duration:[concreteAttribute.duration intValue]]];
            }
        }
        
        self.attributes = attributes;
        self.mimeType = desc.mimeType;
        self.size = [desc.size intValue];
        
        NSData *cachedData = nil;
        TGImageInfo *thumbmailInfo = desc.thumb == nil ? nil : [[TGImageInfo alloc] initWithSecret73SizesDescription:@[desc.thumb] cachedData:&cachedData];
        if (thumbmailInfo != nil && !thumbmailInfo.empty)
        {
            self.thumbnailInfo = thumbmailInfo;
            if (cachedData != nil)
            {
                static NSString *filesDirectory = nil;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^
                              {
                                  filesDirectory = [[TGAppDelegate documentsPath] stringByAppendingPathComponent:@"files"];
                              });
                
                NSString *fileDirectoryName = nil;
                fileDirectoryName = [[NSString alloc] initWithFormat:@"%" PRIx64 "", self.documentId];
                NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
                
                [[NSFileManager defaultManager] createDirectoryAtPath:fileDirectory withIntermediateDirectories:true attributes:nil error:nil];
                
                NSString *filePath = [fileDirectory stringByAppendingPathComponent:@"thumbnail"];
                
                [cachedData writeToFile:filePath atomically:true];
            }
        }
    }
    return self;
}

@end
