#ifndef TG_LEGACY_TL_TLSECUREVALUEHASH_H
#define TG_LEGACY_TL_TLSECUREVALUEHASH_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLSecureValueType;

@interface TLSecureValueHash : NSObject <TLObject>

@end

@interface TLSecureValueHash$secureValueHash : TLSecureValueHash

@property (nonatomic, retain) TLSecureValueType *type;
@property (nonatomic, retain) NSData *n_hash;

@end

#endif
