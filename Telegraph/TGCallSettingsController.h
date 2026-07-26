#import "TGCollectionMenuController.h"

#import "../submodules/LegacyComponents/LegacyComponents/ASWatcher.h"

@interface TGCallSettingsController : TGCollectionMenuController <ASWatcher>

@property (nonatomic, strong) ASHandle *actionHandle;

@end
