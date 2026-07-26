#import "TGApplication.h"

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGAppDelegate.h"

#import "../submodules/LegacyComponents/SafariServices/SafariServices.h"
#import "TGWebAppController.h"
#import "TGHashtagOverviewController.h"
#import "TGRootController.h"

static NSString *TGAppDelegateIos6CompatPath(NSSearchPathDirectory directory)
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, true);
    NSString *path = paths.count == 0 ? nil : [paths objectAtIndex:0];
    
    if (path.length == 0)
        path = NSTemporaryDirectory();
    if (path.length == 0)
        path = @"/tmp";
    
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:true attributes:nil error:nil];
    return path;
}

@implementation TGAppDelegate (Ios6RuntimeCompat)

+ (NSString *)documentsPath
{
    return TGAppDelegateIos6CompatPath(NSDocumentDirectory);
}

+ (NSString *)cachePath
{
    return TGAppDelegateIos6CompatPath(NSCachesDirectory);
}

+ (NSUserDefaults *)userDefaults
{
    return [NSUserDefaults standardUserDefaults];
}

+ (void)movePathsToContainer
{
}

- (bool)willBeLocked
{
    return false;
}

- (void)resetRemoteDeviceLocked
{
    // The iOS 6 linker can omit the private implementation from TGAppDelegate.
    // Remote lock reporting is optional; keeping this selector available avoids
    // crashing while disabling or unlocking the local passcode.
}

@end

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 70000
@implementation UIPercentDrivenInteractiveTransition
- (void)updateInteractiveTransition:(CGFloat)percentComplete {}
- (void)cancelInteractiveTransition {}
- (void)finishInteractiveTransition {}
@end
#endif

void TGAssert(bool value)
{
    if (!value)
        NSLog(@"TGAssert failed");
}

@implementation NSURLSessionConfiguration
+ (instancetype)defaultSessionConfiguration
{
    return [[self alloc] init];
}
@end

@implementation NSURLSession
+ (instancetype)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration
{
    return [[self alloc] init];
}
+ (instancetype)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration delegate:(id)delegate delegateQueue:(NSOperationQueue *)queue
{
    return [[self alloc] init];
}
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url
{
    return nil;
}
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
{
    return nil;
}
- (void)invalidateAndCancel {}
@end

@implementation NSURLSessionTask
- (void)resume {}
- (void)cancel {}
@end

@implementation NSURLSessionDataTask
@end

@implementation UIImpactFeedbackGenerator
- (instancetype)initWithStyle:(NSInteger)style
{
    return [super init];
}
- (void)prepare {}
- (void)impactOccurred {}
@end

@implementation UIKeyCommand
+ (instancetype)keyCommandWithInput:(NSString *)input modifierFlags:(NSUInteger)modifierFlags action:(SEL)action
{
    // The iOS 6 SDK compatibility name expands to TGIOS6KeyCommand.  UIKit on
    // newer systems requires real UIKeyCommand instances and queries their
    // action/input properties while a text view becomes first responder.
    if (iosMajorVersion() >= 7)
    {
        Class systemKeyCommandClass = NSClassFromString(@"UIKeyCommand");
        SEL factorySelector = @selector(keyCommandWithInput:modifierFlags:action:);
        if (systemKeyCommandClass != Nil && systemKeyCommandClass != [self class] &&
            [systemKeyCommandClass respondsToSelector:factorySelector])
        {
            IMP implementation = [systemKeyCommandClass methodForSelector:factorySelector];
            id (*factory)(id, SEL, NSString *, NSUInteger, SEL) = (void *)implementation;
            return factory(systemKeyCommandClass, factorySelector, input, modifierFlags, action);
        }
    }

    return [[self alloc] init];
}
@end

@implementation UIAlertController
@end

@implementation UIDocumentPickerViewController
@end

@implementation PHObject
@end

@implementation PHAsset
@end

@implementation PHAssetChangeRequest
@end

@implementation PHAssetCollection
@end

@implementation PHAssetResource
@end

