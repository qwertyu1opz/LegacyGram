#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "../submodules/LegacyComponents/LegacyComponents/ASWatcher.h"

#import "TGCollectionMenuController.h"

@interface TGAccountSettingsController : TGCollectionMenuController <ASWatcher>

@property (nonatomic, strong) ASHandle *actionHandle;

- (id)initWithUid:(int32_t)uid;

- (void)_updateProfileImage:(UIImage *)image;

@end
