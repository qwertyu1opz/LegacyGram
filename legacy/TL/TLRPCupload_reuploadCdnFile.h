#ifndef TG_LEGACY_TL_TLRPCUPLOAD_REUPLOADCDNFILE_H
#define TG_LEGACY_TL_TLRPCUPLOAD_REUPLOADCDNFILE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class NSArray_FileHash;

@interface TLRPCupload_reuploadCdnFile : TLMetaRpc

@property (nonatomic, retain) NSData *file_token;
@property (nonatomic, retain) NSData *request_token;

- (Class)responseClass;

- (int)impliedResponseSignature;

@end

@interface TLRPCupload_reuploadCdnFile$upload_reuploadCdnFile : TLRPCupload_reuploadCdnFile


@end

#endif
