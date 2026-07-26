#import <UIKit/UIKit.h>

#import "../submodules/LegacyComponents/LegacyComponents/LegacyComponents.h"

@interface TGPaymentWebController : TGViewController

@property (nonatomic, copy) void (^completed)(NSString *data, NSString *title, bool save);
@property (nonatomic, copy) void (^completedConfirmation)();

- (instancetype)initWithUrl:(NSString *)url confirmation:(bool)confirmation canSave:(bool)canSave allowSaving:(bool)allowSaving;

@end
