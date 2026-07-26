/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGModernConversationAudioPlayer.h"
#import "IOS6FeatureProbe.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGTimerTarget.h"

#import "TGModernConversationAudioPlayerContext.h"

#ifndef IOS6_MUSIC_LOG
#define IOS6_MUSIC_LOG(...) do { } while (0)
#endif

@interface TGModernConversationAudioPlayer () <TGAudioPlayerDelegate>
{
    NSString *_filePath;
    bool _music;
    bool _controlAudioSession;
    
    CGFloat _rate;
    
    NSTimer *_timer;
    
    TGModernConversationAudioPlayerContext *_inlineMediaContext;
    
    bool _isPaused;
    bool _isFinished;
}

@end

@implementation TGModernConversationAudioPlayer

- (instancetype)initWithFilePath:(NSString *)filePath music:(bool)music controlAudioSession:(bool)controlAudioSession
{
    self = [super init];
    if (self != nil)
    {
        _filePath = filePath;
        _music = music;
        _controlAudioSession = controlAudioSession;
        _rate = 1.0f;
        
        _audioPlayer = [TGAudioPlayer audioPlayerForPath:filePath music:music controlAudioSession:controlAudioSession];
        _audioPlayer.delegate = self;
        _queue = [SQueue mainQueue];
    }
    return self;
}

- (void)dealloc
{
    [self cleanup];
}

- (void)cleanup
{
    if (_timer != nil)
    {
        [_timer invalidate];
        _timer = nil;
    }
    
    if (_audioPlayer != nil)
    {
        _audioPlayer.delegate = nil;
        [_audioPlayer stop];
        _audioPlayer = nil;
    }
}

- (TGModernViewInlineMediaContext *)inlineMediaContext
{
    if (_inlineMediaContext == nil)
        _inlineMediaContext = [[TGModernConversationAudioPlayerContext alloc] initWithAudioPlayer:self];
    
    return _inlineMediaContext;
}

- (void)setRate:(CGFloat)rate
{
    _rate = rate;
    if (_audioPlayer != nil) {
        [_audioPlayer setRate:_rate];
    }
}

- (void)play
{
    if (_audioPlayer == nil) {
        _audioPlayer = [TGAudioPlayer audioPlayerForPath:_filePath music:_music controlAudioSession:_controlAudioSession];
        [_audioPlayer setRate:_rate];
        _audioPlayer.delegate = self;
    }
    
    _isPaused = false;
    _isFinished = false;
    
    if (_timer != nil)
    {
        [_timer invalidate];
        _timer = nil;
    }
    
    [_audioPlayer play];
    
    [self updateCurrentTime];
    _timer = [TGTimerTarget scheduledMainThreadTimerWithTarget:self action:@selector(updateCurrentTime) interval:0.01 repeat:true];
}

- (void)play:(float)playbackPosition
{
    _isPaused = false;
    _isFinished = false;
    
    if (_timer != nil)
    {
        [_timer invalidate];
        _timer = nil;
    }
    
    NSTimeInterval preciseDuration = [_audioPlayer duration];
    if (preciseDuration > 0.1)
    {
        [_audioPlayer playFromPosition:MAX(0.0, MIN(preciseDuration, playbackPosition * preciseDuration))];
        [_inlineMediaContext postUpdatePlaybackPosition:true];
    }
    else
    {
        [_audioPlayer play];
        [self updateCurrentTime];
    }
    
    _timer = [TGTimerTarget scheduledMainThreadTimerWithTarget:self action:@selector(updateCurrentTime) interval:0.01 repeat:true];
}

- (void)updateCurrentTime
{
    [_inlineMediaContext postUpdatePlaybackPosition:false];
}

- (void)pause {
    [self pause:^{}];
}

- (void)pause:(void (^)())completion
{
    _isPaused = true;
    
    [_audioPlayer pause:completion];
    
    if (_timer != nil)
    {
        [_timer invalidate];
        _timer = nil;
    }
    
    [_inlineMediaContext postUpdatePlaybackPosition:false];
}

