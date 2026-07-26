#import "TGEmbedPIPScrubber.h"

#import "LegacyComponentsInternal.h"

@interface TGEmbedPIPScrubber ()
{
    UIView *_playProgressView;
    UIView *_remainingProgressView;
    UIView *_downloadProgressView;
}
@end

@implementation TGEmbedPIPScrubber

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        self.userInteractionEnabled = false;
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        id lightBlurEffect = nil;
#endif
        _playProgressView = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:_playProgressView];
        
        _downloadProgressView = [[UIView alloc] init];
        _downloadProgressView.backgroundColor = UIColorRGBA(0x000000, 0.45f);
        [self addSubview:_downloadProgressView];
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        id blurEffect = nil;
#endif
        _remainingProgressView = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:_remainingProgressView];
    }
    return self;
}

- (void)setPlayProgress:(CGFloat)playProgress
{
    if (isnan(playProgress))
        playProgress = 0.0f;
    
    _playProgress = playProgress;
    [self setNeedsLayout];
}

- (void)setDownloadProgress:(CGFloat)downloadProgress
{
    _downloadProgress = downloadProgress;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat playedWidth = floor(self.frame.size.width * _playProgress);
    if (isnan(playedWidth))
        playedWidth = 0.0f;
    
    _playProgressView.frame = CGRectMake(0, 0, playedWidth, self.frame.size.height);
    _remainingProgressView.frame = CGRectMake(playedWidth, 0, self.frame.size.width - playedWidth, self.frame.size.height);
    
    CGFloat downloadedWidth = MAX(0.0f, playedWidth - floor(self.frame.size.width * _downloadProgress));
    _downloadProgressView.frame = CGRectMake(playedWidth, 0, downloadedWidth, self.frame.size.height);
}

@end
