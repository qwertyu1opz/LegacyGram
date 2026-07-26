/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGNativeAudioPlayer.h"

#import "../submodules/LegacyComponents/LegacyComponents/ASQueue.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGObserverProxy.h"

@interface TGNativeAudioPlayer ()
{
    CGFloat _rate;
    AVPlayerItem *_currentItem;
    TGObserverProxy *_didPlayToEndObserver;
    NSString *_currentPath;
    AVPlayerItem *_queuedItem;
    NSString *_queuedPath;
    TGObserverProxy *_queuedDidPlayToEndObserver;
}

@end

static NSString *TGNativeAudioPlayerRealPath(NSString *path)
{
    if (path.length == 0)
        return nil;
    NSString *realPath = path;
    NSArray *audioExtensions = @[@"mp3", @"aac", @"m4a", @"mov", @"mp4"];
    if (![audioExtensions containsObject:realPath.pathExtension.lowercaseString])
    {
        realPath = [path stringByAppendingPathExtension:@"mp3"];
        [[NSFileManager defaultManager] createSymbolicLinkAtPath:realPath withDestinationPath:path error:nil];
    }
    return realPath;
}

@implementation TGNativeAudioPlayer

- (instancetype)initWithPath:(NSString *)path music:(bool)music controlAudioSession:(bool)controlAudioSession
{
    self = [super initWithMusic:music controlAudioSession:controlAudioSession];
    if (self != nil)
    {
        _rate = 1.0f;
        
        __autoreleasing NSError *error = nil;
        NSString *realPath = TGNativeAudioPlayerRealPath(path);
        _currentPath = [realPath copy];
        _currentItem = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:realPath]];
        if (_currentItem != nil) {
            _player = [[AVQueuePlayer alloc] initWithItems:@[_currentItem]];
            _didPlayToEndObserver = [[TGObserverProxy alloc] initWithTarget:self targetSelector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:_currentItem];
        }
        
        if (_player == nil || error != nil)
        {
            [self cleanupWithError];
        }
    }
    return self;
}

- (bool)replaceWithPath:(NSString *)path
{
    NSString *realPath = TGNativeAudioPlayerRealPath(path);
    if (realPath.length == 0 || _player == nil)
        return false;

    __block bool replaced = false;
    [[TGAudioPlayer _playerQueue] dispatchOnQueue:^
    {
        if (_queuedItem != nil && [_queuedPath isEqualToString:realPath] && ((AVQueuePlayer *)_player).currentItem == _queuedItem)
        {
            _currentItem = _queuedItem;
            _currentPath = _queuedPath;
            _didPlayToEndObserver = _queuedDidPlayToEndObserver;
            _queuedItem = nil;
            _queuedPath = nil;
            _queuedDidPlayToEndObserver = nil;
            replaced = true;
            return;
        }

        AVPlayerItem *nextItem = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:realPath]];
        if (nextItem != nil)
        {
            _didPlayToEndObserver = nil;
            _queuedDidPlayToEndObserver = nil;
            _queuedItem = nil;
            _queuedPath = nil;
            _currentItem = nextItem;
            _currentPath = [realPath copy];
            [(AVQueuePlayer *)_player removeAllItems];
            [(AVQueuePlayer *)_player insertItem:nextItem afterItem:nil];
            _didPlayToEndObserver = [[TGObserverProxy alloc] initWithTarget:self targetSelector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:nextItem];
            replaced = true;
        }
    } synchronous:true];
    return replaced;
}

- (bool)prepareNextPath:(NSString *)path
{
    NSString *realPath = TGNativeAudioPlayerRealPath(path);
    if (realPath.length == 0 || _player == nil)
        return false;

    __block bool prepared = false;
    [[TGAudioPlayer _playerQueue] dispatchOnQueue:^
    {
        if ([_currentPath isEqualToString:realPath] || [_queuedPath isEqualToString:realPath])
        {
            prepared = true;
            return;
        }

        AVQueuePlayer *queuePlayer = (AVQueuePlayer *)_player;
        if (_queuedItem != nil)
        {
            [queuePlayer removeItem:_queuedItem];
            _queuedDidPlayToEndObserver = nil;
            _queuedItem = nil;
            _queuedPath = nil;
        }

        AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:[NSURL fileURLWithPath:realPath]];
        if (item != nil && [queuePlayer canInsertItem:item afterItem:_currentItem])
        {
            [queuePlayer insertItem:item afterItem:_currentItem];
            _queuedItem = item;
            _queuedPath = [realPath copy];
            _queuedDidPlayToEndObserver = [[TGObserverProxy alloc] initWithTarget:self targetSelector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:item];
            prepared = true;
        }
    } synchronous:true];
    return prepared;
}

- (void)dealloc
{
    [self cleanup];
}

- (void)cleanupWithError
{
    [self cleanup];
}

- (void)cleanup
{
    AVPlayer *player = _player;
    _player = nil;
    
    [[TGAudioPlayer _playerQueue] dispatchOnQueue:^
    {
        [player pause];
    }];
    
    [self _endAudioSessionFinal];
}

- (void)playFromPosition:(NSTimeInterval)position
{
    [[TGAudioPlayer _playerQueue] dispatchOnQueue:^
    {
        [self _beginAudioSession];
        
        if (position >= 0.0) {
            CMTime targetTime = CMTimeMakeWithSeconds(position, NSEC_PER_SEC);
            [_currentItem seekToTime:targetTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if (iosMajorVersion() >= 7)
            _currentItem.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmTimeDomain;
#endif
        [_player play];
        _player.rate = (float)_rate;
    }];
}

- (void)pause:(void (^)())completion
{
    [[TGAudioPlayer _playerQueue] dispatchOnQueue:^
    {
        [_player pause];
        if (completion) {
            completion();
        }
    }];
}

- (void)stop
{
    [[TGAudioPlayer _playerQueue] dispatchOnQueue:^
    {
        [_player pause];
    }];
}

- (void)setRate:(CGFloat)rate
{
    [[TGAudioPlayer _playerQueue] dispatchOnQueue:^
    {
        _rate = rate;
        [_player setRate:(float)rate];
    }];
}

- (NSTimeInterval)currentPositionSync:(bool)sync
{
    __block NSTimeInterval result = 0.0;
    
    dispatch_block_t block = ^
    {
        result = CMTimeGetSeconds(_currentItem.currentTime);
    };
    
    if (sync)
        [[TGAudioPlayer _playerQueue] dispatchOnQueue:block synchronous:true];
    else
        block();
    
    return result;
}

- (NSTimeInterval)duration
{
    return CMTimeGetSeconds(_currentItem.duration);
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)__unused player successfully:(BOOL)__unused flag
{
}

- (void)playerItemDidPlayToEndTime:(NSNotification *)__unused notification
{
    // AVQueuePlayer starts the prepared item by itself, including while the
    // process is suspended.  Pausing here would stop that automatic hand-off.
    if (_queuedItem == nil)
        [_player pause];
    
    [self _notifyFinished];
}

@end
