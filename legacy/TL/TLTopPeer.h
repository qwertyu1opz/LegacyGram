#ifndef TG_LEGACY_TL_TLTOPPEER_H
#define TG_LEGACY_TL_TLTOPPEER_H

#import <Foundation/Foundation.h>

#import "TLObject.h"
#import "TLMetaRpc.h"

@class TLPeer;

@interface TLTopPeer : NSObject <TLObject>

@property (nonatomic, retain) TLPeer *peer;
@property (nonatomic) double rating;

@end

@interface TLTopPeer$topPeer : TLTopPeer


@end

#endif
