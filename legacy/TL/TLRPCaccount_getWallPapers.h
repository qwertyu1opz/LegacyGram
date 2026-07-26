#ifndef TG_LEGACY_TL_TLRPCACCOUNT_GETWALLPAPERS_H
#define TG_LEGACY_TL_TLRPCACCOUNT_GETWALLPAPERS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class NSArray_WallPaper;

@interface TLRPCaccount_getWallPapers : TLMetaRpc


- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCaccount_getWallPapers$account_getWallPapers : TLRPCaccount_getWallPapers


@end

#endif
