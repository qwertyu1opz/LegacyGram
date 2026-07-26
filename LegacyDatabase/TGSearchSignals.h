#import <Foundation/Foundation.h>

#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

#import "TGShareContext.h"

@interface TGSearchSignals : NSObject

+ (SSignal *)searchChatsWithContext:(TGShareContext *)context chats:(NSArray *)chats users:(NSArray *)users query:(NSString *)query;
+ (SSignal *)searchUsersWithContext:(TGShareContext *)context query:(NSString *)query;

@end
