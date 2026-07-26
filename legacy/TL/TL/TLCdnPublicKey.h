#ifndef TG_LEGACY_TL_TLCDNPUBLICKEY_H
#define TG_LEGACY_TL_TLCDNPUBLICKEY_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLCdnPublicKey : NSObject <TLObject>

@property (nonatomic) int32_t dc_id;
@property (nonatomic, retain) NSString *public_key;

@end

@interface TLCdnPublicKey$cdnPublicKey : TLCdnPublicKey


@end

#endif
