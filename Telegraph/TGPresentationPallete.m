#import "TGPresentationPallete.h"

#import "TGWallpaperManager.h"

#import "../submodules/LegacyComponents/LegacyComponents/TGColorWallpaperInfo.h"

@implementation TGPresentationPallete

+ (bool)hasWallpaper
{
    return ![[[TGWallpaperManager instance] currentWallpaperInfo] isKindOfClass:[TGColorWallpaperInfo class]];
}

@end
