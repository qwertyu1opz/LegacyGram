#import "TGPlaceholderImageDataSource.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGInterfaceAssets.h"

static TG_SYNCHRONIZED_DEFINE(imageCache) = PTHREAD_MUTEX_INITIALIZER;

typedef struct
{
    int top;
    int bottom;
} TGTwoColors;

static const TGTwoColors colors[] = {
    { .top = 0xff516a, .bottom = 0xff885e }, //red
    { .top = 0xffa85c, .bottom = 0xffcd6a }, //orange
    { .top = 0x665fff, .bottom = 0x82b1ff }, //purple
    { .top = 0x54cb68, .bottom = 0xa0de7e }, //green
    { .top = 0x28c9b7, .bottom = 0x53edd6 }, //cyan
    { .top = 0x2a9ef1, .bottom = 0x72d5fd }, //blue
    { .top = 0xd669ed, .bottom = 0xe0a2f3 }, //pink
};

static bool TGClassicIOS6StyleEnabled(void)
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"TGClassicIOS6Style"];
}

static UIImage *TGClassicIOS6AvatarPlaceholder(NSString *type, CGSize size)
{
    if (!TGClassicIOS6StyleEnabled())
        return nil;

    bool group = [type isEqualToString:@"group-avatar"];
    NSString *name = group ? (size.width <= 40.0f ? @"DialogListGroupAvatarPlaceholderSmall" : @"DialogListGroupAvatarPlaceholder") : (size.width <= 40.0f ? @"DialogListAvatarPlaceholderSmall" : @"DialogListAvatarPlaceholder");
    NSString *resourceName = [UIScreen mainScreen].scale > 1.5f ? [name stringByAppendingFormat:@"%c2x", 64] : name;
    NSString *path = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"png" inDirectory:@"ClassicIOS6"];
    UIImage *source = path.length == 0 ? nil : [UIImage imageWithContentsOfFile:path];
    if (source == nil)
        return nil;
    if ([UIScreen mainScreen].scale > 1.5f && source.CGImage != NULL)
        source = [UIImage imageWithCGImage:source.CGImage scale:2.0f orientation:UIImageOrientationUp];

    UIGraphicsBeginImageContextWithOptions(size, false, 0.0f);
    [source drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@implementation TGPlaceholderImageDataSource

+ (void)load
{
    @autoreleasepool
    {
        [TGImageDataSource registerDataSource:[[TGPlaceholderImageDataSource alloc] init]];
    }
}

+ (NSMutableDictionary *)imageCache
{
    static NSMutableDictionary *dict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        dict = [[NSMutableDictionary alloc] init];
    });
    return dict;
}

- (bool)canHandleUri:(NSString *)uri
{
    return [uri hasPrefix:@"placeholder://"];
}

- (bool)canHandleAttributeUri:(NSString *)uri
{
    return [uri hasPrefix:@"placeholder://"];
}

- (NSValue *)groupGradient:(int64_t)gid
{
    return [NSValue valueWithBytes:&colors[[[TGInterfaceAssets instance] groupColorIndex:gid]] objCType:@encode(TGTwoColors)];
}

- (id)loadAttributeSyncForUri:(NSString *)uri attribute:(NSString *)attribute
{
    if ([uri hasPrefix:@"placeholder://"] && [attribute hasPrefix:@"groupGradient-"])
    {
        return [self groupGradient:[[attribute substringFromIndex:@"groupGradient-".length] longLongValue]];
    }
    
    return nil;
}

