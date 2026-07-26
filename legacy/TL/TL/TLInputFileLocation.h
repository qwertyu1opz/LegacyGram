#ifndef TG_LEGACY_TL_TLINPUTFILELOCATION_H
#define TG_LEGACY_TL_TLINPUTFILELOCATION_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLInputFileLocation : NSObject <TLObject>


@end

@interface TLInputFileLocation$inputFileLocation : TLInputFileLocation

@property (nonatomic) int64_t volume_id;
@property (nonatomic) int32_t local_id;
@property (nonatomic) int64_t secret;
@property (nonatomic, strong) NSData *file_reference;

@end

@interface TLInputFileLocation$inputEncryptedFileLocation : TLInputFileLocation

@property (nonatomic) int64_t n_id;
@property (nonatomic) int64_t access_hash;

@end

@interface TLInputFileLocation$inputDocumentFileLocation : TLInputFileLocation

@property (nonatomic) int64_t n_id;
@property (nonatomic) int64_t access_hash;
@property (nonatomic, strong) NSData *file_reference;
@property (nonatomic, strong) NSString *thumb_size;

@end

@interface TLInputFileLocation$inputPhotoFileLocation : TLInputFileLocation

@property (nonatomic) int64_t n_id;
@property (nonatomic) int64_t access_hash;
@property (nonatomic, strong) NSData *file_reference;
@property (nonatomic, strong) NSString *thumb_size;

@end

@interface TLInputFileLocation$inputPeerPhotoFileLocation : TLInputFileLocation

@property (nonatomic) int64_t peer_id;
@property (nonatomic) int64_t access_hash;
@property (nonatomic) int64_t photo_id;
@property (nonatomic) int32_t peer_type;
@property (nonatomic) bool big;

@end

@interface TLInputFileLocation$inputSecureFileLocation : TLInputFileLocation

@property (nonatomic) int64_t n_id;
@property (nonatomic) int64_t access_hash;

@end

#endif
