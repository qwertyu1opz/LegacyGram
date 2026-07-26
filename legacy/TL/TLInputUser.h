#ifndef TG_LEGACY_TL_TLINPUTUSER_H
#define TG_LEGACY_TL_TLINPUTUSER_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLInputUser : NSObject <TLObject>


@end

@interface TLInputUser$inputUserEmpty : TLInputUser


@end

@interface TLInputUser$inputUserSelf : TLInputUser


@end

@interface TLInputUser$inputUser : TLInputUser

@property (nonatomic) int64_t user_id;
@property (nonatomic) int64_t access_hash;

@end

#endif
