#import <Foundation/Foundation.h>

#import "../thirdparty/SSignalKit/SSignalKit/SSignalKit.h"

@interface TGPeerInfoSignals : NSObject

+ (SSignal *)resolveBotDomain:(NSString *)query;
+ (SSignal *)resolveBotDomain:(NSString *)query contextBotsOnly:(bool)contextBotsOnly;

+ (SSignal *)dismissReportSpamForPeers;

@end
