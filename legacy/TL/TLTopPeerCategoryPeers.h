#ifndef TG_LEGACY_TL_TLTOPPEERCATEGORYPEERS_H
#define TG_LEGACY_TL_TLTOPPEERCATEGORYPEERS_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLTopPeerCategory;

@interface TLTopPeerCategoryPeers : NSObject <TLObject>

@property (nonatomic, retain) TLTopPeerCategory *category;
@property (nonatomic) int32_t count;
@property (nonatomic, retain) NSArray *peers;

@end

@interface TLTopPeerCategoryPeers$topPeerCategoryPeers : TLTopPeerCategoryPeers


@end

#endif
