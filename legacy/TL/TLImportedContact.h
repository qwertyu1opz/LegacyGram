#ifndef TG_LEGACY_TL_TLIMPORTEDCONTACT_H
#define TG_LEGACY_TL_TLIMPORTEDCONTACT_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLImportedContact : NSObject <TLObject>

@property (nonatomic) int32_t user_id;
@property (nonatomic) int64_t client_id;

@end

@interface TLImportedContact$importedContact : TLImportedContact


@end

#endif
