#import "TGEmbedVimeoPlayerView.h"
#import "TGEmbedPlayerState.h"

#import "LegacyComponentsInternal.h"

NSString *const TGVimeoPlayerCallbackOnReady = @"onReady";
NSString *const TGVimeoPlayerCallbackOnState = @"onState";

static NSDictionary *TGEmbedLegacyQueryParameters(NSURL *url)
{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSString *query = [url query];
    for (NSString *part in [query componentsSeparatedByString:@"&"])
    {
        if (part.length == 0)
            continue;
        NSRange range = [part rangeOfString:@"="];
        NSString *key = nil;
        NSString *value = nil;
        if (range.location == NSNotFound)
        {
            key = part;
            value = @"";
        }
        else
        {
            key = [part substringToIndex:range.location];
            value = [part substringFromIndex:range.location + range.length];
        }
        key = [key stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if (key != nil && value != nil)
            [result setObject:value forKey:key];
    }
    return result;
}

@interface TGEmbedVimeoPlayerView ()
{
    NSString *_videoId;
    
    bool _started;
    bool _initiallyPlayed;
    
    NSInteger _ignorePositionUpdates;
}
@end

@implementation TGEmbedVimeoPlayerView

- (instancetype)initWithWebPageAttachment:(TGWebPageMediaAttachment *)webPage thumbnailSignal:(SSignal *)thumbnailSignal alternateCachePathSignal:(SSignal *)alternateCachePathSignal
{
    self = [super initWithWebPageAttachment:webPage thumbnailSignal:thumbnailSignal alternateCachePathSignal:alternateCachePathSignal];
    if (self != nil)
    {
        _videoId = [TGEmbedVimeoPlayerView _vimeoVideoIdFromText:webPage.embedUrl];
    }
    return self;
}

- (void)playVideo
{
    [super playVideo];
    
    if (_initiallyPlayed)
    {
        [self _evaluateJS:@"player.api('play');" completion:nil];
    }
    else
    {
        [self _evaluateJS:@"injectCmd('initialPlay')" completion:nil];
        _initiallyPlayed = true;
    }
    
    _ignorePositionUpdates = 2;
}

- (void)pauseVideo:(bool)manually
{
    [super pauseVideo:manually];
    [self _evaluateJS:@"player.api('pause');" completion:nil];
}

- (void)seekToPosition:(NSTimeInterval)position
{
    NSString *command = [NSString stringWithFormat:@"player.api('seekTo', %@);", @(position)];
    [self _evaluateJS:command completion:nil];
    
    TGEmbedPlayerState *newState = [TGEmbedPlayerState stateWithPlaying:self.state.isPlaying duration:self.state.duration position:position downloadProgress:self.state.downloadProgress buffering:self.state.buffering];
    [self updateState:newState];
    
    _ignorePositionUpdates = 2;
}

- (TGEmbedPlayerControlsType)_controlsType
{
    return TGEmbedPlayerControlsTypeFull;
}

- (void)_onPageReady
{
    
}

- (void)_didBeginPlayback
{
    [super _didBeginPlayback];
    
    TGDispatchAfter(0.5, dispatch_get_main_queue(), ^
    {
        [self setDimmed:false animated:true shouldDelay:false];
    });
}

- (void)_notifyOfCallbackURL:(NSURL *)url
{
    NSString *action = url.host;
    
    NSString *query = url.query;
    NSString *data;
    if (query != nil)
        data = [query componentsSeparatedByString:@"="][1];
    
    if ([action isEqual:TGVimeoPlayerCallbackOnReady])
    {
        
    }
    else if ([action isEqualToString:TGVimeoPlayerCallbackOnState])
    {
        NSDictionary *queryItems = TGEmbedLegacyQueryParameters(url);
        
        bool playing = self.state.playing;
        bool finished = false;
        NSTimeInterval position = self.state.position;
        NSTimeInterval duration = self.state.duration;
        CGFloat downloadProgress = self.state.downloadProgress;
        bool buffering = self.state.buffering;

        NSString *playbackValue = [queryItems objectForKey:@"playback"];
        if (playbackValue != nil)
        {
            playing = ([playbackValue integerValue] == 1);
            finished = ([playbackValue integerValue] == 2);
        }
        NSString *positionValue = [queryItems objectForKey:@"position"];
        if (positionValue != nil)
        {
            if (_ignorePositionUpdates > 0)
                _ignorePositionUpdates--;
            else
                position = [positionValue doubleValue];
        }
        NSString *durationValue = [queryItems objectForKey:@"duration"];
        if (durationValue != nil)
            duration = [durationValue doubleValue];
        NSString *downloadValue = [queryItems objectForKey:@"download"];
        if (downloadValue != nil)
            downloadProgress = [downloadValue floatValue];
        
        if (!_started && playing)
        {
            _started = true;
            [self _didBeginPlayback];
        }
        
        if (finished)
            position = 0.0;
        
        TGEmbedPlayerState *newState = [TGEmbedPlayerState stateWithPlaying:playing duration:duration position:position downloadProgress:downloadProgress buffering:buffering];
        [self updateState:newState];
    }
}

- (NSString *)_embedHTML
{
    NSError *error = nil;
    NSString *path = TGComponentsPathForResource(@"VimeoPlayer", @"html");
    
    NSString *embedHTMLTemplate = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (error != nil)
    {
        TGLegacyLog(@"[VimeoEmbedPlayer]: Received error rendering template: %@", error);
        return nil;
    }
    
    NSString *autoplay = self.disallowAutoplay ? @"false" : @"true";
    NSString *embedHTML = [NSString stringWithFormat:embedHTMLTemplate, _videoId, autoplay];
    return embedHTML;
}

- (NSURL *)_baseURL
{
    return [NSURL URLWithString:@"https://player.vimeo.com/"];
}

- (void)_setupUserScripts:(WKUserContentController *)contentController
{
    NSError *error = nil;
    NSString *path = TGComponentsPathForResource(@"VimeoPlayerInject", @"js");
    NSString *scriptText = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (error != nil)
        TGLegacyLog(@"[VimeoEmbedPlayer]: Received error loading inject script: %@", error);
    
    WKUserScript *script = [[WKUserScript alloc] initWithSource:scriptText injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:false];
    [contentController addUserScript:script];
}

- (bool)_scaleViewToMaxSize
{
    return true;
}

+ (NSString *)_vimeoVideoIdFromText:(NSString *)text
{
    if ([text hasPrefix:@"http://player.vimeo.com/video/"] || [text hasPrefix:@"https://player.vimeo.com/video/"])
    {
        NSString *suffix = @"";
        
        NSMutableArray *prefixes = [NSMutableArray arrayWithArray:@
        [
            @"http://player.vimeo.com/video/",
            @"https://player.vimeo.com/video/"
        ]];
        
        while (suffix.length == 0 && prefixes.count > 0)
        {
            NSString *prefix = prefixes.firstObject;
            if ([text hasPrefix:prefix])
            {
                suffix = [text substringFromIndex:prefix.length];
                break;
            }
            else
            {
                [prefixes removeObjectAtIndex:0];
            }
        }
        
        for (int i = 0; i < (int)suffix.length; i++)
        {
            unichar c = [suffix characterAtIndex:i];
            if (!((c >= '0' && c <= '9')))
                break;
        }
        
        return suffix;
    }
    
    return nil;
}

+ (bool)_supportsWebPage:(TGWebPageMediaAttachment *)webPage
{
    NSString *url = webPage.embedUrl;
    return ([url hasPrefix:@"http://player.vimeo.com/video/"] || [url hasPrefix:@"https://player.vimeo.com/video/"]);
}

@end
