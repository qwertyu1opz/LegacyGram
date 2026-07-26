#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "../submodules/LegacyComponents/LegacyComponents/ActionStage.h"

@interface TGLoginPhoneController : TGViewController <ASWatcher>

@property (nonatomic, strong) ASHandle *actionHandle;

- (void)setPhoneNumber:(NSString *)phoneNumber;

@end
