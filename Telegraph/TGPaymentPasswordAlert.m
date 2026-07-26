#import "TGPaymentPasswordAlert.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

@interface TGPaymentPasswordAlertContext : NSObject

@property (nonatomic, weak) UIAlertController *controller;

@end

@implementation TGPaymentPasswordAlertContext

- (instancetype)initWithController:(UIAlertController *)controller {
    self = [super init];
    if (self != nil) {
        self.controller = controller;
    }
    return self;
}

- (void)passwordChanged:(UITextField *)textField {
    __strong UIAlertController *controller = self.controller;
    if (controller != nil) {
    }
}

@end

#endif

@implementation TGPaymentPasswordAlert

+ (UIViewController *)alertWithText:(NSString *)text result:(void (^)(NSString *))result {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    UIAlertController *alerController = [UIAlertController alertControllerWithTitle:@"Payment Confirmation" message:text preferredStyle:UIAlertControllerStyleAlert];
    TGPaymentPasswordAlertContext *context = [[TGPaymentPasswordAlertContext alloc] initWithController:alerController];
    
    [alerController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Password";
        textField.secureTextEntry = YES;
        [textField addTarget:context action:@selector(passwordChanged:) forControlEvents:UIControlEventEditingChanged];
    }];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Pay" style: UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        __strong UIAlertController *controller = context.controller;
        if (controller != nil) {
            result(controller.textFields[0].text);
        }
    }];
    [alerController addAction:confirmAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *action) {
        [context description];
    }];
    [alerController addAction:cancelAction];
    return alerController;
#else
    return nil;
#endif
}

@end
