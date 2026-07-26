#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "../submodules/LegacyComponents/LegacyComponents/ActionStage.h"

@class TGTermsOfService;

@interface TGLoginCodeController : TGViewController <ASWatcher, TGNavigationControllerItem>

@property (nonatomic, strong) ASHandle *actionHandle;

@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSString *phoneCodeHash;
@property (nonatomic, strong) NSString *phoneCode;

- (id)initWithShowKeyboard:(bool)showKeyboard phoneNumber:(NSString *)phoneNumber phoneCodeHash:(NSString *)phoneCodeHash phoneTimeout:(NSTimeInterval)phoneTimeout messageSentToTelegram:(bool)messageSentToTelegram messageSentViaPhone:(bool)messageSentViaPhone termsOfService:(TGTermsOfService *)termsOfService;

- (void)applyCode:(NSString *)code;

@end
