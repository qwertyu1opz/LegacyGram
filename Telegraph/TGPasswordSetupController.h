#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@interface TGPasswordSetupController : TGViewController

@property (nonatomic, copy) void (^completion)(NSString *);

- (instancetype)initWithSetupNew:(bool)setupNew;

@end
