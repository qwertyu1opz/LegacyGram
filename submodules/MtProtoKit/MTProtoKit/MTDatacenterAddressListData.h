#import <Foundation/Foundation.h>

@interface MTDatacenterAddressListData : NSObject

@property (nonatomic, strong, readonly) NSDictionary *addressList;

- (instancetype)initWithAddressList:(NSDictionary *)addressList;

@end
