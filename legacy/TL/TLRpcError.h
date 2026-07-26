#ifndef TG_LEGACY_TL_TLRPCERROR_H
#define TG_LEGACY_TL_TLRPCERROR_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLRpcError : NSObject <TLObject>

@property (nonatomic) int32_t error_code;
@property (nonatomic, retain) NSString *error_message;

@end

@interface TLRpcError$rpc_error : TLRpcError


@end

#endif
