#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TGPaymentPasswordAlert : NSObject

+ (UIViewController *)alertWithText:(NSString *)text result:(void (^)(NSString *))result;

@end
