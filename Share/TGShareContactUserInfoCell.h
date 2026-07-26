#import <UIKit/UIKit.h>
#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@interface TGShareContactUserInfoCell : UITableViewCell

- (void)setName:(NSString *)name avatarSignal:(SSignal *)avatarSignal;

@end
