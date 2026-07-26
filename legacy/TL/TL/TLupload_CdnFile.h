#ifndef TG_LEGACY_TL_TLUPLOAD_CDNFILE_H
#define TG_LEGACY_TL_TLUPLOAD_CDNFILE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLupload_CdnFile : NSObject <TLObject>


@end

@interface TLupload_CdnFile$upload_cdnFileReuploadNeeded : TLupload_CdnFile

@property (nonatomic, retain) NSData *request_token;

@end

@interface TLupload_CdnFile$upload_cdnFile : TLupload_CdnFile

@property (nonatomic, retain) NSData *bytes;

@end

#endif
