#import <Foundation/Foundation.h>

@interface MTDatacenterVerificationData : NSObject

@property (nonatomic, readonly) NSInteger datacenterId;
@property (nonatomic, readonly) bool isTestingEnvironment;

- (instancetype )initWithDatacenterId:(NSInteger)datacenterId isTestingEnvironment:(bool)isTestingEnvironment;

@end
