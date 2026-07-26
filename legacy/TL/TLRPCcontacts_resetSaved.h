#ifndef TG_LEGACY_TL_TLRPCCONTACTS_RESETSAVED_H
#define TG_LEGACY_TL_TLRPCCONTACTS_RESETSAVED_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLRPCcontacts_resetSaved : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCcontacts_resetSaved$contacts_resetSaved : TLRPCcontacts_resetSaved


@end

#endif