- (id)cacheKeyForArgs:(NSDictionary *)args
{
    if ([args[@"type"] isEqualToString:@"user-avatar"])
    {
        int uid = [args[@"uid"] intValue];
        int colorIndex = [[TGInterfaceAssets instance] userColorIndex:uid];
        
        return [[NSString alloc] initWithFormat:@"%@:%d:%@x%@:%d", args[@"type"], uid == 0 ? -1 : colorIndex, args[@"w"], args[@"h"], TGClassicIOS6StyleEnabled() ? 1 : 0];
    }
    else
    {
        int64_t gid = [args[@"cid"] longLongValue];
        int colorIndex = [[TGInterfaceAssets instance] groupColorIndex:gid];
        
        return [[NSString alloc] initWithFormat:@"%@:%d:%@x%@:%d", args[@"type"], gid == 0 ? -1 : colorIndex, args[@"w"], args[@"h"], TGClassicIOS6StyleEnabled() ? 1 : 0];
    }
}

- (TGDataResource *)loadDataSyncWithUri:(NSString *)uri canWait:(bool)canWait acceptPartialData:(bool)__unused acceptPartialData asyncTaskId:(__autoreleasing id *)__unused asyncTaskId progress:(void (^)(float))__unused progress partialCompletion:(void (^)(TGDataResource *))__unused partialCompletion completion:(void (^)(TGDataResource *))__unused completion
{
    if (uri == nil)
        return nil;
    
    NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:@"placeholder://?".length]];
    
    TG_SYNCHRONIZED_BEGIN(imageCache);
    UIImage *cachedImage = [TGPlaceholderImageDataSource imageCache][[self cacheKeyForArgs:args]];
    TG_SYNCHRONIZED_END(imageCache);
    
    if (cachedImage != nil)
        return [[TGDataResource alloc] initWithImage:cachedImage decoded:true];
    
    if (!canWait)
        return nil;
    
    return [self _createAndCachePlaceholderWithArgs:args];
}

- (TGTwoColors)_colorsForUid:(int32_t)uid
{
    if (uid == 0)
        return (TGTwoColors){.top = 0xb1b1b1, .bottom = 0xcdcdcd };

    int colorIndex = [[TGInterfaceAssets instance] userColorIndex:uid];
    return colors[colorIndex];
}

- (TGTwoColors)_colorsForGroupId:(int64_t)groupId
{
    if (groupId == 0)
        return (TGTwoColors){.top = 0x8a8d91, .bottom = 0xbfc1c3};
    
    int colorIndex = [[TGInterfaceAssets instance] groupColorIndex:groupId];
    return colors[colorIndex];
}

