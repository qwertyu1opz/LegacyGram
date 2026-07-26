#ifndef TG_LEGACY_TL_TLINPUTFILE_H
#define TG_LEGACY_TL_TLINPUTFILE_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLInputFile : NSObject <TLObject>

@property (nonatomic) int64_t n_id;
@property (nonatomic) int32_t parts;
@property (nonatomic, retain) NSString *name;

@end

@interface TLInputFile$inputFile : TLInputFile

@property (nonatomic, retain) NSString *md5_checksum;

@end

@interface TLInputFile$inputFileBig : TLInputFile


@end

#endif