- (void)stop
{
    _isPaused = true;
    
    [_audioPlayer stop];
    
    if (_timer != nil)
    {
        [_timer invalidate];
        _timer = nil;
    }
    
    [self cleanup];
}

- (bool)replaceWithFilePath:(NSString *)filePath
{
    if (!_music || _audioPlayer == nil || ![_audioPlayer replaceWithPath:filePath])
        return false;
    _filePath = [filePath copy];
    _isPaused = false;
    _isFinished = false;
    return true;
}

- (bool)prepareNextFilePath:(NSString *)filePath
{
    if (!_music || _audioPlayer == nil)
        return false;
    return [_audioPlayer prepareNextPath:filePath];
}

- (float)playbackPosition
{
    return [self playbackPositionSync:false];
}

- (float)playbackPositionSync:(bool)sync
{
    NSTimeInterval duration = [_audioPlayer duration];
    if (duration > 0.1)
        return (float)([_audioPlayer currentPositionSync:sync] / duration);
    
    return 0.0f;
}

- (NSTimeInterval)absolutePlaybackPosition {
    return [_audioPlayer currentPositionSync:true];
}

- (NSTimeInterval)duration
{
    return [_audioPlayer duration];
}

- (bool)isPaused
{
    return _isPaused;
}

- (bool)isFinished
{
    return _isFinished;
}

- (void)audioPlayerDidPause:(TGAudioPlayer *)__unused audioPlayer {
    TGDispatchOnMainThread(^{
        _isPaused = true;
        
        if (_timer != nil)
        {
            [_timer invalidate];
            _timer = nil;
        }
        
        [_inlineMediaContext postUpdatePlaybackPosition:false];
    });
}

- (void)audioPlayerDidFinishPlaying:(TGAudioPlayer *)__unused audioPlayer
{
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier backgroundTask = UIBackgroundTaskInvalid;
    if (application.applicationState != UIApplicationStateActive)
    {
        dispatch_block_t beginTask = ^
        {
            backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^
            {
                UIBackgroundTaskIdentifier task = backgroundTask;
                backgroundTask = UIBackgroundTaskInvalid;
                if (task != UIBackgroundTaskInvalid)
                    [application endBackgroundTask:task];
            }];
        };
        if ([NSThread isMainThread])
            beginTask();
        else
            dispatch_sync(dispatch_get_main_queue(), beginTask);
    }
    IOS6_MUSIC_LOG(@"MUSIC audio.finish.callback music=%d task=%d", _music ? 1 : 0, (int)backgroundTask);

    TGDispatchOnMainThread(^
    {
        _isPaused = true;
        _isFinished = true;
        
        if (_timer != nil)
        {
            [_timer invalidate];
            _timer = nil;
        }
        
        [_inlineMediaContext postUpdatePlaybackPosition:false];
        
        // Keep the native AVPlayer alive for music.  iOS 6 frequently refuses
        // to start a newly-created AVPlayer after the screen has locked; the
        // music player replaces its item instead.
        if (!_music)
            [self cleanup];
        
        id<TGModernConversationAudioPlayerDelegate> delegate = _delegate;
        IOS6_MUSIC_LOG(@"MUSIC audio.finish.delegate delegate=%@ responds=%d", NSStringFromClass([(id)delegate class]), [delegate respondsToSelector:@selector(audioPlayerDidFinish)] ? 1 : 0);
        if ([delegate respondsToSelector:@selector(audioPlayerDidFinish)])
            [delegate audioPlayerDidFinish];

        // The delegate schedules the actual next-track work asynchronously.
        // Keep this tiny bridge alive long enough for that work to create and
        // start the next audio player before iOS suspends the process again.
        if (backgroundTask != UIBackgroundTaskInvalid)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
            {
                UIBackgroundTaskIdentifier task = backgroundTask;
                backgroundTask = UIBackgroundTaskInvalid;
                if (task != UIBackgroundTaskInvalid)
                {
                    IOS6_MUSIC_LOG(@"MUSIC audio.finish.taskEnd task=%d", (int)task);
                    [application endBackgroundTask:task];
                }
            });
        }
    });
}

@end
