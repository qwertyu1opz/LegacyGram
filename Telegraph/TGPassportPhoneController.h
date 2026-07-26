#import "TGCollectionMenuController.h"
#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"
#import "TGPassportForm.h"

@interface TGPassportPhoneController : TGCollectionMenuController

@property (nonatomic, strong) void (^completionBlock)(TGPassportDecryptedValue *);

- (instancetype)initWithSettings:(SVariable *)settings;

@end