@implementation PHAssetResourceManager
@end

@implementation PHCachingImageManager
@end

@implementation PHFetchOptions
@end

@implementation PHImageManager
@end

@implementation PHImageRequestOptions
@end

@implementation PHLivePhotoRequestOptions
@end

@implementation PHPhotoLibrary
@end

@implementation PHVideoRequestOptions
@end

@implementation CNContactFormatter
@end

@implementation CNContactVCardSerialization
@end

@implementation CNLabeledValue
@end

@implementation CNMutableContact
@end

@implementation CNPhoneNumber
@end

@implementation WCSession
@end

static NSString *TGIos6YouTubeDecodedString(NSString *string)
{
    NSString *result = string;
    for (NSUInteger i = 0; i < 3 && result.length != 0; i++)
    {
        NSString *decoded = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if (decoded.length == 0 || [decoded isEqualToString:result])
            break;
        result = decoded;
    }
    return result;
}

static NSString *TGIos6YouTubeQueryValue(NSURL *url, NSArray *names)
{
    NSString *query = url.query;
    if (query.length == 0)
        return nil;

    for (NSString *item in [query componentsSeparatedByString:@"&"])
    {
        NSRange separator = [item rangeOfString:@"="];
        NSString *rawKey = separator.location == NSNotFound ? item : [item substringToIndex:separator.location];
        NSString *key = [[TGIos6YouTubeDecodedString(rawKey) lowercaseString] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
        if (![names containsObject:key])
            continue;

        NSString *rawValue = separator.location == NSNotFound ? @"" : [item substringFromIndex:separator.location + 1];
        return TGIos6YouTubeDecodedString([rawValue stringByReplacingOccurrencesOfString:@"+" withString:@" "]);
    }
    return nil;
}

static BOOL TGIos6YouTubeHostMatches(NSString *host, NSString *domain)
{
    if ([host isEqualToString:domain])
        return YES;
    return [host hasSuffix:[@"." stringByAppendingString:domain]];
}

static NSString *TGIos6YouTubeValidatedVideoId(NSString *candidate)
{
    candidate = TGIos6YouTubeDecodedString(candidate);
    if (candidate.length == 0)
        return nil;

    NSCharacterSet *invalidCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"] invertedSet];
    NSRange invalidRange = [candidate rangeOfCharacterFromSet:invalidCharacters];
    if (invalidRange.location == 0)
        return nil;
    if (invalidRange.location != NSNotFound)
        candidate = [candidate substringToIndex:invalidRange.location];

    // YouTube video identifiers are exactly 11 URL-safe characters. Being
    // strict here prevents channel, playlist and clip identifiers from being
    // accidentally sent to the old YouTube application as videos.
    return candidate.length == 11 ? candidate : nil;
}

static NSString *TGIos6YouTubeVideoIdFromURL(NSURL *url, NSUInteger depth)
{
    if (url == nil || depth > 3)
        return nil;

    NSString *host = [url.host lowercaseString];
    if (host.length == 0)
        return nil;

    BOOL shortHost = TGIos6YouTubeHostMatches(host, @"youtu.be");
    BOOL youtubeHost = TGIos6YouTubeHostMatches(host, @"youtube.com") || TGIos6YouTubeHostMatches(host, @"youtube-nocookie.com");
    if (!shortHost && !youtubeHost)
        return nil;

    if (youtubeHost)
    {
        NSString *lowerPath = [url.path lowercaseString];
        if ([lowerPath isEqualToString:@"/redirect"] || [lowerPath isEqualToString:@"/attribution_link"])
        {
            NSString *wrappedString = TGIos6YouTubeQueryValue(url, @[@"u", @"url", @"q"]);
            if (wrappedString.length != 0)
            {
                if ([wrappedString hasPrefix:@"//"])
                    wrappedString = [@"https:" stringByAppendingString:wrappedString];
                else if ([wrappedString hasPrefix:@"/"])
                    wrappedString = [@"https://www.youtube.com" stringByAppendingString:wrappedString];
                else if ([wrappedString rangeOfString:@"://"].location == NSNotFound)
                    wrappedString = [@"https://" stringByAppendingString:wrappedString];

                NSString *wrappedId = TGIos6YouTubeVideoIdFromURL([NSURL URLWithString:wrappedString], depth + 1);
                if (wrappedId.length != 0)
                    return wrappedId;
            }
        }
    }

    NSString *candidate = nil;
    if (shortHost)
    {
        for (NSString *component in [url.path componentsSeparatedByString:@"/"])
        {
            if (component.length != 0)
            {
                candidate = component;
                break;
            }
        }
    }
    else
    {
        candidate = TGIos6YouTubeQueryValue(url, @[@"v"]);
        if (candidate.length == 0)
        {
            NSArray *components = [url.path componentsSeparatedByString:@"/"];
            for (NSUInteger index = 0; index + 1 < components.count; index++)
            {
                NSString *component = [[components objectAtIndex:index] lowercaseString];
                if ([component isEqualToString:@"shorts"] || [component isEqualToString:@"live"] || [component isEqualToString:@"embed"] || [component isEqualToString:@"v"])
                {
                    candidate = [components objectAtIndex:index + 1];
                    break;
                }
            }
        }
    }
    return TGIos6YouTubeValidatedVideoId(candidate);
}

@interface TGApplication ()
{
}

@end

@implementation TGApplication

- (id)init
{
    self = [super init];
    if (self != nil)
    {
    }
    return self;
}

- (NSMutableDictionary *)gameShareDict {
    if (_gameShareDict == nil) {
        _gameShareDict = [[NSMutableDictionary alloc] init];
    }
    return _gameShareDict;
}

- (NSString *)telegramMeLinkFromText:(NSString *)text startPrivatePayload:(__autoreleasing NSString **)startPrivatePayload startGroupPayload:(__autoreleasing NSString **)startGroupPayload gamePayload:(__autoreleasing NSString **)gamePayload groupedSingle:(bool *)groupedSingle
{
    NSString *pattern = @"https?:\\/\\/(telegram\\.me|t\\.me|telegram\\.dog)\\/([a-zA-Z0-9_\\/]+)(\\?.*)?$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
    NSTextCheckingResult *match = [regex firstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
    if (match != nil)
    {
        NSString *arguments = ([match numberOfRanges] >= 3 && [match rangeAtIndex:3].location != NSNotFound) ? [[text substringWithRange:[match rangeAtIndex:3]] substringFromIndex:1] : nil;
        if (arguments.length != 0)
        {
            if ([arguments isEqualToString:@"single"])
            {
                if (groupedSingle)
                   *groupedSingle = true;
            }
            else
            {
                NSDictionary *dict = [TGStringUtils argumentDictionaryInUrlString:arguments];
                if (dict.count == 1 && (dict[@"start"] != nil || dict[@"startgroup"] || dict[@"game"]))
                {
                    if (startPrivatePayload)
                       *startPrivatePayload = dict[@"start"];
                    if (startGroupPayload)
                       *startGroupPayload = dict[@"startgroup"];
                    if (gamePayload)
                       *gamePayload = dict[@"game"];
                }
                else
                    return nil;
            }
        }
        return [text substringWithRange:[match rangeAtIndex:2]];
    }
    
    {
        NSString *pattern = @"https?:\\/\\/t\\.me\\/([a-zA-Z0-9_\\/]+)(\\?.*)?$";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL];
        NSTextCheckingResult *match = [regex firstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
        if (match != nil)
        {
            NSString *arguments = ([match numberOfRanges] >= 2 && [match rangeAtIndex:2].location != NSNotFound) ? [[text substringWithRange:[match rangeAtIndex:2]] substringFromIndex:1] : nil;
            if (arguments.length != 0)
            {
                NSDictionary *dict = [TGStringUtils argumentDictionaryInUrlString:arguments];
                if (dict.count == 1 && (dict[@"start"] != nil || dict[@"startgroup"] || dict[@"game"]))
                {
                    if (startPrivatePayload)
                       *startPrivatePayload = dict[@"start"];
                    if (startGroupPayload)
                       *startGroupPayload = dict[@"startgroup"];
                    if (gamePayload)
                       *gamePayload = dict[@"game"];
                }
                else
                    return nil;
            }
            return [text substringWithRange:[match rangeAtIndex:1]];
        }
    }
    return nil;
}

- (NSString *)shareLinkFromText:(NSString *)text {
    NSString *pattern = @"https?:\\/\\/telegram\\.me\\/share\\/url\\?(.*)$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:NULL];
    NSTextCheckingResult *match = [regex firstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
    if (match != nil) {
        NSString *arguments = ([match numberOfRanges] >= 1 && [match rangeAtIndex:1].location != NSNotFound) ? [text substringWithRange:[match rangeAtIndex:1]] : nil;
        if (arguments.length != 0)
        {
            return arguments;
        }
        return [text substringWithRange:[match rangeAtIndex:1]];
    }
    
    {
        NSString *pattern = @"https?:\\/\\/t\\.me\\/share\\/url\\?(.*)$";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:NULL];
        NSTextCheckingResult *match = [regex firstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
        if (match != nil) {
            NSString *arguments = ([match numberOfRanges] >= 1 && [match rangeAtIndex:1].location != NSNotFound) ? [text substringWithRange:[match rangeAtIndex:1]] : nil;
            if (arguments.length != 0)
            {
                return arguments;
            }
            return [text substringWithRange:[match rangeAtIndex:1]];
        }
    }
    
    return nil;
}

- (NSString *)proxyLinkFromText:(NSString *)text {
    NSString *pattern = @"(https|http)?:\\/\\/(telegram|t)\\.me\\/proxy\\?(.*)$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:NULL];
    NSTextCheckingResult *match = [regex firstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
    if (match != nil) {
        NSString *arguments = ([match numberOfRanges] >= 3 && [match rangeAtIndex:3].location != NSNotFound) ? [text substringWithRange:[match rangeAtIndex:3]] : nil;
        if (arguments.length != 0) {
            return arguments;
        }
    }
    
    return nil;
}

- (NSString *)socksLinkFromText:(NSString *)text {
    NSString *pattern = @"(https|http)?:\\/\\/(telegram|t)\\.me\\/socks\\?(.*)$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:NULL];
    NSTextCheckingResult *match = [regex firstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
    if (match != nil) {
        NSString *arguments = ([match numberOfRanges] >= 3 && [match rangeAtIndex:3].location != NSNotFound) ? [text substringWithRange:[match rangeAtIndex:3]] : nil;
        if (arguments.length != 0) {
            return arguments;
        }
    }
    
    return nil;
}

- (BOOL)openURL:(NSURL *)url forceNative:(BOOL)forceNative {
    return [self openURL:url forceNative:forceNative keepStack:false];
}

- (BOOL)openURL:(NSURL *)url forceNative:(BOOL)__unused forceNative keepStack:(bool)keepStack
{
    if (url.absoluteString.length == 0)
        return true;
    
    if (url.scheme.length == 0) {
        url = [NSURL URLWithString:[@"http://" stringByAppendingString:[url absoluteString]]];
    }

    NSString *lowercaseScheme = [url.scheme lowercaseString];
    if ([lowercaseScheme isEqualToString:@"http"] || [lowercaseScheme isEqualToString:@"https"])
    {
        NSString *youtubeVideoId = TGIos6YouTubeVideoIdFromURL(url, 0);
        if (youtubeVideoId.length != 0)
        {
            NSArray *applicationSchemes = @[@"youtube", @"vnd.youtube"];
            for (NSString *applicationScheme in applicationSchemes)
            {
                NSURL *applicationUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@://watch?v=%@", applicationScheme, youtubeVideoId]];
                if ([super canOpenURL:applicationUrl])
                    return [super openURL:applicationUrl];
            }
        }
    }
    
    NSString *rawAbsoluteString = url.absoluteString;
    NSString *absolutePrefixString = [url.absoluteString lowercaseString];
    if ([absolutePrefixString hasPrefix:@"tel:"] || [absolutePrefixString hasPrefix:@"facetime:"])
    {
        [TGAppDelegateInstance performPhoneCall:url];
        return true;
    }
    
    if ([url.scheme isEqualToString:@"tg"] || [url.scheme isEqualToString:@"telegram"])
    {
        [(TGAppDelegate *)self.delegate handleOpenDocument:url animated:true];
        return true;
    }
    
    if ([absolutePrefixString hasPrefix:@"http://telegram.me/addstickers/"])
    {
        NSString *stickerPackHash = [rawAbsoluteString substringFromIndex:@"http://telegram.me/addstickers/".length];
        NSString *internalUrl = [[NSString alloc] initWithFormat:@"tg://addstickers?set=%@", stickerPackHash];
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true];
        return true;
    }
    
    if ([absolutePrefixString hasPrefix:@"http://t.me/addstickers/"])
    {
        NSString *stickerPackHash = [rawAbsoluteString substringFromIndex:@"http://t.me/addstickers/".length];
        NSString *internalUrl = [[NSString alloc] initWithFormat:@"tg://addstickers?set=%@", stickerPackHash];
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true];
        return true;
    }
    
    if ([absolutePrefixString hasPrefix:@"https://telegram.me/addstickers/"])
    {
        NSString *stickerPackHash = [rawAbsoluteString substringFromIndex:@"https://telegram.me/addstickers/".length];
        NSString *internalUrl = [[NSString alloc] initWithFormat:@"tg://addstickers?set=%@", stickerPackHash];
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true];
        return true;
    }
    
    if ([absolutePrefixString hasPrefix:@"https://t.me/addstickers/"])
    {
        NSString *stickerPackHash = [rawAbsoluteString substringFromIndex:@"https://t.me/addstickers/".length];
        NSString *internalUrl = [[NSString alloc] initWithFormat:@"tg://addstickers?set=%@", stickerPackHash];
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true];
        return true;
    }
    
    if ([absolutePrefixString hasPrefix:@"https://telegram.me/addstickers/"])
    {
        NSString *stickerPackHash = [rawAbsoluteString substringFromIndex:@"https://telegram.me/addstickers/".length];
        NSString *internalUrl = [[NSString alloc] initWithFormat:@"tg://addstickers?set=%@", stickerPackHash];
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true];
        return true;
    }
    
    /*NSString *instantViewPattern = @"https?:\\/\\/(t|telegram)\\.me\\/iv\\?(.*?)$";
    NSRegularExpression *instantViewRegex = [NSRegularExpression regularExpressionWithPattern:instantViewPattern options:NSRegularExpressionCaseInsensitive error:NULL];
    NSArray *instantViewMatches = [instantViewRegex matchesInString:rawAbsoluteString options:0 range:NSMakeRange(0, rawAbsoluteString.length)];
    for (NSTextCheckingResult *match in instantViewMatches) {
        if ([match rangeAtIndex:2].location != NSNotFound) {
            [TGStringUtils argumentDictionaryInUrlString:[rawAbsoluteString substringWithRange:[match rangeAtIndex:2]]];
            [(TGAppDelegate *)self.delegate handleOpenInstantView:];
            return true;
        }
        
        break;
    }*/
    
    if ([absolutePrefixString hasPrefix:@"http://t.me/joinchat/"])
    {
        NSString *groupHash = [rawAbsoluteString substringFromIndex:@"http://t.me/joinchat/".length];
        NSString *internalUrl = [[NSString alloc] initWithFormat:@"tg://join?invite=%@", groupHash];
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true keepStack:keepStack];
        return true;
    }
    
    if ([absolutePrefixString hasPrefix:@"https://telegram.me/joinchat/"])
    {
        NSString *groupHash = [rawAbsoluteString substringFromIndex:@"https://telegram.me/joinchat/".length];
        NSString *internalUrl = [[NSString alloc] initWithFormat:@"tg://join?invite=%@", groupHash];
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true keepStack:keepStack];
        return true;
    }
    
    if ([absolutePrefixString hasPrefix:@"https://t.me/joinchat/"])
    {
        NSString *groupHash = [rawAbsoluteString substringFromIndex:@"https://t.me/joinchat/".length];
        NSString *internalUrl = [[NSString alloc] initWithFormat:@"tg://join?invite=%@", groupHash];
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true keepStack:keepStack];
        return true;
    }
    
    if ([absolutePrefixString hasPrefix:@"t.me/joinchat/"])
    {
        NSString *groupHash = [rawAbsoluteString substringFromIndex:@"t.me/joinchat/".length];
        NSString *internalUrl = [[NSString alloc] initWithFormat:@"tg://join?invite=%@", groupHash];
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true keepStack:keepStack];
        return true;
    }
    
    if ([absolutePrefixString hasPrefix:@"telegram.me/joinchat/"])
    {
        NSString *groupHash = [rawAbsoluteString substringFromIndex:@"telegram.me/joinchat/".length];
        NSString *internalUrl = [[NSString alloc] initWithFormat:@"tg://join?invite=%@", groupHash];
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true keepStack:keepStack];
        return true;
    }
    
    if ([absolutePrefixString hasPrefix:@"http://telegram.me/joinchat/"])
    {
        NSString *groupHash = [rawAbsoluteString substringFromIndex:@"http://telegram.me/joinchat/".length];
        NSString *internalUrl = [[NSString alloc] initWithFormat:@"tg://join?invite=%@", groupHash];
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true keepStack:keepStack];
        return true;
    }
    
    if ([absolutePrefixString hasPrefix:@"https://telegram.me/confirmphone?"])
    {
        NSString *arguments = [rawAbsoluteString substringFromIndex:@"https://telegram.me/confirmphone?".length];
        NSString *internalUrl = [[NSString alloc] initWithFormat:@"tg://confirmphone?%@", arguments];
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true];
        return true;
    }
    
    if ([absolutePrefixString hasPrefix:@"https://t.me/confirmphone?"])
    {
        NSString *arguments = [rawAbsoluteString substringFromIndex:@"https://t.me/confirmphone?".length];
        NSString *internalUrl = [[NSString alloc] initWithFormat:@"tg://confirmphone?%@", arguments];
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true];
        return true;
    }
    
    NSString *startPrivatePayload = nil;
    NSString *startGroupPayload = nil;
    NSString *gamePayload = nil;
    bool groupedSingle = false;
    NSString *telegramMeLink = [self telegramMeLinkFromText:rawAbsoluteString startPrivatePayload:&startPrivatePayload startGroupPayload:&startGroupPayload gamePayload:&gamePayload groupedSingle:&groupedSingle];
    if (telegramMeLink.length != 0 && ![telegramMeLink isEqualToString:@"iv"])
    {
        NSString *domainName = telegramMeLink;
        NSString *postId = nil;
        NSRange slashRange = [telegramMeLink rangeOfString:@"/"];
        if (slashRange.location != NSNotFound) {
            domainName = [telegramMeLink substringToIndex:slashRange.location];
            postId = [telegramMeLink substringFromIndex:slashRange.location + 1];
        }
        NSMutableString *internalUrl = nil;
        if (postId.length == 0) {
            internalUrl = [[NSMutableString alloc] initWithFormat:@"tg://resolve?domain=%@", domainName];
        } else {
            internalUrl = [[NSMutableString alloc] initWithFormat:@"tg://resolve?domain=%@&post=%@", domainName, postId];
        }
        
        if (groupedSingle)
             [internalUrl appendString:@"&single"];
        
        if (startPrivatePayload.length != 0 || startGroupPayload.length != 0 || gamePayload != nil)
        {
            if (startPrivatePayload.length != 0)
                [internalUrl appendFormat:@"&start=%@", startPrivatePayload];
            if (startGroupPayload.length != 0)
                [internalUrl appendFormat:@"&startgroup=%@", startGroupPayload];
            if (gamePayload.length != 0)
                [internalUrl appendFormat:@"&game=%@", gamePayload];
        }
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true keepStack:keepStack];
        return true;
    }
    
    NSString *shareLinkFromText = [self shareLinkFromText:rawAbsoluteString];
    if (shareLinkFromText.length != 0) {
        NSMutableString *internalUrl = [[NSMutableString alloc] initWithFormat:@"tg://msg_url?%@", shareLinkFromText];
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true];
        return true;
    }
    
    NSString *socksLink = [self socksLinkFromText:rawAbsoluteString];
    if (socksLink.length != 0) {
        NSMutableString *internalUrl = [[NSMutableString alloc] initWithFormat:@"tg://socks?%@", socksLink];
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true];
        return true;
    }
    
    NSString *proxyLink = [self proxyLinkFromText:rawAbsoluteString];
    if (proxyLink.length != 0) {
        NSMutableString *internalUrl = [[NSMutableString alloc] initWithFormat:@"tg://proxy?%@", proxyLink];
        [(TGAppDelegate *)self.delegate handleOpenDocument:[NSURL URLWithString:internalUrl] animated:true];
        return true;
    }
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone && iosMajorVersion() >= 9 && ([url.scheme isEqual:@"http"] || [url.scheme isEqual:@"https"])) {
        
        UIViewController *parentController = TGAppDelegateInstance.window.rootViewController;
        if ([parentController.presentedViewController isKindOfClass:[TGHashtagOverviewController class]])
        {
            parentController = parentController.presentedViewController;
        }
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            dispatch_async(dispatch_get_main_queue(), ^{
                SFSafariViewController *controller = [[SFSafariViewController alloc] initWithURL:url entersReaderIfAvailable:false];
                [parentController presentViewController:controller animated:true completion:nil];
            });
        } else {
            SFSafariViewController *controller = [[SFSafariViewController alloc] initWithURL:url entersReaderIfAvailable:false];
            [parentController presentViewController:controller animated:true completion:nil];
        }
        return true;
    }
    
    return [super openURL:url];
}

