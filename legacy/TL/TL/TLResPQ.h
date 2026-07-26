#ifndef TG_LEGACY_TL_TLRESPQ_H
#define TG_LEGACY_TL_TLRESPQ_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLResPQ : NSObject <TLObject>

@property (nonatomic, retain) NSData *nonce;
@property (nonatomic, retain) NSData *server_nonce;
@property (nonatomic, retain) NSData *pq;
@property (nonatomic, retain) NSArray *server_public_key_fingerprints;

@end

@interface TLResPQ$resPQ : TLResPQ


@end

#endif
