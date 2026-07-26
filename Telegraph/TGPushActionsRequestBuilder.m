#import "TGPushActionsRequestBuilder.h"

#import "TGAppDelegate.h"

#import "TGTelegraph.h"

static NSString *devicePushToken = nil;

@interface TGPushActionsRequestBuilder () <TGDeviceTokenListener>

@end

@implementation TGPushActionsRequestBuilder

+ (NSString *)genericPath
{
    return @"/tg/service/settings/push/@";
}

+ (void)clearCachedDevicePushToken
{
    devicePushToken = nil;
}

- (void)execute:(NSDictionary *)__unused options
{
    NSRange range;
    range.location = [@"/tg/service/settings/push/(" length];
    range.length = [self.path length] - 1 - range.location;
    NSString *action = [self.path substringWithRange:range];

    bool apnsEnabled = TGIOS6APNsNotificationsEnabled();
    if ([action isEqualToString:@"subscribe"] && !apnsEnabled)
    {
        NSString *tokenToRemove = devicePushToken;
        devicePushToken = nil;

        if (tokenToRemove.length != 0)
            self.cancelToken = [TGTelegraphInstance doUpdatePushSubscription:false deviceToken:tokenToRemove requestBuilder:self];
        else
            [ActionStageInstance() actionCompleted:self.path result:nil];
        return;
    }

    if ([action isEqualToString:@"unsubscribe"] && devicePushToken == nil)
    {
        [ActionStageInstance() actionCompleted:self.path result:nil];
        return;
    }

    if (devicePushToken == nil)
    {
        TGLog(@"IOS6PUSH subscription waitingForToken path=%@", self.path);
        TGDispatchOnMainThread(^
        {
            [TGAppDelegateInstance requestDeviceToken:self];
        });
        
        [ActionStageInstance() actionFailed:self.path reason:-1];
        
        return;
    }
    
    if ([action isEqualToString:@"subscribe"])
    {
        TGLog(@"IOS6PUSH subscription start action=subscribe tokenLength=%d", (int)devicePushToken.length);
        self.cancelToken = [TGTelegraphInstance doUpdatePushSubscription:true deviceToken:devicePushToken requestBuilder:self];
    }
    else if ([action isEqualToString:@"unsubscribe"])
    {
        NSString *tokenToRemove = devicePushToken;
        devicePushToken = nil;
        TGLog(@"IOS6PUSH subscription start action=unsubscribe tokenLength=%d", (int)tokenToRemove.length);
        self.cancelToken = [TGTelegraphInstance doUpdatePushSubscription:false deviceToken:tokenToRemove requestBuilder:self];
    }
    else
    {
        [ActionStageInstance() actionFailed:self.path reason:-1];
    }
}

- (void)deviceTokenRequestCompleted:(NSString *)deviceToken
{
    if (deviceToken != nil)
    {
        TGLog(@"IOS6PUSH token deliveredToSubscription length=%d", (int)deviceToken.length);
        devicePushToken = deviceToken;
        [self execute:nil];
    }
    else
    {
        TGLog(@"IOS6PUSH token unavailable");
        [self pushSubscriptionUpdateFailed];
    }
}

- (void)pushSubscriptionUpdateSuccess
{
    TGLog(@"IOS6PUSH subscription success path=%@", self.path);
    [ActionStageInstance() actionCompleted:self.path result:nil];
}

- (void)pushSubscriptionUpdateFailed
{
    TGLog(@"IOS6PUSH subscription failure path=%@", self.path);
    [ActionStageInstance() actionFailed:self.path reason:-1];
}

@end
