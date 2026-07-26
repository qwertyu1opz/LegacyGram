#import "TLauth_Authorization$auth_authorization.h"

#import "TLMetaClassStore.h"

@implementation TLauth_Authorization$auth_authorization

- (void)TLserialize:(NSOutputStream *)__unused os
{
    TGLog(@"***** TLauth_Authorization$auth_authorization serialization not supported");
}

- (id<TLObject>)TLdeserialize:(NSInputStream *)is signature:(int32_t)__unused signature environment:(id<TLSerializationEnvironment>)__unused environment context:(TLSerializationContext *)__unused context error:(__autoreleasing NSError **)__unused error
{
    TLauth_Authorization$auth_authorization *result = [[TLauth_Authorization$auth_authorization alloc] init];
    
    int32_t flags = [is readInt32];
    result.flags = flags;
    TGLog(@"IOS6AUTH auth.authorization parse signature=0x%08x flags=%d", signature, flags);
    
    if (flags & (1 << 0)) {
        result.tmp_sessions = [is readInt32];
        TGLog(@"IOS6AUTH auth.authorization tmp_sessions=%d", result.tmp_sessions);
    }
    
    if (flags & (1 << 1)) {
        int32_t otherwiseReloginDays = [is readInt32];
        TGLog(@"IOS6AUTH auth.authorization otherwise_relogin_days=%d", otherwiseReloginDays);
    }
    
    if (flags & (1 << 2)) {
        NSData *futureAuthToken = [is readBytes];
        TGLog(@"IOS6AUTH auth.authorization future_auth_token_len=%d", (int)futureAuthToken.length);
    }
    
    {
        int32_t signature = [is readInt32];
        TGLog(@"IOS6AUTH auth.authorization user signature=0x%08x", signature);
        result.user = TLMetaClassStore::constructObject(is, signature, environment, nil, error);
        if (error != nil && *error != nil) {
            return nil;
        }
    }
    
    return result;
}

@end
