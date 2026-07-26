#ifndef TG_LEGACY_TL_TLPHONECALLPROTOCOL_H
#define TG_LEGACY_TL_TLPHONECALLPROTOCOL_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"


@interface TLPhoneCallProtocol : NSObject <TLObject>

@property (nonatomic) int32_t flags;
@property (nonatomic) int32_t min_layer;
@property (nonatomic) int32_t max_layer;
@property (nonatomic, retain) NSArray *library_versions;

@end

@interface TLPhoneCallProtocol$phoneCallProtocol : TLPhoneCallProtocol


@end

#endif
