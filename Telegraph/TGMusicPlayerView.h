#import <UIKit/UIKit.h>

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "TGMusicPlayer.h"

@interface TGMusicPlayerView : UIView <TGNavigationBarMusicPlayerView>

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController;

- (void)setStatus:(TGMusicPlayerStatus *)status;

@end
