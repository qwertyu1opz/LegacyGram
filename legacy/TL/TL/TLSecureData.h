#ifndef TG_LEGACY_TL_TLSECUREDATA_H
#define TG_LEGACY_TL_TLSECUREDATA_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLSecureData : NSObject <TLObject>

@property (nonatomic, retain) NSData *data;
@property (nonatomic, retain) NSData *data_hash;
@property (nonatomic, retain) NSData *secret;

@end

@interface TLSecureData$secureData : TLSecureData

@end

#endif
