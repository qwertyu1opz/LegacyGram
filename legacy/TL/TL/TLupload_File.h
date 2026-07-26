#ifndef TG_LEGACY_TL_TLUPLOAD_FILE_H
#define TG_LEGACY_TL_TLUPLOAD_FILE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLstorage_FileType;

@interface TLupload_File : NSObject <TLObject>


@end

@interface TLupload_File$upload_file : TLupload_File

@property (nonatomic, retain) TLstorage_FileType *type;
@property (nonatomic) int32_t mtime;
@property (nonatomic, retain) NSData *bytes;

@end

@interface TLupload_File$upload_fileCdnRedirect : TLupload_File

@property (nonatomic) int32_t dc_id;
@property (nonatomic, retain) NSData *file_token;
@property (nonatomic, retain) NSData *encryption_key;
@property (nonatomic, retain) NSData *encryption_iv;
@property (nonatomic, retain) NSArray *file_hashes;

@end

#endif
