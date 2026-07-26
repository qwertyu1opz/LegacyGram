#import "TGOpenInVideoItems.h"

#import "TGRemoteHttpLocationSignal.h"
#import "TGInstagramMediaIdSignal.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGEmbedYoutubePlayerView.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGEmbedVimeoPlayerView.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGEmbedVinePlayerView.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGEmbedCoubPlayerView.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGEmbedInstagramPlayerView.h"
#import "../submodules/LegacyComponents/LegacyComponents/TGEmbedSoundCloudPlayerView.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGProgressWindow.h"

static NSString *TGYouTubeVideoIdentifierFromURL(NSURL *url)
{
    NSString *host = [url.host lowercaseString];
    if (host.length == 0)
        return nil;

    NSString *candidate = nil;

    if ([host isEqualToString:@"youtu.be"] || [host hasSuffix:@".youtu.be"])
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
    else if ([host isEqualToString:@"youtube.com"] || [host hasSuffix:@".youtube.com"] || [host isEqualToString:@"youtube-nocookie.com"] || [host hasSuffix:@".youtube-nocookie.com"])
    {
        for (NSString *queryItem in [url.query componentsSeparatedByString:@"&"])
        {
            NSRange separator = [queryItem rangeOfString:@"="];
            if (separator.location != NSNotFound && [[queryItem substringToIndex:separator.location] isEqualToString:@"v"])
            {
                candidate = [[queryItem substringFromIndex:separator.location + 1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                break;
            }
        }

        if (candidate.length == 0)
        {
            NSArray *components = [url.path componentsSeparatedByString:@"/"];
            for (NSUInteger index = 0; index + 1 < components.count; index++)
            {
                NSString *component = [components[index] lowercaseString];
                if ([component isEqualToString:@"shorts"] || [component isEqualToString:@"embed"] || [component isEqualToString:@"live"] || [component isEqualToString:@"v"])
                {
                    candidate = components[index + 1];
                    break;
                }
            }
        }
    }

    if (candidate.length == 0)
        return nil;

    NSCharacterSet *invalidCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"] invertedSet];
    NSRange invalidRange = [candidate rangeOfCharacterFromSet:invalidCharacters];
    if (invalidRange.location == 0)
        return nil;
    if (invalidRange.location != NSNotFound)
        candidate = [candidate substringToIndex:invalidRange.location];
    return candidate.length == 0 ? nil : candidate;
}

@interface TGOpenInYoutubeItem : TGOpenInVideoItem

@end

@interface TGOpenInVimeoItem : TGOpenInVideoItem

@end

@interface TGOpenInVineItem : TGOpenInVideoItem

@end

@interface TGOpenInCoubItem : TGOpenInVideoItem

@end

@interface TGOpenInInstagramItem : TGOpenInVideoItem

@end

@interface TGOpenInSoundCloudItem : TGOpenInVideoItem

@end

@interface TGOpenInVideoItem ()

@end

@implementation TGOpenInVideoItem

+ (NSArray *)appItemsClasses
{
    static dispatch_once_t onceToken;
    static NSArray *appItems;
    dispatch_once(&onceToken, ^
    {
        appItems = @
        [
            [TGOpenInYoutubeItem class],
            [TGOpenInVimeoItem class],
            [TGOpenInVineItem class],
            [TGOpenInCoubItem class],
            [TGOpenInInstagramItem class],
            [TGOpenInSoundCloudItem class]
        ];
    });
    return appItems;
}

+ (NSArray *)appItemsForURL:(NSURL *)url userInfo:(NSDictionary *)userInfo
{
    NSArray *appItemsClasses = [self appItemsClasses];
    NSMutableArray *appItems = [[NSMutableArray alloc] init];
    for (id class in appItemsClasses)
    {
        if ([class canOpen:url] && [class isAvailable])
        {
            TGOpenInVideoItem *item = [[class alloc] initWithObject:url userInfo:userInfo];
            [appItems addObject:item];
        }
        
    }
    return appItems;
}

+ (bool)canOpen:(id)object
{
    return ([object isKindOfClass:[NSURL class]]);
}

@end


@implementation TGOpenInYoutubeItem

- (NSString *)title
{
    return @"YouTube";
}

- (NSInteger)storeIdentifier
{
    return 544007664;
}

- (void)performOpenIn
{
    NSURL *url = (NSURL *)self.object;
    NSString *identifier = TGYouTubeVideoIdentifierFromURL(url);
    if (identifier.length == 0)
        identifier = [TGEmbedYoutubePlayerView _youtubeVideoIdFromText:url.absoluteString originalUrl:url.absoluteString startTime:NULL];
    if (identifier.length == 0)
        return;
    
    NSURL *openInURL = [NSURL URLWithString:[NSString stringWithFormat:@"youtube://watch?v=%@", identifier]];
    [TGOpenInVideoItem openURL:openInURL];
}

- (bool)suppressSafariItem
{
    return (iosMajorVersion() >= 9);
}

+ (NSString *)defaultURLScheme
{
    return @"youtube";
}

+ (bool)canOpen:(id)object
{
    if (![object isKindOfClass:[NSURL class]])
        return false;
    NSURL *url = (NSURL *)object;
    return TGYouTubeVideoIdentifierFromURL(url).length != 0;
}

@end


@implementation TGOpenInVimeoItem

- (NSString *)title
{
    return @"Vimeo";
}

- (NSInteger)storeIdentifier
{
    return 425194759;
}

- (void)performOpenIn
{
    NSURL *url = (NSURL *)self.object;
    NSString *identifier = [TGEmbedVimeoPlayerView _vimeoVideoIdFromText:url.absoluteString];
    
    NSURL *openInURL = [NSURL URLWithString:[NSString stringWithFormat:@"vimeo://app.vimeo.com/%@", identifier]];
    [TGOpenInVideoItem openURL:openInURL];
}

+ (NSString *)defaultURLScheme
{
    return @"vimeo";
}

+ (bool)canOpen:(id)object
{
    NSURL *url = (NSURL *)object;
    if ([[url.host lowercaseString] rangeOfString:@"vimeo.com"].location != NSNotFound)
        return true;
    
    return false;
}

@end


@implementation TGOpenInVineItem

- (NSString *)title
{
    return @"Vine";
}

- (NSInteger)storeIdentifier
{
    return 592447445;
}

- (void)performOpenIn
{
    NSURL *url = (NSURL *)self.object;
    NSString *identifier = [TGEmbedVinePlayerView _vineVideoIdFromText:url.absoluteString];
    NSString *vineId = [TGEmbedVinePlayerView _vineIdFromPermalink:identifier];
    
    NSURL *openInURL = [NSURL URLWithString:[NSString stringWithFormat:@"vine://post/%@", vineId]];
    [TGOpenInVideoItem openURL:openInURL];
}

+ (NSString *)defaultURLScheme
{
    return @"vine";
}

+ (bool)canOpen:(id)object
{
    NSURL *url = (NSURL *)object;
    if ([[url.host lowercaseString] rangeOfString:@"vine.co"].location != NSNotFound)
        return true;
    
    return false;
}

@end


@implementation TGOpenInCoubItem

- (NSString *)title
{
    return @"Coub";
}

- (NSInteger)storeIdentifier
{
    return 714042522;
}

- (void)performOpenIn
{
    NSURL *url = (NSURL *)self.object;
    
    NSString *identifier = [TGEmbedCoubPlayerView _coubVideoIdFromText:url.absoluteString];
    NSString *metaUrl = [NSString stringWithFormat:@"http://coub.com/api/v2/coubs/%@", identifier];
    
    SSignal *cachedSignal = [[SSignal alloc] initWithGenerator:^id<SDisposable>(SSubscriber *subscriber)
    {
        NSDictionary *json = [TGEmbedCoubPlayerView coubJSONByPermalink:identifier];
        if (json != nil)
        {
            [subscriber putNext:json];
            [subscriber putCompletion];
        }
        else
        {
            [subscriber putError:nil];
        }
        
        return nil;
    }];
    
    SSignal *dataSignal = [[cachedSignal mapToSignal:^SSignal *(NSDictionary *json)
    {
        return [SSignal single:@{ @"json": json, @"cached": @true }];
    }] catch:^SSignal *(__unused id error)
    {
        return [[TGRemoteHttpLocationSignal jsonForHttpLocation:metaUrl] map:^id(NSDictionary *json)
        {
            return @{ @"json": json, @"cached": @false };
        }];
    }];
    
    TGProgressWindow *progressWindow = [[TGProgressWindow alloc] init];
    [progressWindow performSelector:@selector(showAnimated) withObject:nil afterDelay:0.5];
    
    [[[dataSignal deliverOn:[SQueue mainQueue]] onDispose:^
    {
        TGProgressWindow *progressWindow = [[TGProgressWindow alloc] init];
        [progressWindow performSelector:@selector(showAnimated) withObject:nil afterDelay:0.5];
    }] startWithNext:^(NSDictionary *data)
    {
        NSString *coubId = [data[@"json"] objectForKey:@"id"];
        
        if (![data[@"cached"] boolValue])
        [TGEmbedCoubPlayerView setCoubJSON:data[@"json"] forPermalink:identifier];
        
        NSURL *openInURL = [NSURL URLWithString:[NSString stringWithFormat:@"coub://view/%@", coubId]];
        [TGOpenInVideoItem openURL:openInURL];
    }];
}

+ (NSString *)defaultURLScheme
{
    return @"coub";
}

+ (bool)canOpen:(id)object
{
    NSURL *url = (NSURL *)object;
    if ([[url.host lowercaseString] rangeOfString:@"coub.com"].location != NSNotFound)
        return true;
    
    return false;
}

@end


@implementation TGOpenInInstagramItem

- (NSString *)title
{
    return @"Instagram";
}

- (NSInteger)storeIdentifier
{
    return 389801252;
}

- (void)performOpenIn
{
    NSURL *url = (NSURL *)self.object;
    if ([url.path hasPrefix:@"/p/"])
    {
        NSString *identifier = [TGInstagramMediaIdSignal instagramShortcodeFromText:url.absoluteString];
        
        TGProgressWindow *progressWindow = [[TGProgressWindow alloc] init];
        [progressWindow performSelector:@selector(showAnimated) withObject:nil afterDelay:0.5];
        
        [[[[TGInstagramMediaIdSignal instagramMediaIdForShortcode:identifier] deliverOn:[SQueue mainQueue]] onDispose:^
        {
            [NSObject cancelPreviousPerformRequestsWithTarget:progressWindow selector:@selector(showAnimated) object:nil];
            [progressWindow dismiss:true];
        }] startWithNext:^(NSString *mediaId)
        {
            NSURL *openInURL = [NSURL URLWithString:[NSString stringWithFormat:@"instagram://media?id=%@", mediaId]];
            [TGOpenInVideoItem openURL:openInURL];
        }];
    }
    else if (url.pathComponents.count == 2)
    {
        NSString *username = url.pathComponents.lastObject;
        NSURL *openInURL = [NSURL URLWithString:[NSString stringWithFormat:@"instagram://user?username=%@", username]];
        [TGOpenInVideoItem openURL:openInURL];
    }
}

+ (NSString *)defaultURLScheme
{
    return @"instagram";
}

+ (bool)canOpen:(id)object
{
    NSURL *url = (NSURL *)object;
    if ([[[url.host stringByReplacingOccurrencesOfString:@"www." withString:@""] lowercaseString] isEqualToString:@"instagram.com"])
        return true;

    return false;
}

@end


@implementation TGOpenInSoundCloudItem

- (NSString *)title
{
    return @"SoundCloud";
}

- (NSInteger)storeIdentifier
{
    return 336353151;
}

- (void)performOpenIn
{
    NSString *embedUrl = self.userInfo[TGOpenInEmbedURLKey];
    NSString *identifier = [TGEmbedSoundCloudPlayerView _soundCloudIdFromText:embedUrl];
    
    void (^openBlock)(NSString *) = ^(NSString *identifier)
    {
        NSURL *openInURL = [NSURL URLWithString:[NSString stringWithFormat:@"soundcloud://tracks/%@", identifier]];
        [TGOpenInVideoItem openURL:openInURL];
    };
    
    if (identifier != nil)
        openBlock(identifier);
}

+ (NSString *)defaultURLScheme
{
    return @"soundcloud";
}

+ (bool)canOpen:(id)object
{
    NSURL *url = (NSURL *)object;
    if ([[url.host lowercaseString] rangeOfString:@"soundcloud.com"].location != NSNotFound)
        return true;
    
    return false;
}

@end