- (BOOL)openURL:(NSURL *)url
{
    return [self openURL:url forceNative:false];
}

- (BOOL)nativeOpenURL:(NSURL *)url
{
    return [super openURL:url];
}

- (void)setStatusBarStyle:(UIStatusBarStyle)statusBarStyle
{
    [self setStatusBarStyle:statusBarStyle animated:false];
}

- (void)setStatusBarStyle:(UIStatusBarStyle)__unused statusBarStyle animated:(BOOL)__unused animated
{
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    [self setStatusBarHidden:statusBarHidden withAnimation:UIStatusBarAnimationNone];
}

- (void)setStatusBarHidden:(BOOL)hidden withAnimation:(UIStatusBarAnimation)animation
{
    if (_processStatusBarHiddenRequests)
    {
        /*if (animation != UIStatusBarAnimationNone)
         {
         [TGHacks animateApplicationStatusBarAppearance:hidden ? TGStatusBarAppearanceAnimationSlideUp : TGStatusBarAppearanceAnimationSlideUp duration:0.3 completion:^
         {
         if (hidden)
         [TGHacks setApplicationStatusBarAlpha:0.0f];
         }];
         
         if (!hidden)
         [TGHacks setApplicationStatusBarAlpha:1.0f];
         }
         else
         {
         [TGHacks setApplicationStatusBarAlpha:hidden ? 0.0f : 1.0f];
         }*/
        
        [self forceSetStatusBarHidden:hidden withAnimation:animation];
    }
}

- (void)forceSetStatusBarStyle:(UIStatusBarStyle)statusBarStyle animated:(BOOL)animated
{
    [super setStatusBarStyle:statusBarStyle animated:animated];
}

- (void)forceSetStatusBarHidden:(BOOL)hidden withAnimation:(UIStatusBarAnimation)animation
{
    [super setStatusBarHidden:hidden withAnimation:animation];
}

@end