- (TGDataResource *)_createAndCachePlaceholderWithArgs:(NSDictionary *)args
{
    CGSize size = CGSizeZero;
    size.width = [args[@"w"] intValue];
    size.height = [args[@"h"] intValue];
    if (size.width < 1.0f || size.height < 1.0f)
        return nil;
    
    NSString *type = args[@"type"];
    UIImage *classicPlaceholder = TGClassicIOS6AvatarPlaceholder(type, size);
    if (classicPlaceholder != nil)
    {
        TG_SYNCHRONIZED_BEGIN(imageCache);
        [TGPlaceholderImageDataSource imageCache][[self cacheKeyForArgs:args]] = classicPlaceholder;
        TG_SYNCHRONIZED_END(imageCache);
        return [[TGDataResource alloc] initWithImage:classicPlaceholder decoded:true];
    }
    if ([type isEqualToString:@"user-avatar"])
    {
        int32_t uid = [args[@"uid"] intValue];
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0f);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextBeginPath(context);
        CGContextAddEllipseInRect(context, CGRectMake(0.0f, 0.0f, size.width, size.height));
        CGContextClip(context);
        
        TGTwoColors twoColors = [self _colorsForUid:uid];
        
        CGColorRef colors[2] = {
            CGColorRetain(UIColorRGB(twoColors.bottom).CGColor),
            CGColorRetain(UIColorRGB(twoColors.top).CGColor)
        };
        
        CFArrayRef colorsArray = CFArrayCreate(kCFAllocatorDefault, (const void **)&colors, 2, NULL);
        CGFloat locations[2] = {0.0f, 1.0f};
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colorsArray, (CGFloat const *)&locations);
        
        CFRelease(colorsArray);
        CFRelease(colors[0]);
        CFRelease(colors[1]);
        
        CGColorSpaceRelease(colorSpace);
        
        CGContextDrawLinearGradient(context, gradient, CGPointMake(0.0f, 0.0f), CGPointMake(0.0f, size.height), 0);
        
        CFRelease(gradient);
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (image != nil)
        {
            TG_SYNCHRONIZED_BEGIN(imageCache);
            [TGPlaceholderImageDataSource imageCache][[self cacheKeyForArgs:args]] = image;
            TG_SYNCHRONIZED_END(imageCache);
        }
    }
    else if ([type isEqualToString:@"group-avatar"])
    {
        int64_t gid = [args[@"cid"] longLongValue];
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0f);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextBeginPath(context);
        CGContextAddEllipseInRect(context, CGRectMake(0.0f, 0.0f, size.width, size.height));
        CGContextClip(context);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        TGTwoColors twoColors = [self _colorsForGroupId:gid];
        
        CGColorRef colors[2] = {
            CGColorRetain(UIColorRGB(twoColors.bottom).CGColor),
            CGColorRetain(UIColorRGB(twoColors.top).CGColor)
        };
        
        CFArrayRef colorsArray = CFArrayCreate(kCFAllocatorDefault, (const void **)&colors, 2, NULL);
        CGFloat locations[2] = {0.0f, 1.0f};
        
        CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colorsArray, (CGFloat const *)&locations);
        
        CFRelease(colorsArray);
        CFRelease(colors[0]);
        CFRelease(colors[1]);
        
        CGColorSpaceRelease(colorSpace);
        
        CGContextDrawLinearGradient(context, gradient, CGPointMake(0.0f, 0.0f), CGPointMake(0.0f, size.height), 0);
        CFRelease(gradient);
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (image != nil)
        {
            TG_SYNCHRONIZED_BEGIN(imageCache);
            [TGPlaceholderImageDataSource imageCache][[self cacheKeyForArgs:args]] = image;
            TG_SYNCHRONIZED_END(imageCache);
        }
    }
    else if ([type isEqualToString:@"saved-messages"])
    {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0f);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextBeginPath(context);
        CGContextAddEllipseInRect(context, CGRectMake(0.0f, 0.0f, size.width, size.height));
        CGContextClip(context);
        
        TGTwoColors twoColors = colors[5];
        
        CGColorRef colors[2] = {
            CGColorRetain(UIColorRGB(twoColors.bottom).CGColor),
            CGColorRetain(UIColorRGB(twoColors.top).CGColor)
        };
        
        CFArrayRef colorsArray = CFArrayCreate(kCFAllocatorDefault, (const void **)&colors, 2, NULL);
        CGFloat locations[2] = {0.0f, 1.0f};
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colorsArray, (CGFloat const *)&locations);
        
        CFRelease(colorsArray);
        CFRelease(colors[0]);
        CFRelease(colors[1]);
        
        CGColorSpaceRelease(colorSpace);
        
        CGContextDrawLinearGradient(context, gradient, CGPointMake(0.0f, 0.0f), CGPointMake(0.0f, size.height), 0);
        
        CFRelease(gradient);
        
        UIImage *icon = TGImageNamed(@"SavedMessagesIcon");
        CGSize ratios = CGSizeMake(22.0f / 60.0f, 27.0f / 60.0f);
        CGSize iconSize = CGSizeMake(round(size.width * ratios.width), round(size.height * ratios.height));
        [icon drawInRect:CGRectMake((size.width - iconSize.width) / 2.0f, ceil((size.height - iconSize.height) / 2.0f) + 1.0f, iconSize.width, iconSize.height)];
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (image != nil)
        {
            TG_SYNCHRONIZED_BEGIN(imageCache);
            [TGPlaceholderImageDataSource imageCache][[self cacheKeyForArgs:args]] = image;
            TG_SYNCHRONIZED_END(imageCache);
        }
    }
    
    return nil;
}

@end
