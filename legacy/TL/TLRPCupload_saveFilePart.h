#ifndef TG_LEGACY_TL_TLRPCUPLOAD_SAVEFILEPART_H
#define TG_LEGACY_TL_TLRPCUPLOAD_SAVEFILEPART_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLRPCupload_saveFilePart : TLMetaRpc

@property (nonatomic) int64_t file_id;
@property (nonatomic) int32_t file_part;
@property (nonatomic, retain) NSData *bytes;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCupload_saveFilePart$upload_saveFilePart : TLRPCupload_saveFilePart


@end

#endif
