#ifndef TG_LEGACY_TL_TLINVOKEAFTERMSG_H
#define TG_LEGACY_TL_TLINVOKEAFTERMSG_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLInvokeAfterMsg : NSObject <TLObject>

@property (nonatomic) int64_t msg_id;
@property (nonatomic) id<NSObject> query;

@end

@interface TLInvokeAfterMsg$invokeAfterMsg : TLInvokeAfterMsg


@end

#endif
